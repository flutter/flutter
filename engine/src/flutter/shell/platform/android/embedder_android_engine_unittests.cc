// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iterator>
#include <memory>
#include <tuple>
#include <vector>

#if FML_OS_ANDROID
#include <android/api-level.h>
#endif

#include "flutter/shell/platform/android/embedder_android_engine.h"
#include "flutter/shell/platform/android/flutter_main.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(EmbedderAndroidEngineTest, LifecycleAndInitialState) {
  auto jni = std::make_shared<JNIMock>();
  EmbedderAndroidEngine engine(Settings(), jni,
                               AndroidRenderingAPI::kImpellerOpenGLES);

  // Once subsystems (task runners, surface manager, proc table) are
  // initialized, the engine is valid and ready to run.
  EXPECT_TRUE(engine.IsValid());
  EXPECT_EQ(engine.GetRenderingAPI(), AndroidRenderingAPI::kImpellerOpenGLES);
  EXPECT_NE(engine.GetSurfaceManager(), nullptr);
  EXPECT_NE(engine.GetCompositor(), nullptr);
  EXPECT_NE(engine.GetAndroidTaskRunners(), nullptr);
  EXPECT_FALSE(engine.IsSurfaceControlEnabled());
}

TEST(EmbedderAndroidEngineTest, SurfaceControlEnablement) {
  auto jni = std::make_shared<JNIMock>();

  // Disabled by default when surface control is not requested.
  EmbedderAndroidEngine engine_default(Settings(), jni,
                                       AndroidRenderingAPI::kImpellerVulkan);
  EXPECT_FALSE(engine_default.IsSurfaceControlEnabled());

  // Explicit override enables.
  engine_default.SetSurfaceControlEnabled(true);
  EXPECT_TRUE(engine_default.IsSurfaceControlEnabled());

  // Enabled via settings when criteria (surface control + impeller + vulkan)
  // are satisfied.
  Settings settings;
  settings.enable_surface_control = true;
  settings.enable_impeller = true;
  EmbedderAndroidEngine engine_hcpp(settings, jni,
                                    AndroidRenderingAPI::kImpellerVulkan);
#if FML_OS_ANDROID
  if (android_get_device_api_level() >= 34) {
    EXPECT_TRUE(engine_hcpp.IsSurfaceControlEnabled());
  } else {
    EXPECT_FALSE(engine_hcpp.IsSurfaceControlEnabled());
  }
#else
  EXPECT_FALSE(engine_hcpp.IsSurfaceControlEnabled());
#endif
}

TEST(EmbedderAndroidEngineTest, SurfaceLifecycleTransitions) {
  auto jni = std::make_shared<JNIMock>();
  EmbedderAndroidEngine engine(Settings(), jni, AndroidRenderingAPI::kSoftware);

  engine.NotifySurfaceCreated(nullptr, /*is_fake_window=*/true);
  engine.NotifySurfaceChanged(300, 400);
  engine.NotifySurfaceDestroyed();

  engine.NotifySurfaceCreated(nullptr, /*is_fake_window=*/true);
  engine.NotifySurfaceWindowChanged(nullptr, /*is_fake_window=*/true);
  engine.NotifySurfaceChanged(500, 600);
  engine.NotifySurfaceDestroyed();
}

TEST(EmbedderAndroidEngineTest, PointerConversionHelpers) {
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(0), kCancel);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(1), kAdd);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(2), kRemove);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(3), kHover);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(4), kDown);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(5), kMove);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(6), kUp);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(7), kPanZoomStart);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(8), kPanZoomUpdate);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(9), kPanZoomEnd);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerPhase(999), kCancel);

  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerDeviceKind(0),
            kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerDeviceKind(1),
            kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerDeviceKind(2),
            kFlutterPointerDeviceKindStylus);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerDeviceKind(3),
            kFlutterPointerDeviceKindInvertedStylus);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerDeviceKind(4),
            kFlutterPointerDeviceKindTrackpad);

  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerSignalKind(0),
            kFlutterPointerSignalKindNone);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerSignalKind(1),
            kFlutterPointerSignalKindScroll);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerSignalKind(2),
            kFlutterPointerSignalKindScrollInertiaCancel);
  EXPECT_EQ(EmbedderAndroidEngine::ToFlutterPointerSignalKind(3),
            kFlutterPointerSignalKindScale);
}

TEST(EmbedderAndroidEngineTest, UnpackPointerDataPacket) {
  EXPECT_TRUE(
      EmbedderAndroidEngine::UnpackPointerDataPacket(nullptr, 0).empty());
  std::vector<uint8_t> short_buffer(100, 0);
  EXPECT_TRUE(
      EmbedderAndroidEngine::UnpackPointerDataPacket(short_buffer.data(), 100)
          .empty());

  constexpr size_t kEntryBytes = 36 * 8;
  std::vector<uint8_t> buffer(kEntryBytes, 0);
  int64_t* int_fields = reinterpret_cast<int64_t*>(buffer.data());
  double* double_fields = reinterpret_cast<double*>(buffer.data());
  int_fields[1] = 123456;
  int_fields[2] = 4;  // kDown
  int_fields[3] = 0;  // kTouch
  int_fields[5] = 1;  // device
  double_fields[7] = 10.0;
  double_fields[8] = 20.0;

  auto events = EmbedderAndroidEngine::UnpackPointerDataPacket(buffer.data(),
                                                               buffer.size());
  ASSERT_EQ(events.size(), 1u);
  EXPECT_EQ(events[0].timestamp, 123456u);
  EXPECT_EQ(events[0].phase, kDown);
  EXPECT_EQ(events[0].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_DOUBLE_EQ(events[0].x, 10.0);
  EXPECT_DOUBLE_EQ(events[0].y, 20.0);
}

TEST(EmbedderAndroidEngineTest, SerializeSemanticsUpdate) {
  FlutterSemanticsFlags flags2 = {};
  flags2.is_button = true;
  flags2.is_enabled = kFlutterTristateTrue;

  FlutterSemanticsNode2 node = {};
  node.struct_size = sizeof(FlutterSemanticsNode2);
  node.id = 7;
  node.flags2 = &flags2;
  node.label = "Submit";

  FlutterSemanticsNode2* nodes[] = {&node};
  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);
  update.node_count = 1;
  update.nodes = nodes;

  std::vector<uint8_t> buffer;
  std::vector<std::string> strings;
  std::vector<std::vector<uint8_t>> string_attribute_args;
  std::vector<uint8_t> actions_buffer;
  std::vector<std::string> action_strings;

  EmbedderAndroidEngine::SerializeSemanticsUpdate(
      &update, buffer, strings, string_attribute_args, actions_buffer,
      action_strings);

  EXPECT_EQ(buffer.size(), 73u * sizeof(int32_t));
  ASSERT_EQ(strings.size(), 1u);
  EXPECT_EQ(strings[0], "Submit");
}

TEST(EmbedderAndroidEngineTest, ToMutatorsStackHandlesEveryMutationType) {
  FlutterPlatformViewMutation transform = {};
  transform.type = kFlutterPlatformViewMutationTypeTransformation;
  transform.transformation = {1.0, 0.0, 5.0, 0.0, 1.0, 6.0, 0.0, 0.0, 1.0};

  FlutterPlatformViewMutation clip_rect = {};
  clip_rect.type = kFlutterPlatformViewMutationTypeClipRect;
  clip_rect.clip_rect = {1.0, 2.0, 3.0, 4.0};

  FlutterPlatformViewMutation clip_rrect = {};
  clip_rrect.type = kFlutterPlatformViewMutationTypeClipRoundedRect;
  clip_rrect.clip_rounded_rect.rect = {0.0, 0.0, 20.0, 20.0};
  clip_rrect.clip_rounded_rect.upper_left_corner_radius = {2.0, 2.0};
  clip_rrect.clip_rounded_rect.upper_right_corner_radius = {2.0, 2.0};
  clip_rrect.clip_rounded_rect.lower_right_corner_radius = {2.0, 2.0};
  clip_rrect.clip_rounded_rect.lower_left_corner_radius = {2.0, 2.0};

  FlutterPlatformViewMutation opacity = {};
  opacity.type = kFlutterPlatformViewMutationTypeOpacity;
  opacity.opacity = 1.0;

  FlutterPlatformViewMutation clip_rse = {};
  clip_rse.type = kFlutterPlatformViewMutationTypeClipRoundSuperellipse;
  clip_rse.clip_round_superellipse.rect = {0.0, 0.0, 30.0, 40.0};
  clip_rse.clip_round_superellipse.upper_left_corner_radius = {3.0, 3.0};
  clip_rse.clip_round_superellipse.upper_right_corner_radius = {3.0, 3.0};
  clip_rse.clip_round_superellipse.lower_right_corner_radius = {3.0, 3.0};
  clip_rse.clip_round_superellipse.lower_left_corner_radius = {3.0, 3.0};

  FlutterPathSegment segments[] = {
      {kFlutterPathVerbMove, {{0.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
      {kFlutterPathVerbLine, {{10.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
      {kFlutterPathVerbLine, {{10.0, 10.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
      {kFlutterPathVerbClose, {{0.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
  };
  FlutterPlatformViewMutation clip_path = {};
  clip_path.type = kFlutterPlatformViewMutationTypeClipPath;
  clip_path.clip_path.struct_size = sizeof(FlutterPath);
  clip_path.clip_path.fill_type = kFlutterPathFillTypeNonZero;
  clip_path.clip_path.segments_count = std::size(segments);
  clip_path.clip_path.segments = segments;

  const FlutterPlatformViewMutation* mutations[] = {
      &transform, &clip_rect, &clip_rrect, &opacity, &clip_rse, &clip_path};

  MutatorsStack stack =
      EmbedderAndroidEngine::ToMutatorsStack(std::size(mutations), mutations);

  std::vector<MutatorType> types;
  for (auto it = stack.Begin(); it != stack.End(); ++it) {
    types.push_back((*it)->GetType());
  }

  // Every mutation type must survive the translation. A superellipse or path
  // clip that is dropped here leaves the platform view unclipped on screen.
  EXPECT_THAT(types, ::testing::ElementsAre(
                         MutatorType::kTransform, MutatorType::kClipRect,
                         MutatorType::kClipRRect, MutatorType::kOpacity,
                         MutatorType::kClipRSE, MutatorType::kClipPath));
}

TEST(EmbedderAndroidEngineTest, ToMutatorsStackSkipsNullEntries) {
  FlutterPlatformViewMutation opacity = {};
  opacity.type = kFlutterPlatformViewMutationTypeOpacity;
  opacity.opacity = 0.5;

  const FlutterPlatformViewMutation* mutations[] = {nullptr, &opacity};

  MutatorsStack stack =
      EmbedderAndroidEngine::ToMutatorsStack(std::size(mutations), mutations);
  EXPECT_EQ(stack.stack_count(), 1u);
  EXPECT_EQ((*stack.Begin())->GetType(), MutatorType::kOpacity);

  EXPECT_TRUE(EmbedderAndroidEngine::ToMutatorsStack(2, nullptr).is_empty());
}

TEST(EmbedderAndroidEngineTest, ToDlPathRebuildsSegmentsAndFillType) {
  FlutterPathSegment segments[] = {
      {kFlutterPathVerbMove, {{0.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
      {kFlutterPathVerbLine, {{10.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
      {kFlutterPathVerbLine, {{10.0, 10.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
      {kFlutterPathVerbLine, {{0.0, 10.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
      {kFlutterPathVerbClose, {{0.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}}, 0.0},
  };

  FlutterPath path = {};
  path.struct_size = sizeof(FlutterPath);
  path.fill_type = kFlutterPathFillTypeEvenOdd;
  path.segments_count = std::size(segments);
  path.segments = segments;

  DlPath dl_path = EmbedderAndroidEngine::ToDlPath(path);
  EXPECT_EQ(dl_path.GetFillType(), DlPathFillType::kOdd);
  EXPECT_EQ(dl_path.GetBounds(), DlRect::MakeLTRB(0.0f, 0.0f, 10.0f, 10.0f));
}

TEST(EmbedderAndroidEngineTest, ToDlPathToleratesMissingSegments) {
  FlutterPath no_segments = {};
  no_segments.struct_size = sizeof(FlutterPath);
  no_segments.fill_type = kFlutterPathFillTypeNonZero;
  no_segments.segments_count = 4;
  no_segments.segments = nullptr;
  EXPECT_TRUE(EmbedderAndroidEngine::ToDlPath(no_segments).IsEmpty());

  // An embedder built against an older header cannot have populated the
  // segment fields, so the path must be treated as empty rather than read.
  FlutterPath truncated = {};
  truncated.struct_size = sizeof(size_t);
  EXPECT_TRUE(EmbedderAndroidEngine::ToDlPath(truncated).IsEmpty());
}

namespace {

// An arbitrary non-zero view id, so that a dropped `view_id` assignment
// cannot pass by coincidence.
constexpr int64_t kTestViewId = 7;

// The display feature contract `MakeViewportMetricsFromWindowMetrics` in
// `embedder.cc` enforces. Violating any of these makes the engine reject the
// whole metrics event -- size, padding and all -- not just the offending
// feature, so every event this class produces has to satisfy them.
//
// |features| is the object the event borrows from, which is what makes the
// "bounds is readable for 4 * count doubles" check possible: the C struct
// carries no length for it.
void ExpectEngineWouldAcceptDisplayFeatures(
    const FlutterWindowMetricsEvent& event,
    const EmbedderAndroidEngine::DisplayFeatures& features) {
  SCOPED_TRACE(::testing::Message() << "display features contract, count="
                                    << event.display_features_count);
  EXPECT_LE(event.display_features_count,
            static_cast<size_t>(kFlutterMaxDisplayFeatures));
  if (event.display_features_count == 0) {
    EXPECT_EQ(event.display_features_bounds, nullptr);
    EXPECT_EQ(event.display_features_type, nullptr);
    EXPECT_EQ(event.display_features_state, nullptr);
    return;
  }
  ASSERT_NE(event.display_features_bounds, nullptr);
  ASSERT_NE(event.display_features_type, nullptr);
  ASSERT_NE(event.display_features_state, nullptr);
  // The engine reads four doubles per feature from `display_features_bounds`,
  // so the backing array has to be at least that long. These are fatal because
  // the loop below indexes by `display_features_count`: if the count and the
  // arrays ever disagree, the test has to stop here rather than read past the
  // end and crash instead of reporting.
  ASSERT_GE(features.bounds.size(), event.display_features_count * 4);
  ASSERT_EQ(features.type.size(), event.display_features_count);
  ASSERT_EQ(features.state.size(), event.display_features_count);
  for (size_t i = 0; i < event.display_features_count; i++) {
    EXPECT_GE(event.display_features_type[i], kFlutterDisplayFeatureTypeUnknown)
        << "at index " << i;
    EXPECT_LE(event.display_features_type[i], kFlutterDisplayFeatureTypeCutout)
        << "at index " << i;
    EXPECT_GE(event.display_features_state[i],
              kFlutterDisplayFeatureStateUnknown)
        << "at index " << i;
  }
}

}  // namespace

TEST(EmbedderAndroidEngineTest,
     WindowMetricsEventReportsEveryFeatureWithBounds) {
  // Two features' worth of bounds, but the type and state arrays are short.
  // They arrive as three independent Java arrays, so this is possible, and the
  // engine reads `display_features_count` entries from all three. Reporting
  // the count of any array other than bounds would either read past the end of
  // bounds or silently discard a feature the framework has to lay out around.
  ViewportMetrics metrics;
  metrics.physical_display_features_bounds = {0, 0, 10, 10, 20, 0, 30, 10};
  metrics.physical_display_features_type = {kFlutterDisplayFeatureTypeFold};
  metrics.physical_display_features_state = {};

  const auto features =
      EmbedderAndroidEngine::NormalizeDisplayFeatures(metrics);
  const FlutterWindowMetricsEvent event =
      EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(kTestViewId, metrics,
                                                         features);

  ASSERT_EQ(event.display_features_count, 2u);
  ASSERT_NE(event.display_features_type, nullptr);
  ASSERT_NE(event.display_features_state, nullptr);
  EXPECT_EQ(event.display_features_type[0], kFlutterDisplayFeatureTypeFold);
  EXPECT_EQ(event.display_features_state[0],
            kFlutterDisplayFeatureStateUnknown);
  // The missing entries are reported as unknown rather than dropping a feature
  // that has real geometry.
  EXPECT_EQ(event.display_features_type[1], kFlutterDisplayFeatureTypeUnknown);
  EXPECT_EQ(event.display_features_state[1],
            kFlutterDisplayFeatureStateUnknown);
  EXPECT_EQ(event.display_features_bounds, features.bounds.data());
  // The copy has to preserve the geometry verbatim, in order: the framework
  // lays out around these rectangles.
  EXPECT_THAT(features.bounds, ::testing::ElementsAreArray(
                                   metrics.physical_display_features_bounds));
  // The event is addressed to the view it was built for.
  EXPECT_EQ(event.view_id, kTestViewId);
  ExpectEngineWouldAcceptDisplayFeatures(event, features);
}

TEST(EmbedderAndroidEngineTest,
     WindowMetricsEventNormalizesUnusableTypesAndStates) {
  // `FlutterJNI::setViewportMetrics` is public API and forwards these as raw
  // jints, so out of range values can reach here.
  ViewportMetrics metrics;
  metrics.physical_display_features_bounds = {0, 0, 10, 10, 20, 0, 30, 10};
  metrics.physical_display_features_type = {99, -1};
  metrics.physical_display_features_state = {-5, 7};

  const auto features =
      EmbedderAndroidEngine::NormalizeDisplayFeatures(metrics);
  const FlutterWindowMetricsEvent event =
      EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(kTestViewId, metrics,
                                                         features);

  ASSERT_EQ(event.display_features_count, 2u);
  ASSERT_NE(event.display_features_type, nullptr);
  ASSERT_NE(event.display_features_state, nullptr);
  // An unrecognized type would make the framework index past the end of
  // `DisplayFeatureType.values`, so it degrades to unknown.
  EXPECT_EQ(event.display_features_type[0], kFlutterDisplayFeatureTypeUnknown);
  EXPECT_EQ(event.display_features_type[1], kFlutterDisplayFeatureTypeUnknown);
  // A negative state would throw in `_decodeDisplayFeatures`.
  EXPECT_EQ(event.display_features_state[0],
            kFlutterDisplayFeatureStateUnknown);
  // A state the engine does not know yet is deliberately preserved: the
  // framework already falls back to unknown for it, and clamping here would
  // break forward compatibility.
  EXPECT_EQ(event.display_features_state[1], 7);
  ExpectEngineWouldAcceptDisplayFeatures(event, features);
}

TEST(EmbedderAndroidEngineTest,
     WindowMetricsEventWithholdsFeatureArraysAsAGroup) {
  ViewportMetrics metrics;
  const auto features =
      EmbedderAndroidEngine::NormalizeDisplayFeatures(metrics);
  const FlutterWindowMetricsEvent event =
      EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(kTestViewId, metrics,
                                                         features);

  EXPECT_EQ(event.display_features_count, 0u);
  EXPECT_EQ(event.display_features_bounds, nullptr);
  EXPECT_EQ(event.display_features_type, nullptr);
  EXPECT_EQ(event.display_features_state, nullptr);
  ExpectEngineWouldAcceptDisplayFeatures(event, features);
}

TEST(EmbedderAndroidEngineTest,
     WindowMetricsEventTruncatesBeyondTheEngineLimit) {
  const size_t limit = static_cast<size_t>(kFlutterMaxDisplayFeatures);

  ViewportMetrics at_limit;
  at_limit.physical_display_features_bounds = std::vector<double>(limit * 4, 0);
  at_limit.physical_display_features_type = std::vector<int>(limit, 1);
  at_limit.physical_display_features_state = std::vector<int>(limit, 1);
  const auto at_limit_features =
      EmbedderAndroidEngine::NormalizeDisplayFeatures(at_limit);
  const FlutterWindowMetricsEvent at_limit_event =
      EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(kTestViewId, at_limit,
                                                         at_limit_features);
  EXPECT_EQ(at_limit_event.display_features_count, limit);
  ExpectEngineWouldAcceptDisplayFeatures(at_limit_event, at_limit_features);

  // One past the limit the surplus is dropped rather than letting the engine
  // throw away the entire metrics event.
  ViewportMetrics over_limit;
  over_limit.physical_display_features_bounds =
      std::vector<double>((limit + 1) * 4, 0);
  over_limit.physical_display_features_type = std::vector<int>(limit + 1, 1);
  over_limit.physical_display_features_state = std::vector<int>(limit + 1, 1);
  const auto over_limit_features =
      EmbedderAndroidEngine::NormalizeDisplayFeatures(over_limit);
  const FlutterWindowMetricsEvent over_limit_event =
      EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(
          kTestViewId, over_limit, over_limit_features);
  EXPECT_EQ(over_limit_event.display_features_count, limit);
  ExpectEngineWouldAcceptDisplayFeatures(over_limit_event, over_limit_features);
}

TEST(EmbedderAndroidEngineTest,
     WindowMetricsEventNeverReadsPastTheBoundsArray) {
  // The engine reads four doubles per feature, so a bounds array that is not a
  // multiple of four can only describe the features it fully covers.
  ViewportMetrics partial;
  partial.physical_display_features_bounds = {0, 0, 10, 10, 20, 0};
  partial.physical_display_features_type = {1, 2};
  partial.physical_display_features_state = {1, 1};
  const auto partial_features =
      EmbedderAndroidEngine::NormalizeDisplayFeatures(partial);
  const FlutterWindowMetricsEvent partial_event =
      EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(kTestViewId, partial,
                                                         partial_features);
  EXPECT_EQ(partial_event.display_features_count, 1u);
  EXPECT_EQ(partial_features.bounds.size(),
            partial_event.display_features_count * 4);
  // The complete leading rectangle survives unshifted; the trailing partial
  // one is dropped rather than padded out with garbage.
  EXPECT_THAT(partial_features.bounds, ::testing::ElementsAre(0, 0, 10, 10));
  ExpectEngineWouldAcceptDisplayFeatures(partial_event, partial_features);

  // Fewer than four bounds describes no complete feature at all, even though
  // the type and state arrays claim two.
  ViewportMetrics truncated;
  truncated.physical_display_features_bounds = {0, 0};
  truncated.physical_display_features_type = {1, 2};
  truncated.physical_display_features_state = {1, 1};
  const auto truncated_features =
      EmbedderAndroidEngine::NormalizeDisplayFeatures(truncated);
  const FlutterWindowMetricsEvent truncated_event =
      EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(kTestViewId, truncated,
                                                         truncated_features);
  EXPECT_EQ(truncated_event.display_features_count, 0u);
  EXPECT_EQ(truncated_event.display_features_type, nullptr);
  ExpectEngineWouldAcceptDisplayFeatures(truncated_event, truncated_features);
}

}  // namespace testing
}  // namespace flutter
