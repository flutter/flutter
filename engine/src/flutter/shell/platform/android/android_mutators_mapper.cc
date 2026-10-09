// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_mutators_mapper.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <mutex>
#include <utility>

#include "flutter/fml/logging.h"

#if FML_OS_ANDROID
#include <android/log.h>
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#endif

namespace flutter {

#if FML_OS_ANDROID
namespace {

static std::mutex g_jni_mutex;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_mutators_stack_class = nullptr;
static jmethodID g_mutators_stack_init_method = nullptr;
static jmethodID g_mutators_stack_push_transform_method = nullptr;
static jmethodID g_mutators_stack_push_cliprect_method = nullptr;
static jmethodID g_mutators_stack_push_cliprrect_method = nullptr;
static jmethodID g_mutators_stack_push_opacity_method = nullptr;
static jmethodID g_mutators_stack_push_clippath_method = nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_path_class = nullptr;
static jmethodID g_path_init_method = nullptr;
static jmethodID g_path_set_fill_type_method = nullptr;
static jmethodID g_path_move_to_method = nullptr;
static jmethodID g_path_line_to_method = nullptr;
static jmethodID g_path_quad_to_method = nullptr;
static jmethodID g_path_cubic_to_method = nullptr;
static jmethodID g_path_close_method = nullptr;

static fml::jni::ScopedJavaGlobalRef<jobject>* g_fill_type_even_odd = nullptr;

}  // namespace

bool AndroidMutatorsMapper::RegisterJNI(JNIEnv* env) {
  if (env == nullptr) {
    return false;
  }

  std::lock_guard<std::mutex> lock(g_jni_mutex);

  if (g_mutators_stack_class == nullptr) {
    jclass local_stack_class = env->FindClass(
        "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
    if (local_stack_class == nullptr) {
      env->ExceptionClear();
      FML_LOG(ERROR) << "Could not locate FlutterMutatorsStack class";
      return false;
    }
    g_mutators_stack_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, local_stack_class);
    env->DeleteLocalRef(local_stack_class);

    g_mutators_stack_init_method =
        env->GetMethodID(g_mutators_stack_class->obj(), "<init>", "()V");
    g_mutators_stack_push_transform_method = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushTransform", "([F)V");
    g_mutators_stack_push_cliprect_method = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushClipRect", "(FFFF)V");
    g_mutators_stack_push_cliprrect_method = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushClipRRect", "(FFFF[F)V");
    g_mutators_stack_push_opacity_method =
        env->GetMethodID(g_mutators_stack_class->obj(), "pushOpacity", "(F)V");
    g_mutators_stack_push_clippath_method =
        env->GetMethodID(g_mutators_stack_class->obj(), "pushClipPath",
                         "(Landroid/graphics/Path;)V");

    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      FML_LOG(ERROR) << "Failed to resolve FlutterMutatorsStack methods";
      return false;
    }
  }

  if (g_path_class == nullptr) {
    jclass local_path_class = env->FindClass("android/graphics/Path");
    if (local_path_class == nullptr) {
      env->ExceptionClear();
      FML_LOG(ERROR) << "Could not locate android.graphics.Path class";
      return false;
    }
    g_path_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, local_path_class);
    env->DeleteLocalRef(local_path_class);

    g_path_init_method = env->GetMethodID(g_path_class->obj(), "<init>", "()V");
    g_path_set_fill_type_method =
        env->GetMethodID(g_path_class->obj(), "setFillType",
                         "(Landroid/graphics/Path$FillType;)V");
    g_path_move_to_method =
        env->GetMethodID(g_path_class->obj(), "moveTo", "(FF)V");
    g_path_line_to_method =
        env->GetMethodID(g_path_class->obj(), "lineTo", "(FF)V");
    g_path_quad_to_method =
        env->GetMethodID(g_path_class->obj(), "quadTo", "(FFFF)V");
    g_path_cubic_to_method =
        env->GetMethodID(g_path_class->obj(), "cubicTo", "(FFFFFF)V");
    g_path_close_method = env->GetMethodID(g_path_class->obj(), "close", "()V");

    jclass fill_type_class = env->FindClass("android/graphics/Path$FillType");
    if (fill_type_class != nullptr) {
      jfieldID even_odd_field = env->GetStaticFieldID(
          fill_type_class, "EVEN_ODD", "Landroid/graphics/Path$FillType;");
      if (even_odd_field != nullptr) {
        jobject even_odd_obj =
            env->GetStaticObjectField(fill_type_class, even_odd_field);
        if (even_odd_obj != nullptr) {
          g_fill_type_even_odd =
              new fml::jni::ScopedJavaGlobalRef<jobject>(env, even_odd_obj);
          env->DeleteLocalRef(even_odd_obj);
        }
      }
      env->DeleteLocalRef(fill_type_class);
    }

    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      FML_LOG(ERROR) << "Failed to resolve android.graphics.Path methods";
      return false;
    }
  }

  return true;
}

jobject AndroidMutatorsMapper::CreateJavaMutatorsStack(
    JNIEnv* env,
    size_t mutations_count,
    const FlutterPlatformViewMutation** mutations,
    double device_pixel_ratio) {
  std::vector<AndroidMutatorRecord> records =
      ParseMutations(mutations_count, mutations, device_pixel_ratio);
  return CreateJavaMutatorsStackFromRecords(env, records);
}

jobject AndroidMutatorsMapper::CreateJavaMutatorsStackFromRecords(
    JNIEnv* env,
    const std::vector<AndroidMutatorRecord>& records) {
  if (env == nullptr) {
    return nullptr;
  }

  if (!RegisterJNI(env)) {
    return nullptr;
  }

  jobject java_stack = env->NewObject(g_mutators_stack_class->obj(),
                                      g_mutators_stack_init_method);
  if (java_stack == nullptr) {
    return nullptr;
  }

  for (const auto& record : records) {
    switch (record.type) {
      case kFlutterPlatformViewMutationTypeTransformation: {
        if (record.matrix.size() == 9 &&
            g_mutators_stack_push_transform_method != nullptr) {
          fml::jni::ScopedJavaLocalRef<jfloatArray> matrix_array(
              env, env->NewFloatArray(9));
          env->SetFloatArrayRegion(matrix_array.obj(), 0, 9,
                                   record.matrix.data());
          env->CallVoidMethod(java_stack,
                              g_mutators_stack_push_transform_method,
                              matrix_array.obj());
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRect: {
        if (g_mutators_stack_push_cliprect_method != nullptr) {
          env->CallVoidMethod(java_stack, g_mutators_stack_push_cliprect_method,
                              static_cast<jfloat>(record.rect.left),
                              static_cast<jfloat>(record.rect.top),
                              static_cast<jfloat>(record.rect.right),
                              static_cast<jfloat>(record.rect.bottom));
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundedRect:
      case kFlutterPlatformViewMutationTypeClipRoundSuperellipse: {
        if (record.radiis.size() == 8 &&
            g_mutators_stack_push_cliprrect_method != nullptr) {
          fml::jni::ScopedJavaLocalRef<jfloatArray> radiis_array(
              env, env->NewFloatArray(8));
          env->SetFloatArrayRegion(radiis_array.obj(), 0, 8,
                                   record.radiis.data());
          env->CallVoidMethod(
              java_stack, g_mutators_stack_push_cliprrect_method,
              static_cast<jfloat>(record.rect.left),
              static_cast<jfloat>(record.rect.top),
              static_cast<jfloat>(record.rect.right),
              static_cast<jfloat>(record.rect.bottom), radiis_array.obj());
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeClipPath: {
        if (g_path_class != nullptr && g_path_init_method != nullptr &&
            g_mutators_stack_push_clippath_method != nullptr) {
          jobject java_path =
              env->NewObject(g_path_class->obj(), g_path_init_method);
          if (java_path != nullptr) {
            if (record.path_fill_type == kFlutterPathFillTypeEvenOdd &&
                g_path_set_fill_type_method != nullptr &&
                g_fill_type_even_odd != nullptr &&
                g_fill_type_even_odd->obj() != nullptr) {
              env->CallVoidMethod(java_path, g_path_set_fill_type_method,
                                  g_fill_type_even_odd->obj());
            }

            for (const auto& seg : record.path_segments) {
              switch (seg.verb) {
                case kFlutterPathVerbMove:
                  if (g_path_move_to_method != nullptr) {
                    env->CallVoidMethod(java_path, g_path_move_to_method,
                                        static_cast<jfloat>(seg.points[0].x),
                                        static_cast<jfloat>(seg.points[0].y));
                  }
                  break;
                case kFlutterPathVerbLine:
                  if (g_path_line_to_method != nullptr) {
                    env->CallVoidMethod(java_path, g_path_line_to_method,
                                        static_cast<jfloat>(seg.points[0].x),
                                        static_cast<jfloat>(seg.points[0].y));
                  }
                  break;
                case kFlutterPathVerbQuad:
                case kFlutterPathVerbConic:
                  if (g_path_quad_to_method != nullptr) {
                    env->CallVoidMethod(java_path, g_path_quad_to_method,
                                        static_cast<jfloat>(seg.points[0].x),
                                        static_cast<jfloat>(seg.points[0].y),
                                        static_cast<jfloat>(seg.points[1].x),
                                        static_cast<jfloat>(seg.points[1].y));
                  }
                  break;
                case kFlutterPathVerbCubic:
                  if (g_path_cubic_to_method != nullptr) {
                    env->CallVoidMethod(java_path, g_path_cubic_to_method,
                                        static_cast<jfloat>(seg.points[0].x),
                                        static_cast<jfloat>(seg.points[0].y),
                                        static_cast<jfloat>(seg.points[1].x),
                                        static_cast<jfloat>(seg.points[1].y),
                                        static_cast<jfloat>(seg.points[2].x),
                                        static_cast<jfloat>(seg.points[2].y));
                  }
                  break;
                case kFlutterPathVerbClose:
                  if (g_path_close_method != nullptr) {
                    env->CallVoidMethod(java_path, g_path_close_method);
                  }
                  break;
              }
            }
            env->CallVoidMethod(
                java_stack, g_mutators_stack_push_clippath_method, java_path);
            env->DeleteLocalRef(java_path);
          }
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeOpacity: {
        if (g_mutators_stack_push_opacity_method != nullptr) {
          env->CallVoidMethod(java_stack, g_mutators_stack_push_opacity_method,
                              static_cast<jfloat>(record.opacity));
        }
        break;
      }
    }
  }

  return java_stack;
}
#endif  // FML_OS_ANDROID

std::vector<float> AndroidMutatorsMapper::TransformToAndroidMatrix(
    const FlutterTransformation& transform,
    double device_pixel_ratio) {
  float dpr = (!std::isfinite(device_pixel_ratio) || device_pixel_ratio <= 0.0)
                  ? 1.0f
                  : static_cast<float>(device_pixel_ratio);
  return {
      static_cast<float>(transform.scaleX),
      static_cast<float>(transform.skewX),
      static_cast<float>(transform.transX * dpr),
      static_cast<float>(transform.skewY),
      static_cast<float>(transform.scaleY),
      static_cast<float>(transform.transY * dpr),
      static_cast<float>(transform.pers0),
      static_cast<float>(transform.pers1),
      static_cast<float>(transform.pers2),
  };
}

std::vector<float> AndroidMutatorsMapper::RadiiToAndroidArray(
    const FlutterSize& upper_left,
    const FlutterSize& upper_right,
    const FlutterSize& lower_right,
    const FlutterSize& lower_left,
    double device_pixel_ratio) {
  float dpr = (!std::isfinite(device_pixel_ratio) || device_pixel_ratio <= 0.0)
                  ? 1.0f
                  : static_cast<float>(device_pixel_ratio);
  return {
      static_cast<float>(upper_left.width * dpr),
      static_cast<float>(upper_left.height * dpr),
      static_cast<float>(upper_right.width * dpr),
      static_cast<float>(upper_right.height * dpr),
      static_cast<float>(lower_right.width * dpr),
      static_cast<float>(lower_right.height * dpr),
      static_cast<float>(lower_left.width * dpr),
      static_cast<float>(lower_left.height * dpr),
  };
}

std::vector<AndroidMutatorRecord> AndroidMutatorsMapper::ParseMutations(
    size_t mutations_count,
    const FlutterPlatformViewMutation** mutations,
    double device_pixel_ratio) {
  std::vector<AndroidMutatorRecord> records;
  if (mutations == nullptr || mutations_count == 0) {
    return records;
  }

  float dpr = (!std::isfinite(device_pixel_ratio) || device_pixel_ratio <= 0.0)
                  ? 1.0f
                  : static_cast<float>(device_pixel_ratio);
  records.reserve(mutations_count);

  for (size_t i = 0; i < mutations_count; ++i) {
    const FlutterPlatformViewMutation* mutation = mutations[i];
    if (mutation == nullptr) {
      continue;
    }

    AndroidMutatorRecord record;
    record.type = mutation->type;

    switch (mutation->type) {
      case kFlutterPlatformViewMutationTypeTransformation: {
        record.matrix = TransformToAndroidMatrix(mutation->transformation,
                                                 device_pixel_ratio);
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRect: {
        record.rect.left = mutation->clip_rect.left * dpr;
        record.rect.top = mutation->clip_rect.top * dpr;
        record.rect.right = mutation->clip_rect.right * dpr;
        record.rect.bottom = mutation->clip_rect.bottom * dpr;
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundedRect: {
        record.rect.left = mutation->clip_rounded_rect.rect.left * dpr;
        record.rect.top = mutation->clip_rounded_rect.rect.top * dpr;
        record.rect.right = mutation->clip_rounded_rect.rect.right * dpr;
        record.rect.bottom = mutation->clip_rounded_rect.rect.bottom * dpr;
        record.radiis = RadiiToAndroidArray(
            mutation->clip_rounded_rect.upper_left_corner_radius,
            mutation->clip_rounded_rect.upper_right_corner_radius,
            mutation->clip_rounded_rect.lower_right_corner_radius,
            mutation->clip_rounded_rect.lower_left_corner_radius,
            device_pixel_ratio);
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundSuperellipse: {
        record.rect.left = mutation->clip_round_superellipse.rect.left * dpr;
        record.rect.top = mutation->clip_round_superellipse.rect.top * dpr;
        record.rect.right = mutation->clip_round_superellipse.rect.right * dpr;
        record.rect.bottom =
            mutation->clip_round_superellipse.rect.bottom * dpr;
        record.radiis = RadiiToAndroidArray(
            mutation->clip_round_superellipse.upper_left_corner_radius,
            mutation->clip_round_superellipse.upper_right_corner_radius,
            mutation->clip_round_superellipse.lower_right_corner_radius,
            mutation->clip_round_superellipse.lower_left_corner_radius,
            device_pixel_ratio);
        break;
      }
      case kFlutterPlatformViewMutationTypeClipPath: {
        if (mutation->clip_path.struct_size >= sizeof(FlutterPath)) {
          record.path_fill_type = mutation->clip_path.fill_type;
          if (mutation->clip_path.segments != nullptr &&
              mutation->clip_path.segments_count > 0) {
            record.path_segments.reserve(mutation->clip_path.segments_count);
            for (size_t s = 0; s < mutation->clip_path.segments_count; ++s) {
              FlutterPathSegment seg = mutation->clip_path.segments[s];
              for (int p = 0; p < 3; ++p) {
                seg.points[p].x *= dpr;
                seg.points[p].y *= dpr;
              }
              record.path_segments.push_back(seg);
            }
          }
        }
        break;
      }
      case kFlutterPlatformViewMutationTypeOpacity: {
        record.opacity =
            (!std::isfinite(mutation->opacity))
                ? 1.0f
                : static_cast<float>(std::clamp(mutation->opacity, 0.0, 1.0));
        break;
      }
    }
    records.push_back(std::move(record));
  }

  return records;
}

}  // namespace flutter
