// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/ui/views/cpp/fidl.h>
#include <gtest/gtest.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async-loop/default.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>

#include "focus_delegate.h"
#include "tests/fakes/focuser.h"
#include "tests/fakes/platform_message.h"
#include "tests/fakes/view_ref_focused.h"
#include "third_party/rapidjson/include/rapidjson/document.h"

rapidjson::Value ParsePlatformMessage(std::string json) {
  rapidjson::Document document;
  document.Parse(json);
  if (document.HasParseError() || !document.IsObject()) {
    FML_LOG(ERROR) << "Could not parse document";
    return rapidjson::Value();
  }
  return document.GetObject();
}

namespace flutter_runner::testing {

class FocusDelegateTest : public ::testing::Test {
 public:
  std::unique_ptr<FakeViewRefFocused> vrf;
  std::unique_ptr<FakeFocuser> focuser;
  std::unique_ptr<FocusDelegate> focus_delegate;

  void RunLoopUntilIdle() { loop_.RunUntilIdle(); }

 protected:
  FocusDelegateTest() : loop_(&kAsyncLoopConfigAttachToCurrentThread) {}

  void SetUp() override {
    vrf = std::make_unique<FakeViewRefFocused>();
    focuser = std::make_unique<FakeFocuser>();
    focus_delegate = std::make_unique<FocusDelegate>(
        vrf_bindings.AddBinding(vrf.get()),
        focuser_bindings.AddBinding(focuser.get()));
  }

  void TearDown() override {
    vrf_bindings.CloseAll();
    focuser_bindings.CloseAll();
    loop_.Quit();
    loop_.ResetQuit();
  }

 private:
  async::Loop loop_;
  fidl::BindingSet<ViewRefFocused> vrf_bindings;
  fidl::BindingSet<Focuser> focuser_bindings;

  FML_DISALLOW_COPY_AND_ASSIGN(FocusDelegateTest);
};

// Tests that WatchLoop() should callback and complete PlatformMessageResponses
// correctly, given a series of vrf invocations.
TEST_F(FocusDelegateTest, WatchCallbackSeries) {
  std::vector<bool> vrf_states{false, true,  true, false,
                               true,  false, true, true};
  std::size_t vrf_index = 0;
  std::size_t callback_index = 0;
  focus_delegate->WatchLoop([&](bool focus_state) {
    // Make sure the focus state that FocusDelegate gives us is consistent with
    // what was fired from the vrf.
    EXPECT_EQ(vrf_states[callback_index], focus_state);

    // View.focus.getCurrent should complete with the current (up to date) focus
    // state.
    auto response = FakePlatformMessageResponse::Create();
    EXPECT_TRUE(focus_delegate->HandlePlatformMessage(
        ParsePlatformMessage("{\"method\":\"View.focus.getCurrent\"}"),
        response));
    response->ExpectCompleted(focus_state ? "[true]" : "[false]");

    // Ensure this callback always happens in lockstep with
    // vrf->ScheduleCallback.
    EXPECT_EQ(vrf_index, callback_index++);
  });

  // Subsequent WatchLoop calls should not be respected.
  focus_delegate->WatchLoop([](bool _) {
    ADD_FAILURE() << "Subsequent WatchLoops should not be respected!";
  });

  do {
    // Ensure the next focus state is handled correctly.
    auto response1 = FakePlatformMessageResponse::Create();
    EXPECT_TRUE(focus_delegate->HandlePlatformMessage(
        ParsePlatformMessage("{\"method\":\"View.focus.getNext\"}"),
        response1));

    // Since there's already an outstanding PlatformMessageResponse, this one
    // should be completed null.
    auto response2 = FakePlatformMessageResponse::Create();
    EXPECT_TRUE(focus_delegate->HandlePlatformMessage(
        ParsePlatformMessage("{\"method\":\"View.focus.getNext\"}"),
        response2));
    response2->ExpectCompleted("[null]");

    // Post watch events and trigger the next vrf event.
    RunLoopUntilIdle();
    vrf->ScheduleCallback(vrf_states[vrf_index]);
    RunLoopUntilIdle();

    // Next focus state should be completed by now.
    response1->ExpectCompleted(vrf_states[vrf_index] ? "[true]" : "[false]");

    // Check View.focus.getCurrent again, and increment vrf_index since we move
    // on to the next focus state.
    auto response3 = FakePlatformMessageResponse::Create();
    EXPECT_TRUE(focus_delegate->HandlePlatformMessage(
        ParsePlatformMessage("{\"method\":\"View.focus.getCurrent\"}"),
        response3));
    response3->ExpectCompleted(vrf_states[vrf_index++] ? "[true]" : "[false]");

    // vrf->times_watched should always be 1 more than the amount of vrf events
    // emitted.
    EXPECT_EQ(vrf_index + 1, vrf->times_watched);
  } while (vrf_index < vrf_states.size());
}

// Tests that HandlePlatformMessage() completes a "View.focus.request" response
// with a non-error status code.
TEST_F(FocusDelegateTest, RequestFocusTest) {
  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();
  // Create the platform message request.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.focus.request\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request with an expected completion response.
  auto response = FakePlatformMessageResponse::Create();
  EXPECT_TRUE(focus_delegate->HandlePlatformMessage(
      ParsePlatformMessage(message.str()), response));
  RunLoopUntilIdle();

  response->ExpectCompleted("[0]");
  EXPECT_TRUE(focuser->request_focus_called());
}

// Tests that HandlePlatformMessage() completes a "View.focus.request" response
// with a Error::DENIED status code.
TEST_F(FocusDelegateTest, RequestFocusFailTest) {
  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();
  // We're testing the focus failure case.
  focuser->fail_request_focus();
  // Create the platform message request.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.focus.request\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request with an expected completion response.
  auto response = FakePlatformMessageResponse::Create();
  EXPECT_TRUE(focus_delegate->HandlePlatformMessage(
      ParsePlatformMessage(message.str()), response));
  RunLoopUntilIdle();

  response->ExpectCompleted(
      "[" +
      std::to_string(
          static_cast<std::underlying_type_t<fuchsia::ui::views::Error>>(
              fuchsia::ui::views::Error::DENIED)) +
      "]");
  EXPECT_TRUE(focuser->request_focus_called());
}

// Tests that WatchLoop() should callback and complete PlatformMessageResponses
// correctly, given a series of vrf invocations.
// TODO(fxbug.dev/79740): Delete after soft transition.
TEST_F(FocusDelegateTest, DeprecatedWatchCallbackSeries) {
  std::vector<bool> vrf_states{false, true,  true, false,
                               true,  false, true, true};
  std::size_t vrf_index = 0;
  std::size_t callback_index = 0;
  focus_delegate->WatchLoop([&](bool focus_state) {
    // Make sure the focus state that FocusDelegate gives us is consistent with
    // what was fired from the vrf.
    EXPECT_EQ(vrf_states[callback_index], focus_state);

    // CompleteCurrentFocusState should complete with the current (up to date)
    // focus state.
    auto response = FakePlatformMessageResponse::Create();
    EXPECT_TRUE(focus_delegate->CompleteCurrentFocusState(response));
    response->ExpectCompleted(focus_state ? "[true]" : "[false]");

    // Ensure this callback always happens in lockstep with
    // vrf->ScheduleCallback.
    EXPECT_EQ(vrf_index, callback_index++);
  });

  // Subsequent WatchLoop calls should not be respected.
  focus_delegate->WatchLoop([](bool _) {
    ADD_FAILURE() << "Subsequent WatchLoops should not be respected!";
  });

  do {
    // Ensure the next focus state is handled correctly.
    auto response1 = FakePlatformMessageResponse::Create();
    EXPECT_TRUE(focus_delegate->CompleteNextFocusState(response1));

    // Since there's already an outstanding PlatformMessageResponse, this one
    // should be completed empty.
    auto response = FakePlatformMessageResponse::Create();
    EXPECT_FALSE(focus_delegate->CompleteNextFocusState(response));

    // Post watch events and trigger the next vrf event.
    RunLoopUntilIdle();
    vrf->ScheduleCallback(vrf_states[vrf_index]);
    RunLoopUntilIdle();

    // Next focus state should be completed by now.
    response1->ExpectCompleted(vrf_states[vrf_index] ? "[true]" : "[false]");

    // Check CompleteCurrentFocusState again, and increment vrf_index, since we
    // move on to the next focus state.
    response = FakePlatformMessageResponse::Create();
    EXPECT_TRUE(focus_delegate->CompleteCurrentFocusState(response));
    response->ExpectCompleted(vrf_states[vrf_index++] ? "[true]" : "[false]");

    // vrf->times_watched should always be 1 more than the amount of vrf events
    // emitted.
    EXPECT_EQ(vrf_index + 1, vrf->times_watched);
  } while (vrf_index < vrf_states.size());
}

// Tests that RequestFocus() completes the platform message's response with a
// non-error status code.
// TODO(fxbug.dev/79740): Delete after soft transition.
TEST_F(FocusDelegateTest, DeprecatedRequestFocusTest) {
  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();
  // Create the platform message request.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.requestFocus\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request with an expected completion response.
  auto response = FakePlatformMessageResponse::Create();
  focus_delegate->RequestFocus(ParsePlatformMessage(message.str()), response);
  RunLoopUntilIdle();

  response->ExpectCompleted("[0]");
  EXPECT_TRUE(focuser->request_focus_called());
}

// Tests that RequestFocus() completes the platform message's response with a
// Error::DENIED status code.
// TODO(fxbug.dev/79740): Delete after soft transition.
TEST_F(FocusDelegateTest, DeprecatedRequestFocusFailTest) {
  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();
  // We're testing the focus failure case.
  focuser->fail_request_focus();
  // Create the platform message request.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.requestFocus\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request with an expected completion response.
  auto response = FakePlatformMessageResponse::Create();
  focus_delegate->RequestFocus(ParsePlatformMessage(message.str()), response);
  RunLoopUntilIdle();

  response->ExpectCompleted(
      "[" +
      std::to_string(
          static_cast<std::underlying_type_t<fuchsia::ui::views::Error>>(
              fuchsia::ui::views::Error::DENIED)) +
      "]");
  EXPECT_TRUE(focuser->request_focus_called());
}

}  // namespace flutter_runner::testing
