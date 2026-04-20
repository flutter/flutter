// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_IMAGE_DL_IMAGE_H_
#define FLUTTER_DISPLAY_LIST_IMAGE_DL_IMAGE_H_

#include <memory>
#include <optional>
#include <string>

#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkRefCnt.h"

namespace impeller {
class DlImageImpeller;
}  // namespace impeller

namespace flutter {
class DlImageSkia;

//------------------------------------------------------------------------------
/// @brief      Represents an image whose allocation is (usually) resident on
///             device memory.
///
///             Since it is usually impossible or expensive to transmute images
///             for one rendering backend to another, these objects are backend
///             specific.
///
class DlImage : public SkRefCnt {
 public:
  // Describes which GPU context owns this image.
  enum class OwningContext { kRaster, kIO };

  virtual ~DlImage();

  //----------------------------------------------------------------------------
  /// @brief      The backend type of this image.
  ///
  enum class Type { kSkia, kImpeller };

  //----------------------------------------------------------------------------
  /// @brief      Returns the backend type of this image.
  ///
  /// @return     The image type.
  ///
  virtual Type GetImageType() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      Safe downcast to DlImageSkia.
  ///
  /// @return     A pointer to DlImageSkia or null if not a Skia image.
  ///
  virtual const DlImageSkia* asSkiaImage() const { return nullptr; }

  //----------------------------------------------------------------------------
  /// @brief      Safe downcast to DlImageImpeller.
  ///
  /// @return     A pointer to DlImageImpeller or null if not an Impeller image.
  ///
  virtual const impeller::DlImageImpeller* asImpellerImage() const {
    return nullptr;
  }

  //----------------------------------------------------------------------------
  /// @brief      Returns true if the image is backed by a GPU texture.
  ///
  virtual bool isTextureBacked() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      Gets the color space of the image.
  ///
  /// @return     The color space.
  ///
  virtual DlColorSpace GetColorSpace() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      If the pixel format of this image ignores alpha, this returns
  ///             true. This method might conservatively return false when it
  ///             cannot guarnatee an opaque image, for example when the pixel
  ///             format of the image supports alpha but the image is made up of
  ///             entirely opaque pixels.
  ///
  /// @return     True if the pixel format of this image ignores alpha.
  ///
  virtual bool isOpaque() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      If the underlying platform image held by this object has no
  ///             threading requirements for the release of that image (or if
  ///             arrangements have already been made to forward that image to
  ///             the correct thread upon deletion), this method returns true.
  ///
  /// @return     True if the underlying image is held in a thread-safe manner.
  ///
  virtual bool isUIThreadSafe() const = 0;

  //----------------------------------------------------------------------------
  /// @return     The dimensions of the pixel grid.
  ///
  virtual DlISize GetSize() const = 0;

  //----------------------------------------------------------------------------
  /// @return     The approximate byte size of the allocation of this image.
  ///             This takes into account details such as mip-mapping. The
  ///             allocation is usually resident in device memory.
  ///
  virtual size_t GetApproximateByteSize() const = 0;

  //----------------------------------------------------------------------------
  /// @return     The width of the pixel grid. A convenience method that calls
  ///             |DlImage::dimensions|.
  ///
  int width() const;

  //----------------------------------------------------------------------------
  /// @return     The height of the pixel grid. A convenience method that calls
  ///             |DlImage::dimensions|.
  ///
  int height() const;

  //----------------------------------------------------------------------------
  /// @return     The bounds of the pixel grid with 0, 0 as origin. A
  ///             convenience method that calls |DlImage::dimensions|.
  ///
  DlIRect GetBounds() const;

  //----------------------------------------------------------------------------
  /// @return     Specifies which context was used to create this image. The
  ///             image must be collected on the same task runner as its
  ///             context.
  virtual OwningContext owning_context() const { return OwningContext::kIO; }

  //----------------------------------------------------------------------------
  /// @return     An error, if any, that occurred when trying to create the
  ///             image.
  virtual std::optional<std::string> get_error() const;

  bool Equals(const DlImage* other) const;

  bool Equals(const DlImage& other) const { return Equals(&other); }

  bool Equals(const sk_sp<const DlImage>& other) const {
    return Equals(other.get());
  }

 protected:
  DlImage();
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_IMAGE_DL_IMAGE_H_
