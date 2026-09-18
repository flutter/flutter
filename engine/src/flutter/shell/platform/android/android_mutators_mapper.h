// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_

#include <cstdint>
#include <memory>
#include <vector>

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if FML_OS_ANDROID
#include <jni.h>
#else
// Host testing stub for JNI types
typedef void* jobject;
typedef void* JNIEnv;
typedef void* jclass;
typedef void* jmethodID;
#endif

namespace flutter {

/// @brief Represents a parsed platform view mutator in host/device portable
/// format.
struct AndroidMutatorRecord {
  FlutterPlatformViewMutationType type =
      kFlutterPlatformViewMutationTypeTransformation;
  std::vector<float> matrix;  // 9 floats for 3x3 2D matrix
  FlutterRect rect = {0.0, 0.0, 0.0, 0.0};
  std::vector<float> radiis;  // 8 floats for corner radii
  float opacity = 1.0f;
  FlutterPathFillType path_fill_type = kFlutterPathFillTypeNonZero;
  std::vector<FlutterPathSegment> path_segments;
};

/// @brief Maps Flutter embedder platform view mutations to Android platform
/// structures
///        and Java FlutterMutatorsStack with Device Pixel Ratio (DPR)
///        normalization.
class AndroidMutatorsMapper {
 public:
  /// Parses embedder mutations into portable AndroidMutatorRecord structs with
  /// DPR normalization.
  static std::vector<AndroidMutatorRecord> ParseMutations(
      size_t mutations_count,
      const FlutterPlatformViewMutation** mutations,
      double device_pixel_ratio = 1.0);

  /// Normalizes a 4x4 or 3x3 FlutterTransformation into an Android 3x3 float
  /// array (9 elements).
  static std::vector<float> TransformToAndroidMatrix(
      const FlutterTransformation& transform,
      double device_pixel_ratio = 1.0);

  /// Converts corner radii from FlutterRoundedRect or FlutterRoundSuperellipse
  /// into an 8-float array.
  static std::vector<float> RadiiToAndroidArray(
      const FlutterSize& upper_left,
      const FlutterSize& upper_right,
      const FlutterSize& lower_right,
      const FlutterSize& lower_left,
      double device_pixel_ratio = 1.0);

#if FML_OS_ANDROID
  /// Initializes and caches JNI class and method IDs for FlutterMutatorsStack
  /// and Path.
  static bool RegisterJNI(JNIEnv* env);

  /// Instantiates and populates a Java
  /// io.flutter.embedding.engine.mutatorsstack.FlutterMutatorsStack object from
  /// raw embedder mutations.
  static jobject CreateJavaMutatorsStack(
      JNIEnv* env,
      size_t mutations_count,
      const FlutterPlatformViewMutation** mutations,
      double device_pixel_ratio = 1.0);

  /// Instantiates and populates a Java
  /// io.flutter.embedding.engine.mutatorsstack.FlutterMutatorsStack object from
  /// parsed AndroidMutatorRecords.
  static jobject CreateJavaMutatorsStackFromRecords(
      JNIEnv* env,
      const std::vector<AndroidMutatorRecord>& records);
#endif

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(AndroidMutatorsMapper);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_MUTATORS_MAPPER_H_
