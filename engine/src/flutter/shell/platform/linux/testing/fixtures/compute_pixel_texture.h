// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_FIXTURES_COMPUTE_PIXEL_TEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_FIXTURES_COMPUTE_PIXEL_TEXTURE_H_

#include <flutter_linux/flutter_linux.h>

// Test-only pixel-buffer plugin: an asymmetric RGBA pattern detects channel
// swaps and vertical flips, independently of the green compute result.
struct ComputePixelTexture {
  FlPixelBufferTexture parent;
};
struct ComputePixelTextureClass {
  FlPixelBufferTextureClass parent;
};
G_DEFINE_TYPE(ComputePixelTexture,
              compute_pixel_texture,
              fl_pixel_buffer_texture_get_type())

static void compute_pixel_texture_class_init(ComputePixelTextureClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels =
      [](FlPixelBufferTexture*, const uint8_t** bytes, uint32_t* width,
         uint32_t* height, GError**) -> gboolean {
    static const uint8_t pixels[] = {255, 0, 0,   255, 0,   255, 0,   255,
                                     0,   0, 255, 255, 255, 255, 255, 255};
    *bytes = pixels;
    *width = 2;
    *height = 2;
    return TRUE;
  };
}
static void compute_pixel_texture_init(ComputePixelTexture*) {}

// Call immediately after realizing the view. Registration occurs on demand so
// ordinary compute tests do not exercise external-texture registration.
inline void install_compute_pixel_texture(FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "compute-probe/pixels", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel,
      [](FlMethodChannel*, FlMethodCall* call, gpointer data) {
        auto* registrar = FL_TEXTURE_REGISTRAR(data);
        g_autoptr(FlPixelBufferTexture) texture = FL_PIXEL_BUFFER_TEXTURE(
            g_object_new(compute_pixel_texture_get_type(), nullptr));
        const bool registered = fl_texture_registrar_register_texture(
            registrar, FL_TEXTURE(texture));
        int64_t id = registered ? fl_texture_get_id(FL_TEXTURE(texture)) : -1;
        if (registered) {
          fl_texture_registrar_mark_texture_frame_available(
              registrar, FL_TEXTURE(texture));
        }
        g_autoptr(FlValue) value = fl_value_new_int(id);
        g_autoptr(FlMethodSuccessResponse) response =
            fl_method_success_response_new(value);
        fl_method_call_respond(call, FL_METHOD_RESPONSE(response), nullptr);
      },
      g_object_ref(fl_engine_get_texture_registrar(fl_view_get_engine(view))),
      g_object_unref);
}
#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_FIXTURES_COMPUTE_PIXEL_TEXTURE_H_
