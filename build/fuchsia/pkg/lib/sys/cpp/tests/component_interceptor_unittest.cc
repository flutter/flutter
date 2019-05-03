// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include <vector>

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/gtest/real_loop_fixture.h>
#include <lib/sys/cpp/testing/component_interceptor.h>
#include <lib/sys/cpp/testing/test_with_environment.h>

#include "gtest/gtest.h"

namespace {

using fuchsia::sys::TerminationReason;

// Records |LoadUrl|s, but forwards requests to a fallback loader.
class TestLoader : fuchsia::sys::Loader {
 public:
  // Fallback loader comes from the supplied |env|.
  TestLoader(const fuchsia::sys::EnvironmentPtr& env) {
    fuchsia::sys::ServiceProviderPtr sp;
    env->GetServices(sp.NewRequest());
    sp->ConnectToService(fuchsia::sys::Loader::Name_,
                         fallback_loader_.NewRequest().TakeChannel());
  }

  virtual ~TestLoader() = default;

  fuchsia::sys::LoaderPtr NewRequest() {
    fuchsia::sys::LoaderPtr loader;
    loader.Bind(bindings_.AddBinding(this));
    return loader;
  }

  // |fuchsia::sys::Loader|
  void LoadUrl(std::string url, LoadUrlCallback response) override {
    requested_urls.push_back(url);
    fallback_loader_->LoadUrl(url, std::move(response));
  }

  std::vector<std::string> requested_urls;

 private:
  fidl::BindingSet<fuchsia::sys::Loader> bindings_;
  fuchsia::sys::LoaderPtr fallback_loader_;
};

// This fixture gives us a real_env().
class ComponentInterceptorTest : public sys::testing::TestWithEnvironment {};

// This tests fallback-loader and intercept-url cases using the same enclosing
// environment.
TEST_F(ComponentInterceptorTest, TestFallbackAndInterceptingUrls) {
  TestLoader test_loader(real_env());

  sys::testing::ComponentInterceptor interceptor(test_loader.NewRequest());
  auto env = sys::testing::EnclosingEnvironment::Create(
      "test_harness", real_env(),
      interceptor.MakeEnvironmentServices(real_env()));

  constexpr char kInterceptUrl[] = "file://intercept_url";
  constexpr char kFallbackUrl[] = "file://fallback_url";

  // Test the intercepting case.
  {
    std::string actual_url;

    bool intercepted_url = false;
    ASSERT_TRUE(interceptor.InterceptURL(
        kInterceptUrl, "",
        [&actual_url, &intercepted_url](
            fuchsia::sys::StartupInfo startup_info,
            std::unique_ptr<sys::testing::InterceptedComponent> component) {
          intercepted_url = true;
          actual_url = startup_info.launch_info.url;
        }));

    fuchsia::sys::ComponentControllerPtr controller;
    fuchsia::sys::LaunchInfo info;
    info.url = kInterceptUrl;
    env->CreateComponent(std::move(info), controller.NewRequest());

    ASSERT_TRUE(RunLoopUntil([&] { return intercepted_url; }));
    EXPECT_EQ(kInterceptUrl, actual_url);
  }

  test_loader.requested_urls.clear();

  // Test the fallback loader case.
  {
    fuchsia::sys::ComponentControllerPtr controller;
    fuchsia::sys::LaunchInfo info;
    info.url = kFallbackUrl;
    // Should this call into our TestLoader.
    env->CreateComponent(std::move(info), controller.NewRequest());

    ASSERT_TRUE(
        RunLoopUntil([&] { return test_loader.requested_urls.size() > 0u; }));

    EXPECT_EQ(kFallbackUrl, test_loader.requested_urls[0]);
  }
}

TEST_F(ComponentInterceptorTest, TestOnKill) {
  TestLoader test_loader(real_env());

  sys::testing::ComponentInterceptor interceptor(test_loader.NewRequest());
  auto env = sys::testing::EnclosingEnvironment::Create(
      "test_harness", real_env(),
      interceptor.MakeEnvironmentServices(real_env()));

  constexpr char kInterceptUrl[] = "file://intercept_url";

  // Test the intercepting case.
  std::string actual_url;

  bool killed = false;
  std::unique_ptr<sys::testing::InterceptedComponent> component;
  ASSERT_TRUE(interceptor.InterceptURL(
      kInterceptUrl, "",
      [&](fuchsia::sys::StartupInfo startup_info,
          std::unique_ptr<sys::testing::InterceptedComponent>
              intercepted_component) {
        component = std::move(intercepted_component);
        component->set_on_kill([startup_info = std::move(startup_info),
                                &killed]() { killed = true; });
      }));

  {
    fuchsia::sys::ComponentControllerPtr controller;
    fuchsia::sys::LaunchInfo info;
    info.url = kInterceptUrl;
    env->CreateComponent(std::move(info), controller.NewRequest());

    ASSERT_TRUE(RunLoopUntil([&] { return !!component; }));
    ASSERT_FALSE(killed);
  }
  // should be killed
  ASSERT_TRUE(RunLoopUntil([&] { return killed; }));
}

TEST_F(ComponentInterceptorTest, ExtraCmx) {
  auto interceptor =
      sys::testing::ComponentInterceptor::CreateWithEnvironmentLoader(
          real_env());
  auto env = sys::testing::EnclosingEnvironment::Create(
      "test_harness", real_env(),
      interceptor.MakeEnvironmentServices(real_env()));

  constexpr char kUrl[] = "file://fake_url";
  bool intercepted_url = false;
  std::map<std::string, std::string> program_metadata;
  ASSERT_TRUE(interceptor.InterceptURL(
      kUrl, R"({
        "runner": "fake",
        "program": {
          "binary": "",
          "data": "randomstring"
        }
      })",
      [&](fuchsia::sys::StartupInfo startup_info,
          std::unique_ptr<sys::testing::InterceptedComponent> c) {
        intercepted_url = true;
        for (const auto& metadata : startup_info.program_metadata.get()) {
          program_metadata[metadata.key] = metadata.value;
        }
      }));

  fuchsia::sys::ComponentControllerPtr controller;
  fuchsia::sys::LaunchInfo info;
  info.url = kUrl;

  // This should call into our TestLoader.
  env->CreateComponent(std::move(info), controller.NewRequest());

  // Test that we intercepting URL
  ASSERT_TRUE(
      RunLoopWithTimeoutOrUntil([&] { return intercepted_url; }, zx::sec(2)));
  EXPECT_TRUE(intercepted_url);
  EXPECT_EQ("randomstring", program_metadata["data"]);
}

}  // namespace
