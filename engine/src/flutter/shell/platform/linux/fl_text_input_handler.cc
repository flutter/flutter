// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_text_input_handler.h"

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

struct _FlTextInputHandler {
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

  GWeakRef view_delegate;

  flutter::TextInputModel* text_model;

  // A 4x4 matrix that maps from `EditableText` local coordinates to the
  // coordinate system of `PipelineOwner.rootNode`.
  double editabletext_transform[4][4];

  // The smallest rect, in local coordinates, of the text in the composing
  // range, or of the caret in the case where there is no current composing
  // range. This value is updated via `TextInput.setMarkedTextRect` messages
  // over the text input channel.
  GdkRectangle composing_rect;

  GCancellable* cancellable;
};

G_DEFINE_TYPE(FlTextInputHandler, fl_text_input_handler, G_TYPE_OBJECT)

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
    if (!g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      g_warning("Failed to call %s: %s", kUpdateEditingStateMethod,
                error->message);
    }
  }
}

// Informs Flutter of text input changes.
static void update_editing_state(FlTextInputHandler* self) {
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(self->client_id));
  g_autoptr(FlValue) value = fl_value_new_map();

  flutter::TextRange selection = self->text_model->selection();
  fl_value_set_string_take(
      value, kTextKey,
      fl_value_new_string(self->text_model->GetText().c_str()));
  fl_value_set_string_take(value, kSelectionBaseKey,
                           fl_value_new_int(selection.base()));
  fl_value_set_string_take(value, kSelectionExtentKey,
                           fl_value_new_int(selection.extent()));

  int composing_base = -1;
  int composing_extent = -1;
  if (!self->text_model->composing_range().collapsed()) {
    composing_base = self->text_model->composing_range().base();
    composing_extent = self->text_model->composing_range().extent();
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

  fl_method_channel_invoke_method(self->channel, kUpdateEditingStateMethod,
                                  args, self->cancellable,
                                  update_editing_state_response_cb, self);
}

// Informs Flutter of text input changes by passing just the delta.
static void update_editing_state_with_delta(FlTextInputHandler* self,
                                            flutter::TextEditingDelta* delta) {
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(self->client_id));

  g_autoptr(FlValue) deltaValue = fl_value_new_map();
  fl_value_set_string_take(deltaValue, "oldText",
                           fl_value_new_string(delta->old_text().c_str()));

  fl_value_set_string_take(deltaValue, "deltaText",
                           fl_value_new_string(delta->delta_text().c_str()));

  fl_value_set_string_take(deltaValue, "deltaStart",
                           fl_value_new_int(delta->delta_start()));

  fl_value_set_string_take(deltaValue, "deltaEnd",
                           fl_value_new_int(delta->delta_end()));

  flutter::TextRange selection = self->text_model->selection();
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
  if (!self->text_model->composing_range().collapsed()) {
    composing_base = self->text_model->composing_range().base();
    composing_extent = self->text_model->composing_range().extent();
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
      self->channel, kUpdateEditingStateWithDeltasMethod, args,
      self->cancellable, update_editing_state_response_cb, self);
}

// Called when a response is received from TextInputClient.performAction()
static void perform_action_response_cb(GObject* object,
                                       GAsyncResult* result,
                                       gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  if (!finish_method(object, result, &error)) {
    if (!g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      g_warning("Failed to call %s: %s", kPerformActionMethod, error->message);
    }
  }
}

// Inform Flutter that the input has been activated.
static void perform_action(FlTextInputHandler* self) {
  g_return_if_fail(FL_IS_TEXT_INPUT_HANDLER(self));
  g_return_if_fail(self->client_id != 0);
  g_return_if_fail(self->input_action != nullptr);

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(self->client_id));
  fl_value_append_take(args, fl_value_new_string(self->input_action));

  fl_method_channel_invoke_method(self->channel, kPerformActionMethod, args,
                                  self->cancellable, perform_action_response_cb,
                                  self);
}

// Signal handler for GtkIMContext::preedit-start
static void im_preedit_start_cb(FlTextInputHandler* self) {
  self->text_model->BeginComposing();
}

// Signal handler for GtkIMContext::preedit-changed
static void im_preedit_changed_cb(FlTextInputHandler* self) {
  std::string text_before_change = self->text_model->GetText();
  flutter::TextRange composing_before_change =
      self->text_model->composing_range();
  g_autofree gchar* buf = nullptr;
  gint cursor_offset = 0;
  gtk_im_context_get_preedit_string(self->im_context, &buf, nullptr,
                                    &cursor_offset);
  if (self->text_model->composing()) {
    cursor_offset += self->text_model->composing_range().start();
  } else {
    cursor_offset += self->text_model->selection().start();
  }
  self->text_model->UpdateComposingText(buf);
  self->text_model->SetSelection(flutter::TextRange(cursor_offset));

  if (self->enable_delta_model) {
    std::string text(buf);
    flutter::TextEditingDelta delta = flutter::TextEditingDelta(
        text_before_change, composing_before_change, text);
    update_editing_state_with_delta(self, &delta);
  } else {
    update_editing_state(self);
  }
}

// Signal handler for GtkIMContext::commit
static void im_commit_cb(FlTextInputHandler* self, const gchar* text) {
  std::string text_before_change = self->text_model->GetText();
  flutter::TextRange composing_before_change =
      self->text_model->composing_range();
  flutter::TextRange selection_before_change = self->text_model->selection();
  gboolean was_composing = self->text_model->composing();

  self->text_model->AddText(text);
  if (self->text_model->composing()) {
    self->text_model->CommitComposing();
  }

  if (self->enable_delta_model) {
    flutter::TextRange replace_range =
        was_composing ? composing_before_change : selection_before_change;
    std::unique_ptr<flutter::TextEditingDelta> delta =
        std::make_unique<flutter::TextEditingDelta>(text_before_change,
                                                    replace_range, text);
    update_editing_state_with_delta(self, delta.get());
  } else {
    update_editing_state(self);
  }
}

// Signal handler for GtkIMContext::preedit-end
static void im_preedit_end_cb(FlTextInputHandler* self) {
  self->text_model->EndComposing();
  if (self->enable_delta_model) {
    flutter::TextEditingDelta delta =
        flutter::TextEditingDelta(self->text_model->GetText());
    update_editing_state_with_delta(self, &delta);
  } else {
    update_editing_state(self);
  }
}

// Signal handler for GtkIMContext::retrieve-surrounding
static gboolean im_retrieve_surrounding_cb(FlTextInputHandler* self) {
  auto text = self->text_model->GetText();
  size_t cursor_offset = self->text_model->GetCursorOffset();
  gtk_im_context_set_surrounding(self->im_context, text.c_str(), -1,
                                 cursor_offset);
  return TRUE;
}

// Signal handler for GtkIMContext::delete-surrounding
static gboolean im_delete_surrounding_cb(FlTextInputHandler* self,
                                         gint offset,
                                         gint n_chars) {
  std::string text_before_change = self->text_model->GetText();
  if (self->text_model->DeleteSurrounding(offset, n_chars)) {
    if (self->enable_delta_model) {
      flutter::TextEditingDelta delta = flutter::TextEditingDelta(
          text_before_change, self->text_model->composing_range(),
          self->text_model->GetText());
      update_editing_state_with_delta(self, &delta);
    } else {
      update_editing_state(self);
    }
  }
  return TRUE;
}

// Called when the input method client is set up.
static FlMethodResponse* set_client(FlTextInputHandler* self, FlValue* args) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(args) < 2) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Expected 2-element list", nullptr));
  }

  self->client_id = fl_value_get_int(fl_value_get_list_value(args, 0));
  FlValue* config_value = fl_value_get_list_value(args, 1);
  g_free(self->input_action);
  FlValue* input_action_value =
      fl_value_lookup_string(config_value, kInputActionKey);
  if (fl_value_get_type(input_action_value) == FL_VALUE_TYPE_STRING) {
    self->input_action = g_strdup(fl_value_get_string(input_action_value));
  }

  FlValue* enable_delta_model_value =
      fl_value_lookup_string(config_value, kEnableDeltaModel);
  gboolean enable_delta_model = fl_value_get_bool(enable_delta_model_value);
  self->enable_delta_model = enable_delta_model;

  // Reset the input type, then set only if appropriate.
  self->input_type = kFlTextInputTypeText;
  FlValue* input_type_value =
      fl_value_lookup_string(config_value, kTextInputTypeKey);
  if (fl_value_get_type(input_type_value) == FL_VALUE_TYPE_MAP) {
    FlValue* input_type_name =
        fl_value_lookup_string(input_type_value, kTextInputTypeNameKey);
    if (fl_value_get_type(input_type_name) == FL_VALUE_TYPE_STRING) {
      const gchar* input_type = fl_value_get_string(input_type_name);
      if (g_strcmp0(input_type, kMultilineInputType) == 0) {
        self->input_type = kFlTextInputTypeMultiline;
      } else if (g_strcmp0(input_type, kNoneInputType) == 0) {
        self->input_type = kFlTextInputTypeNone;
      }
    }
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Hides the input method.
static FlMethodResponse* hide(FlTextInputHandler* self) {
  gtk_im_context_focus_out(self->im_context);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Shows the input method.
static FlMethodResponse* show(FlTextInputHandler* self) {
  if (self->input_type == kFlTextInputTypeNone) {
    return hide(self);
  }

  gtk_im_context_focus_in(self->im_context);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Updates the editing state from Flutter.
static FlMethodResponse* set_editing_state(FlTextInputHandler* self,
                                           FlValue* args) {
  const gchar* text =
      fl_value_get_string(fl_value_lookup_string(args, kTextKey));
  self->text_model->SetText(text);

  int64_t selection_base =
      fl_value_get_int(fl_value_lookup_string(args, kSelectionBaseKey));
  int64_t selection_extent =
      fl_value_get_int(fl_value_lookup_string(args, kSelectionExtentKey));
  // Flutter uses -1/-1 for invalid; translate that to 0/0 for the model.
  if (selection_base == -1 && selection_extent == -1) {
    selection_base = selection_extent = 0;
  }

  self->text_model->SetText(text);
  self->text_model->SetSelection(
      flutter::TextRange(selection_base, selection_extent));

  int64_t composing_base =
      fl_value_get_int(fl_value_lookup_string(args, kComposingBaseKey));
  int64_t composing_extent =
      fl_value_get_int(fl_value_lookup_string(args, kComposingExtentKey));
  if (composing_base == -1 && composing_extent == -1) {
    self->text_model->EndComposing();
  } else {
    size_t composing_start = std::min(composing_base, composing_extent);
    size_t cursor_offset = selection_base - composing_start;
    self->text_model->SetComposingRange(
        flutter::TextRange(composing_base, composing_extent), cursor_offset);
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when the input method client is complete.
static FlMethodResponse* clear_client(FlTextInputHandler* self) {
  self->client_id = kClientIdUnset;

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
static void update_im_cursor_position(FlTextInputHandler* self) {
  g_autoptr(FlTextInputViewDelegate) view_delegate =
      FL_TEXT_INPUT_VIEW_DELEGATE(g_weak_ref_get(&self->view_delegate));
  if (view_delegate == nullptr) {
    return;
  }

  // Skip update if not composing to avoid setting to position 0.
  if (!self->text_model->composing()) {
    return;
  }

  // Transform the x, y positions of the cursor from local coordinates to
  // Flutter view coordinates.
  gint x = self->composing_rect.x * self->editabletext_transform[0][0] +
           self->composing_rect.y * self->editabletext_transform[1][0] +
           self->editabletext_transform[3][0] + self->composing_rect.width;
  gint y = self->composing_rect.x * self->editabletext_transform[0][1] +
           self->composing_rect.y * self->editabletext_transform[1][1] +
           self->editabletext_transform[3][1] + self->composing_rect.height;

  // Transform from Flutter view coordinates to GTK window coordinates.
  GdkRectangle preedit_rect = {};
  fl_text_input_view_delegate_translate_coordinates(
      view_delegate, x, y, &preedit_rect.x, &preedit_rect.y);

  // Set the cursor location in window coordinates so that GTK can position any
  // system input method windows.
  gtk_im_context_set_cursor_location(self->im_context, &preedit_rect);
}

// Handles updates to the EditableText size and position from the framework.
//
// On changes to the size or position of the RenderObject underlying the
// EditableText, this update may be triggered. It provides an updated size and
// transform from the local coordinate system of the EditableText to root
// Flutter coordinate system.
static FlMethodResponse* set_editable_size_and_transform(
    FlTextInputHandler* self,
    FlValue* args) {
  FlValue* transform = fl_value_lookup_string(args, kTransform);
  size_t transform_len = fl_value_get_length(transform);
  g_warn_if_fail(transform_len == 16);

  for (size_t i = 0; i < transform_len; ++i) {
    double val = fl_value_get_float(fl_value_get_list_value(transform, i));
    self->editabletext_transform[i / 4][i % 4] = val;
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
static FlMethodResponse* set_marked_text_rect(FlTextInputHandler* self,
                                              FlValue* args) {
  self->composing_rect.x =
      fl_value_get_float(fl_value_lookup_string(args, "x"));
  self->composing_rect.y =
      fl_value_get_float(fl_value_lookup_string(args, "y"));
  self->composing_rect.width =
      fl_value_get_float(fl_value_lookup_string(args, "width"));
  self->composing_rect.height =
      fl_value_get_float(fl_value_lookup_string(args, "height"));
  update_im_cursor_position(self);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  FlTextInputHandler* self = FL_TEXT_INPUT_HANDLER(user_data);

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

// Disposes of an FlTextInputHandler.
static void fl_text_input_handler_dispose(GObject* object) {
  FlTextInputHandler* self = FL_TEXT_INPUT_HANDLER(object);

  g_cancellable_cancel(self->cancellable);

  g_clear_object(&self->channel);
  g_clear_pointer(&self->input_action, g_free);
  g_clear_object(&self->im_context);
  if (self->text_model != nullptr) {
    delete self->text_model;
    self->text_model = nullptr;
  }
  g_weak_ref_clear(&self->view_delegate);
  g_clear_object(&self->cancellable);

  G_OBJECT_CLASS(fl_text_input_handler_parent_class)->dispose(object);
}

// Initializes the FlTextInputHandler class.
static void fl_text_input_handler_class_init(FlTextInputHandlerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_text_input_handler_dispose;
}

// Initializes an instance of the FlTextInputHandler class.
static void fl_text_input_handler_init(FlTextInputHandler* self) {
  self->client_id = kClientIdUnset;
  self->input_type = kFlTextInputTypeText;
  self->text_model = new flutter::TextInputModel();
  self->cancellable = g_cancellable_new();
}

static void init_im_context(FlTextInputHandler* self,
                            GtkIMContext* im_context) {
  self->im_context = GTK_IM_CONTEXT(g_object_ref(im_context));

  // On Wayland, this call sets up the input method so it can be enabled
  // immediately when required. Without it, on-screen keyboard's don't come up
  // the first time a text field is focused.
  gtk_im_context_focus_out(self->im_context);

  g_signal_connect_object(self->im_context, "preedit-start",
                          G_CALLBACK(im_preedit_start_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(self->im_context, "preedit-end",
                          G_CALLBACK(im_preedit_end_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(self->im_context, "preedit-changed",
                          G_CALLBACK(im_preedit_changed_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(self->im_context, "commit", G_CALLBACK(im_commit_cb),
                          self, G_CONNECT_SWAPPED);
  g_signal_connect_object(self->im_context, "retrieve-surrounding",
                          G_CALLBACK(im_retrieve_surrounding_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(self->im_context, "delete-surrounding",
                          G_CALLBACK(im_delete_surrounding_cb), self,
                          G_CONNECT_SWAPPED);
}

FlTextInputHandler* fl_text_input_handler_new(
    FlBinaryMessenger* messenger,
    GtkIMContext* im_context,
    FlTextInputViewDelegate* view_delegate) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);
  g_return_val_if_fail(GTK_IS_IM_CONTEXT(im_context), nullptr);
  g_return_val_if_fail(FL_IS_TEXT_INPUT_VIEW_DELEGATE(view_delegate), nullptr);

  FlTextInputHandler* self = FL_TEXT_INPUT_HANDLER(
      g_object_new(fl_text_input_handler_get_type(), nullptr));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  self->channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb, self,
                                            nullptr);

  init_im_context(self, im_context);

  g_weak_ref_init(&self->view_delegate, view_delegate);

  return self;
}

gboolean fl_text_input_handler_filter_keypress(FlTextInputHandler* self,
                                               FlKeyEvent* event) {
  g_return_val_if_fail(FL_IS_TEXT_INPUT_HANDLER(self), FALSE);

  if (self->client_id == kClientIdUnset) {
    return FALSE;
  }

  if (gtk_im_context_filter_keypress(
          self->im_context,
          reinterpret_cast<GdkEventKey*>(fl_key_event_get_origin(event)))) {
    return TRUE;
  }

  std::string text_before_change = self->text_model->GetText();
  flutter::TextRange selection_before_change = self->text_model->selection();
  std::string text = self->text_model->GetText();

  // Handle the enter/return key.
  gboolean do_action = FALSE;
  // Handle navigation keys.
  gboolean changed = FALSE;
  if (fl_key_event_get_is_press(event)) {
    switch (fl_key_event_get_keyval(event)) {
      case GDK_KEY_End:
      case GDK_KEY_KP_End:
        if (fl_key_event_get_state(event) & GDK_SHIFT_MASK) {
          changed = self->text_model->SelectToEnd();
        } else {
          changed = self->text_model->MoveCursorToEnd();
        }
        break;
      case GDK_KEY_Return:
      case GDK_KEY_KP_Enter:
      case GDK_KEY_ISO_Enter:
        if (self->input_type == kFlTextInputTypeMultiline &&
            strcmp(self->input_action, kNewlineInputAction) == 0) {
          self->text_model->AddCodePoint('\n');
          text = "\n";
          changed = TRUE;
        }
        do_action = TRUE;
        break;
      case GDK_KEY_Home:
      case GDK_KEY_KP_Home:
        if (fl_key_event_get_state(event) & GDK_SHIFT_MASK) {
          changed = self->text_model->SelectToBeginning();
        } else {
          changed = self->text_model->MoveCursorToBeginning();
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
    if (self->enable_delta_model) {
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
