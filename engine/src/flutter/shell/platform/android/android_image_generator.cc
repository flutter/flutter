// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_image_generator.h"

#include <cstring>
#include <memory>
#include <utility>

#include <android/bitmap.h>
#include <android/hardware_buffer.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/android/jni_util.h"

namespace flutter {

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_jni_class = nullptr;
static jmethodID g_decode_image_method = nullptr;

AndroidImageGenerator::~AndroidImageGenerator() {
  if (software_decoded_release_) {
    software_decoded_release_();
  }
}

AndroidImageGenerator::AndroidImageGenerator(std::vector<uint8_t> data)
    : data_(std::move(data)),
      image_info_({
          .width = 0,
          .height = 0,
          .color_type = kFlutterImageGeneratorColorTypeUnknown,
          .alpha_type = kFlutterImageGeneratorAlphaTypeUnknown,
      }) {}

const FlutterImageGeneratorInfo& AndroidImageGenerator::GetInfo() {
  header_decoded_latch_.Wait();
  return image_info_;
}

uint32_t AndroidImageGenerator::GetFrameCount() const {
  return 1;
}

uint32_t AndroidImageGenerator::GetPlayCount() const {
  return 1;
}

FlutterImageGeneratorFrameInfo AndroidImageGenerator::GetFrameInfo(
    uint32_t frame_index) {
  return FlutterImageGeneratorFrameInfo{
      .required_frame = -1,
      .duration_ms = 0,
      .disposal_method = kFlutterImageGeneratorDisposalMethodKeep,
      .has_disposal_rect = false,
      .disposal_rect = {},
      .blend_mode = kFlutterImageGeneratorBlendModeSrcOver,
  };
}

bool AndroidImageGenerator::GetScaledDimensions(float desired_scale,
                                                uint32_t* scaled_width_out,
                                                uint32_t* scaled_height_out) {
  if (!scaled_width_out || !scaled_height_out) {
    return false;
  }
  const FlutterImageGeneratorInfo& info = GetInfo();
  if (!header_valid_ || info.width == 0 || info.height == 0) {
    return false;
  }
  *scaled_width_out = info.width;
  *scaled_height_out = info.height;
  return true;
}

bool AndroidImageGenerator::GetPixels(const FlutterImageGeneratorInfo& info,
                                      void* pixels,
                                      size_t row_bytes,
                                      uint32_t frame_index,
                                      std::optional<uint32_t> prior_frame) {
  fully_decoded_latch_.Wait();

  if (!software_decoded_data_ || !pixels) {
    return false;
  }

  if (kFlutterImageGeneratorColorTypeRGBA8888 != info.color_type) {
    return false;
  }

  switch (info.alpha_type) {
    case kFlutterImageGeneratorAlphaTypeOpaque:
      if (kFlutterImageGeneratorAlphaTypeOpaque != GetInfo().alpha_type) {
        return false;
      }
      break;
    case kFlutterImageGeneratorAlphaTypePremul:
      break;
    default:
      return false;
  }

  // Each RGBA_8888 pixel is 4 bytes.
  constexpr size_t kBytesPerPixelRGBA8888 = sizeof(uint32_t);
  const size_t min_row_bytes =
      static_cast<size_t>(info.width) * kBytesPerPixelRGBA8888;
  if (info.width == 0 || info.height == 0 || row_bytes < min_row_bytes) {
    return false;
  }

  const size_t last_row_index = static_cast<size_t>(info.height - 1);
  const size_t last_row_offset = last_row_index * row_bytes;
  if (last_row_index > 0 && last_row_offset / last_row_index != row_bytes) {
    return false;
  }
  if (last_row_offset > SIZE_MAX - min_row_bytes) {
    return false;
  }
  const size_t pixels_size = last_row_offset + min_row_bytes;
  if (pixels_size < software_decoded_size_) {
    return false;
  }
  std::memcpy(pixels, software_decoded_data_, software_decoded_size_);
  return true;
}

void AndroidImageGenerator::DecodeImage() {
  DoDecodeImage();

  header_decoded_latch_.Signal();
  fully_decoded_latch_.Signal();
}

void AndroidImageGenerator::DoDecodeImage() {
  FML_DCHECK(g_flutter_jni_class);
  FML_DCHECK(g_decode_image_method);

  // Call FlutterJNI.decodeImage

  JNIEnv* env = fml::jni::AttachCurrentThread();

  // This task is run on the IO thread.  Create a frame to ensure that all
  // local JNI references used here are freed.
  fml::jni::ScopedJavaLocalFrame scoped_local_reference_frame(env);

  jobject direct_buffer =
      env->NewDirectByteBuffer(data_.data(), static_cast<jlong>(data_.size()));

  auto bitmap = std::make_unique<fml::jni::ScopedJavaGlobalRef<jobject>>(
      env, env->CallStaticObjectMethod(g_flutter_jni_class->obj(),
                                       g_decode_image_method, direct_buffer,
                                       reinterpret_cast<jlong>(this)));
  FML_CHECK(fml::jni::CheckException(env));

  if (bitmap->is_null()) {
    return;
  }

  AndroidBitmapInfo info;
  [[maybe_unused]] int status;
  if ((status = AndroidBitmap_getInfo(env, bitmap->obj(), &info)) < 0) {
    FML_DLOG(ERROR) << "Failed to get bitmap info, status=" << status;
    return;
  }
  FML_DCHECK(info.format == ANDROID_BITMAP_FORMAT_RGBA_8888);

  // Lock the android buffer and release it when the generator is destroyed.

  void* pixel_lock = nullptr;
  if ((status = AndroidBitmap_lockPixels(env, bitmap->obj(), &pixel_lock)) <
      0) {
    FML_DLOG(ERROR) << "Failed to lock pixels, error=" << status;
    return;
  }

  software_decoded_data_ = pixel_lock;
  software_decoded_size_ =
      static_cast<size_t>(info.width) * info.height * sizeof(uint32_t);
  fml::jni::ScopedJavaGlobalRef<jobject>* raw_bitmap = bitmap.release();
  software_decoded_release_ = [raw_bitmap]() {
    JNIEnv* release_env = fml::jni::AttachCurrentThread();
    AndroidBitmap_unlockPixels(release_env, raw_bitmap->obj());
    delete raw_bitmap;
  };
}

bool AndroidImageGenerator::Register(JNIEnv* env) {
  g_flutter_jni_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("io/flutter/embedding/engine/FlutterJNI"));
  FML_DCHECK(!g_flutter_jni_class->is_null());

  g_decode_image_method = env->GetStaticMethodID(
      g_flutter_jni_class->obj(), "decodeImage",
      "(Ljava/nio/ByteBuffer;J)Landroid/graphics/Bitmap;");
  FML_DCHECK(g_decode_image_method);

  static const JNINativeMethod header_decoded_method = {
      .name = "nativeImageHeaderCallback",
      .signature = "(JII)V",
      .fnPtr = reinterpret_cast<void*>(
          &AndroidImageGenerator::NativeImageHeaderCallback),
  };
  if (env->RegisterNatives(g_flutter_jni_class->obj(), &header_decoded_method,
                           1) != 0) {
    FML_LOG(ERROR)
        << "Failed to register FlutterJNI.nativeImageHeaderCallback method";
    return false;
  }

  return true;
}

std::shared_ptr<AndroidImageGenerator> AndroidImageGenerator::MakeFromData(
    std::vector<uint8_t> data,
    const fml::RefPtr<fml::TaskRunner>& task_runner) {
  std::shared_ptr<AndroidImageGenerator> generator(
      new AndroidImageGenerator(std::move(data)));

  fml::TaskRunner::RunNowOrPostTask(
      task_runner, [generator]() { generator->DecodeImage(); });

  if (generator->IsValidImageData()) {
    return generator;
  }

  return nullptr;
}

FlutterImageGeneratorRegistrationInfo
AndroidImageGenerator::MakeFlutterImageGeneratorRegistrationInfo(
    fml::RefPtr<fml::TaskRunner> task_runner,
    int32_t priority) {
  FlutterImageGeneratorRegistrationInfo registration_info = {};
  registration_info.struct_size = sizeof(FlutterImageGeneratorRegistrationInfo);
  registration_info.priority = priority;
  registration_info.user_data =
      new fml::RefPtr<fml::TaskRunner>(std::move(task_runner));
  registration_info.destruction_callback = [](void* user_data) {
    delete static_cast<fml::RefPtr<fml::TaskRunner>*>(user_data);
  };
  registration_info.create_generator =
      [](const uint8_t* buffer, size_t buffer_size, void* user_data,
         FlutterImageGenerator* generator_out) -> bool {
    if (!buffer || buffer_size == 0 || !user_data || !generator_out) {
      return false;
    }
    auto* runner_ptr = static_cast<fml::RefPtr<fml::TaskRunner>*>(user_data);
    std::vector<uint8_t> bytes(buffer, buffer + buffer_size);
    auto generator =
        AndroidImageGenerator::MakeFromData(std::move(bytes), *runner_ptr);
    if (!generator) {
      return false;
    }

    std::memset(generator_out, 0, sizeof(FlutterImageGenerator));
    generator_out->struct_size = sizeof(FlutterImageGenerator);
    generator_out->user_data =
        new std::shared_ptr<AndroidImageGenerator>(std::move(generator));
    generator_out->destruction_callback = [](void* ud) {
      delete static_cast<std::shared_ptr<AndroidImageGenerator>*>(ud);
    };
    generator_out->get_info = [](void* ud,
                                 FlutterImageGeneratorInfo* info_out) -> bool {
      if (!ud || !info_out) {
        return false;
      }
      auto& gen = *static_cast<std::shared_ptr<AndroidImageGenerator>*>(ud);
      const FlutterImageGeneratorInfo& info = gen->GetInfo();
      if (info.width == 0 || info.height == 0) {
        return false;
      }
      *info_out = info;
      return true;
    };
    generator_out->get_pixels =
        [](void* ud, const FlutterImageGeneratorInfo* info, void* pixels,
           size_t row_bytes, uint32_t frame_index,
           int64_t prior_frame) -> bool {
      if (!ud || !pixels) {
        return false;
      }
      auto& gen = *static_cast<std::shared_ptr<AndroidImageGenerator>*>(ud);
      const FlutterImageGeneratorInfo target_info =
          info ? *info : gen->GetInfo();
      std::optional<uint32_t> prior_opt =
          prior_frame >= 0
              ? std::optional<uint32_t>(static_cast<uint32_t>(prior_frame))
              : std::nullopt;
      return gen->GetPixels(target_info, pixels, row_bytes, frame_index,
                            prior_opt);
    };
    generator_out->get_frame_count = [](void* ud) -> uint32_t {
      if (!ud) {
        return 0;
      }
      auto& gen = *static_cast<std::shared_ptr<AndroidImageGenerator>*>(ud);
      return gen->GetFrameCount();
    };
    generator_out->get_play_count = [](void* ud) -> uint32_t {
      if (!ud) {
        return 0;
      }
      auto& gen = *static_cast<std::shared_ptr<AndroidImageGenerator>*>(ud);
      return gen->GetPlayCount();
    };
    generator_out->get_frame_info =
        [](void* ud, uint32_t frame_index,
           FlutterImageGeneratorFrameInfo* frame_info_out) -> bool {
      if (!ud || !frame_info_out) {
        return false;
      }
      auto& gen = *static_cast<std::shared_ptr<AndroidImageGenerator>*>(ud);
      *frame_info_out = gen->GetFrameInfo(frame_index);
      return true;
    };
    generator_out->get_scaled_dimensions =
        [](void* ud, float desired_scale, uint32_t* scaled_width_out,
           uint32_t* scaled_height_out) -> bool {
      if (!ud || !scaled_width_out || !scaled_height_out) {
        return false;
      }
      auto& gen = *static_cast<std::shared_ptr<AndroidImageGenerator>*>(ud);
      return gen->GetScaledDimensions(desired_scale, scaled_width_out,
                                      scaled_height_out);
    };
    return true;
  };
  return registration_info;
}

std::shared_ptr<AndroidImageGenerator> AndroidImageGenerator::MakeForTesting(
    const FlutterImageGeneratorInfo& header_info,
    std::vector<uint8_t> decoded_data) {
  std::shared_ptr<AndroidImageGenerator> generator(
      new AndroidImageGenerator(std::vector<uint8_t>()));
  generator->image_info_ = header_info;
  generator->header_valid_ = header_info.width > 0 && header_info.height > 0;
  auto owned_data =
      std::make_shared<std::vector<uint8_t>>(std::move(decoded_data));
  generator->software_decoded_data_ = owned_data->data();
  generator->software_decoded_size_ = owned_data->size();
  generator->software_decoded_release_ = [owned_data]() mutable {
    owned_data.reset();
  };
  generator->header_decoded_latch_.Signal();
  generator->fully_decoded_latch_.Signal();
  return generator;
}

void AndroidImageGenerator::NativeImageHeaderCallback(JNIEnv* env,
                                                      jclass jcaller,
                                                      jlong generator_address,
                                                      int width,
                                                      int height) {
  AndroidImageGenerator* generator =
      reinterpret_cast<AndroidImageGenerator*>(generator_address);

  if (width > 0 && height > 0) {
    generator->image_info_ = {
        .width = static_cast<uint32_t>(width),
        .height = static_cast<uint32_t>(height),
        .color_type = kFlutterImageGeneratorColorTypeRGBA8888,
        .alpha_type = kFlutterImageGeneratorAlphaTypePremul,
    };
    generator->header_valid_ = true;
  }
  generator->header_decoded_latch_.Signal();
}

bool AndroidImageGenerator::IsValidImageData() {
  // The generator kicks off an IO task to decode everything, and calls to
  // "GetInfo()" block until either the header has been decoded or decoding has
  // failed, whichever is sooner. The decoder is initialized with header_valid_
  // false and updates the dimensions if the image is able to be decoded.
  GetInfo();
  return header_valid_;
}

}  // namespace flutter
