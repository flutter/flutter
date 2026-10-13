// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstddef>
#include <memory>

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_ahb_texture.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_ahb.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// Bounds the tests paint into. Any non-empty size works.
constexpr DlRect kBounds = DlRect::MakeWH(10, 10);

void Paint(Texture& texture, bool freeze) {
  DisplayListBuilder builder;
  Texture::PaintContext context{.canvas = &builder};
  texture.Paint(context, kBounds, freeze, DlImageSampling::kNearestNeighbor);
}

// Stands in for the image a backend imports from a hardware buffer.
class FakeDlImage : public DlImage {
 public:
  Type GetImageType() const override { return Type::kImpeller; }
  bool isTextureBacked() const override { return true; }
  DlColorSpace GetColorSpace() const override { return DlColorSpace::kSRGB; }
  bool isOpaque() const override { return true; }
  bool isUIThreadSafe() const override { return true; }
  DlISize GetSize() const override { return DlISize(1, 1); }
  size_t GetApproximateByteSize() const override { return sizeof(*this); }
};

// Hands out frames and counts how many the texture releases.
struct FakeHardwareBufferProducer {
  bool has_frame = true;
  int acquire_calls = 0;
  int release_calls = 0;
  int destruction_calls = 0;

  static FakeHardwareBufferProducer& From(void* user_data) {
    return *static_cast<FakeHardwareBufferProducer*>(user_data);
  }

  static FlutterAndroidHardwareBufferSource Callbacks(
      bool drop_frames_on_context_destroyed) {
    return {
        .struct_size = sizeof(FlutterAndroidHardwareBufferSource),
        .acquire_frame_callback =
            [](void* user_data, FlutterAndroidHardwareBufferFrame* frame_out) {
              FakeHardwareBufferProducer& producer = From(user_data);
              producer.acquire_calls++;
              if (!producer.has_frame) {
                return false;
              }
              frame_out->hardware_buffer = nullptr;
              frame_out->release_user_data = &producer;
              frame_out->release_callback = [](void* release_user_data) {
                From(release_user_data).release_calls++;
              };
              return true;
            },
        .drop_frames_on_context_destroyed = drop_frames_on_context_destroyed,
    };
  }

  EmbedderAndroidHardwareBufferSource MakeSource(
      bool drop_frames_on_context_destroyed) {
    return {.callbacks = Callbacks(drop_frames_on_context_destroyed),
            .user_data = this};
  }

  FlutterExternalTextureInfo MakeInfo(
      const FlutterAndroidHardwareBufferSource* source) {
    return {
        .struct_size = sizeof(FlutterExternalTextureInfo),
        .texture_id = 0,
        .type = kFlutterExternalTextureTypeAndroidHardwareBuffer,
        .user_data = this,
        .open_gl_stream = nullptr,
        .destruction_callback =
            [](void* user_data) { From(user_data).destruction_calls++; },
        .android_hardware_buffer = source,
    };
  }
};

// Turns every acquired frame into an image, the way the backends do.
class TestImageTexture : public EmbedderExternalTextureAHB {
 public:
  explicit TestImageTexture(EmbedderAndroidHardwareBufferSource source)
      : EmbedderExternalTextureAHB(/*id=*/1, source) {}

  bool has_image() const { return dl_image_ != nullptr; }

 private:
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override {
    std::unique_ptr<AcquiredFrame> frame = AcquireFrame();
    if (frame) {
      dl_image_ = sk_make_sp<FakeDlImage>();
    }
  }

  void Attach(PaintContext& context) override {
    state_ = AttachmentState::kAttached;
  }

  void Detach() override {}
};

}  // namespace

TEST(EmbedderExternalTextureAHBTest,
     AcquiresOnUnfrozenPaintsAndReleasesEachFrame) {
  FakeHardwareBufferProducer producer;
  TestImageTexture texture(
      producer.MakeSource(/*drop_frames_on_context_destroyed=*/false));

  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/true);

  EXPECT_EQ(producer.acquire_calls, 2);
  EXPECT_EQ(producer.release_calls, 2);
}

TEST(EmbedderExternalTextureAHBTest, NoFrameMeansNothingToRelease) {
  FakeHardwareBufferProducer producer;
  producer.has_frame = false;
  TestImageTexture texture(
      producer.MakeSource(/*drop_frames_on_context_destroyed=*/false));

  Paint(texture, /*freeze=*/false);

  EXPECT_EQ(producer.acquire_calls, 1);
  EXPECT_EQ(producer.release_calls, 0);
  EXPECT_FALSE(texture.has_image());
}

TEST(EmbedderExternalTextureAHBTest, DropsTheImageOnContextLossOnlyWhenAsked) {
  FakeHardwareBufferProducer dropping_producer;
  TestImageTexture dropping(
      dropping_producer.MakeSource(/*drop_frames_on_context_destroyed=*/true));
  FakeHardwareBufferProducer keeping_producer;
  TestImageTexture keeping(
      keeping_producer.MakeSource(/*drop_frames_on_context_destroyed=*/false));
  Paint(dropping, /*freeze=*/false);
  Paint(keeping, /*freeze=*/false);

  static_cast<Texture&>(dropping).OnGrContextDestroyed();
  static_cast<Texture&>(keeping).OnGrContextDestroyed();

  EXPECT_FALSE(dropping.has_image());
  EXPECT_TRUE(keeping.has_image());
}

TEST(EmbedderAHBTextureTest, CreateRejectsIncompleteInfo) {
  FakeHardwareBufferProducer producer;
  const FlutterAndroidHardwareBufferSource callbacks =
      FakeHardwareBufferProducer::Callbacks(
          /*drop_frames_on_context_destroyed=*/false);

  EXPECT_EQ(EmbedderAHBTexture::Create(producer.MakeInfo(nullptr), nullptr),
            nullptr);

  FlutterAndroidHardwareBufferSource no_acquire = callbacks;
  no_acquire.acquire_frame_callback = nullptr;
  EXPECT_EQ(EmbedderAHBTexture::Create(producer.MakeInfo(&no_acquire), nullptr),
            nullptr);

  FlutterAndroidHardwareBufferSource short_source = callbacks;
  short_source.struct_size = sizeof(size_t);
  EXPECT_EQ(
      EmbedderAHBTexture::Create(producer.MakeInfo(&short_source), nullptr),
      nullptr);

  // An info from before the source field existed cannot name a source.
  FlutterExternalTextureInfo short_info = producer.MakeInfo(&callbacks);
  short_info.struct_size =
      offsetof(FlutterExternalTextureInfo, android_hardware_buffer);
  EXPECT_EQ(EmbedderAHBTexture::Create(short_info, nullptr), nullptr);

  FlutterExternalTextureInfo stream_type = producer.MakeInfo(&callbacks);
  stream_type.type = kFlutterExternalTextureTypeOpenGLStream;
  EXPECT_EQ(EmbedderAHBTexture::Create(stream_type, nullptr), nullptr);

  // Rejected infos stay owned by the caller.
  EXPECT_EQ(producer.destruction_calls, 0);
}

TEST(EmbedderAHBTextureTest, OwnsUserDataUntilDestroyed) {
  FakeHardwareBufferProducer producer;
  const FlutterAndroidHardwareBufferSource callbacks =
      FakeHardwareBufferProducer::Callbacks(
          /*drop_frames_on_context_destroyed=*/false);
  std::unique_ptr<EmbedderAHBTexture> texture =
      EmbedderAHBTexture::Create(producer.MakeInfo(&callbacks), nullptr);
  ASSERT_NE(texture, nullptr);
  EXPECT_EQ(texture->Id(), 0);

  // Without a GPU context there is no implementation, so the source is not
  // called.
  Paint(*texture, /*freeze=*/false);
  EXPECT_EQ(producer.acquire_calls, 0);
  EXPECT_EQ(producer.destruction_calls, 0);

  texture.reset();
  EXPECT_EQ(producer.destruction_calls, 1);
}

}  // namespace testing
}  // namespace flutter
