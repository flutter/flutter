#ifndef FLUTTER_LIB_UI_PAINTING_DL_IMAGE_TEXTURE_REGISTRY_H_
#define FLUTTER_LIB_UI_PAINTING_DL_IMAGE_TEXTURE_REGISTRY_H_

#include "flutter/common/graphics/texture.h"
#include "flutter/display_list/image/dl_image.h"

namespace flutter {

class DlImageTextureRegistry : public DlImage {
 public:
  DlImageTextureRegistry(std::shared_ptr<flutter::TextureRegistry> registry,
                         impeller::AiksContext* aiks_context,
                         GrDirectContext* gr_context,
                         int64_t texture_id,
                         int width,
                         int height);

  ~DlImageTextureRegistry() override = default;

  sk_sp<SkImage> skia_image() const override;

  std::shared_ptr<impeller::Texture> impeller_texture() const override;

  bool isOpaque() const override { return false; }
  bool isTextureBacked() const override { return true; }
  bool isUIThreadSafe() const override { return true; }
  DlISize GetSize() const override { return size_; }
  size_t GetApproximateByteSize() const override {
    return size_.width * size_.height * 4;
  }

 private:
  std::shared_ptr<flutter::TextureRegistry> registry_;
  impeller::AiksContext* aiks_context_;
  GrDirectContext* gr_context_;
  int64_t texture_id_;
  DlISize size_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_DL_IMAGE_TEXTURE_REGISTRY_H_
