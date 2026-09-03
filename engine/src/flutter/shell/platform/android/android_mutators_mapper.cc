// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_mutators_mapper.h"

#include <algorithm>
#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
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

  if (std::abs(wp) < 1e-7f) {
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
  constexpr float kEpsilon = 1e-5f;
  if (rect != other.rect) {
    return false;
  }
  for (size_t i = 0; i < 8; ++i) {
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
  m.rect = r;
  return m;
}

AndroidMutator AndroidMutator::MakeClipRRect(const AndroidRoundedRect& rr) {
  TRACE_EVENT0("flutter", "AndroidMutator::MakeClipRRect");
  AndroidMutator m;
  m.type = AndroidMutatorType::kClipRRect;
  m.rrect = rr;
  return m;
}

AndroidMutator AndroidMutator::MakeTransform(const AndroidMatrix3x3& mat) {
  TRACE_EVENT0("flutter", "AndroidMutator::MakeTransform");
  AndroidMutator m;
  m.type = AndroidMutatorType::kTransform;
  m.matrix = mat;
  return m;
}

AndroidMutator AndroidMutator::MakeOpacity(float op) {
  TRACE_EVENT0("flutter", "AndroidMutator::MakeOpacity");
  AndroidMutator m;
  m.type = AndroidMutatorType::kOpacity;
  m.opacity = op;
  return m;
}

bool AndroidMutator::operator==(const AndroidMutator& other) const {
  if (type != other.type) {
    return false;
  }
  switch (type) {
    case AndroidMutatorType::kClipRect:
      return rect == other.rect;
    case AndroidMutatorType::kClipRRect:
      return rrect == other.rrect;
    case AndroidMutatorType::kTransform:
      return matrix == other.matrix;
    case AndroidMutatorType::kOpacity:
      return std::abs(opacity - other.opacity) < 1e-5f;
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
  mutators_.push_back(AndroidMutator::MakeOpacity(opacity));
  final_opacity_ = std::clamp(final_opacity_ * opacity, 0.0f, 1.0f);
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
  if (screen_density > 0.0f) {
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
        write_pod(mutator.rect);
        break;
      case AndroidMutatorType::kClipRRect:
        write_pod(mutator.rrect);
        break;
      case AndroidMutatorType::kTransform:
        write_pod(mutator.matrix);
        break;
      case AndroidMutatorType::kOpacity:
        write_pod(mutator.opacity);
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

  AndroidMutatorsStack stack;
  stack.mutators_.reserve(count);

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
        stack.mutators_.push_back(AndroidMutator::MakeClipRect(rect));
        break;
      }
      case AndroidMutatorType::kClipRRect: {
        AndroidRoundedRect rrect;
        if (!read_pod(rrect)) {
          return std::nullopt;
        }
        stack.mutators_.push_back(AndroidMutator::MakeClipRRect(rrect));
        break;
      }
      case AndroidMutatorType::kTransform: {
        AndroidMatrix3x3 matrix;
        if (!read_pod(matrix)) {
          return std::nullopt;
        }
        stack.mutators_.push_back(AndroidMutator::MakeTransform(matrix));
        break;
      }
      case AndroidMutatorType::kOpacity: {
        float opacity = 1.0f;
        if (!read_pod(opacity)) {
          return std::nullopt;
        }
        stack.mutators_.push_back(AndroidMutator::MakeOpacity(opacity));
        break;
      }
      default:
        return std::nullopt;
    }
  }

  if (!read_pod(stack.final_matrix_)) {
    return std::nullopt;
  }
  if (!read_pod(stack.final_opacity_)) {
    return std::nullopt;
  }

  uint32_t clip_rects_count = 0;
  if (!read_pod(clip_rects_count)) {
    return std::nullopt;
  }
  stack.final_clip_rects_.resize(clip_rects_count);
  for (uint32_t i = 0; i < clip_rects_count; ++i) {
    if (!read_pod(stack.final_clip_rects_[i])) {
      return std::nullopt;
    }
  }

  uint32_t clip_rrects_count = 0;
  if (!read_pod(clip_rrects_count)) {
    return std::nullopt;
  }
  stack.final_clip_rrects_.resize(clip_rrects_count);
  for (uint32_t i = 0; i < clip_rrects_count; ++i) {
    if (!read_pod(stack.final_clip_rrects_[i])) {
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
    case kFlutterPlatformViewMutationTypeOpacity:
      return AndroidMutator::MakeOpacity(static_cast<float>(mutation.opacity));
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
    switch (mutation->type) {
      case kFlutterPlatformViewMutationTypeOpacity:
        stack.PushOpacity(static_cast<float>(mutation->opacity));
        break;
      case kFlutterPlatformViewMutationTypeClipRect:
        stack.PushClipRect(mutation->clip_rect);
        break;
      case kFlutterPlatformViewMutationTypeClipRoundedRect:
        stack.PushClipRRect(mutation->clip_rounded_rect);
        break;
      case kFlutterPlatformViewMutationTypeTransformation:
        stack.PushTransform(mutation->transformation);
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
