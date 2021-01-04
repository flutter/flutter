// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_settings_plugin.h"

#include <cstring>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_message_codec.h"

static constexpr char kChannelName[] = "flutter/settings";
static constexpr char kTextScaleFactorKey[] = "textScaleFactor";
static constexpr char kAlwaysUse24HourFormatKey[] = "alwaysUse24HourFormat";
static constexpr char kPlatformBrightnessKey[] = "platformBrightness";
static constexpr char kPlatformBrightnessLight[] = "light";
static constexpr char kPlatformBrightnessDark[] = "dark";

static constexpr char kDesktopInterfaceSchema[] = "org.gnome.desktop.interface";
static constexpr char kDesktopGtkThemeKey[] = "gtk-theme";
static constexpr char kDesktopTextScalingFactorKey[] = "text-scaling-factor";
static constexpr char kDesktopClockFormatKey[] = "clock-format";
static constexpr char kClockFormat24Hour[] = "24h";

struct _FlSettingsPlugin {
  GObject parent_instance;

  FlBasicMessageChannel* channel;

  GSettings* interface_settings;
};

G_DEFINE_TYPE(FlSettingsPlugin, fl_settings_plugin, G_TYPE_OBJECT)

// Sends the current settings to the Flutter engine.
static void update_settings(FlSettingsPlugin* self) {
  gdouble scaling_factor = 1.0;
  gboolean always_use_24hr = FALSE;
  const gchar* platform_brightness = kPlatformBrightnessLight;

  if (self->interface_settings != nullptr) {
    scaling_factor = g_settings_get_double(self->interface_settings,
                                           kDesktopTextScalingFactorKey);
    g_autofree gchar* clock_format =
        g_settings_get_string(self->interface_settings, kDesktopClockFormatKey);
    always_use_24hr = g_strcmp0(clock_format, kClockFormat24Hour) == 0;

    // GTK doesn't have a specific flag for dark themes, so we have some
    // hard-coded themes for Ubuntu (Yaru) and GNOME (Adwaita).
    g_autofree gchar* gtk_theme =
        g_settings_get_string(self->interface_settings, kDesktopGtkThemeKey);
    if (g_strcmp0(gtk_theme, "Yaru-dark") == 0 ||
        g_strcmp0(gtk_theme, "Adwaita-dark") == 0) {
      platform_brightness = kPlatformBrightnessDark;
    }
  }

  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, kTextScaleFactorKey,
                           fl_value_new_float(scaling_factor));
  fl_value_set_string_take(message, kAlwaysUse24HourFormatKey,
                           fl_value_new_bool(always_use_24hr));
  fl_value_set_string_take(message, kPlatformBrightnessKey,
                           fl_value_new_string(platform_brightness));
  fl_basic_message_channel_send(self->channel, message, nullptr, nullptr,
                                nullptr);
}

static void fl_settings_plugin_dispose(GObject* object) {
  FlSettingsPlugin* self = FL_SETTINGS_PLUGIN(object);

  g_clear_object(&self->channel);
  g_clear_object(&self->interface_settings);

  G_OBJECT_CLASS(fl_settings_plugin_parent_class)->dispose(object);
}

static void fl_settings_plugin_class_init(FlSettingsPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_settings_plugin_dispose;
}

static void fl_settings_plugin_init(FlSettingsPlugin* self) {}

FlSettingsPlugin* fl_settings_plugin_new(FlBinaryMessenger* messenger) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlSettingsPlugin* self =
      FL_SETTINGS_PLUGIN(g_object_new(fl_settings_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  self->channel = fl_basic_message_channel_new(messenger, kChannelName,
                                               FL_MESSAGE_CODEC(codec));

  return self;
}

void fl_settings_plugin_start(FlSettingsPlugin* self) {
  g_return_if_fail(FL_IS_SETTINGS_PLUGIN(self));

  // If we are on GNOME, get settings from GSettings.
  GSettingsSchemaSource* source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) schema =
        g_settings_schema_source_lookup(source, kDesktopInterfaceSchema, FALSE);
    if (schema != nullptr) {
      self->interface_settings = g_settings_new_full(schema, nullptr, nullptr);
      g_signal_connect_object(
          self->interface_settings, "changed::text-scaling-factor",
          G_CALLBACK(update_settings), self, G_CONNECT_SWAPPED);
      g_signal_connect_object(self->interface_settings, "changed::clock-format",
                              G_CALLBACK(update_settings), self,
                              G_CONNECT_SWAPPED);
      g_signal_connect_object(self->interface_settings, "changed::gtk-theme",
                              G_CALLBACK(update_settings), self,
                              G_CONNECT_SWAPPED);
    }
  }

  update_settings(self);
}
