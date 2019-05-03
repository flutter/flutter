// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <zircon/processargs.h>

#include "fidl/examples/echo/cpp/fidl.h"
#include "lib/async-loop/cpp/loop.h"
#include "lib/async/cpp/wait.h"
#include "lib/async/dispatcher.h"
#include "lib/sys/cpp/testing/enclosing_environment.h"
#include "lib/sys/cpp/testing/test_with_environment.h"
#include "src/lib/fxl/strings/string_printf.h"

using namespace fuchsia::sys;
namespace echo = ::fidl::examples::echo;

namespace sys::testing::test {

constexpr char kHelperProc[] =
    "fuchsia-pkg://fuchsia.com/component_cpp_tests#meta/helper_proc.cmx";
constexpr int kNumberOfTries = 3;

// helper class that creates and listens on
// a socket while appending to a std::stringstream
class SocketReader {
 public:
  SocketReader() : wait_(this) {}

  zx::handle OpenSocket() {
    ZX_ASSERT(!socket_.is_valid());
    zx::socket ret;
    zx::socket::create(0, &ret, &socket_);
    wait_.set_object(socket_.get());
    wait_.set_trigger(ZX_SOCKET_READABLE | ZX_SOCKET_PEER_CLOSED);
    wait_.Begin(async_get_default_dispatcher());
    return zx::handle(std::move(ret));
  }

  std::string GetString() { return stream_.str(); }

  void OnData(async_dispatcher_t* dispatcher, async::WaitBase* wait,
              zx_status_t status, const zx_packet_signal_t* signal) {
    if (status != ZX_OK) {
      return;
    }
    if (signal->observed & ZX_SOCKET_READABLE) {
      char buff[1024];
      size_t actual;
      status = socket_.read(0, buff, sizeof(buff) - 1, &actual);
      ASSERT_EQ(status, ZX_OK);
      buff[actual] = '\0';
      stream_ << buff;
    }

    if (!(signal->observed & ZX_SOCKET_PEER_CLOSED)) {
      wait_.Begin(dispatcher);
    }
  }

 private:
  zx::socket socket_;
  std::stringstream stream_;
  async::WaitMethod<SocketReader, &SocketReader::OnData> wait_;
};

class EnclosingEnvTest : public TestWithEnvironment {
 public:
  // Tries to connect and communicate with echo service
  bool TryEchoService(const std::unique_ptr<EnclosingEnvironment>& env) {
    // We give this part of the test 3 shots to complete
    // this is the safest way to do this and prevent flakiness.
    // Because EnvironmentServices is listening on a ComponentController channel
    // to restart the service, we can't control that it'll actually recreate the
    // service in 100% deterministic order.
    echo::EchoPtr echo;
    for (int tries = 0; tries < kNumberOfTries; tries++) {
      // reset flag again and communicate with the service,
      // it must be spun back up
      bool req_done = false;
      // dismiss old channel

      // connect again
      env->ConnectToService(echo.NewRequest());

      bool channel_closed = false;
      echo.set_error_handler(
          [&](zx_status_t status) { channel_closed = true; });
      // talk with the service once and assert it's ok
      echo->EchoString("hello", [&req_done](::fidl::StringPtr rsp) {
        EXPECT_EQ(rsp, "hello");
        req_done = true;
      });
      RunLoopUntil([&]() { return req_done || channel_closed; });
      if (req_done) {
        return true;
      } else {
        std::cerr << "Didn't receive echo response in attempt number "
                  << (tries + 1) << std::endl;
      }
    }
    return false;
  }
};

TEST_F(EnclosingEnvTest, RespawnService) {
  auto svc = CreateServices();
  LaunchInfo linfo;
  linfo.url = kHelperProc;
  linfo.arguments.reset({"--echo", "--kill=die"});
  svc->AddServiceWithLaunchInfo(std::move(linfo), echo::Echo::Name_);
  auto env = CreateNewEnclosingEnvironment("test-env", std::move(svc));
  ASSERT_TRUE(WaitForEnclosingEnvToStart(env.get()));
  // attempt to connect to service:
  bool req_done = false;
  bool got_error = false;
  echo::EchoPtr echo;
  echo.set_error_handler(
      [&got_error](zx_status_t status) { got_error = true; });
  env->ConnectToService(echo.NewRequest());

  // talk with the service once and assert it's done
  echo->EchoString("hello", [&req_done](::fidl::StringPtr rsp) {
    ASSERT_EQ(rsp, "hello");
    req_done = true;
  });
  ASSERT_TRUE(RunLoopUntil([&req_done]() { return req_done; }));

  // reset flag, and send the kill string
  req_done = false;
  // talk with the service once and assert it's done
  echo->EchoString("die", [&req_done](::fidl::StringPtr rsp) {
    ASSERT_EQ(rsp, "die");
    req_done = true;
  });

  // wait until we see the response AND the channel closing
  ASSERT_TRUE(RunLoopUntil(
      [&req_done, &got_error]() { return req_done && got_error; }));

  // Try to communicate with server again, we expect
  // it to be spun up once more
  ASSERT_TRUE(TryEchoService(env));
}

TEST_F(EnclosingEnvTest, EnclosingEnvOnASeperateThread) {
  std::unique_ptr<sys::testing::EnclosingEnvironment> env = nullptr;
  async::Loop loop(&kAsyncLoopConfigNoAttachToThread);
  loop.StartThread("vfs test thread");

  auto svc =
      sys::testing::EnvironmentServices::Create(real_env(), loop.dispatcher());

  LaunchInfo linfo;
  linfo.url = kHelperProc;
  linfo.arguments.reset({"--echo", "--kill=die"});
  svc->AddServiceWithLaunchInfo(std::move(linfo), echo::Echo::Name_);
  env = CreateNewEnclosingEnvironment("test-env", std::move(svc));
  ASSERT_TRUE(WaitForEnclosingEnvToStart(env.get()));

  echo::EchoSyncPtr echo_ptr;
  env->ConnectToService(echo_ptr.NewRequest());
  fidl::StringPtr response;
  echo_ptr->EchoString("hello1", &response);

  ASSERT_EQ(response, "hello1");
}

TEST_F(EnclosingEnvTest, RespawnServiceWithHandler) {
  auto svc = CreateServices();

  int call_counter = 0;
  svc->AddServiceWithLaunchInfo(
      kHelperProc,
      [&call_counter]() {
        LaunchInfo linfo;
        linfo.url = kHelperProc;
        linfo.arguments.reset({"--echo", "--kill=die"});
        call_counter++;
        return linfo;
      },
      echo::Echo::Name_);
  auto env = CreateNewEnclosingEnvironment("test-env", std::move(svc));
  ASSERT_TRUE(WaitForEnclosingEnvToStart(env.get()));
  // attempt to connect to service:
  bool req_done = false;
  bool got_error = false;
  echo::EchoPtr echo;
  echo.set_error_handler(
      [&got_error](zx_status_t status) { got_error = true; });
  env->ConnectToService(echo.NewRequest());

  // talk with the service once and assert it's done
  echo->EchoString("hello", [&req_done](::fidl::StringPtr rsp) {
    ASSERT_EQ(rsp, "hello");
    req_done = true;
  });
  ASSERT_TRUE(RunLoopUntil([&req_done]() { return req_done; }));
  // check that the launch info factory function was called only once
  EXPECT_EQ(call_counter, 1);

  // reset flag, and send the kill string
  req_done = false;
  // talk with the service once and assert it's done
  echo->EchoString("die", [&req_done](::fidl::StringPtr rsp) {
    ASSERT_EQ(rsp, "die");
    req_done = true;
  });

  // wait until we see the response AND the channel closing
  ASSERT_TRUE(RunLoopUntil(
      [&req_done, &got_error]() { return req_done && got_error; }));

  // Try to communicate with server again, we expect
  // it to be spun up once more
  ASSERT_TRUE(TryEchoService(env));

  // check that the launch info factory function was called only TWICE
  EXPECT_EQ(call_counter, 2);
}

TEST_F(EnclosingEnvTest, OutErrPassing) {
  auto svc = CreateServices();

  SocketReader cout_reader;
  SocketReader cerr_reader;
  svc->AddServiceWithLaunchInfo(
      kHelperProc,
      [&cout_reader, &cerr_reader]() {
        LaunchInfo linfo;
        linfo.url = kHelperProc;
        linfo.arguments.reset({"--echo", "--cout=potato", "--cerr=tomato"});

        linfo.out = FileDescriptor::New();
        linfo.out->type0 = PA_FD;
        linfo.out->handle0 = cout_reader.OpenSocket();
        linfo.err = FileDescriptor::New();
        linfo.err->type0 = PA_FD;
        linfo.err->handle0 = cerr_reader.OpenSocket();

        return linfo;
      },
      echo::Echo::Name_);
  auto env = CreateNewEnclosingEnvironment("test-env", std::move(svc));
  ASSERT_TRUE(WaitForEnclosingEnvToStart(env.get()));
  // attempt to connect to service:
  echo::EchoPtr echo;

  // this should trigger hello_proc to start and
  // print "potato" to cout and "tomato" to err
  env->ConnectToService(echo.NewRequest());

  // now it's just a matter of waiting for the socket readers to
  // have seen those strings:
  ASSERT_TRUE(RunLoopUntil([&cout_reader, &cerr_reader]() {
    return cout_reader.GetString().find("potato") != std::string::npos &&
           cerr_reader.GetString().find("tomato") != std::string::npos;
  }));
}

class FakeLoader : public fuchsia::sys::Loader {
 public:
  FakeLoader() {
    loader_service_ = std::make_shared<vfs::Service>(
        [this](zx::channel channel, async_dispatcher_t* dispatcher) {
          bindings_.AddBinding(
              this,
              fidl::InterfaceRequest<fuchsia::sys::Loader>(std::move(channel)),
              dispatcher);
        });
  }

  void LoadUrl(std::string url, LoadUrlCallback callback) override {
    ASSERT_TRUE(!url.empty());
    component_urls_.push_back(url);
  }
  std::vector<std::string>& component_urls() { return component_urls_; };

  std::shared_ptr<vfs::Service> loader_service() { return loader_service_; }

 private:
  std::shared_ptr<vfs::Service> loader_service_;
  fidl::BindingSet<fuchsia::sys::Loader> bindings_;
  std::vector<std::string> component_urls_;
};

TEST_F(EnclosingEnvTest, CanLaunchMoreThanOneService) {
  FakeLoader loader;
  auto loader_service = loader.loader_service();
  auto svc = CreateServicesWithCustomLoader(loader_service);

  std::vector<std::string> urls;
  std::vector<std::string> svc_names;
  for (int i = 0; i < 3; i++) {
    auto url = fxl::StringPrintf(
        "fuchsia-pkg://fuchsia.com/dummy%d#meta/dummy%d.cmx", i, i);
    auto svc_name = fxl::StringPrintf("service%d", i);
    LaunchInfo linfo;
    linfo.url = url;
    svc->AddServiceWithLaunchInfo(std::move(linfo), svc_name);
    urls.push_back(url);
    svc_names.push_back(svc_name);
  }
  auto env = CreateNewEnclosingEnvironment("test-env", std::move(svc));
  ASSERT_TRUE(WaitForEnclosingEnvToStart(env.get()));

  for (int i = 0; i < 3; i++) {
    echo::EchoPtr echo;
    env->ConnectToService(echo.NewRequest(), svc_names[i]);
  }
  ASSERT_TRUE(RunLoopUntil([&loader]() {
    return loader.component_urls().size() == 3;
  })) << loader.component_urls().size();
  ASSERT_EQ(loader.component_urls(), urls);
}

}  // namespace sys::testing::test
