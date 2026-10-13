// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/shell/platform/android/image_external_texture.h"
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

}  // namespace

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
