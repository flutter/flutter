// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <utility>

#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/fl_text_input_plugin.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_method_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger_response_handle.h"
#include "flutter/shell/platform/linux/testing/mock_im_context.h"
#include "flutter/shell/platform/linux/testing/mock_text_input_view_delegate.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

void printTo(FlMethodResponse* response, ::std::ostream* os) {
  *os << ::testing::PrintToString(
      fl_method_response_get_result(response, nullptr));
}

MATCHER_P(SuccessResponse, result, "") {
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), arg, nullptr);
  if (fl_value_equal(fl_method_response_get_result(response, nullptr),
                     result)) {
    return true;
  }
  *result_listener << ::testing::PrintToString(response);
  return false;
}

MATCHER_P(FlValueEq, value, "equal to " + ::testing::PrintToString(value)) {
  return fl_value_equal(arg, value);
}

class MethodCallMatcher {
 public:
  using is_gtest_matcher = void;

  explicit MethodCallMatcher(::testing::Matcher<std::string> name,
                             ::testing::Matcher<FlValue*> args)
      : name_(std::move(name)), args_(std::move(args)) {}

  bool MatchAndExplain(GBytes* method_call,
                       ::testing::MatchResultListener* result_listener) const {
    g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
    g_autoptr(GError) error = nullptr;
    g_autofree gchar* name = nullptr;
    g_autoptr(FlValue) args = nullptr;
    gboolean result = fl_method_codec_decode_method_call(
        FL_METHOD_CODEC(codec), method_call, &name, &args, &error);
    if (!result) {
      *result_listener << ::testing::PrintToString(error->message);
      return false;
    }
    if (!name_.MatchAndExplain(name, result_listener)) {
      *result_listener << " where the name doesn't match: \"" << name << "\"";
      return false;
    }
    if (!args_.MatchAndExplain(args, result_listener)) {
      *result_listener << " where the args don't match: "
                       << ::testing::PrintToString(args);
      return false;
    }
    return true;
  }

  void DescribeTo(std::ostream* os) const {
    *os << "method name ";
    name_.DescribeTo(os);
    *os << " and args ";
    args_.DescribeTo(os);
  }

  void DescribeNegationTo(std::ostream* os) const {
    *os << "method name ";
    name_.DescribeNegationTo(os);
    *os << " or args ";
    args_.DescribeNegationTo(os);
  }

 private:
  ::testing::Matcher<std::string> name_;
  ::testing::Matcher<FlValue*> args_;
};

::testing::Matcher<GBytes*> MethodCall(const std::string& name,
                                       ::testing::Matcher<FlValue*> args) {
  return MethodCallMatcher(::testing::StrEq(name), std::move(args));
}

static FlValue* build_map(std::map<const gchar*, FlValue*> args) {
  FlValue* value = fl_value_new_map();
  for (auto it = args.begin(); it != args.end(); ++it) {
    fl_value_set_string_take(value, it->first, it->second);
  }
  return value;
}

static FlValue* build_list(std::vector<FlValue*> args) {
  FlValue* value = fl_value_new_list();
  for (auto it = args.begin(); it != args.end(); ++it) {
    fl_value_append_take(value, *it);
  }
  return value;
}

struct InputConfig {
  int64_t client_id = -1;
  const gchar* input_type = "TextInputType.text";
  const gchar* input_action = "TextInputAction.none";
  gboolean enable_delta_model = false;
};

static FlValue* build_input_config(InputConfig config) {
  return build_list({
      fl_value_new_int(config.client_id),
      build_map({
          {"inputAction", fl_value_new_string(config.input_action)},
          {"inputType", build_map({
                            {"name", fl_value_new_string(config.input_type)},
                        })},
          {"enableDeltaModel", fl_value_new_bool(config.enable_delta_model)},
      }),
  });
}

struct EditingState {
  const gchar* text = "";
  int selection_base = -1;
  int selection_extent = -1;
  int composing_base = -1;
  int composing_extent = -1;
};

static FlValue* build_editing_state(EditingState state) {
  return build_map({
      {"text", fl_value_new_string(state.text)},
      {"selectionBase", fl_value_new_int(state.selection_base)},
      {"selectionExtent", fl_value_new_int(state.selection_extent)},
      {"selectionAffinity", fl_value_new_string("TextAffinity.downstream")},
      {"selectionIsDirectional", fl_value_new_bool(false)},
      {"composingBase", fl_value_new_int(state.composing_base)},
      {"composingExtent", fl_value_new_int(state.composing_extent)},
  });
}

struct EditingDelta {
  const gchar* old_text = "";
  const gchar* delta_text = "";
  int delta_start = -1;
  int delta_end = -1;
  int selection_base = -1;
  int selection_extent = -1;
  int composing_base = -1;
  int composing_extent = -1;
};

static FlValue* build_editing_delta(EditingDelta delta) {
  return build_map({
      {"oldText", fl_value_new_string(delta.old_text)},
      {"deltaText", fl_value_new_string(delta.delta_text)},
      {"deltaStart", fl_value_new_int(delta.delta_start)},
      {"deltaEnd", fl_value_new_int(delta.delta_end)},
      {"selectionBase", fl_value_new_int(delta.selection_base)},
      {"selectionExtent", fl_value_new_int(delta.selection_extent)},
      {"selectionAffinity", fl_value_new_string("TextAffinity.downstream")},
      {"selectionIsDirectional", fl_value_new_bool(false)},
      {"composingBase", fl_value_new_int(delta.composing_base)},
      {"composingExtent", fl_value_new_int(delta.composing_extent)},
  });
}

static void send_key_event(FlTextInputPlugin* plugin,
                           gint keyval,
                           gint state = 0) {
  GdkEvent* gdk_event = gdk_event_new(GDK_KEY_PRESS);
  gdk_event->key.keyval = keyval;
  gdk_event->key.state = state;
  FlKeyEvent* key_event = fl_key_event_new_from_gdk_event(gdk_event);
  fl_text_input_plugin_filter_keypress(plugin, key_event);
  fl_key_event_dispose(key_event);
}

TEST(FlTextInputPluginTest, MessageHandler) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  EXPECT_TRUE(messenger.HasMessageHandler("flutter/textinput"));
}

TEST(FlTextInputPluginTest, SetClient) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  g_autoptr(FlValue) args = build_input_config({.client_id = 1});
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", args, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", message);
}

TEST(FlTextInputPluginTest, Show) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  EXPECT_CALL(context,
              gtk_im_context_focus_in(::testing::Eq<GtkIMContext*>(context)));

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.show", nullptr, nullptr);

  messenger.ReceiveMessage("flutter/textinput", message);
}

TEST(FlTextInputPluginTest, Hide) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  EXPECT_CALL(context,
              gtk_im_context_focus_out(::testing::Eq<GtkIMContext*>(context)));

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.hide", nullptr, nullptr);

  messenger.ReceiveMessage("flutter/textinput", message);
}

TEST(FlTextInputPluginTest, ClearClient) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.clearClient", nullptr, nullptr);

  messenger.ReceiveMessage("flutter/textinput", message);
}

TEST(FlTextInputPluginTest, PerformAction) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  // set input config
  g_autoptr(FlValue) config = build_input_config({
      .client_id = 1,
      .input_type = "TextInputType.multiline",
      .input_action = "TextInputAction.newline",
  });
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", config, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  // set editing state
  g_autoptr(FlValue) state = build_editing_state({
      .text = "Flutter",
      .selection_base = 7,
      .selection_extent = 7,
  });
  g_autoptr(GBytes) set_state = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setEditingState", state, nullptr);

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_state);

  // update editing state
  g_autoptr(FlValue) new_state = build_list({
      fl_value_new_int(1),  // client_id
      build_editing_state({
          .text = "Flutter\n",
          .selection_base = 8,
          .selection_extent = 8,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(new_state)),
                             ::testing::_, ::testing::_, ::testing::_));

  // perform action
  g_autoptr(FlValue) action = build_list({
      fl_value_new_int(1),  // client_id
      fl_value_new_string("TextInputAction.newline"),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.performAction",
                                        FlValueEq(action)),
                             ::testing::_, ::testing::_, ::testing::_));

  send_key_event(plugin, GDK_KEY_Return);
}

// Regression test for https://github.com/flutter/flutter/issues/125879.
TEST(FlTextInputPluginTest, MultilineWithSendAction) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  // Set input config.
  g_autoptr(FlValue) config = build_input_config({
      .client_id = 1,
      .input_type = "TextInputType.multiline",
      .input_action = "TextInputAction.send",
  });
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", config, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  // Set editing state.
  g_autoptr(FlValue) state = build_editing_state({
      .text = "Flutter",
      .selection_base = 7,
      .selection_extent = 7,
  });
  g_autoptr(GBytes) set_state = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setEditingState", state, nullptr);

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_state);

  // Perform action.
  g_autoptr(FlValue) action = build_list({
      fl_value_new_int(1),  // client_id
      fl_value_new_string("TextInputAction.send"),
  });

  // Because the input action is not set to TextInputAction.newline, the next
  // expected call is "TextInputClient.performAction". If the input action was
  // set to TextInputAction.newline the next call would be
  // "TextInputClient.updateEditingState" (this case is tested in the test named
  // 'PerformAction').
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.performAction",
                                        FlValueEq(action)),
                             ::testing::_, ::testing::_, ::testing::_));

  send_key_event(plugin, GDK_KEY_Return);
}

TEST(FlTextInputPluginTest, MoveCursor) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  // set input config
  g_autoptr(FlValue) config = build_input_config({.client_id = 1});
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", config, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  // set editing state
  g_autoptr(FlValue) state = build_editing_state({
      .text = "Flutter",
      .selection_base = 4,
      .selection_extent = 4,
  });
  g_autoptr(GBytes) set_state = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setEditingState", state, nullptr);

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_state);

  // move cursor to beginning
  g_autoptr(FlValue) beginning = build_list({
      fl_value_new_int(1),  // client_id
      build_editing_state({
          .text = "Flutter",
          .selection_base = 0,
          .selection_extent = 0,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(beginning)),
                             ::testing::_, ::testing::_, ::testing::_));

  send_key_event(plugin, GDK_KEY_Home);

  // move cursor to end
  g_autoptr(FlValue) end = build_list({
      fl_value_new_int(1),  // client_id
      build_editing_state({
          .text = "Flutter",
          .selection_base = 7,
          .selection_extent = 7,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(end)),
                             ::testing::_, ::testing::_, ::testing::_));

  send_key_event(plugin, GDK_KEY_End);
}

TEST(FlTextInputPluginTest, Select) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  // set input config
  g_autoptr(FlValue) config = build_input_config({.client_id = 1});
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", config, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  // set editing state
  g_autoptr(FlValue) state = build_editing_state({
      .text = "Flutter",
      .selection_base = 4,
      .selection_extent = 4,
  });
  g_autoptr(GBytes) set_state = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setEditingState", state, nullptr);

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_state);

  // select to end
  g_autoptr(FlValue) select_to_end = build_list({
      fl_value_new_int(1),  // client_id
      build_editing_state({
          .text = "Flutter",
          .selection_base = 4,
          .selection_extent = 7,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(select_to_end)),
                             ::testing::_, ::testing::_, ::testing::_));

  send_key_event(plugin, GDK_KEY_End, GDK_SHIFT_MASK);

  // select to beginning
  g_autoptr(FlValue) select_to_beginning = build_list({
      fl_value_new_int(1),  // client_id
      build_editing_state({
          .text = "Flutter",
          .selection_base = 4,
          .selection_extent = 0,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(select_to_beginning)),
                             ::testing::_, ::testing::_, ::testing::_));

  send_key_event(plugin, GDK_KEY_Home, GDK_SHIFT_MASK);
}

TEST(FlTextInputPluginTest, Composing) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  g_signal_emit_by_name(context, "preedit-start", nullptr);

  // update
  EXPECT_CALL(context,
              gtk_im_context_get_preedit_string(
                  ::testing::Eq<GtkIMContext*>(context),
                  ::testing::A<gchar**>(), ::testing::_, ::testing::A<gint*>()))
      .WillOnce(
          ::testing::DoAll(::testing::SetArgPointee<1>(g_strdup("Flutter")),
                           ::testing::SetArgPointee<3>(0)));

  g_autoptr(FlValue) state = build_list({
      fl_value_new_int(-1),  // client_id
      build_editing_state({
          .text = "Flutter",
          .selection_base = 0,
          .selection_extent = 0,
          .composing_base = 0,
          .composing_extent = 7,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(state)),
                             ::testing::_, ::testing::_, ::testing::_));

  g_signal_emit_by_name(context, "preedit-changed", nullptr);

  // commit
  g_autoptr(FlValue) commit = build_list({
      fl_value_new_int(-1),  // client_id
      build_editing_state({
          .text = "engine",
          .selection_base = 6,
          .selection_extent = 6,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(commit)),
                             ::testing::_, ::testing::_, ::testing::_));

  g_signal_emit_by_name(context, "commit", "engine", nullptr);

  // end
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        ::testing::_),
                             ::testing::_, ::testing::_, ::testing::_));

  g_signal_emit_by_name(context, "preedit-end", nullptr);
}

TEST(FlTextInputPluginTest, SurroundingText) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  // set input config
  g_autoptr(FlValue) config = build_input_config({.client_id = 1});
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", config, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  // set editing state
  g_autoptr(FlValue) state = build_editing_state({
      .text = "Flutter",
      .selection_base = 3,
      .selection_extent = 3,
  });
  g_autoptr(GBytes) set_state = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setEditingState", state, nullptr);

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_state);

  // retrieve
  EXPECT_CALL(context, gtk_im_context_set_surrounding(
                           ::testing::Eq<GtkIMContext*>(context),
                           ::testing::StrEq("Flutter"), 7, 3));

  gboolean retrieved = false;
  g_signal_emit_by_name(context, "retrieve-surrounding", &retrieved, nullptr);
  EXPECT_TRUE(retrieved);

  // delete
  g_autoptr(FlValue) update = build_list({
      fl_value_new_int(1),  // client_id
      build_editing_state({
          .text = "Flutr",
          .selection_base = 3,
          .selection_extent = 3,
      }),
  });

  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/textinput"),
                             MethodCall("TextInputClient.updateEditingState",
                                        FlValueEq(update)),
                             ::testing::_, ::testing::_, ::testing::_));

  gboolean deleted = false;
  g_signal_emit_by_name(context, "delete-surrounding", 1, 2, &deleted, nullptr);
  EXPECT_TRUE(deleted);
}

TEST(FlTextInputPluginTest, SetMarkedTextRect) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  g_signal_emit_by_name(context, "preedit-start", nullptr);

  // set editable size and transform
  g_autoptr(FlValue) size_and_transform = build_map({
      {
          "transform",
          build_list({
              fl_value_new_float(1),
              fl_value_new_float(2),
              fl_value_new_float(3),
              fl_value_new_float(4),
              fl_value_new_float(5),
              fl_value_new_float(6),
              fl_value_new_float(7),
              fl_value_new_float(8),
              fl_value_new_float(9),
              fl_value_new_float(10),
              fl_value_new_float(11),
              fl_value_new_float(12),
              fl_value_new_float(13),
              fl_value_new_float(14),
              fl_value_new_float(15),
              fl_value_new_float(16),
          }),
      },
  });
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_editable_size_and_transform =
      fl_method_codec_encode_method_call(
          FL_METHOD_CODEC(codec), "TextInput.setEditableSizeAndTransform",
          size_and_transform, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput",
                           set_editable_size_and_transform);

  // set marked text rect
  g_autoptr(FlValue) rect = build_map({
      {"x", fl_value_new_float(1)},
      {"y", fl_value_new_float(2)},
      {"width", fl_value_new_float(3)},
      {"height", fl_value_new_float(4)},
  });
  g_autoptr(GBytes) set_marked_text_rect = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setMarkedTextRect", rect, nullptr);

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  EXPECT_CALL(delegate, fl_text_input_view_delegate_translate_coordinates(
                            ::testing::Eq<FlTextInputViewDelegate*>(delegate),
                            ::testing::Eq(27), ::testing::Eq(32), ::testing::_,
                            ::testing::_))
      .WillOnce(::testing::DoAll(::testing::SetArgPointee<3>(123),
                                 ::testing::SetArgPointee<4>(456)));

  EXPECT_CALL(context, gtk_im_context_set_cursor_location(
                           ::testing::Eq<GtkIMContext*>(context),
                           ::testing::Pointee(::testing::AllOf(
                               ::testing::Field(&GdkRectangle::x, 123),
                               ::testing::Field(&GdkRectangle::y, 456),
                               ::testing::Field(&GdkRectangle::width, 0),
                               ::testing::Field(&GdkRectangle::height, 0)))));

  messenger.ReceiveMessage("flutter/textinput", set_marked_text_rect);
}

TEST(FlTextInputPluginTest, TextInputTypeNone) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  g_autoptr(FlValue) args = build_input_config({
      .client_id = 1,
      .input_type = "TextInputType.none",
  });
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", args, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::A<FlBinaryMessengerResponseHandle*>(),
                             SuccessResponse(null), ::testing::A<GError**>()))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  EXPECT_CALL(context,
              gtk_im_context_focus_in(::testing::Eq<GtkIMContext*>(context)))
      .Times(0);
  EXPECT_CALL(context,
              gtk_im_context_focus_out(::testing::Eq<GtkIMContext*>(context)));

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  g_autoptr(GBytes) show = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.show", nullptr, nullptr);

  messenger.ReceiveMessage("flutter/textinput", show);
}

TEST(FlTextInputPluginTest, TextEditingDelta) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  // set config
  g_autoptr(FlValue) args = build_input_config({
      .client_id = 1,
      .enable_delta_model = true,
  });
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", args, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::A<FlBinaryMessengerResponseHandle*>(),
                             SuccessResponse(null), ::testing::A<GError**>()))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  // set editing state
  g_autoptr(FlValue) state = build_editing_state({
      .text = "Flutter",
      .selection_base = 7,
      .selection_extent = 7,
  });
  g_autoptr(GBytes) set_state = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setEditingState", state, nullptr);

  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_state);

  // update editing state with deltas
  g_autoptr(FlValue) deltas = build_list({
      fl_value_new_int(1),  // client_id
      build_map({{
          "deltas",
          build_list({
              build_editing_delta({
                  .old_text = "Flutter",
                  .delta_text = "Flutter",
                  .delta_start = 7,
                  .delta_end = 7,
                  .selection_base = 0,
                  .selection_extent = 0,
              }),
          }),
      }}),
  });

  EXPECT_CALL(messenger,
              fl_binary_messenger_send_on_channel(
                  ::testing::Eq<FlBinaryMessenger*>(messenger),
                  ::testing::StrEq("flutter/textinput"),
                  MethodCall("TextInputClient.updateEditingStateWithDeltas",
                             FlValueEq(deltas)),
                  ::testing::_, ::testing::_, ::testing::_));

  send_key_event(plugin, GDK_KEY_Home);
}

TEST(FlTextInputPluginTest, ComposingDelta) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockIMContext> context;
  ::testing::NiceMock<flutter::testing::MockTextInputViewDelegate> delegate;

  g_autoptr(FlTextInputPlugin) plugin =
      fl_text_input_plugin_new(messenger, context, delegate);
  EXPECT_NE(plugin, nullptr);

  // set config
  g_autoptr(FlValue) args = build_input_config({
      .client_id = 1,
      .enable_delta_model = true,
  });
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) set_client = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", args, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::A<FlBinaryMessengerResponseHandle*>(),
                             SuccessResponse(null), ::testing::A<GError**>()))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", set_client);

  // update
  EXPECT_CALL(context,
              gtk_im_context_get_preedit_string(
                  ::testing::Eq<GtkIMContext*>(context),
                  ::testing::A<gchar**>(), ::testing::_, ::testing::A<gint*>()))
      .WillOnce(
          ::testing::DoAll(::testing::SetArgPointee<1>(g_strdup("Flutter ")),
                           ::testing::SetArgPointee<3>(8)));

  g_autoptr(FlValue) update = build_list({
      fl_value_new_int(1),  // client_id
      build_map({{
          "deltas",
          build_list({
              build_editing_delta({
                  .old_text = "",
                  .delta_text = "Flutter ",
                  .delta_start = 0,
                  .delta_end = 8,
                  .selection_base = 8,
                  .selection_extent = 8,
                  .composing_base = 0,
                  .composing_extent = 8,
              }),
          }),
      }}),
  });

  EXPECT_CALL(messenger,
              fl_binary_messenger_send_on_channel(
                  ::testing::Eq<FlBinaryMessenger*>(messenger),
                  ::testing::StrEq("flutter/textinput"),
                  MethodCall("TextInputClient.updateEditingStateWithDeltas",
                             FlValueEq(update)),
                  ::testing::_, ::testing::_, ::testing::_));

  g_signal_emit_by_name(context, "preedit-changed", nullptr);

  // commit
  g_autoptr(FlValue) commit = build_list({
      fl_value_new_int(1),  // client_id
      build_map({{
          "deltas",
          build_list({
              build_editing_delta({
                  .old_text = "Flutter ",
                  .delta_text = "engine",
                  .delta_start = 8,
                  .delta_end = 8,
                  .selection_base = 14,
                  .selection_extent = 14,
                  .composing_base = 0,
                  .composing_extent = 8,
              }),
          }),
      }}),
  });

  EXPECT_CALL(messenger,
              fl_binary_messenger_send_on_channel(
                  ::testing::Eq<FlBinaryMessenger*>(messenger),
                  ::testing::StrEq("flutter/textinput"),
                  MethodCall("TextInputClient.updateEditingStateWithDeltas",
                             FlValueEq(commit)),
                  ::testing::_, ::testing::_, ::testing::_));

  g_signal_emit_by_name(context, "commit", "engine", nullptr);

  // end
  g_autoptr(FlValue) end = build_list({
      fl_value_new_int(1),  // client_id
      build_map({{
          "deltas",
          build_list({
              build_editing_delta({
                  .delta_text = "Flutter engine",
                  .selection_base = 14,
                  .selection_extent = 14,
              }),
          }),
      }}),
  });

  EXPECT_CALL(messenger,
              fl_binary_messenger_send_on_channel(
                  ::testing::Eq<FlBinaryMessenger*>(messenger),
                  ::testing::StrEq("flutter/textinput"),
                  MethodCall("TextInputClient.updateEditingStateWithDeltas",
                             FlValueEq(end)),
                  ::testing::_, ::testing::_, ::testing::_));

  g_signal_emit_by_name(context, "preedit-end", nullptr);
}
