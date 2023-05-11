// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_text_input_plugin.h"

#include <gtk/gtk.h>

#include "flutter/shell/platform/common/text_editing_delta.h"
#include "flutter/shell/platform/common/text_input_model.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_method_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"

static constexpr char kChannelName[] = "flutter/textinput";

static constexpr char kBadArgumentsError[] = "Bad Arguments";

static constexpr char kSetClientMethod[] = "TextInput.setClient";
static constexpr char kShowMethod[] = "TextInput.show";
static constexpr char kSetEditingStateMethod[] = "TextInput.setEditingState";
static constexpr char kClearClientMethod[] = "TextInput.clearClient";
static constexpr char kHideMethod[] = "TextInput.hide";
static constexpr char kUpdateEditingStateMethod[] =
    "TextInputClient.updateEditingState";
static constexpr char kUpdateEditingStateWithDeltasMethod[] =
    "TextInputClient.updateEditingStateWithDeltas";
static constexpr char kPerformActionMethod[] = "TextInputClient.performAction";
static constexpr char kSetEditableSizeAndTransform[] =
    "TextInput.setEditableSizeAndTransform";
static constexpr char kSetMarkedTextRect[] = "TextInput.setMarkedTextRect";

static constexpr char kInputActionKey[] = "inputAction";
static constexpr char kTextInputTypeKey[] = "inputType";
static constexpr char kEnableDeltaModel[] = "enableDeltaModel";
static constexpr char kTextInputTypeNameKey[] = "name";
static constexpr char kTextKey[] = "text";
static constexpr char kSelectionBaseKey[] = "selectionBase";
static constexpr char kSelectionExtentKey[] = "selectionExtent";
static constexpr char kSelectionAffinityKey[] = "selectionAffinity";
static constexpr char kSelectionIsDirectionalKey[] = "selectionIsDirectional";
static constexpr char kComposingBaseKey[] = "composingBase";
static constexpr char kComposingExtentKey[] = "composingExtent";

static constexpr char kTransform[] = "transform";

static constexpr char kTextAffinityDownstream[] = "TextAffinity.downstream";
static constexpr char kMultilineInputType[] = "TextInputType.multiline";
static constexpr char kNoneInputType[] = "TextInputType.none";

static constexpr char kNewlineInputAction[] = "TextInputAction.newline";

static constexpr int64_t kClientIdUnset = -1;

typedef enum {
  kFlTextInputTypeText,
  // Send newline when multi-line and enter is pressed.
  kFlTextInputTypeMultiline,
  // The input method is not shown at all.
  kFlTextInputTypeNone,
} FlTextInputType;

struct FlTextInputPluginPrivate {
  GObject parent_instance;

  FlMethodChannel* channel;

  // Client ID provided by Flutter to report events with.
  int64_t client_id;

  // Input action to perform when enter pressed.
  gchar* input_action;

  // The type of the input method.
  FlTextInputType input_type;

  // Whether to enable that the engine sends text input updates to the framework
  // as TextEditingDeltas or as one TextEditingValue.
  // For more information on the delta model, see:
  // https://master-api.flutter.dev/flutter/services/TextInputConfiguration/enableDeltaModel.html
  gboolean enable_delta_model;

  // Input method.
  GtkIMContext* im_context;

  FlTextInputViewDelegate* view_delegate;

  flutter::TextInputModel* text_model;

  // A 4x4 matrix that maps from `EditableText` local coordinates to the
  // coordinate system of `PipelineOwner.rootNode`.
  double editabletext_transform[4][4];

  // The smallest rect, in local coordinates, of the text in the composing
  // range, or of the caret in the case where there is no current composing
  // range. This value is updated via `TextInput.setMarkedTextRect` messages
  // over the text input channel.
  GdkRectangle composing_rect;
};

G_DEFINE_TYPE_WITH_PRIVATE(FlTextInputPlugin,
                           fl_text_input_plugin,
                           G_TYPE_OBJECT)

// Completes method call and returns TRUE if the call was successful.
static gboolean finish_method(GObject* object,
                              GAsyncResult* result,
                              GError** error) {
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, error);
  if (response == nullptr) {
    return FALSE;
  }
  return fl_method_response_get_result(response, error) != nullptr;
}

// Called when a response is received from TextInputClient.updateEditingState()
static void update_editing_state_response_cb(GObject* object,
                                             GAsyncResult* result,
                                             gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  if (!finish_method(object, result, &error)) {
    g_warning("Failed to call %s: %s", kUpdateEditingStateMethod,
              error->message);
  }
}

// Informs Flutter of text input changes.
static void update_editing_state(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(priv->client_id));
  g_autoptr(FlValue) value = fl_value_new_map();

  flutter::TextRange selection = priv->text_model->selection();
  fl_value_set_string_take(
      value, kTextKey,
      fl_value_new_string(priv->text_model->GetText().c_str()));
  fl_value_set_string_take(value, kSelectionBaseKey,
                           fl_value_new_int(selection.base()));
  fl_value_set_string_take(value, kSelectionExtentKey,
                           fl_value_new_int(selection.extent()));

  int composing_base = -1;
  int composing_extent = -1;
  if (!priv->text_model->composing_range().collapsed()) {
    composing_base = priv->text_model->composing_range().base();
    composing_extent = priv->text_model->composing_range().extent();
  }
  fl_value_set_string_take(value, kComposingBaseKey,
                           fl_value_new_int(composing_base));
  fl_value_set_string_take(value, kComposingExtentKey,
                           fl_value_new_int(composing_extent));

  // The following keys are not implemented and set to default values.
  fl_value_set_string_take(value, kSelectionAffinityKey,
                           fl_value_new_string(kTextAffinityDownstream));
  fl_value_set_string_take(value, kSelectionIsDirectionalKey,
                           fl_value_new_bool(FALSE));

  fl_value_append(args, value);

  fl_method_channel_invoke_method(priv->channel, kUpdateEditingStateMethod,
                                  args, nullptr,
                                  update_editing_state_response_cb, self);
}

// Informs Flutter of text input changes by passing just the delta.
static void update_editing_state_with_delta(FlTextInputPlugin* self,
                                            flutter::TextEditingDelta* delta) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(priv->client_id));

  g_autoptr(FlValue) deltaValue = fl_value_new_map();
  fl_value_set_string_take(deltaValue, "oldText",
                           fl_value_new_string(delta->old_text().c_str()));

  fl_value_set_string_take(deltaValue, "deltaText",
                           fl_value_new_string(delta->delta_text().c_str()));

  fl_value_set_string_take(deltaValue, "deltaStart",
                           fl_value_new_int(delta->delta_start()));

  fl_value_set_string_take(deltaValue, "deltaEnd",
                           fl_value_new_int(delta->delta_end()));

  flutter::TextRange selection = priv->text_model->selection();
  fl_value_set_string_take(deltaValue, "selectionBase",
                           fl_value_new_int(selection.base()));

  fl_value_set_string_take(deltaValue, "selectionExtent",
                           fl_value_new_int(selection.extent()));

  fl_value_set_string_take(deltaValue, "selectionAffinity",
                           fl_value_new_string(kTextAffinityDownstream));

  fl_value_set_string_take(deltaValue, "selectionIsDirectional",
                           fl_value_new_bool(FALSE));

  int composing_base = -1;
  int composing_extent = -1;
  if (!priv->text_model->composing_range().collapsed()) {
    composing_base = priv->text_model->composing_range().base();
    composing_extent = priv->text_model->composing_range().extent();
  }
  fl_value_set_string_take(deltaValue, "composingBase",
                           fl_value_new_int(composing_base));
  fl_value_set_string_take(deltaValue, "composingExtent",
                           fl_value_new_int(composing_extent));

  g_autoptr(FlValue) deltas = fl_value_new_list();
  fl_value_append(deltas, deltaValue);
  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set_string(value, "deltas", deltas);

  fl_value_append(args, value);

  fl_method_channel_invoke_method(
      priv->channel, kUpdateEditingStateWithDeltasMethod, args, nullptr,
      update_editing_state_response_cb, self);
}

// Called when a response is received from TextInputClient.performAction()
static void perform_action_response_cb(GObject* object,
                                       GAsyncResult* result,
                                       gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  if (!finish_method(object, result, &error)) {
    g_warning("Failed to call %s: %s", kPerformActionMethod, error->message);
  }
}

// Inform Flutter that the input has been activated.
static void perform_action(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  g_return_if_fail(FL_IS_TEXT_INPUT_PLUGIN(self));
  g_return_if_fail(priv->client_id != 0);
  g_return_if_fail(priv->input_action != nullptr);

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(priv->client_id));
  fl_value_append_take(args, fl_value_new_string(priv->input_action));

  fl_method_channel_invoke_method(priv->channel, kPerformActionMethod, args,
                                  nullptr, perform_action_response_cb, self);
}

// Signal handler for GtkIMContext::preedit-start
static void im_preedit_start_cb(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  priv->text_model->BeginComposing();
}

// Signal handler for GtkIMContext::preedit-changed
static void im_preedit_changed_cb(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  std::string text_before_change = priv->text_model->GetText();
  g_autofree gchar* buf = nullptr;
  gint cursor_offset = 0;
  gtk_im_context_get_preedit_string(priv->im_context, &buf, nullptr,
                                    &cursor_offset);
  if (priv->text_model->composing()) {
    cursor_offset += priv->text_model->composing_range().start();
  } else {
    cursor_offset += priv->text_model->selection().start();
  }
  priv->text_model->UpdateComposingText(buf);
  priv->text_model->SetSelection(flutter::TextRange(cursor_offset));

  if (priv->enable_delta_model) {
    std::string text(buf);
    flutter::TextEditingDelta delta = flutter::TextEditingDelta(
        text_before_change, priv->text_model->composing_range(), text);
    update_editing_state_with_delta(self, &delta);
  } else {
    update_editing_state(self);
  }
}

// Signal handler for GtkIMContext::commit
static void im_commit_cb(FlTextInputPlugin* self, const gchar* text) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  std::string text_before_change = priv->text_model->GetText();
  flutter::TextRange selection_before_change = priv->text_model->selection();

  priv->text_model->AddText(text);
  if (priv->text_model->composing()) {
    priv->text_model->CommitComposing();
  }

  if (priv->enable_delta_model) {
    flutter::TextEditingDelta delta = flutter::TextEditingDelta(
        text_before_change, selection_before_change, text);
    update_editing_state_with_delta(self, &delta);
  } else {
    update_editing_state(self);
  }
}

// Signal handler for GtkIMContext::preedit-end
static void im_preedit_end_cb(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  priv->text_model->EndComposing();
  if (priv->enable_delta_model) {
    flutter::TextEditingDelta delta = flutter::TextEditingDelta(
        "", flutter::TextRange(-1, -1), priv->text_model->GetText());
    update_editing_state_with_delta(self, &delta);
  } else {
    update_editing_state(self);
  }
}

// Signal handler for GtkIMContext::retrieve-surrounding
static gboolean im_retrieve_surrounding_cb(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  auto text = priv->text_model->GetText();
  size_t cursor_offset = priv->text_model->GetCursorOffset();
  gtk_im_context_set_surrounding(priv->im_context, text.c_str(), -1,
                                 cursor_offset);
  return TRUE;
}

// Signal handler for GtkIMContext::delete-surrounding
static gboolean im_delete_surrounding_cb(FlTextInputPlugin* self,
                                         gint offset,
                                         gint n_chars) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  std::string text_before_change = priv->text_model->GetText();
  if (priv->text_model->DeleteSurrounding(offset, n_chars)) {
    if (priv->enable_delta_model) {
      flutter::TextEditingDelta delta = flutter::TextEditingDelta(
          text_before_change, priv->text_model->composing_range(),
          priv->text_model->GetText());
      update_editing_state_with_delta(self, &delta);
    } else {
      update_editing_state(self);
    }
  }
  return TRUE;
}

// Called when the input method client is set up.
static FlMethodResponse* set_client(FlTextInputPlugin* self, FlValue* args) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(args) < 2) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Expected 2-element list", nullptr));
  }
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  priv->client_id = fl_value_get_int(fl_value_get_list_value(args, 0));
  FlValue* config_value = fl_value_get_list_value(args, 1);
  g_free(priv->input_action);
  FlValue* input_action_value =
      fl_value_lookup_string(config_value, kInputActionKey);
  if (fl_value_get_type(input_action_value) == FL_VALUE_TYPE_STRING) {
    priv->input_action = g_strdup(fl_value_get_string(input_action_value));
  }

  FlValue* enable_delta_model_value =
      fl_value_lookup_string(config_value, kEnableDeltaModel);
  gboolean enable_delta_model = fl_value_get_bool(enable_delta_model_value);
  priv->enable_delta_model = enable_delta_model;

  // Reset the input type, then set only if appropriate.
  priv->input_type = kFlTextInputTypeText;
  FlValue* input_type_value =
      fl_value_lookup_string(config_value, kTextInputTypeKey);
  if (fl_value_get_type(input_type_value) == FL_VALUE_TYPE_MAP) {
    FlValue* input_type_name =
        fl_value_lookup_string(input_type_value, kTextInputTypeNameKey);
    if (fl_value_get_type(input_type_name) == FL_VALUE_TYPE_STRING) {
      const gchar* input_type = fl_value_get_string(input_type_name);
      if (g_strcmp0(input_type, kMultilineInputType) == 0) {
        priv->input_type = kFlTextInputTypeMultiline;
      } else if (g_strcmp0(input_type, kNoneInputType) == 0) {
        priv->input_type = kFlTextInputTypeNone;
      }
    }
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Hides the input method.
static FlMethodResponse* hide(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  gtk_im_context_focus_out(priv->im_context);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Shows the input method.
static FlMethodResponse* show(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  if (priv->input_type == kFlTextInputTypeNone) {
    return hide(self);
  }

  gtk_im_context_focus_in(priv->im_context);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Updates the editing state from Flutter.
static FlMethodResponse* set_editing_state(FlTextInputPlugin* self,
                                           FlValue* args) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  const gchar* text =
      fl_value_get_string(fl_value_lookup_string(args, kTextKey));
  priv->text_model->SetText(text);

  int64_t selection_base =
      fl_value_get_int(fl_value_lookup_string(args, kSelectionBaseKey));
  int64_t selection_extent =
      fl_value_get_int(fl_value_lookup_string(args, kSelectionExtentKey));
  // Flutter uses -1/-1 for invalid; translate that to 0/0 for the model.
  if (selection_base == -1 && selection_extent == -1) {
    selection_base = selection_extent = 0;
  }

  priv->text_model->SetText(text);
  priv->text_model->SetSelection(
      flutter::TextRange(selection_base, selection_extent));

  int64_t composing_base =
      fl_value_get_int(fl_value_lookup_string(args, kComposingBaseKey));
  int64_t composing_extent =
      fl_value_get_int(fl_value_lookup_string(args, kComposingExtentKey));
  if (composing_base == -1 && composing_extent == -1) {
    priv->text_model->EndComposing();
  } else {
    size_t composing_start = std::min(composing_base, composing_extent);
    size_t cursor_offset = selection_base - composing_start;
    priv->text_model->SetComposingRange(
        flutter::TextRange(composing_base, composing_extent), cursor_offset);
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when the input method client is complete.
static FlMethodResponse* clear_client(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  priv->client_id = kClientIdUnset;

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Update the IM cursor position.
//
// As text is input by the user, the framework sends two streams of updates
// over the text input channel: updates to the composing rect (cursor rect when
// not in IME composing mode) and updates to the matrix transform from local
// coordinates to Flutter root coordinates. This function is called after each
// of these updates. It transforms the composing rect to GDK window coordinates
// and notifies GTK of the updated cursor position.
static void update_im_cursor_position(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  // Skip update if not composing to avoid setting to position 0.
  if (!priv->text_model->composing()) {
    return;
  }

  // Transform the x, y positions of the cursor from local coordinates to
  // Flutter view coordinates.
  gint x = priv->composing_rect.x * priv->editabletext_transform[0][0] +
           priv->composing_rect.y * priv->editabletext_transform[1][0] +
           priv->editabletext_transform[3][0] + priv->composing_rect.width;
  gint y = priv->composing_rect.x * priv->editabletext_transform[0][1] +
           priv->composing_rect.y * priv->editabletext_transform[1][1] +
           priv->editabletext_transform[3][1] + priv->composing_rect.height;

  // Transform from Flutter view coordinates to GTK window coordinates.
  GdkRectangle preedit_rect = {};
  fl_text_input_view_delegate_translate_coordinates(
      priv->view_delegate, x, y, &preedit_rect.x, &preedit_rect.y);

  // Set the cursor location in window coordinates so that GTK can position any
  // system input method windows.
  gtk_im_context_set_cursor_location(priv->im_context, &preedit_rect);
}

// Handles updates to the EditableText size and position from the framework.
//
// On changes to the size or position of the RenderObject underlying the
// EditableText, this update may be triggered. It provides an updated size and
// transform from the local coordinate system of the EditableText to root
// Flutter coordinate system.
static FlMethodResponse* set_editable_size_and_transform(
    FlTextInputPlugin* self,
    FlValue* args) {
  FlValue* transform = fl_value_lookup_string(args, kTransform);
  size_t transform_len = fl_value_get_length(transform);
  g_warn_if_fail(transform_len == 16);

  for (size_t i = 0; i < transform_len; ++i) {
    double val = fl_value_get_float(fl_value_get_list_value(transform, i));
    FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
        fl_text_input_plugin_get_instance_private(self));
    priv->editabletext_transform[i / 4][i % 4] = val;
  }
  update_im_cursor_position(self);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Handles updates to the composing rect from the framework.
//
// On changes to the state of the EditableText in the framework, this update
// may be triggered. It provides an updated rect for the composing region in
// local coordinates of the EditableText. In the case where there is no
// composing region, the cursor rect is sent.
static FlMethodResponse* set_marked_text_rect(FlTextInputPlugin* self,
                                              FlValue* args) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  priv->composing_rect.x =
      fl_value_get_float(fl_value_lookup_string(args, "x"));
  priv->composing_rect.y =
      fl_value_get_float(fl_value_lookup_string(args, "y"));
  priv->composing_rect.width =
      fl_value_get_float(fl_value_lookup_string(args, "width"));
  priv->composing_rect.height =
      fl_value_get_float(fl_value_lookup_string(args, "height"));
  update_im_cursor_position(self);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  FlTextInputPlugin* self = FL_TEXT_INPUT_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kSetClientMethod) == 0) {
    response = set_client(self, args);
  } else if (strcmp(method, kShowMethod) == 0) {
    response = show(self);
  } else if (strcmp(method, kSetEditingStateMethod) == 0) {
    response = set_editing_state(self, args);
  } else if (strcmp(method, kClearClientMethod) == 0) {
    response = clear_client(self);
  } else if (strcmp(method, kHideMethod) == 0) {
    response = hide(self);
  } else if (strcmp(method, kSetEditableSizeAndTransform) == 0) {
    response = set_editable_size_and_transform(self, args);
  } else if (strcmp(method, kSetMarkedTextRect) == 0) {
    response = set_marked_text_rect(self, args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method call response: %s", error->message);
  }
}

// Disposes of an FlTextInputPlugin.
static void fl_text_input_plugin_dispose(GObject* object) {
  FlTextInputPlugin* self = FL_TEXT_INPUT_PLUGIN(object);
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  g_clear_object(&priv->channel);
  g_clear_pointer(&priv->input_action, g_free);
  g_clear_object(&priv->im_context);
  if (priv->text_model != nullptr) {
    delete priv->text_model;
    priv->text_model = nullptr;
  }
  if (priv->view_delegate != nullptr) {
    g_object_remove_weak_pointer(
        G_OBJECT(priv->view_delegate),
        reinterpret_cast<gpointer*>(&(priv->view_delegate)));
    priv->view_delegate = nullptr;
  }

  G_OBJECT_CLASS(fl_text_input_plugin_parent_class)->dispose(object);
}

// Implements FlTextInputPlugin::filter_keypress.
static gboolean fl_text_input_plugin_filter_keypress_default(
    FlTextInputPlugin* self,
    FlKeyEvent* event) {
  g_return_val_if_fail(FL_IS_TEXT_INPUT_PLUGIN(self), false);

  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  if (priv->client_id == kClientIdUnset) {
    return FALSE;
  }

  GdkEventKey* key_event = reinterpret_cast<GdkEventKey*>(event->origin);
  if (gtk_im_context_filter_keypress(priv->im_context, key_event)) {
    return TRUE;
  }

  std::string text_before_change = priv->text_model->GetText();
  flutter::TextRange selection_before_change = priv->text_model->selection();
  std::string text = priv->text_model->GetText();

  // Handle the enter/return key.
  gboolean do_action = FALSE;
  // Handle navigation keys.
  gboolean changed = FALSE;
  if (event->is_press) {
    switch (event->keyval) {
      case GDK_KEY_End:
      case GDK_KEY_KP_End:
        if (event->state & GDK_SHIFT_MASK) {
          changed = priv->text_model->SelectToEnd();
        } else {
          changed = priv->text_model->MoveCursorToEnd();
        }
        break;
      case GDK_KEY_Return:
      case GDK_KEY_KP_Enter:
      case GDK_KEY_ISO_Enter:
        if (priv->input_type == kFlTextInputTypeMultiline &&
            strcmp(priv->input_action, kNewlineInputAction) == 0) {
          priv->text_model->AddCodePoint('\n');
          text = "\n";
          changed = TRUE;
        }
        do_action = TRUE;
        break;
      case GDK_KEY_Home:
      case GDK_KEY_KP_Home:
        if (event->state & GDK_SHIFT_MASK) {
          changed = priv->text_model->SelectToBeginning();
        } else {
          changed = priv->text_model->MoveCursorToBeginning();
        }
        break;
      case GDK_KEY_BackSpace:
      case GDK_KEY_Delete:
      case GDK_KEY_KP_Delete:
      case GDK_KEY_Left:
      case GDK_KEY_KP_Left:
      case GDK_KEY_Right:
      case GDK_KEY_KP_Right:
        // Already handled inside the framework in RenderEditable.
        break;
    }
  }

  if (changed) {
    if (priv->enable_delta_model) {
      flutter::TextEditingDelta delta = flutter::TextEditingDelta(
          text_before_change, selection_before_change, text);
      update_editing_state_with_delta(self, &delta);
    } else {
      update_editing_state(self);
    }
  }
  if (do_action) {
    perform_action(self);
  }

  return changed;
}

// Initializes the FlTextInputPlugin class.
static void fl_text_input_plugin_class_init(FlTextInputPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_text_input_plugin_dispose;
  FL_TEXT_INPUT_PLUGIN_CLASS(klass)->filter_keypress =
      fl_text_input_plugin_filter_keypress_default;
}

// Initializes an instance of the FlTextInputPlugin class.
static void fl_text_input_plugin_init(FlTextInputPlugin* self) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));

  priv->client_id = kClientIdUnset;
  priv->input_type = kFlTextInputTypeText;
  priv->text_model = new flutter::TextInputModel();
}

static void init_im_context(FlTextInputPlugin* self, GtkIMContext* im_context) {
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  priv->im_context = GTK_IM_CONTEXT(g_object_ref(im_context));

  // On Wayland, this call sets up the input method so it can be enabled
  // immediately when required. Without it, on-screen keyboard's don't come up
  // the first time a text field is focused.
  gtk_im_context_focus_out(priv->im_context);

  g_signal_connect_object(priv->im_context, "preedit-start",
                          G_CALLBACK(im_preedit_start_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(priv->im_context, "preedit-end",
                          G_CALLBACK(im_preedit_end_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(priv->im_context, "preedit-changed",
                          G_CALLBACK(im_preedit_changed_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(priv->im_context, "commit", G_CALLBACK(im_commit_cb),
                          self, G_CONNECT_SWAPPED);
  g_signal_connect_object(priv->im_context, "retrieve-surrounding",
                          G_CALLBACK(im_retrieve_surrounding_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(priv->im_context, "delete-surrounding",
                          G_CALLBACK(im_delete_surrounding_cb), self,
                          G_CONNECT_SWAPPED);
}

FlTextInputPlugin* fl_text_input_plugin_new(
    FlBinaryMessenger* messenger,
    GtkIMContext* im_context,
    FlTextInputViewDelegate* view_delegate) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);
  g_return_val_if_fail(GTK_IS_IM_CONTEXT(im_context), nullptr);
  g_return_val_if_fail(FL_IS_TEXT_INPUT_VIEW_DELEGATE(view_delegate), nullptr);

  FlTextInputPlugin* self = FL_TEXT_INPUT_PLUGIN(
      g_object_new(fl_text_input_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  FlTextInputPluginPrivate* priv = static_cast<FlTextInputPluginPrivate*>(
      fl_text_input_plugin_get_instance_private(self));
  priv->channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(priv->channel, method_call_cb, self,
                                            nullptr);

  init_im_context(self, im_context);

  priv->view_delegate = view_delegate;
  g_object_add_weak_pointer(
      G_OBJECT(view_delegate),
      reinterpret_cast<gpointer*>(&(priv->view_delegate)));

  return self;
}

// Filters the a keypress given to the plugin through the plugin's
// filter_keypress callback.
gboolean fl_text_input_plugin_filter_keypress(FlTextInputPlugin* self,
                                              FlKeyEvent* event) {
  g_return_val_if_fail(FL_IS_TEXT_INPUT_PLUGIN(self), FALSE);
  if (FL_TEXT_INPUT_PLUGIN_GET_CLASS(self)->filter_keypress) {
    return FL_TEXT_INPUT_PLUGIN_GET_CLASS(self)->filter_keypress(self, event);
  }
  return FALSE;
}
