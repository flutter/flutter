// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_text_input_plugin.h"

#include <gtk/gtk.h>

#include "flutter/shell/platform/common/cpp/text_input_model.h"
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
static constexpr char kPerformActionMethod[] = "TextInputClient.performAction";

static constexpr char kInputActionKey[] = "inputAction";
static constexpr char kTextKey[] = "text";
static constexpr char kSelectionBaseKey[] = "selectionBase";
static constexpr char kSelectionExtentKey[] = "selectionExtent";
static constexpr char kSelectionAffinityKey[] = "selectionAffinity";
static constexpr char kSelectionIsDirectionalKey[] = "selectionIsDirectional";
static constexpr char kComposingBaseKey[] = "composingBase";
static constexpr char kComposingExtentKey[] = "composingExtent";

static constexpr char kTextAffinityDownstream[] = "TextAffinity.downstream";

static constexpr int64_t kClientIdUnset = -1;

struct _FlTextInputPlugin {
  GObject parent_instance;

  FlMethodChannel* channel;

  // Client ID provided by Flutter to report events with.
  int64_t client_id;

  // Input action to perform when enter pressed.
  gchar* input_action;

  // Input method.
  GtkIMContext* im_context;

  flutter::TextInputModel* text_model;
};

G_DEFINE_TYPE(FlTextInputPlugin, fl_text_input_plugin, G_TYPE_OBJECT)

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
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(self->client_id));
  g_autoptr(FlValue) value = fl_value_new_map();

  fl_value_set_string_take(
      value, kTextKey,
      fl_value_new_string(self->text_model->GetText().c_str()));
  fl_value_set_string_take(
      value, kSelectionBaseKey,
      fl_value_new_int(self->text_model->selection_base()));
  fl_value_set_string_take(
      value, kSelectionExtentKey,
      fl_value_new_int(self->text_model->selection_extent()));

  // The following keys are not implemented and set to default values.
  fl_value_set_string_take(value, kSelectionAffinityKey,
                           fl_value_new_string(kTextAffinityDownstream));
  fl_value_set_string_take(value, kSelectionIsDirectionalKey,
                           fl_value_new_bool(FALSE));
  fl_value_set_string_take(value, kComposingBaseKey, fl_value_new_int(-1));
  fl_value_set_string_take(value, kComposingExtentKey, fl_value_new_int(-1));

  fl_value_append(args, value);

  fl_method_channel_invoke_method(self->channel, kUpdateEditingStateMethod,
                                  args, nullptr,
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
  g_return_if_fail(FL_IS_TEXT_INPUT_PLUGIN(self));
  g_return_if_fail(self->client_id != 0);
  g_return_if_fail(self->input_action != nullptr);

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_int(self->client_id));
  fl_value_append_take(args, fl_value_new_string(self->input_action));

  fl_method_channel_invoke_method(self->channel, kPerformActionMethod, args,
                                  nullptr, perform_action_response_cb, self);
}

// Signal handler for GtkIMContext::commit
static void im_commit_cb(FlTextInputPlugin* self, const gchar* text) {
  self->text_model->AddText(text);
  update_editing_state(self);
}

// Signal handler for GtkIMContext::retrieve-surrounding
static gboolean im_retrieve_surrounding_cb(FlTextInputPlugin* self) {
  auto text = self->text_model->GetText();
  size_t cursor_offset = self->text_model->GetCursorOffset();
  gtk_im_context_set_surrounding(self->im_context, text.c_str(), -1,
                                 cursor_offset);
  return TRUE;
}

// Signal handler for GtkIMContext::delete-surrounding
static gboolean im_delete_surrounding_cb(FlTextInputPlugin* self,
                                         gint offset,
                                         gint n_chars) {
  if (self->text_model->DeleteSurrounding(offset, n_chars)) {
    update_editing_state(self);
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

  self->client_id = fl_value_get_int(fl_value_get_list_value(args, 0));
  FlValue* config_value = fl_value_get_list_value(args, 1);
  g_free(self->input_action);
  FlValue* input_action_value =
      fl_value_lookup_string(config_value, kInputActionKey);
  if (fl_value_get_type(input_action_value) == FL_VALUE_TYPE_STRING) {
    self->input_action = g_strdup(fl_value_get_string(input_action_value));
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Shows the input method.
static FlMethodResponse* show(FlTextInputPlugin* self) {
  gtk_im_context_focus_in(self->im_context);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Updates the editing state from Flutter.
static FlMethodResponse* set_editing_state(FlTextInputPlugin* self,
                                           FlValue* args) {
  const gchar* text =
      fl_value_get_string(fl_value_lookup_string(args, kTextKey));
  int64_t selection_base =
      fl_value_get_int(fl_value_lookup_string(args, kSelectionBaseKey));
  int64_t selection_extent =
      fl_value_get_int(fl_value_lookup_string(args, kSelectionExtentKey));
  // Flutter uses -1/-1 for invalid; translate that to 0/0 for the model.
  if (selection_base == -1 && selection_extent == -1) {
    selection_base = selection_extent = 0;
  }

  self->text_model->SetEditingState(selection_base, selection_extent, text);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when the input method client is complete.
static FlMethodResponse* clear_client(FlTextInputPlugin* self) {
  self->client_id = kClientIdUnset;

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Hides the input method.
static FlMethodResponse* hide(FlTextInputPlugin* self) {
  gtk_im_context_focus_out(self->im_context);

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
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method call response: %s", error->message);
  }
}

static void fl_text_input_plugin_dispose(GObject* object) {
  FlTextInputPlugin* self = FL_TEXT_INPUT_PLUGIN(object);

  g_clear_object(&self->channel);
  g_clear_pointer(&self->input_action, g_free);
  g_clear_object(&self->im_context);
  if (self->text_model != nullptr) {
    delete self->text_model;
    self->text_model = nullptr;
  }

  G_OBJECT_CLASS(fl_text_input_plugin_parent_class)->dispose(object);
}

static void fl_text_input_plugin_class_init(FlTextInputPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_text_input_plugin_dispose;
}

static void fl_text_input_plugin_init(FlTextInputPlugin* self) {
  self->client_id = kClientIdUnset;
  self->im_context = gtk_im_multicontext_new();
  g_signal_connect_object(self->im_context, "commit", G_CALLBACK(im_commit_cb),
                          self, G_CONNECT_SWAPPED);
  g_signal_connect_object(self->im_context, "retrieve-surrounding",
                          G_CALLBACK(im_retrieve_surrounding_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(self->im_context, "delete-surrounding",
                          G_CALLBACK(im_delete_surrounding_cb), self,
                          G_CONNECT_SWAPPED);
  self->text_model = new flutter::TextInputModel();
}

FlTextInputPlugin* fl_text_input_plugin_new(FlBinaryMessenger* messenger) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlTextInputPlugin* self = FL_TEXT_INPUT_PLUGIN(
      g_object_new(fl_text_input_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  self->channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb, self,
                                            nullptr);

  return self;
}

gboolean fl_text_input_plugin_filter_keypress(FlTextInputPlugin* self,
                                              GdkEventKey* event) {
  g_return_val_if_fail(FL_IS_TEXT_INPUT_PLUGIN(self), FALSE);

  if (self->client_id == kClientIdUnset) {
    return FALSE;
  }

  if (gtk_im_context_filter_keypress(self->im_context, event)) {
    return TRUE;
  }

  // Handle navigation keys.
  gboolean changed = FALSE;
  if (event->type == GDK_KEY_PRESS) {
    switch (event->keyval) {
      case GDK_KEY_BackSpace:
        changed = self->text_model->Backspace();
        break;
      case GDK_KEY_Delete:
      case GDK_KEY_KP_Delete:
        // Already handled inside Flutter.
        break;
      case GDK_KEY_End:
      case GDK_KEY_KP_End:
        changed = self->text_model->MoveCursorToEnd();
        break;
      case GDK_KEY_Return:
      case GDK_KEY_KP_Enter:
      case GDK_KEY_ISO_Enter:
        perform_action(self);
        break;
      case GDK_KEY_Home:
      case GDK_KEY_KP_Home:
        changed = self->text_model->MoveCursorToBeginning();
        break;
      case GDK_KEY_Left:
      case GDK_KEY_KP_Left:
        // Already handled inside Flutter.
        break;
      case GDK_KEY_Right:
      case GDK_KEY_KP_Right:
        // Already handled inside Flutter.
        break;
    }
  }

  if (changed) {
    update_editing_state(self);
  }

  return FALSE;
}
