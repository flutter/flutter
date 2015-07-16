// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/android/java_bitmap.h"

#include <android/bitmap.h>

#include "base/android/jni_string.h"
#include "base/logging.h"
#include "jni/BitmapHelper_jni.h"
#include "skia/ext/image_operations.h"
#include "ui/gfx/size.h"

using base::android::AttachCurrentThread;
using base::android::ConvertUTF8ToJavaString;

namespace gfx {

JavaBitmap::JavaBitmap(jobject bitmap)
    : bitmap_(bitmap),
      pixels_(NULL) {
  int err = AndroidBitmap_lockPixels(AttachCurrentThread(), bitmap_, &pixels_);
  DCHECK(!err);
  DCHECK(pixels_);

  AndroidBitmapInfo info;
  err = AndroidBitmap_getInfo(AttachCurrentThread(), bitmap_, &info);
  DCHECK(!err);
  size_ = gfx::Size(info.width, info.height);
  format_ = info.format;
  stride_ = info.stride;
}

JavaBitmap::~JavaBitmap() {
  int err = AndroidBitmap_unlockPixels(AttachCurrentThread(), bitmap_);
  DCHECK(!err);
}

// static
bool JavaBitmap::RegisterJavaBitmap(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

static int SkColorTypeToBitmapFormat(SkColorType color_type) {
  switch (color_type) {
    case kAlpha_8_SkColorType:
      return BITMAP_FORMAT_ALPHA_8;
    case kARGB_4444_SkColorType:
      return BITMAP_FORMAT_ARGB_4444;
    case kN32_SkColorType:
      return BITMAP_FORMAT_ARGB_8888;
    case kRGB_565_SkColorType:
      return BITMAP_FORMAT_RGB_565;
    case kUnknown_SkColorType:
    default:
      NOTREACHED();
      return BITMAP_FORMAT_NO_CONFIG;
  }
}

ScopedJavaLocalRef<jobject> CreateJavaBitmap(int width,
                                             int height,
                                             SkColorType color_type) {
  DCHECK_GT(width, 0);
  DCHECK_GT(height, 0);
  int java_bitmap_config = SkColorTypeToBitmapFormat(color_type);
  return Java_BitmapHelper_createBitmap(
      AttachCurrentThread(), width, height, java_bitmap_config);
}

ScopedJavaLocalRef<jobject> ConvertToJavaBitmap(const SkBitmap* skbitmap) {
  DCHECK(skbitmap);
  DCHECK(!skbitmap->isNull());
  SkColorType color_type = skbitmap->colorType();
  DCHECK((color_type == kRGB_565_SkColorType) ||
         (color_type == kN32_SkColorType));
  ScopedJavaLocalRef<jobject> jbitmap = CreateJavaBitmap(
      skbitmap->width(), skbitmap->height(), color_type);
  SkAutoLockPixels src_lock(*skbitmap);
  JavaBitmap dst_lock(jbitmap.obj());
  void* src_pixels = skbitmap->getPixels();
  void* dst_pixels = dst_lock.pixels();
  memcpy(dst_pixels, src_pixels, skbitmap->getSize());

  return jbitmap;
}

SkBitmap CreateSkBitmapFromAndroidResource(const char* name, gfx::Size size) {
  DCHECK(name);
  DCHECK(!size.IsEmpty());
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> jname(ConvertUTF8ToJavaString(env, name));
  base::android::ScopedJavaLocalRef<jobject> jobj =
      Java_BitmapHelper_decodeDrawableResource(
          env, jname.obj(), size.width(), size.height());

  if (jobj.is_null())
    return SkBitmap();

  SkBitmap bitmap = CreateSkBitmapFromJavaBitmap(gfx::JavaBitmap(jobj.obj()));
  if (bitmap.isNull())
    return bitmap;

  return skia::ImageOperations::Resize(
      bitmap, skia::ImageOperations::RESIZE_BOX, size.width(), size.height());
}

SkBitmap CreateSkBitmapFromJavaBitmap(const JavaBitmap& jbitmap) {
  // TODO(jdduke): Convert to DCHECK's when sufficient data has been capture for
  // crbug.com/341406.
  CHECK_EQ(jbitmap.format(), ANDROID_BITMAP_FORMAT_RGBA_8888);
  CHECK(!jbitmap.size().IsEmpty());
  CHECK_GT(jbitmap.stride(), 0U);
  CHECK(jbitmap.pixels());

  gfx::Size src_size = jbitmap.size();

  SkBitmap skbitmap;
  skbitmap.allocPixels(SkImageInfo::MakeN32Premul(src_size.width(),
                                                  src_size.height()),
                       jbitmap.stride());
  const void* src_pixels = jbitmap.pixels();
  void* dst_pixels = skbitmap.getPixels();
  memcpy(dst_pixels, src_pixels, skbitmap.getSize());

  return skbitmap;
}

SkColorType ConvertToSkiaColorType(jobject bitmap_config) {
  int jbitmap_config = Java_BitmapHelper_getBitmapFormatForConfig(
      AttachCurrentThread(), bitmap_config);
  switch (jbitmap_config) {
    case BITMAP_FORMAT_ALPHA_8:
      return kAlpha_8_SkColorType;
    case BITMAP_FORMAT_ARGB_4444:
      return kARGB_4444_SkColorType;
    case BITMAP_FORMAT_ARGB_8888:
      return kN32_SkColorType;
    case BITMAP_FORMAT_RGB_565:
      return kRGB_565_SkColorType;
    case BITMAP_FORMAT_NO_CONFIG:
    default:
      return kUnknown_SkColorType;
  }
}

}  //  namespace gfx
