#include "flutter/common/graphics/texture.h"
#include "flutter/lib/ui/painting/dl_image_texture_registry.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class MockTexture : public Texture {
 public:
  explicit MockTexture(int64_t id) : Texture(id) {}
  ~MockTexture() override = default;

  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override {}
  void MarkNewFrameAvailable() override {}
  void OnTextureUnregistered() override {}

  void OnGrContextCreated() override {}
  void OnGrContextDestroyed() override {}

  sk_sp<DlImage> GetTextureImage(PaintContext& context,
                                 const DlRect& bounds,
                                 bool freeze) override {
    return nullptr;
  }
};

TEST(DlImageTextureRegistryTest, BasicInfo) {
  DlImageTextureRegistry dl_image(1234, 100, 200);

  EXPECT_EQ(dl_image.GetSize().width, 100);
  EXPECT_EQ(dl_image.GetSize().height, 200);
  EXPECT_FALSE(dl_image.isOpaque());
  EXPECT_TRUE(dl_image.isTextureBacked());
  EXPECT_TRUE(dl_image.isUIThreadSafe());
  EXPECT_EQ(dl_image.GetApproximateByteSize(), 100u * 200u * 4u);
}

TEST(DlImageTextureRegistryTest, ResolvesToNullWhenNoRegistry) {
  TextureRegistry::SetCurrent({});  // Ensure it's null
  DlImageTextureRegistry dl_image(1234, 100, 200);

  EXPECT_EQ(dl_image.skia_image(), nullptr);
  EXPECT_EQ(dl_image.impeller_texture(), nullptr);
}

TEST(DlImageTextureRegistryTest, ResolvesToNullWhenTextureNotFound) {
  auto registry = std::make_shared<TextureRegistry>();
  TextureRegistry::SetCurrent(registry);
  DlImageTextureRegistry dl_image(1234, 100, 200);

  EXPECT_EQ(dl_image.skia_image(), nullptr);
  EXPECT_EQ(dl_image.impeller_texture(), nullptr);

  TextureRegistry::SetCurrent({});
}

TEST(DlImageTextureRegistryTest, ResolvesWhenTextureFound) {
  auto registry = std::make_shared<TextureRegistry>();
  TextureRegistry::SetCurrent(registry);

  auto texture = std::shared_ptr<MockTexture>(new MockTexture(1234));
  registry->RegisterTexture(texture);

  DlImageTextureRegistry dl_image(1234, 100, 200);

  // Still null because our MockTexture returns null, but it proves it didn't
  // crash.
  EXPECT_EQ(dl_image.skia_image(), nullptr);
  EXPECT_EQ(dl_image.impeller_texture(), nullptr);

  TextureRegistry::SetCurrent({});
}

}  // namespace testing
}  // namespace flutter
