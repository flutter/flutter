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
#include "flutter/fml/trace_event.h"

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

namespace android {

namespace {
constexpr uint32_t kMutatorsStackMagic = 0x4D555453;  // 'MUTS'
constexpr uint32_t kMutatorsStackVersion = 1;
}  // namespace

// ============================================================================
// AndroidMatrix3x3 Implementation
// ============================================================================

AndroidMatrix3x3 AndroidMatrix3x3::Identity() {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::Identity");
  return AndroidMatrix3x3();
}

AndroidMatrix3x3 AndroidMatrix3x3::MakeTranslation(float tx, float ty) {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::MakeTranslation");
  AndroidMatrix3x3 mat;
  mat.values[2] = tx;
  mat.values[5] = ty;
  return mat;
}

AndroidMatrix3x3 AndroidMatrix3x3::MakeScale(float sx, float sy) {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::MakeScale");
  AndroidMatrix3x3 mat;
  mat.values[0] = sx;
  mat.values[4] = sy;
  return mat;
}

AndroidMatrix3x3 AndroidMatrix3x3::FromFlutterTransformation(
    const FlutterTransformation& transform) {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::FromFlutterTransformation");
  AndroidMatrix3x3 mat;
  mat.values[0] = static_cast<float>(transform.scaleX);
  mat.values[1] = static_cast<float>(transform.skewX);
  mat.values[2] = static_cast<float>(transform.transX);
  mat.values[3] = static_cast<float>(transform.skewY);
  mat.values[4] = static_cast<float>(transform.scaleY);
  mat.values[5] = static_cast<float>(transform.transY);
  mat.values[6] = static_cast<float>(transform.pers0);
  mat.values[7] = static_cast<float>(transform.pers1);
  mat.values[8] = static_cast<float>(transform.pers2);
  return mat;
}

bool AndroidMatrix3x3::IsIdentity() const {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::IsIdentity");
  constexpr float kEpsilon = 1e-5f;
  return std::abs(values[0] - 1.0f) < kEpsilon &&
         std::abs(values[1]) < kEpsilon && std::abs(values[2]) < kEpsilon &&
         std::abs(values[3]) < kEpsilon &&
         std::abs(values[4] - 1.0f) < kEpsilon &&
         std::abs(values[5]) < kEpsilon && std::abs(values[6]) < kEpsilon &&
         std::abs(values[7]) < kEpsilon &&
         std::abs(values[8] - 1.0f) < kEpsilon;
}

AndroidMatrix3x3 AndroidMatrix3x3::Multiply(
    const AndroidMatrix3x3& other) const {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::Multiply");
  AndroidMatrix3x3 result;
  for (int row = 0; row < 3; ++row) {
    for (int col = 0; col < 3; ++col) {
      result.values[row * 3 + col] =
          values[row * 3 + 0] * other.values[0 * 3 + col] +
          values[row * 3 + 1] * other.values[1 * 3 + col] +
          values[row * 3 + 2] * other.values[2 * 3 + col];
    }
  }
  return result;
}

void AndroidMatrix3x3::PreConcat(const AndroidMatrix3x3& other) {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::PreConcat");
  *this = Multiply(other);
}

void AndroidMatrix3x3::PostConcat(const AndroidMatrix3x3& other) {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::PostConcat");
  *this = other.Multiply(*this);
}

void AndroidMatrix3x3::PreScale(float sx, float sy) {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::PreScale");
  PreConcat(MakeScale(sx, sy));
}

void AndroidMatrix3x3::PostTranslate(float tx, float ty) {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::PostTranslate");
  PostConcat(MakeTranslation(tx, ty));
}

bool AndroidMatrix3x3::TransformPoint(float x,
                                      float y,
                                      float* out_x,
                                      float* out_y) const {
  TRACE_EVENT0("flutter", "AndroidMatrix3x3::TransformPoint");
  float xp = values[0] * x + values[1] * y + values[2];
  float yp = values[3] * x + values[4] * y + values[5];
  float wp = values[6] * x + values[7] * y + values[8];

  if (!std::isfinite(wp) || std::abs(wp) < 1e-7f) {
    if (out_x) {
      *out_x = xp;
    }
    if (out_y) {
      *out_y = yp;
    }
    return false;
  }

  if (out_x) {
    *out_x = xp / wp;
  }
  if (out_y) {
    *out_y = yp / wp;
  }
  return true;
}

bool AndroidMatrix3x3::operator==(const AndroidMatrix3x3& other) const {
  constexpr float kEpsilon = 1e-5f;
  for (size_t i = 0; i < 9; ++i) {
    if (!std::isfinite(values[i]) || !std::isfinite(other.values[i])) {
      return false;
    }
    if (std::abs(values[i] - other.values[i]) > kEpsilon) {
      return false;
    }
  }
  return true;
}

// ============================================================================
// AndroidRect & AndroidRoundedRect Implementation
// ============================================================================

AndroidRect AndroidRect::FromFlutterRect(const FlutterRect& rect) {
  TRACE_EVENT0("flutter", "AndroidRect::FromFlutterRect");
  return {static_cast<float>(rect.left), static_cast<float>(rect.top),
          static_cast<float>(rect.right), static_cast<float>(rect.bottom)};
}

bool AndroidRect::operator==(const AndroidRect& other) const {
  if (!std::isfinite(left) || !std::isfinite(other.left) ||
      !std::isfinite(top) || !std::isfinite(other.top) ||
      !std::isfinite(right) || !std::isfinite(other.right) ||
      !std::isfinite(bottom) || !std::isfinite(other.bottom)) {
    return false;
  }
  constexpr float kEpsilon = 1e-5f;
  return std::abs(left - other.left) < kEpsilon &&
         std::abs(top - other.top) < kEpsilon &&
         std::abs(right - other.right) < kEpsilon &&
         std::abs(bottom - other.bottom) < kEpsilon;
}

AndroidRoundedRect AndroidRoundedRect::FromFlutterRoundedRect(
    const FlutterRoundedRect& rrect) {
  TRACE_EVENT0("flutter", "AndroidRoundedRect::FromFlutterRoundedRect");
  AndroidRoundedRect result;
  result.rect = AndroidRect::FromFlutterRect(rrect.rect);
  result.radii[0] = static_cast<float>(rrect.upper_left_corner_radius.width);
  result.radii[1] = static_cast<float>(rrect.upper_left_corner_radius.height);
  result.radii[2] = static_cast<float>(rrect.upper_right_corner_radius.width);
  result.radii[3] = static_cast<float>(rrect.upper_right_corner_radius.height);
  result.radii[4] = static_cast<float>(rrect.lower_right_corner_radius.width);
  result.radii[5] = static_cast<float>(rrect.lower_right_corner_radius.height);
  result.radii[6] = static_cast<float>(rrect.lower_left_corner_radius.width);
  result.radii[7] = static_cast<float>(rrect.lower_left_corner_radius.height);
  return result;
}

bool AndroidRoundedRect::operator==(const AndroidRoundedRect& other) const {
  if (rect != other.rect) {
    return false;
  }
  constexpr float kEpsilon = 1e-5f;
  for (size_t i = 0; i < 8; ++i) {
    if (!std::isfinite(radii[i]) || !std::isfinite(other.radii[i])) {
      return false;
    }
    if (std::abs(radii[i] - other.radii[i]) > kEpsilon) {
      return false;
    }
  }
  return true;
}

// ============================================================================
// AndroidMutator Implementation
// ============================================================================

AndroidMutator AndroidMutator::MakeClipRect(const AndroidRect& r) {
  TRACE_EVENT0("flutter", "AndroidMutator::MakeClipRect");
  AndroidMutator m;
  m.type = AndroidMutatorType::kClipRect;
  m.data = r;
  return m;
}

AndroidMutator AndroidMutator::MakeClipRRect(const AndroidRoundedRect& rr) {
  TRACE_EVENT0("flutter", "AndroidMutator::MakeClipRRect");
  AndroidMutator m;
  m.type = AndroidMutatorType::kClipRRect;
  m.data = rr;
  return m;
}

AndroidMutator AndroidMutator::MakeTransform(const AndroidMatrix3x3& mat) {
  TRACE_EVENT0("flutter", "AndroidMutator::MakeTransform");
  AndroidMutator m;
  m.type = AndroidMutatorType::kTransform;
  m.data = mat;
  return m;
}

AndroidMutator AndroidMutator::MakeOpacity(float op) {
  TRACE_EVENT0("flutter", "AndroidMutator::MakeOpacity");
  AndroidMutator m;
  m.type = AndroidMutatorType::kOpacity;
  m.data = op;
  return m;
}

bool AndroidMutator::operator==(const AndroidMutator& other) const {
  if (type != other.type) {
    return false;
  }
  switch (type) {
    case AndroidMutatorType::kClipRect:
      return GetRect() == other.GetRect();
    case AndroidMutatorType::kClipRRect:
      return GetRRect() == other.GetRRect();
    case AndroidMutatorType::kTransform:
      return GetMatrix() == other.GetMatrix();
    case AndroidMutatorType::kOpacity: {
      float op1 = GetOpacity();
      float op2 = other.GetOpacity();
      if (!std::isfinite(op1) || !std::isfinite(op2)) {
        return false;
      }
      return std::abs(op1 - op2) < 1e-5f;
    }
  }
  return true;
}

// ============================================================================
// AndroidMutatorsStack Implementation
// ============================================================================

AndroidMutatorsStack::AndroidMutatorsStack() {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::AndroidMutatorsStack");
  final_matrix_ = AndroidMatrix3x3::Identity();
  final_opacity_ = 1.0f;
}

AndroidMutatorsStack::~AndroidMutatorsStack() {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::~AndroidMutatorsStack");
}

void AndroidMutatorsStack::PushTransform(const AndroidMatrix3x3& matrix) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::PushTransform(matrix)");
  mutators_.push_back(AndroidMutator::MakeTransform(matrix));
  final_matrix_.PreConcat(matrix);
}

void AndroidMutatorsStack::PushTransform(
    const FlutterTransformation& transform) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::PushTransform(transform)");
  PushTransform(AndroidMatrix3x3::FromFlutterTransformation(transform));
}

void AndroidMutatorsStack::PushClipRect(const AndroidRect& rect) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::PushClipRect(rect)");
  mutators_.push_back(AndroidMutator::MakeClipRect(rect));
  final_clip_rects_.push_back(rect);
}

void AndroidMutatorsStack::PushClipRect(const FlutterRect& rect) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::PushClipRect(flutter_rect)");
  PushClipRect(AndroidRect::FromFlutterRect(rect));
}

void AndroidMutatorsStack::PushClipRRect(const AndroidRoundedRect& rrect) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::PushClipRRect(rrect)");
  mutators_.push_back(AndroidMutator::MakeClipRRect(rrect));
  final_clip_rrects_.push_back(rrect);
}

void AndroidMutatorsStack::PushClipRRect(const FlutterRoundedRect& rrect) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::PushClipRRect(flutter_rrect)");
  PushClipRRect(AndroidRoundedRect::FromFlutterRoundedRect(rrect));
}

void AndroidMutatorsStack::PushOpacity(float opacity) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::PushOpacity");
  float clamped_op =
      std::isfinite(opacity) ? std::clamp(opacity, 0.0f, 1.0f) : 1.0f;
  mutators_.push_back(AndroidMutator::MakeOpacity(clamped_op));
  final_opacity_ = std::clamp(final_opacity_ * clamped_op, 0.0f, 1.0f);
}

void AndroidMutatorsStack::Clear() {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::Clear");
  mutators_.clear();
  final_matrix_ = AndroidMatrix3x3::Identity();
  final_opacity_ = 1.0f;
  final_clip_rects_.clear();
  final_clip_rrects_.clear();
}

AndroidMatrix3x3 AndroidMutatorsStack::GetPlatformViewMatrix(
    float screen_density,
    float left,
    float top) const {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::GetPlatformViewMatrix");
  AndroidMatrix3x3 result = final_matrix_;
  if (std::isfinite(screen_density) && screen_density > 0.0f) {
    result.PreScale(1.0f / screen_density, 1.0f / screen_density);
  }
  result.PostTranslate(-left, -top);
  return result;
}

std::vector<uint8_t> AndroidMutatorsStack::Serialize() const {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::Serialize");
  std::vector<uint8_t> buffer;

  auto write_pod = [&buffer](const auto& val) {
    const uint8_t* ptr = reinterpret_cast<const uint8_t*>(&val);
    buffer.insert(buffer.end(), ptr, ptr + sizeof(val));
  };

  write_pod(kMutatorsStackMagic);
  write_pod(kMutatorsStackVersion);

  uint32_t count = static_cast<uint32_t>(mutators_.size());
  write_pod(count);

  for (const auto& mutator : mutators_) {
    uint32_t type_val = static_cast<uint32_t>(mutator.type);
    write_pod(type_val);
    switch (mutator.type) {
      case AndroidMutatorType::kClipRect:
        write_pod(mutator.GetRect());
        break;
      case AndroidMutatorType::kClipRRect:
        write_pod(mutator.GetRRect());
        break;
      case AndroidMutatorType::kTransform:
        write_pod(mutator.GetMatrix());
        break;
      case AndroidMutatorType::kOpacity:
        write_pod(mutator.GetOpacity());
        break;
    }
  }

  write_pod(final_matrix_);
  write_pod(final_opacity_);

  uint32_t clip_rects_count = static_cast<uint32_t>(final_clip_rects_.size());
  write_pod(clip_rects_count);
  for (const auto& r : final_clip_rects_) {
    write_pod(r);
  }

  uint32_t clip_rrects_count = static_cast<uint32_t>(final_clip_rrects_.size());
  write_pod(clip_rrects_count);
  for (const auto& rr : final_clip_rrects_) {
    write_pod(rr);
  }

  return buffer;
}

std::optional<AndroidMutatorsStack> AndroidMutatorsStack::Deserialize(
    const uint8_t* data,
    size_t size) {
  TRACE_EVENT0("flutter", "AndroidMutatorsStack::Deserialize");
  if (!data || size < sizeof(uint32_t) * 3) {
    return std::nullopt;
  }

  size_t offset = 0;
  auto read_pod = [data, size, &offset](auto& val) -> bool {
    if (offset + sizeof(val) > size) {
      return false;
    }
    std::memcpy(&val, data + offset, sizeof(val));
    offset += sizeof(val);
    return true;
  };

  uint32_t magic = 0;
  if (!read_pod(magic) || magic != kMutatorsStackMagic) {
    return std::nullopt;
  }

  uint32_t version = 0;
  if (!read_pod(version) || version != kMutatorsStackVersion) {
    return std::nullopt;
  }

  uint32_t count = 0;
  if (!read_pod(count)) {
    return std::nullopt;
  }

  constexpr uint32_t kMaxMutators = 1024;
  if (count > kMaxMutators || count > (size - offset) / sizeof(uint32_t)) {
    return std::nullopt;
  }

  AndroidMutatorsStack stack;

  for (uint32_t i = 0; i < count; ++i) {
    uint32_t type_val = 0;
    if (!read_pod(type_val)) {
      return std::nullopt;
    }
    AndroidMutatorType type = static_cast<AndroidMutatorType>(type_val);
    switch (type) {
      case AndroidMutatorType::kClipRect: {
        AndroidRect rect;
        if (!read_pod(rect)) {
          return std::nullopt;
        }
        stack.PushClipRect(rect);
        break;
      }
      case AndroidMutatorType::kClipRRect: {
        AndroidRoundedRect rrect;
        if (!read_pod(rrect)) {
          return std::nullopt;
        }
        stack.PushClipRRect(rrect);
        break;
      }
      case AndroidMutatorType::kTransform: {
        AndroidMatrix3x3 matrix;
        if (!read_pod(matrix)) {
          return std::nullopt;
        }
        stack.PushTransform(matrix);
        break;
      }
      case AndroidMutatorType::kOpacity: {
        float opacity = 1.0f;
        if (!read_pod(opacity)) {
          return std::nullopt;
        }
        stack.PushOpacity(opacity);
        break;
      }
      default:
        return std::nullopt;
    }
  }

  // Validate serialized derived state against reconstructed state
  AndroidMatrix3x3 stream_final_matrix;
  if (!read_pod(stream_final_matrix) ||
      stack.final_matrix_ != stream_final_matrix) {
    return std::nullopt;
  }

  float stream_final_opacity = 0.0f;
  if (!read_pod(stream_final_opacity) || !std::isfinite(stream_final_opacity) ||
      std::abs(stack.final_opacity_ - stream_final_opacity) > 1e-5f) {
    return std::nullopt;
  }

  uint32_t clip_rects_count = 0;
  if (!read_pod(clip_rects_count) || clip_rects_count > kMaxMutators ||
      clip_rects_count != stack.final_clip_rects_.size()) {
    return std::nullopt;
  }
  for (size_t i = 0; i < clip_rects_count; ++i) {
    AndroidRect r;
    if (!read_pod(r) || stack.final_clip_rects_[i] != r) {
      return std::nullopt;
    }
  }

  uint32_t clip_rrects_count = 0;
  if (!read_pod(clip_rrects_count) || clip_rrects_count > kMaxMutators ||
      clip_rrects_count != stack.final_clip_rrects_.size()) {
    return std::nullopt;
  }
  for (size_t i = 0; i < clip_rrects_count; ++i) {
    AndroidRoundedRect rr;
    if (!read_pod(rr) || stack.final_clip_rrects_[i] != rr) {
      return std::nullopt;
    }
  }

  if (offset != size) {
    return std::nullopt;
  }

  return stack;
}

bool AndroidMutatorsStack::operator==(const AndroidMutatorsStack& other) const {
  return mutators_ == other.mutators_ && final_matrix_ == other.final_matrix_ &&
         std::abs(final_opacity_ - other.final_opacity_) < 1e-5f &&
         final_clip_rects_ == other.final_clip_rects_ &&
         final_clip_rrects_ == other.final_clip_rrects_;
}

// ============================================================================
// AndroidMutatorsMapper Implementation
// ============================================================================

AndroidMutatorsMapper::AndroidMutatorsMapper() {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::AndroidMutatorsMapper");
}

AndroidMutatorsMapper::~AndroidMutatorsMapper() {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::~AndroidMutatorsMapper");
}

std::optional<AndroidMutator> AndroidMutatorsMapper::MapMutation(
    const FlutterPlatformViewMutation& mutation) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::MapMutation");
  switch (mutation.type) {
    case kFlutterPlatformViewMutationTypeOpacity: {
      float op = static_cast<float>(mutation.opacity);
      float clamped_op = std::isfinite(op) ? std::clamp(op, 0.0f, 1.0f) : 1.0f;
      return AndroidMutator::MakeOpacity(clamped_op);
    }
    case kFlutterPlatformViewMutationTypeClipRect:
      return AndroidMutator::MakeClipRect(
          AndroidRect::FromFlutterRect(mutation.clip_rect));
    case kFlutterPlatformViewMutationTypeClipRoundedRect:
      return AndroidMutator::MakeClipRRect(
          AndroidRoundedRect::FromFlutterRoundedRect(
              mutation.clip_rounded_rect));
    case kFlutterPlatformViewMutationTypeTransformation:
      return AndroidMutator::MakeTransform(
          AndroidMatrix3x3::FromFlutterTransformation(mutation.transformation));
    default:
      break;
  }
  return std::nullopt;
}

AndroidMutatorsStack AndroidMutatorsMapper::MapMutations(
    const FlutterPlatformViewMutation** mutations,
    size_t count) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::MapMutations");
  AndroidMutatorsStack stack;
  if (!mutations || count == 0) {
    return stack;
  }

  for (size_t i = 0; i < count; ++i) {
    const FlutterPlatformViewMutation* mutation = mutations[i];
    if (!mutation) {
      continue;
    }
    auto mapped = MapMutation(*mutation);
    if (!mapped.has_value()) {
      continue;
    }
    switch (mapped->type) {
      case AndroidMutatorType::kOpacity:
        stack.PushOpacity(mapped->GetOpacity());
        break;
      case AndroidMutatorType::kClipRect:
        stack.PushClipRect(mapped->GetRect());
        break;
      case AndroidMutatorType::kClipRRect:
        stack.PushClipRRect(mapped->GetRRect());
        break;
      case AndroidMutatorType::kTransform:
        stack.PushTransform(mapped->GetMatrix());
        break;
    }
  }

  return stack;
}

AndroidMutatorsStack AndroidMutatorsMapper::MapPlatformView(
    const FlutterPlatformView& platform_view) {
  TRACE_EVENT0("flutter", "AndroidMutatorsMapper::MapPlatformView");
  if (platform_view.struct_size < sizeof(FlutterPlatformView)) {
    return AndroidMutatorsStack();
  }
  return MapMutations(platform_view.mutations, platform_view.mutations_count);
}

}  // namespace android

}  // namespace flutter
