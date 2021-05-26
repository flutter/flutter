// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_settings_plugin.h"

#include <gmodule.h>
#include <gtk/gtk.h>
#include <math.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_message_codec.h"

static constexpr char kChannelName[] = "flutter/settings";
static constexpr char kTextScaleFactorKey[] = "textScaleFactor";
static constexpr char kAlwaysUse24HourFormatKey[] = "alwaysUse24HourFormat";
static constexpr char kPlatformBrightnessKey[] = "platformBrightness";
static constexpr char kPlatformBrightnessLight[] = "light";
static constexpr char kPlatformBrightnessDark[] = "dark";

static constexpr char kDesktopInterfaceSchema[] = "org.gnome.desktop.interface";
static constexpr char kDesktopTextScalingFactorKey[] = "text-scaling-factor";
static constexpr char kDesktopClockFormatKey[] = "clock-format";
static constexpr char kClockFormat24Hour[] = "24h";

enum class Brightness { Light, Dark };

struct _FlSettingsPlugin {
  GObject parent_instance;

  FlBasicMessageChannel* channel;

  GSettings* interface_settings;

  GArray* connections;
};

G_DEFINE_TYPE(FlSettingsPlugin, fl_settings_plugin, G_TYPE_OBJECT)

// The color brightness calculation has been adapted from theme_data.dart:
// https://github.com/flutter/flutter/blob/8fe4cc79648a952f9c7e49a5248756c2ff98fa3b/packages/flutter/lib/src/material/theme_data.dart#L1470-L1488

// See <https://www.w3.org/TR/WCAG20/#relativeluminancedef>.
static gdouble linearize_color_component(gdouble component) {
  if (component <= 0.03928)
    return component / 12.92;
  return pow((component + 0.055) / 1.055, 2.4);
}

// See <https://en.wikipedia.org/wiki/Relative_luminance>.
gdouble compute_luminance(GdkRGBA* color) {
  gdouble r = linearize_color_component(color->red);
  gdouble g = linearize_color_component(color->green);
  gdouble b = linearize_color_component(color->blue);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

static Brightness estimate_brightness_for_color(GdkRGBA* color) {
  gdouble relative_luminance = compute_luminance(color);

  // See <https://www.w3.org/TR/WCAG20/#contrast-ratiodef> and
  // <https://material.io/go/design-theming#color-color-palette>.
  const gdouble kThreshold = 0.15;
  if ((relative_luminance + 0.05) * (relative_luminance + 0.05) > kThreshold)
    return Brightness::Light;
  return Brightness::Dark;
}

static bool is_dark_theme() {
  // GTK doesn't have a specific flag for dark themes, so we check if the
  // style text color is light or dark
  GList* windows = gtk_window_list_toplevels();
  if (windows == nullptr)
    return false;

  GtkWidget* window = GTK_WIDGET(windows->data);
  g_list_free(windows);

  GdkRGBA text_color;
  GtkStyleContext* style = gtk_widget_get_style_context(window);
  gtk_style_context_get_color(style, GTK_STATE_FLAG_NORMAL, &text_color);
  return estimate_brightness_for_color(&text_color) == Brightness::Light;
}

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
  }

  if (is_dark_theme()) {
    platform_brightness = kPlatformBrightnessDark;
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

  for (guint i = 0; i < self->connections->len; i += 1) {
    g_signal_handler_disconnect(self->interface_settings,
                                g_array_index(self->connections, gulong, i));
  }
  g_array_unref(self->connections);
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
  self->connections = g_array_new(FALSE, FALSE, sizeof(gulong));

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
      gulong new_connections[] = {
          g_signal_connect_object(
              self->interface_settings, "changed::text-scaling-factor",
              G_CALLBACK(update_settings), self, G_CONNECT_SWAPPED),
          g_signal_connect_object(
              self->interface_settings, "changed::clock-format",
              G_CALLBACK(update_settings), self, G_CONNECT_SWAPPED),
          g_signal_connect_object(
              self->interface_settings, "changed::gtk-theme",
              G_CALLBACK(update_settings), self, G_CONNECT_SWAPPED),
      };
      g_array_append_vals(self->connections, new_connections,
                          sizeof(new_connections) / sizeof(gulong));
    }
  }

  update_settings(self);
}
