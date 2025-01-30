// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/windowing_handler.h"

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/method_result_functions.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_method_codec.h"
#include "flutter/shell/platform/windows/flutter_host_window_controller.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
using ::testing::_;
using ::testing::Eq;
using ::testing::Matches;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::StrEq;

constexpr char kChannelName[] = "flutter/windowing";
constexpr char kCreateWindowMethod[] = "createWindow";
constexpr char kCreatePopupMethod[] = "createPopup";
constexpr char kDestroyWindowMethod[] = "destroyWindow";

constexpr char kAnchorRectKey[] = "anchorRect";
constexpr char kChildAnchorKey[] = "childAnchor";
constexpr char kConstraintAdjustmentKey[] = "constraintAdjustment";
constexpr char kMinSizeKey[] = "minSize";
constexpr char kMaxSizeKey[] = "maxSize";
constexpr char kOffsetKey[] = "offset";
constexpr char kParentAnchorKey[] = "parentAnchor";
constexpr char kParentViewIdKey[] = "parentViewId";
constexpr char kPositionerKey[] = "positioner";
constexpr char kSizeKey[] = "size";
constexpr char kStateKey[] = "state";
constexpr char kTitleKey[] = "title";

void SimulateWindowingMessage(TestBinaryMessenger* messenger,
                              const std::string& method_name,
                              std::unique_ptr<EncodableValue> arguments,
                              MethodResult<EncodableValue>* result_handler) {
  MethodCall<> call(method_name, std::move(arguments));

  auto message = StandardMethodCodec::GetInstance().EncodeMethodCall(call);

  EXPECT_TRUE(messenger->SimulateEngineMessage(
      kChannelName, message->data(), message->size(),
      [&result_handler](const uint8_t* reply, size_t reply_size) {
        StandardMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, result_handler);
      }));
}

class MockFlutterHostWindowController : public FlutterHostWindowController {
 public:
  MockFlutterHostWindowController(FlutterWindowsEngine* engine)
      : FlutterHostWindowController(engine) {}
  ~MockFlutterHostWindowController() = default;

  MOCK_METHOD(std::optional<WindowMetadata>,
              CreateHostWindow,
              (WindowCreationSettings const& settings),
              (override));
  MOCK_METHOD(bool, DestroyHostWindow, (FlutterViewId view_id), (override));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockFlutterHostWindowController);
};

}  // namespace

class WindowingHandlerTest : public WindowsTest {
 public:
  WindowingHandlerTest() = default;
  virtual ~WindowingHandlerTest() = default;

 protected:
  void SetUp() override {
    FlutterWindowsEngineBuilder builder(GetContext());
    engine_ = builder.Build();

    mock_controller_ =
        std::make_unique<NiceMock<MockFlutterHostWindowController>>(
            engine_.get());

    ON_CALL(*mock_controller_, CreateHostWindow)
        .WillByDefault([](WindowCreationSettings const& settings) {
          return WindowMetadata{
              .size = settings.size,
              .parent_id = settings.parent_view_id,
              .state = WindowState::kRestored,
              .relative_position = Point{},
          };
        });
    ON_CALL(*mock_controller_, DestroyHostWindow).WillByDefault(Return(true));
  }

  MockFlutterHostWindowController* controller() {
    return mock_controller_.get();
  }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::unique_ptr<NiceMock<MockFlutterHostWindowController>> mock_controller_;

  FML_DISALLOW_COPY_AND_ASSIGN(WindowingHandlerTest);
};

MATCHER_P(WindowPositionerMatches, expected, "Matches WindowPositioner") {
  return arg.anchor_rect == expected.anchor_rect &&
         arg.parent_anchor == expected.parent_anchor &&
         arg.child_anchor == expected.child_anchor &&
         arg.offset == expected.offset &&
         arg.constraint_adjustment == expected.constraint_adjustment;
}

MATCHER_P(WindowCreationSettingsMatches,
          expected,
          "Matches WindowCreationSettings") {
  return arg.archetype == expected.archetype && arg.size == expected.size &&
         arg.min_size == expected.min_size &&
         arg.max_size == expected.max_size && arg.title == expected.title &&
         arg.state == expected.state &&
         arg.parent_view_id == expected.parent_view_id &&
         (arg.positioner.has_value() == expected.positioner.has_value()) &&
         (!arg.positioner.has_value() ||
          Matches(WindowPositionerMatches(expected.positioner.value()))(
              arg.positioner.value()));
}

TEST_F(WindowingHandlerTest, HandleCreateRegularWindow) {
  TestBinaryMessenger messenger;
  WindowingHandler windowing_handler(&messenger, controller());

  WindowCreationSettings const settings = {
      .archetype = WindowArchetype::kRegular,
      .size = {800.0, 600.0},
      .title = "regular",
  };

  EncodableMap const arguments = {
      {EncodableValue(kSizeKey),
       EncodableValue(EncodableList{EncodableValue(settings.size.width()),
                                    EncodableValue(settings.size.height())})},
      {EncodableValue(kMinSizeKey), EncodableValue()},
      {EncodableValue(kMaxSizeKey), EncodableValue()},
      {EncodableValue(kTitleKey), EncodableValue(*settings.title)},
      {EncodableValue(kStateKey), EncodableValue()},
  };

  bool success = false;
  MethodResultFunctions<> result_handler(
      [&success](const EncodableValue* result) { success = true; }, nullptr,
      nullptr);

  EXPECT_CALL(*controller(),
              CreateHostWindow(WindowCreationSettingsMatches(settings)))
      .Times(1);

  SimulateWindowingMessage(&messenger, kCreateWindowMethod,
                           std::make_unique<EncodableValue>(arguments),
                           &result_handler);

  EXPECT_TRUE(success);
}

TEST_F(WindowingHandlerTest, HandleCreatePopup) {
  TestBinaryMessenger messenger;
  WindowingHandler windowing_handler(&messenger, controller());

  Size const size = {200.0, 200.0};
  WindowPositioner const positioner = WindowPositioner{
      .anchor_rect = std::optional<Rect>({{0.0, 0.0}, size}),
      .parent_anchor = WindowPositioner::Anchor::kCenter,
      .child_anchor = WindowPositioner::Anchor::kCenter,
      .offset = {0.0, 0.0},
      .constraint_adjustment =
          WindowPositioner::ConstraintAdjustment::kSlideAny,
  };

  WindowCreationSettings const settings = {
      .archetype = WindowArchetype::kPopup,
      .size = size,
      .parent_view_id = 0,
      .positioner = positioner,
  };

  EncodableMap const arguments = {
      {EncodableValue(kParentViewIdKey),
       EncodableValue(static_cast<int>(settings.parent_view_id.value()))},
      {EncodableValue(kSizeKey),
       EncodableValue(EncodableList{EncodableValue(settings.size.width()),
                                    EncodableValue(settings.size.height())})},
      {EncodableValue(kMinSizeKey), EncodableValue()},
      {EncodableValue(kMaxSizeKey), EncodableValue()},
      {EncodableValue(kPositionerKey),
       EncodableValue(EncodableMap{
           {EncodableValue(kAnchorRectKey),
            EncodableValue(EncodableList{
                EncodableValue(positioner.anchor_rect->left()),
                EncodableValue(positioner.anchor_rect->top()),
                EncodableValue(positioner.anchor_rect->width()),
                EncodableValue(positioner.anchor_rect->height())})},
           {EncodableValue(kParentAnchorKey),
            EncodableValue("WindowPositionerAnchor.center")},
           {EncodableValue(kChildAnchorKey),
            EncodableValue("WindowPositionerAnchor.center")},
           {EncodableValue(kOffsetKey),
            EncodableValue(
                EncodableList{EncodableValue(positioner.offset.x()),
                              EncodableValue(positioner.offset.y())})},
           {EncodableValue(kConstraintAdjustmentKey),
            EncodableValue(EncodableValue(EncodableList{
                EncodableValue("WindowPositionerConstraintAdjustment.slideX"),
                EncodableValue(
                    "WindowPositionerConstraintAdjustment.slideY")}))},
       })},
  };

  bool success = false;
  MethodResultFunctions<> result_handler(
      [&success](const EncodableValue* result) { success = true; }, nullptr,
      nullptr);

  EXPECT_CALL(*controller(),
              CreateHostWindow(WindowCreationSettingsMatches(settings)))
      .Times(1);

  SimulateWindowingMessage(&messenger, kCreatePopupMethod,
                           std::make_unique<EncodableValue>(arguments),
                           &result_handler);

  EXPECT_TRUE(success);
}

TEST_F(WindowingHandlerTest, HandleDestroyWindow) {
  TestBinaryMessenger messenger;
  WindowingHandler windowing_handler(&messenger, controller());

  EncodableMap const arguments = {
      {EncodableValue("viewId"), EncodableValue(1)},
  };

  bool success = false;
  MethodResultFunctions<> result_handler(
      [&success](const EncodableValue* result) { success = true; }, nullptr,
      nullptr);

  EXPECT_CALL(*controller(), DestroyHostWindow(1)).Times(1);

  SimulateWindowingMessage(&messenger, kDestroyWindowMethod,
                           std::make_unique<EncodableValue>(arguments),
                           &result_handler);

  EXPECT_TRUE(success);
}

}  // namespace testing
}  // namespace flutter
