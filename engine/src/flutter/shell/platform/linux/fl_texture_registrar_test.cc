// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_texture_registrar.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_texture_registrar_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_pixel_buffer_texture.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_texture_gl.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_texture_registrar.h"
#include "gtest/gtest.h"

#include <epoxy/gl.h>

#include <gmodule.h>

static constexpr uint32_t kBufferWidth = 4u;
static constexpr uint32_t kBufferHeight = 4u;
static constexpr uint32_t kRealBufferWidth = 2u;
static constexpr uint32_t kRealBufferHeight = 2u;
static constexpr uint64_t kThreadCount = 16u;

G_DECLARE_FINAL_TYPE(FlTestRegistrarTexture,
                     fl_test_registrar_texture,
                     FL,
                     TEST_REGISTRAR_TEXTURE,
                     FlTextureGL)

/// A simple texture.
struct _FlTestRegistrarTexture {
  FlTextureGL parent_instance;
};

G_DEFINE_TYPE(FlTestRegistrarTexture,
              fl_test_registrar_texture,
              fl_texture_gl_get_type())

static gboolean fl_test_registrar_texture_populate(FlTextureGL* texture,
                                                   uint32_t* target,
                                                   uint32_t* format,
                                                   uint32_t* width,
                                                   uint32_t* height,
                                                   GError** error) {
  EXPECT_TRUE(FL_IS_TEST_REGISTRAR_TEXTURE(texture));

  EXPECT_EQ(*width, kBufferWidth);
  EXPECT_EQ(*height, kBufferHeight);
  *target = GL_TEXTURE_2D;
  *format = GL_R8;
  *width = kRealBufferWidth;
  *height = kRealBufferHeight;

  return TRUE;
}

static void fl_test_registrar_texture_class_init(
    FlTestRegistrarTextureClass* klass) {
  FL_TEXTURE_GL_CLASS(klass)->populate = fl_test_registrar_texture_populate;
}

static void fl_test_registrar_texture_init(FlTestRegistrarTexture* self) {}

static FlTestRegistrarTexture* fl_test_registrar_texture_new() {
  return FL_TEST_REGISTRAR_TEXTURE(
      g_object_new(fl_test_registrar_texture_get_type(), nullptr));
}

static gpointer add_mock_texture_to_registrar(gpointer pointer) {
  g_return_val_if_fail(FL_IS_TEXTURE_REGISTRAR(pointer), nullptr);
  FlTextureRegistrar* registrar = FL_TEXTURE_REGISTRAR(pointer);
  g_autoptr(FlTexture) texture = FL_TEXTURE(fl_test_registrar_texture_new());
  fl_texture_registrar_register_texture(registrar, texture);
  int64_t* id = g_new0(int64_t, 1);
  id[0] = fl_texture_get_id(texture);
  return id;
}

class FlTextureRegistrarTest : public flutter::testing::LinuxTest {};

// Checks can make a mock registrar.
TEST_F(FlTextureRegistrarTest, MockRegistrar) {
  g_autoptr(FlTexture) texture = FL_TEXTURE(fl_test_registrar_texture_new());
  g_autoptr(FlMockTextureRegistrar) registrar = fl_mock_texture_registrar_new();
  EXPECT_TRUE(FL_IS_MOCK_TEXTURE_REGISTRAR(registrar));

  EXPECT_TRUE(fl_texture_registrar_register_texture(
      FL_TEXTURE_REGISTRAR(registrar), texture));
  EXPECT_EQ(fl_mock_texture_registrar_get_texture(registrar), texture);
  EXPECT_TRUE(fl_texture_registrar_mark_texture_frame_available(
      FL_TEXTURE_REGISTRAR(registrar), texture));
  EXPECT_TRUE(fl_mock_texture_registrar_get_frame_available(registrar));
  EXPECT_TRUE(fl_texture_registrar_unregister_texture(
      FL_TEXTURE_REGISTRAR(registrar), texture));
  EXPECT_EQ(fl_mock_texture_registrar_get_texture(registrar), nullptr);
}

// Test that registering a texture works.
TEST_F(FlTextureRegistrarTest, RegisterTexture) {
  bool register_called = false;
  fl_engine_get_embedder_api(engine)->RegisterExternalTexture =
      MOCK_ENGINE_PROC(RegisterExternalTexture,
                       ([&register_called](auto engine, int64_t texture_id) {
                         register_called = true;
                         return kSuccess;
                       }));
  bool unregister_called = false;
  fl_engine_get_embedder_api(engine)->UnregisterExternalTexture =
      MOCK_ENGINE_PROC(UnregisterExternalTexture,
                       ([&unregister_called](auto engine, int64_t texture_id) {
                         unregister_called = true;
                         return kSuccess;
                       }));

  g_autoptr(FlTextureRegistrar) registrar = fl_texture_registrar_new(engine);
  g_autoptr(FlTexture) texture = FL_TEXTURE(fl_test_registrar_texture_new());

  // EXPECT_FALSE(fl_texture_registrar_unregister_texture(registrar, texture));
  EXPECT_FALSE(register_called);
  EXPECT_TRUE(fl_texture_registrar_register_texture(registrar, texture));
  EXPECT_TRUE(register_called);
  EXPECT_FALSE(unregister_called);
  EXPECT_TRUE(fl_texture_registrar_unregister_texture(registrar, texture));
  EXPECT_TRUE(unregister_called);
}

// Test that marking a texture frame available works.
TEST_F(FlTextureRegistrarTest, MarkTextureFrameAvailable) {
  bool register_called = false;
  fl_engine_get_embedder_api(engine)->RegisterExternalTexture =
      MOCK_ENGINE_PROC(RegisterExternalTexture,
                       ([&register_called](auto engine, int64_t texture_id) {
                         register_called = true;
                         return kSuccess;
                       }));
  fl_engine_get_embedder_api(engine)->UnregisterExternalTexture =
      MOCK_ENGINE_PROC(
          UnregisterExternalTexture,
          ([](auto engine, int64_t texture_id) { return kSuccess; }));
  fl_engine_get_embedder_api(engine)->MarkExternalTextureFrameAvailable =
      MOCK_ENGINE_PROC(
          MarkExternalTextureFrameAvailable,
          ([](auto engine, int64_t texture_id) { return kSuccess; }));

  g_autoptr(FlTextureRegistrar) registrar = fl_texture_registrar_new(engine);
  g_autoptr(FlTexture) texture = FL_TEXTURE(fl_test_registrar_texture_new());

  EXPECT_TRUE(fl_texture_registrar_register_texture(registrar, texture));
  EXPECT_TRUE(register_called);
  EXPECT_TRUE(
      fl_texture_registrar_mark_texture_frame_available(registrar, texture));
}

// Test handles error marking a texture frame available.
TEST_F(FlTextureRegistrarTest, MarkInvalidTextureFrameAvailable) {
  fl_engine_get_embedder_api(engine)->RegisterExternalTexture =
      MOCK_ENGINE_PROC(
          RegisterExternalTexture,
          ([](auto engine, int64_t texture_id) { return kSuccess; }));
  fl_engine_get_embedder_api(engine)->UnregisterExternalTexture =
      MOCK_ENGINE_PROC(
          UnregisterExternalTexture,
          ([](auto engine, int64_t texture_id) { return kSuccess; }));
  fl_engine_get_embedder_api(engine)->MarkExternalTextureFrameAvailable =
      MOCK_ENGINE_PROC(MarkExternalTextureFrameAvailable,
                       ([](auto engine, int64_t texture_id) {
                         return kInternalInconsistency;
                       }));

  g_autoptr(FlTextureRegistrar) registrar = fl_texture_registrar_new(engine);
  g_autoptr(FlTexture) texture = FL_TEXTURE(fl_test_registrar_texture_new());

  EXPECT_TRUE(fl_texture_registrar_register_texture(registrar, texture));
  EXPECT_FALSE(
      fl_texture_registrar_mark_texture_frame_available(registrar, texture));
}

// Test the textures can be accessed via multiple threads without
// synchronization issues.
TEST_F(FlTextureRegistrarTest, RegistrarRegisterTextureInMultipleThreads) {
  fl_engine_get_embedder_api(engine)->RegisterExternalTexture =
      MOCK_ENGINE_PROC(
          RegisterExternalTexture,
          ([](auto engine, int64_t texture_id) { return kSuccess; }));
  fl_engine_get_embedder_api(engine)->UnregisterExternalTexture =
      MOCK_ENGINE_PROC(
          UnregisterExternalTexture,
          ([](auto engine, int64_t texture_id) { return kSuccess; }));

  g_autoptr(FlTextureRegistrar) registrar = fl_texture_registrar_new(engine);
  GThread* threads[kThreadCount];
  int64_t ids[kThreadCount];

  for (uint64_t t = 0; t < kThreadCount; t++) {
    threads[t] =
        g_thread_new(nullptr, add_mock_texture_to_registrar, registrar);
    EXPECT_NE(threads[t], nullptr);
  }
  for (uint64_t t = 0; t < kThreadCount; t++) {
    g_autofree int64_t* id = static_cast<int64_t*>(g_thread_join(threads[t]));
    ids[t] = *id;
  };
  // Check all the textures were created.
  for (uint64_t t = 0; t < kThreadCount; t++) {
    EXPECT_TRUE(fl_texture_registrar_lookup_texture(registrar, ids[t]) != NULL);
  };
}
