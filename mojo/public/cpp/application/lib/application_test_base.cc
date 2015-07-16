// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/application_test_base.h"

#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/system/message_pipe.h"
#include "mojo/public/interfaces/application/application.mojom.h"

namespace mojo {
namespace test {

namespace {
// Share the application command-line arguments with multiple application tests.
Array<String> g_args;

// Share the application URL with multiple application tests.
String g_url;

// Application request handle passed from the shell in MojoMain, stored in
// between SetUp()/TearDown() so we can (re-)intialize new ApplicationImpls.
InterfaceRequest<Application> g_application_request;

// Shell pointer passed in the initial mojo.Application.Initialize() call,
// stored in between initial setup and the first test and between SetUp/TearDown
// calls so we can (re-)initialize new ApplicationImpls.
ShellPtr g_shell;

void InitializeArgs(int argc, std::vector<const char*> argv) {
  MOJO_CHECK(g_args.is_null());
  for (const char* arg : argv) {
    if (arg)
      g_args.push_back(arg);
  }
}

class ShellAndArgumentGrabber : public Application {
 public:
  ShellAndArgumentGrabber(Array<String>* args,
                          InterfaceRequest<Application> application_request)
      : args_(args), binding_(this, application_request.Pass()) {}

  void WaitForInitialize() {
    // Initialize is always the first call made on Application.
    MOJO_CHECK(binding_.WaitForIncomingMethodCall());
  }

 private:
  // Application implementation.
  void Initialize(ShellPtr shell,
                  Array<String> args,
                  const mojo::String& url) override {
    *args_ = args.Pass();
    g_url = url;
    g_application_request = binding_.Unbind();
    g_shell = shell.Pass();
  }

  void AcceptConnection(const String& requestor_url,
                        InterfaceRequest<ServiceProvider> services,
                        ServiceProviderPtr exposed_services,
                        const String& url) override {
    MOJO_CHECK(false);
  }

  void RequestQuit() override { MOJO_CHECK(false); }

  Array<String>* args_;
  Binding<Application> binding_;
};

}  // namespace

const Array<String>& Args() {
  return g_args;
}

MojoResult RunAllTests(MojoHandle application_request_handle) {
  {
    // This loop is used for init, and then destroyed before running tests.
    Environment::InstantiateDefaultRunLoop();

    // Grab the shell handle and GTEST commandline arguments.
    // GTEST command line arguments are supported amid application arguments:
    // $ mojo_shell mojo:example_apptests
    //   --args-for='mojo:example_apptests arg1 --gtest_filter=foo arg2'
    Array<String> args;
    ShellAndArgumentGrabber grabber(
        &args, MakeRequest<Application>(MakeScopedHandle(
                   MessagePipeHandle(application_request_handle))));
    grabber.WaitForInitialize();
    MOJO_CHECK(g_shell);
    MOJO_CHECK(g_application_request.is_pending());

    // InitGoogleTest expects (argc + 1) elements, including a terminating null.
    // It also removes GTEST arguments from |argv| and updates the |argc| count.
    MOJO_CHECK(args.size() <
               static_cast<size_t>(std::numeric_limits<int>::max()));
    int argc = static_cast<int>(args.size());
    std::vector<const char*> argv(argc + 1);
    for (int i = 0; i < argc; ++i)
      argv[i] = args[i].get().c_str();
    argv[argc] = nullptr;

    testing::InitGoogleTest(&argc, const_cast<char**>(&(argv[0])));
    InitializeArgs(argc, argv);

    Environment::DestroyDefaultRunLoop();
  }

  int result = RUN_ALL_TESTS();

  // Shut down our message pipes before exiting.
  (void)g_application_request.PassMessagePipe();
  (void)g_shell.PassInterface();

  return (result == 0) ? MOJO_RESULT_OK : MOJO_RESULT_UNKNOWN;
}

ApplicationTestBase::ApplicationTestBase() : application_impl_(nullptr) {
}

ApplicationTestBase::~ApplicationTestBase() {
}

ApplicationDelegate* ApplicationTestBase::GetApplicationDelegate() {
  return &default_application_delegate_;
}

void ApplicationTestBase::SetUp() {
  // A run loop is recommended for ApplicationImpl initialization and
  // communication.
  if (ShouldCreateDefaultRunLoop())
    Environment::InstantiateDefaultRunLoop();

  MOJO_CHECK(g_application_request.is_pending());
  MOJO_CHECK(g_shell);

  // New applications are constructed for each test to avoid persisting state.
  application_impl_ = new ApplicationImpl(GetApplicationDelegate(),
                                          g_application_request.Pass());

  // Fake application initialization with the given command line arguments.
  application_impl_->Initialize(g_shell.Pass(), g_args.Clone(), g_url);
}

void ApplicationTestBase::TearDown() {
  MOJO_CHECK(!g_application_request.is_pending());
  MOJO_CHECK(!g_shell);

  application_impl_->UnbindConnections(&g_application_request, &g_shell);
  delete application_impl_;
  if (ShouldCreateDefaultRunLoop())
    Environment::DestroyDefaultRunLoop();
}

bool ApplicationTestBase::ShouldCreateDefaultRunLoop() {
  return true;
}

}  // namespace test
}  // namespace mojo
