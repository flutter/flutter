// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <array>
#include <memory>

#include "flutter/display_list/dl_builder.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream.h"
#include "flutter/shell/platform/embedder/embedder_gl_stream_texture.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// The GL texture name the test implementation attaches to.
constexpr int kFakeTextureName = 7;

// Bounds the tests paint into. Any non-empty size works.
constexpr DlRect kBounds = DlRect::MakeWH(10, 10);

// A column-major UV transform that scales lookups by one half.
constexpr std::array<float, 16> kHalfScale = {
    0.5, 0,   0, 0,  //
    0,   0.5, 0, 0,  //
    0,   0,   1, 0,  //
    0,   0,   0, 1,  //
};

// Records what the texture asks of the embedder's stream.
struct FakeStream {
  int attach_calls = 0;
  uint32_t attached_name = 0;
  int update_calls = 0;
  int detach_calls = 0;
  int pending_frame_queries = 0;
  int destruction_calls = 0;
  bool pending_frame = false;

  static FakeStream& From(void* user_data) {
    return *static_cast<FakeStream*>(user_data);
  }

  static FlutterOpenGLTextureStreamSource Callbacks() {
    return {
        .struct_size = sizeof(FlutterOpenGLTextureStreamSource),
        .attach_callback =
            [](void* user_data, uint32_t texture_name) {
              From(user_data).attach_calls++;
              From(user_data).attached_name = texture_name;
            },
        .update_callback =
            [](void* user_data, float transformation_out[16]) {
              From(user_data).update_calls++;
              std::copy(kHalfScale.begin(), kHalfScale.end(),
                        transformation_out);
            },
        .detach_callback =
            [](void* user_data) { From(user_data).detach_calls++; },
        .has_pending_frame_callback =
            [](void* user_data) {
              From(user_data).pending_frame_queries++;
              return From(user_data).pending_frame;
            },
    };
  }

  EmbedderOpenGLTextureStream Stream() {
    return {.callbacks = Callbacks(), .user_data = this};
  }
};

// Attaches and updates the way the GL implementations do, without GL.
class TestGLStreamTexture : public EmbedderExternalTextureGLStream {
 public:
  explicit TestGLStreamTexture(EmbedderOpenGLTextureStream stream)
      : EmbedderExternalTextureGLStream(/*id=*/1, stream) {}

  SkM44 uv_transformation() const { return GetCurrentUVTransformation(); }

 private:
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override {
    if (state_ == AttachmentState::kUninitialized) {
      Attach(kFakeTextureName);
    }
    Update();
  }
};

void Paint(Texture& texture, bool freeze) {
  DisplayListBuilder builder;
  Texture::PaintContext context{.canvas = &builder};
  texture.Paint(context, kBounds, freeze, DlImageSampling::kNearestNeighbor);
}

FlutterExternalTextureInfo StreamTextureInfo(
    FakeStream* stream,
    const FlutterOpenGLTextureStreamSource* callbacks) {
  return {
      .struct_size = sizeof(FlutterExternalTextureInfo),
      .texture_id = 0,
      .type = kFlutterExternalTextureTypeOpenGLStream,
      .user_data = stream,
      .open_gl_stream = callbacks,
      .destruction_callback =
          [](void* user_data) {
            FakeStream::From(user_data).destruction_calls++;
          },
  };
}

}  // namespace

TEST(EmbedderGLStreamTextureTest, AttachesOnceAndUpdatesOnEveryUnfrozenPaint) {
  FakeStream stream;
  TestGLStreamTexture texture(stream.Stream());

  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/false);

  EXPECT_EQ(stream.attach_calls, 1);
  EXPECT_EQ(stream.attached_name, static_cast<uint32_t>(kFakeTextureName));
  EXPECT_EQ(stream.update_calls, 3);
  // Only frozen paints ask whether a frame is pending.
  EXPECT_EQ(stream.pending_frame_queries, 0);
}

TEST(EmbedderGLStreamTextureTest, FrozenPaintAsksForPendingFrame) {
  FakeStream stream;
  TestGLStreamTexture texture(stream.Stream());
  Paint(texture, /*freeze=*/false);

  Paint(texture, /*freeze=*/true);

  EXPECT_EQ(stream.pending_frame_queries, 1);
}

TEST(EmbedderGLStreamTextureTest, UsesTheTransformationOfTheStream) {
  FakeStream stream;
  TestGLStreamTexture texture(stream.Stream());

  Paint(texture, /*freeze=*/false);

  EXPECT_EQ(texture.uv_transformation(), SkM44::ColMajor(kHalfScale.data()));
}

TEST(EmbedderGLStreamTextureTest, DetachesOnContextLossAndReattachesAfter) {
  FakeStream stream;
  TestGLStreamTexture texture(stream.Stream());
  Paint(texture, /*freeze=*/false);

  static_cast<Texture&>(texture).OnGrContextDestroyed();
  EXPECT_EQ(stream.detach_calls, 1);
  // Nothing is painted while there is no context.
  Paint(texture, /*freeze=*/false);
  EXPECT_EQ(stream.update_calls, 1);

  static_cast<Texture&>(texture).OnGrContextCreated();
  Paint(texture, /*freeze=*/false);
  EXPECT_EQ(stream.attach_calls, 2);
  EXPECT_EQ(stream.update_calls, 2);
}

TEST(EmbedderGLStreamTextureTest, CreateRejectsIncompleteInfo) {
  FakeStream stream;
  const FlutterOpenGLTextureStreamSource callbacks = FakeStream::Callbacks();

  FlutterExternalTextureInfo no_source = StreamTextureInfo(&stream, nullptr);
  EXPECT_EQ(EmbedderGLStreamTexture::Create(no_source), nullptr);

  FlutterOpenGLTextureStreamSource no_update = callbacks;
  no_update.update_callback = nullptr;
  EXPECT_EQ(
      EmbedderGLStreamTexture::Create(StreamTextureInfo(&stream, &no_update)),
      nullptr);

  FlutterOpenGLTextureStreamSource short_source = callbacks;
  short_source.struct_size = sizeof(size_t);
  EXPECT_EQ(EmbedderGLStreamTexture::Create(
                StreamTextureInfo(&stream, &short_source)),
            nullptr);

  // Rejected infos stay owned by the caller.
  EXPECT_EQ(stream.destruction_calls, 0);
}

TEST(EmbedderGLStreamTextureTest, OwnsUserDataUntilDestroyed) {
  FakeStream stream;
  const FlutterOpenGLTextureStreamSource callbacks = FakeStream::Callbacks();
  std::unique_ptr<EmbedderGLStreamTexture> texture =
      EmbedderGLStreamTexture::Create(StreamTextureInfo(&stream, &callbacks));
  ASSERT_NE(texture, nullptr);
  EXPECT_EQ(texture->Id(), 0);

  // Without a GPU context there is no implementation, so the stream is not
  // called.
  Paint(*texture, /*freeze=*/false);
  EXPECT_EQ(stream.attach_calls, 0);
  EXPECT_EQ(stream.destruction_calls, 0);

  texture.reset();
  EXPECT_EQ(stream.destruction_calls, 1);
}

}  // namespace testing
}  // namespace flutter
