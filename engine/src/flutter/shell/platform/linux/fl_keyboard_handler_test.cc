// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_handler.h"

#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

static constexpr char kKeyboardChannelName[] = "flutter/keyboard";
static constexpr char kGetKeyboardStateMethod[] = "getKeyboardState";
static constexpr uint64_t kMockPhysicalKey = 42;
static constexpr uint64_t kMockLogicalKey = 42;

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMockKeyboardHandlerDelegate,
                     fl_mock_keyboard_handler_delegate,
                     FL,
                     MOCK_KEYBOARD_HANDLER_DELEGATE,
                     GObject);

G_END_DECLS

MATCHER_P(MethodSuccessResponse, result, "") {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), arg, nullptr);
  fl_method_response_get_result(response, nullptr);
  if (fl_value_equal(fl_method_response_get_result(response, nullptr),
                     result)) {
    return true;
  }
  *result_listener << ::testing::PrintToString(response);
  return false;
}

struct _FlMockKeyboardHandlerDelegate {
  GObject parent_instance;
};

static void fl_mock_keyboard_handler_delegate_keyboard_view_delegate_iface_init(
    FlKeyboardViewDelegateInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlMockKeyboardHandlerDelegate,
    fl_mock_keyboard_handler_delegate,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(
        fl_keyboard_view_delegate_get_type(),
        fl_mock_keyboard_handler_delegate_keyboard_view_delegate_iface_init))

static void fl_mock_keyboard_handler_delegate_init(
    FlMockKeyboardHandlerDelegate* self) {}

static void fl_mock_keyboard_handler_delegate_class_init(
    FlMockKeyboardHandlerDelegateClass* klass) {}

static GHashTable* fl_mock_view_keyboard_get_keyboard_state(
    FlKeyboardViewDelegate* view_delegate) {
  GHashTable* result = g_hash_table_new(g_direct_hash, g_direct_equal);
  g_hash_table_insert(result, reinterpret_cast<gpointer>(kMockPhysicalKey),
                      reinterpret_cast<gpointer>(kMockLogicalKey));

  return result;
}

static void fl_mock_keyboard_handler_delegate_keyboard_view_delegate_iface_init(
    FlKeyboardViewDelegateInterface* iface) {
  iface->get_keyboard_state = fl_mock_view_keyboard_get_keyboard_state;
}

static FlMockKeyboardHandlerDelegate* fl_mock_keyboard_handler_delegate_new() {
  FlMockKeyboardHandlerDelegate* self = FL_MOCK_KEYBOARD_HANDLER_DELEGATE(
      g_object_new(fl_mock_keyboard_handler_delegate_get_type(), nullptr));

  // Added to stop compiler complaining about an unused function.
  FL_IS_MOCK_KEYBOARD_HANDLER_DELEGATE(self);

  return self;
}

TEST(FlKeyboardHandlerTest, KeyboardChannelGetPressedState) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;

  g_autoptr(FlKeyboardHandler) handler = fl_keyboard_handler_new(
      messenger,
      FL_KEYBOARD_VIEW_DELEGATE(fl_mock_keyboard_handler_delegate_new()));
  EXPECT_NE(handler, nullptr);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), kGetKeyboardStateMethod, nullptr, nullptr);

  g_autoptr(FlValue) response = fl_value_new_map();
  fl_value_set_take(response, fl_value_new_int(kMockPhysicalKey),
                    fl_value_new_int(kMockLogicalKey));
  EXPECT_CALL(messenger,
              fl_binary_messenger_send_response(
                  ::testing::Eq<FlBinaryMessenger*>(messenger), ::testing::_,
                  MethodSuccessResponse(response), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage(kKeyboardChannelName, message);
}
