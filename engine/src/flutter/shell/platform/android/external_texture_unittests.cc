// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <memory>

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/shell/platform/android/image_external_texture.h"
#include "flutter/shell/platform/android/surface_texture_external_texture.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// The GL texture name the fake SurfaceTexture texture attaches to.
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

// Records what the texture asks of its producer.
struct FakeSurfaceTextureProducer {
  int attach_calls = 0;
  uint32_t attached_name = 0;
  int update_calls = 0;
  int detach_calls = 0;
  int pending_frame_queries = 0;
  int destruction_calls = 0;
  bool pending_frame = false;
  std::array<float, 16> transformation = kHalfScale;

  SurfaceTextureSource MakeSource() {
    return {
        .user_data = this,
        .attach =
            [](void* user_data, uint32_t texture_name) {
              auto* producer =
                  static_cast<FakeSurfaceTextureProducer*>(user_data);
              producer->attach_calls++;
              producer->attached_name = texture_name;
            },
        .update =
            [](void* user_data, float transformation_out[16]) {
              auto* producer =
                  static_cast<FakeSurfaceTextureProducer*>(user_data);
              producer->update_calls++;
              std::copy(producer->transformation.begin(),
                        producer->transformation.end(), transformation_out);
            },
        .detach =
            [](void* user_data) {
              static_cast<FakeSurfaceTextureProducer*>(user_data)
                  ->detach_calls++;
            },
        .has_pending_frame =
            [](void* user_data) {
              auto* producer =
                  static_cast<FakeSurfaceTextureProducer*>(user_data);
              producer->pending_frame_queries++;
              return producer->pending_frame;
            },
        .destruction =
            [](void* user_data) {
              static_cast<FakeSurfaceTextureProducer*>(user_data)
                  ->destruction_calls++;
            },
    };
  }
};

// Attaches and updates the way the GL backends do, without GL.
class TestSurfaceTexture : public SurfaceTextureExternalTexture {
 public:
  explicit TestSurfaceTexture(SurfaceTextureSource source)
      : SurfaceTextureExternalTexture(/*id=*/1, source) {}

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

}  // namespace

TEST(SurfaceTextureSourceTest, AttachesOnceAndUpdatesOnEveryUnfrozenPaint) {
  FakeSurfaceTextureProducer producer;
  TestSurfaceTexture texture(producer.MakeSource());

  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/false);

  EXPECT_EQ(producer.attach_calls, 1);
  EXPECT_EQ(producer.attached_name, static_cast<uint32_t>(kFakeTextureName));
  EXPECT_EQ(producer.update_calls, 3);
  // Only frozen paints ask whether a frame is pending.
  EXPECT_EQ(producer.pending_frame_queries, 0);
}

TEST(SurfaceTextureSourceTest, FrozenPaintAsksForPendingFrame) {
  FakeSurfaceTextureProducer producer;
  TestSurfaceTexture texture(producer.MakeSource());
  Paint(texture, /*freeze=*/false);

  Paint(texture, /*freeze=*/true);

  EXPECT_EQ(producer.pending_frame_queries, 1);
}

TEST(SurfaceTextureSourceTest, UsesTheTransformationOfTheSource) {
  FakeSurfaceTextureProducer producer;
  TestSurfaceTexture texture(producer.MakeSource());

  Paint(texture, /*freeze=*/false);

  EXPECT_EQ(texture.uv_transformation(), SkM44::ColMajor(kHalfScale.data()));
}

TEST(SurfaceTextureSourceTest, DetachesOnContextLossAndReattachesAfter) {
  FakeSurfaceTextureProducer producer;
  TestSurfaceTexture texture(producer.MakeSource());
  Paint(texture, /*freeze=*/false);

  static_cast<Texture&>(texture).OnGrContextDestroyed();
  EXPECT_EQ(producer.detach_calls, 1);
  // Nothing is painted while there is no context.
  Paint(texture, /*freeze=*/false);
  EXPECT_EQ(producer.update_calls, 1);

  static_cast<Texture&>(texture).OnGrContextCreated();
  Paint(texture, /*freeze=*/false);
  EXPECT_EQ(producer.attach_calls, 2);
  EXPECT_EQ(producer.update_calls, 2);
}

TEST(SurfaceTextureSourceTest, DestroyingTheTextureReleasesTheSource) {
  FakeSurfaceTextureProducer producer;
  {
    TestSurfaceTexture texture(producer.MakeSource());
    EXPECT_EQ(producer.destruction_calls, 0);
  }
  EXPECT_EQ(producer.destruction_calls, 1);
}

namespace {

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

  HardwareBufferSource MakeSource(bool drop_frames_on_context_destroyed) {
    return {
        .user_data = this,
        .acquire_frame =
            [](void* user_data, HardwareBufferFrame* frame_out) {
              auto* producer =
                  static_cast<FakeHardwareBufferProducer*>(user_data);
              producer->acquire_calls++;
              if (!producer->has_frame) {
                return false;
              }
              *frame_out = {
                  .buffer = nullptr,
                  .release_user_data = producer,
                  .release =
                      [](void* release_user_data) {
                        static_cast<FakeHardwareBufferProducer*>(
                            release_user_data)
                            ->release_calls++;
                      },
              };
              return true;
            },
        .drop_frames_on_context_destroyed = drop_frames_on_context_destroyed,
        .destruction =
            [](void* user_data) {
              static_cast<FakeHardwareBufferProducer*>(user_data)
                  ->destruction_calls++;
            },
    };
  }
};

// Turns every acquired frame into an image, the way the backends do.
class TestImageTexture : public ImageExternalTexture {
 public:
  explicit TestImageTexture(HardwareBufferSource source)
      : ImageExternalTexture(/*id=*/1, source) {}

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

TEST(HardwareBufferSourceTest, AcquiresOnUnfrozenPaintsAndReleasesEachFrame) {
  FakeHardwareBufferProducer producer;
  TestImageTexture texture(
      producer.MakeSource(/*drop_frames_on_context_destroyed=*/false));

  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/false);
  Paint(texture, /*freeze=*/true);

  EXPECT_EQ(producer.acquire_calls, 2);
  EXPECT_EQ(producer.release_calls, 2);
}

TEST(HardwareBufferSourceTest, NoFrameMeansNothingToRelease) {
  FakeHardwareBufferProducer producer;
  producer.has_frame = false;
  TestImageTexture texture(
      producer.MakeSource(/*drop_frames_on_context_destroyed=*/false));

  Paint(texture, /*freeze=*/false);

  EXPECT_EQ(producer.acquire_calls, 1);
  EXPECT_EQ(producer.release_calls, 0);
  EXPECT_FALSE(texture.has_image());
}

TEST(HardwareBufferSourceTest, DropsTheImageOnContextLossOnlyWhenAsked) {
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

TEST(HardwareBufferSourceTest, DestroyingTheTextureReleasesTheSource) {
  FakeHardwareBufferProducer producer;
  {
    TestImageTexture texture(
        producer.MakeSource(/*drop_frames_on_context_destroyed=*/false));
  }
  EXPECT_EQ(producer.destruction_calls, 1);
}

}  // namespace testing
}  // namespace flutter
