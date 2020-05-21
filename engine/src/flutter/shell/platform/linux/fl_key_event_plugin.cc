// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_event_plugin.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_message_codec.h"

static constexpr char kChannelName[] = "flutter/keyevent";
static constexpr char kTypeKey[] = "type";
static constexpr char kTypeValueUp[] = "keyup";
static constexpr char kTypeValueDown[] = "keydown";
static constexpr char kKeymapKey[] = "keymap";
static constexpr char kKeyCodeKey[] = "keyCode";
static constexpr char kScanCodeKey[] = "scanCode";
static constexpr char kModifiersKey[] = "modifiers";
static constexpr char kToolkitKey[] = "toolkit";
static constexpr char kUnicodeScalarValuesKey[] = "unicodeScalarValues";

static constexpr char kGLFWToolkit[] = "glfw";
static constexpr char kLinuxKeymap[] = "linux";

struct _FlKeyEventPlugin {
  GObject parent_instance;

  FlBasicMessageChannel* channel;
};

G_DEFINE_TYPE(FlKeyEventPlugin, fl_key_event_plugin, G_TYPE_OBJECT)

// Converts a Gdk key code to its GLFW equivalent.
// TODO(robert-ancell) Create a "gtk" toolkit in Flutter so we don't have to
// convert values. https://github.com/flutter/flutter/issues/57603
static int gdk_keyval_to_glfw_key_code(guint keyval) {
  switch (keyval) {
    case GDK_KEY_space:
      return 32;
    case GDK_KEY_apostrophe:
      return 39;
    case GDK_KEY_comma:
      return 44;
    case GDK_KEY_minus:
      return 45;
    case GDK_KEY_period:
      return 46;
    case GDK_KEY_slash:
      return 47;
    case GDK_KEY_0:
      return 48;
    case GDK_KEY_1:
      return 49;
    case GDK_KEY_2:
      return 50;
    case GDK_KEY_3:
      return 51;
    case GDK_KEY_4:
      return 52;
    case GDK_KEY_5:
      return 53;
    case GDK_KEY_6:
      return 54;
    case GDK_KEY_7:
      return 55;
    case GDK_KEY_8:
      return 56;
    case GDK_KEY_9:
      return 57;
    case GDK_KEY_semicolon:
      return 59;
    case GDK_KEY_equal:
      return 61;
    case GDK_KEY_a:
      return 65;
    case GDK_KEY_b:
      return 66;
    case GDK_KEY_c:
      return 67;
    case GDK_KEY_d:
      return 68;
    case GDK_KEY_e:
      return 69;
    case GDK_KEY_f:
      return 70;
    case GDK_KEY_g:
      return 71;
    case GDK_KEY_h:
      return 72;
    case GDK_KEY_i:
      return 73;
    case GDK_KEY_j:
      return 74;
    case GDK_KEY_k:
      return 75;
    case GDK_KEY_l:
      return 76;
    case GDK_KEY_m:
      return 77;
    case GDK_KEY_n:
      return 78;
    case GDK_KEY_o:
      return 79;
    case GDK_KEY_p:
      return 80;
    case GDK_KEY_q:
      return 81;
    case GDK_KEY_r:
      return 82;
    case GDK_KEY_s:
      return 83;
    case GDK_KEY_t:
      return 84;
    case GDK_KEY_u:
      return 85;
    case GDK_KEY_v:
      return 86;
    case GDK_KEY_w:
      return 87;
    case GDK_KEY_x:
      return 88;
    case GDK_KEY_y:
      return 89;
    case GDK_KEY_z:
      return 90;
    case GDK_KEY_bracketleft:
      return 91;
    case GDK_KEY_bracketright:
      return 92;
    case GDK_KEY_grave:
      return 96;
    case GDK_KEY_Escape:
      return 256;
    case GDK_KEY_Return:
      return 257;
    case GDK_KEY_Tab:
      return 258;
    case GDK_KEY_BackSpace:
      return 259;
    case GDK_KEY_Insert:
      return 260;
    case GDK_KEY_Delete:
      return 261;
    case GDK_KEY_Right:
      return 262;
    case GDK_KEY_Left:
      return 263;
    case GDK_KEY_Down:
      return 264;
    case GDK_KEY_Up:
      return 265;
    case GDK_KEY_Page_Up:
      return 266;
    case GDK_KEY_Page_Down:
      return 267;
    case GDK_KEY_Home:
      return 268;
    case GDK_KEY_End:
      return 269;
    case GDK_KEY_Shift_L:
      return 340;
    case GDK_KEY_Control_L:
      return 341;
    case GDK_KEY_Alt_L:
      return 342;
    case GDK_KEY_Super_L:
      return 343;
    case GDK_KEY_Shift_R:
      return 344;
    case GDK_KEY_Control_R:
      return 345;
    case GDK_KEY_Alt_R:
      return 346;
    case GDK_KEY_Super_R:
      return 347;
    default:
      return 0;
  }
}

// Converts a Gdk key state to its GLFW equivalent.
int64_t gdk_state_to_glfw_modifiers(guint8 state) {
  int64_t modifiers = 0;

  if ((state & GDK_SHIFT_MASK) != 0)
    modifiers |= 0x0001;
  if ((state & GDK_CONTROL_MASK) != 0)
    modifiers |= 0x0002;
  if ((state & GDK_MOD1_MASK) != 0)
    modifiers |= 0x0004;
  if ((state & GDK_SUPER_MASK) != 0)
    modifiers |= 0x0008;

  return modifiers;
}

static void fl_key_event_plugin_dispose(GObject* object) {
  FlKeyEventPlugin* self = FL_KEY_EVENT_PLUGIN(object);

  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_key_event_plugin_parent_class)->dispose(object);
}

static void fl_key_event_plugin_class_init(FlKeyEventPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_event_plugin_dispose;
}

static void fl_key_event_plugin_init(FlKeyEventPlugin* self) {}

FlKeyEventPlugin* fl_key_event_plugin_new(FlBinaryMessenger* messenger) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlKeyEventPlugin* self = FL_KEY_EVENT_PLUGIN(
      g_object_new(fl_key_event_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  self->channel = fl_basic_message_channel_new(messenger, kChannelName,
                                               FL_MESSAGE_CODEC(codec));

  return self;
}

void fl_key_event_plugin_send_key_event(FlKeyEventPlugin* self,
                                        GdkEventKey* event) {
  g_return_if_fail(FL_IS_KEY_EVENT_PLUGIN(self));
  g_return_if_fail(event != nullptr);

  const gchar* type;
  if (event->type == GDK_KEY_PRESS)
    type = kTypeValueDown;
  else if (event->type == GDK_KEY_RELEASE)
    type = kTypeValueUp;
  else
    return;

  int64_t scan_code = event->hardware_keycode;
  int64_t key_code = gdk_keyval_to_glfw_key_code(event->keyval);
  int64_t modifiers = gdk_state_to_glfw_modifiers(event->state);
  int64_t unicodeScalarValues = gdk_keyval_to_unicode(event->keyval);

  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, kTypeKey, fl_value_new_string(type));
  fl_value_set_string_take(message, kKeymapKey,
                           fl_value_new_string(kLinuxKeymap));
  fl_value_set_string_take(message, kScanCodeKey, fl_value_new_int(scan_code));
  fl_value_set_string_take(message, kToolkitKey,
                           fl_value_new_string(kGLFWToolkit));
  fl_value_set_string_take(message, kKeyCodeKey, fl_value_new_int(key_code));
  fl_value_set_string_take(message, kModifiersKey, fl_value_new_int(modifiers));
  if (unicodeScalarValues != 0)
    fl_value_set_string_take(message, kUnicodeScalarValuesKey,
                             fl_value_new_int(unicodeScalarValues));

  fl_basic_message_channel_send(self->channel, message, nullptr, nullptr,
                                nullptr);
}
