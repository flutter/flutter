// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/pipeline_variant_recorder.h"

#include <sstream>

#include "flutter/testing/testing.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

namespace {

using ::testing::HasSubstr;
using ::testing::NiceMock;
using ::testing::Not;
using ::testing::Return;

using RecordedVariant = ContentContext::RecordedVariant;

/// A context that reports the given backend and hands out the given library.
std::shared_ptr<NiceMock<MockImpellerContext>> MakeContext(
    const std::shared_ptr<PipelineLibrary>& library,
    Context::BackendType backend) {
  auto context = std::make_shared<NiceMock<MockImpellerContext>>();
  ON_CALL(*context, GetPipelineLibrary()).WillByDefault(Return(library));
  ON_CALL(*context, GetBackendType()).WillByDefault(Return(backend));
  return context;
}

PipelineDescriptor MakeDescriptor(const std::string& label) {
  PipelineDescriptor descriptor;
  descriptor.SetLabel(label);
  return descriptor;
}

/// Options that differ for each `seed`.
ContentContextOptions MakeOptions(uint8_t seed) {
  ContentContextOptions options;
  options.blend_mode = static_cast<BlendMode>(
      seed % (static_cast<uint8_t>(BlendMode::kLastMode) + 1));
  return options;
}

RecordedVariant Warmed(const std::string& label, uint8_t seed = 0) {
  return RecordedVariant{.descriptor = MakeDescriptor(label),
                         .options = MakeOptions(seed),
                         .warmed = true};
}

RecordedVariant Lazy(const std::string& label, uint8_t seed = 0) {
  return RecordedVariant{.descriptor = MakeDescriptor(label),
                         .options = MakeOptions(seed),
                         .warmed = false};
}

class PipelineVariantRecorderTest : public ::testing::Test {
 public:
  void SetUp() override {
    // Variant recording, and with it a report that can be trusted, only exists
    // in debug builds.
    if (!ContentContext::IsPipelineVariantRecordingSupported()) {
      GTEST_SKIP() << "Pipeline variant recording is only in debug builds.";
    }
  }

  /// Renders the recorder's report and returns it as text.
  std::string Report(const PipelineVariantRecorder& recorder,
                     const PipelineVariantRecorder::RunInfo& run_info = {
                         .gtest_filter = "*"}) {
    std::stringstream out;
    recorder.PrintReport(out, run_info);
    return out.str();
  }
};

}  // namespace

TEST_F(PipelineVariantRecorderTest, HarvestsNothingUntilEnabled) {
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  EXPECT_FALSE(recorder.IsEnabled());
  recorder.Harvest(*context, {Warmed("Unwatched Pipeline")});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, Not(HasSubstr("Unwatched Pipeline")));
  EXPECT_THAT(report, HasSubstr("Nothing recorded"));
  // There is nothing to compare across backends.
  EXPECT_THAT(report, Not(HasSubstr("Cross-backend")));
}

TEST_F(PipelineVariantRecorderTest, ReportsWarmedButNeverDrawnVariants) {
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Warmed Pipeline")});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, HasSubstr("\nVulkan\n"));
  EXPECT_THAT(report, HasSubstr("Warmed Pipeline"));
  EXPECT_THAT(report, HasSubstr("WARMED BUT NEVER DRAWN (1)"));
  EXPECT_THAT(
      report,
      HasSubstr(
          "1 variants: 1 warmed (0 drawn) | 0 created lazily, never drawn"));
  EXPECT_THAT(report, HasSubstr("never drawn with any options"));
}

TEST_F(PipelineVariantRecorderTest, DoesNotListDrawnButNeverWarmedVariants) {
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Cold Pipeline"));
  auto context = MakeContext(library, Context::BackendType::kMetal);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Lazy("Cold Pipeline")});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, HasSubstr("\nMetal\n"));
  EXPECT_THAT(
      report,
      HasSubstr(
          "1 variants: 0 warmed (0 drawn) | 0 created lazily, never drawn"));
  EXPECT_THAT(report, HasSubstr("Draws covered by warmed variants: 0 of 1"));
  // Its draws count towards the total, but it is not listed.
  EXPECT_THAT(report, Not(HasSubstr("Cold Pipeline")));
}

TEST_F(PipelineVariantRecorderTest, WarmedAndDrawnVariantIsASingleEntry) {
  // A pipeline warmed at startup and later bound for drawing has to reconcile
  // into one entry, not show up as an unused warm plus an unwarmed draw.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Useful Pipeline"));
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Useful Pipeline")});

  const std::string report = Report(recorder);
  EXPECT_THAT(
      report,
      HasSubstr(
          "1 variants: 1 warmed (1 drawn) | 0 created lazily, never drawn"));
  EXPECT_THAT(report,
              HasSubstr("Draws covered by warmed variants: 1 of 1 (100.0%)"));
}

TEST_F(PipelineVariantRecorderTest, MergesTheSameVariantAcrossContexts) {
  // The playground builds a context per test, so a variant used by several
  // tests arrives through several libraries and has to accumulate.
  auto first_library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  first_library->LogPipelineUsage(MakeDescriptor("Cold Pipeline"));
  auto first_context =
      MakeContext(first_library, Context::BackendType::kVulkan);

  auto second_library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  second_library->LogPipelineUsage(MakeDescriptor("Shared Pipeline"));
  second_library->LogPipelineUsage(MakeDescriptor("Cold Pipeline"));
  auto second_context =
      MakeContext(second_library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*first_context,
                   {Warmed("Shared Pipeline"), Lazy("Cold Pipeline", 1)});
  recorder.Harvest(*second_context,
                   {Warmed("Shared Pipeline"), Lazy("Cold Pipeline", 1)});

  const std::string report = Report(recorder);
  EXPECT_THAT(
      report,
      HasSubstr(
          "2 variants: 1 warmed (1 drawn) | 0 created lazily, never drawn"));
  EXPECT_THAT(report,
              HasSubstr("Draws covered by warmed variants: 1 of 3 (33.3%)"));
}

TEST_F(PipelineVariantRecorderTest, KeepsBackendsSeparate) {
  // Warmup is capability gated, so the same variant can be warmed on one
  // backend and not another. Merging the backends would hide that.
  auto vulkan_library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto vulkan_context =
      MakeContext(vulkan_library, Context::BackendType::kVulkan);

  auto gles_library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  gles_library->LogPipelineUsage(MakeDescriptor("Split Pipeline"));
  auto gles_context =
      MakeContext(gles_library, Context::BackendType::kOpenGLES);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*vulkan_context, {Warmed("Split Pipeline")});
  recorder.Harvest(*gles_context, {Lazy("Split Pipeline")});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, HasSubstr("\nVulkan\n"));
  EXPECT_THAT(report, HasSubstr("\nOpenGLES\n"));
  EXPECT_THAT(
      report,
      HasSubstr(
          "1 variants: 1 warmed (0 drawn) | 0 created lazily, never drawn"));
  EXPECT_THAT(
      report,
      HasSubstr(
          "1 variants: 0 warmed (0 drawn) | 0 created lazily, never drawn"));
}

TEST_F(PipelineVariantRecorderTest, FormatsOptions) {
  ContentContextOptions options;
  options.blend_mode = BlendMode::kPlus;
  options.sample_count = SampleCount::kCount4;
  options.primitive_type = PrimitiveType::kTriangleStrip;
  options.stencil_mode = ContentContextOptions::StencilMode::kCoverCompare;
  options.depth_write_enabled = true;

  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context,
                   {RecordedVariant{.descriptor = MakeDescriptor("Formatted"),
                                    .options = options,
                                    .warmed = true}});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, HasSubstr("blend=Plus"));
  EXPECT_THAT(report, HasSubstr("msaa=4x"));
  EXPECT_THAT(report, HasSubstr("prim=TriangleStrip"));
  EXPECT_THAT(report, HasSubstr("stencil=CoverCompare"));
  EXPECT_THAT(report, HasSubstr("+depth_write"));
}

TEST_F(PipelineVariantRecorderTest, HarvestingTheSameLibraryTwiceIsIdempotent) {
  // Several `ContentContext`s can share one `Context`, and the GLES playground
  // shares one across the whole suite, so the same library reports a running
  // total every time. Adding that total on each harvest inflates draw counts.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto context = MakeContext(library, Context::BackendType::kOpenGLES);

  PipelineVariantRecorder recorder;
  recorder.Enable();

  library->LogPipelineUsage(MakeDescriptor("Shared Pipeline"));
  library->LogPipelineUsage(MakeDescriptor("Shared Pipeline"));
  recorder.Harvest(*context, {Lazy("Shared Pipeline")});
  // Harvested again with no new draws at all.
  recorder.Harvest(*context, {Lazy("Shared Pipeline")});
  // And again after one more draw, so the total is now 3.
  library->LogPipelineUsage(MakeDescriptor("Shared Pipeline"));
  recorder.Harvest(*context, {});
  recorder.Harvest(*context, {});

  EXPECT_THAT(Report(recorder),
              HasSubstr("Draws covered by warmed variants: 0 of 3"));
}

TEST_F(PipelineVariantRecorderTest, HoldsBackDrawsUntilTheyAreClaimed) {
  // Two `ContentContext`s share a library. The one destroyed first did not
  // create the drawn pipeline, so its draws must wait for the second rather
  // than be written off as not belonging to any `ContentContext`.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Late Pipeline"));
  auto context = MakeContext(library, Context::BackendType::kMetal);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Other Pipeline")});
  recorder.Harvest(*context, {Lazy("Late Pipeline", 3)});

  const std::string report = Report(recorder);
  // Written off, the draw would be an extra variant without options.
  EXPECT_THAT(
      report,
      HasSubstr(
          "2 variants: 1 warmed (0 drawn) | 0 created lazily, never drawn"));
}

TEST_F(PipelineVariantRecorderTest, CountsUnclaimedDrawsWithoutOptions) {
  // Runtime effects and pipelines built directly by tests are not variants of
  // anything, and must not be described with a fabricated set of options.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Keyless Pipeline"));
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {});

  const std::string report = Report(recorder);
  EXPECT_THAT(
      report,
      HasSubstr(
          "1 variants: 0 warmed (0 drawn) | 0 created lazily, never drawn"));
  EXPECT_THAT(report, HasSubstr("Draws covered by warmed variants: 0 of 1"));
  EXPECT_THAT(report, Not(HasSubstr("blend=")));
}

TEST_F(PipelineVariantRecorderTest, KeepsUnclaimedDrawsOfFreedLibraries) {
  // Once a library is freed its record is dropped, so that a new library at the
  // same address starts afresh. Its unclaimed draws must survive that.
  PipelineVariantRecorder recorder;
  recorder.Enable();
  {
    auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
    library->LogPipelineUsage(MakeDescriptor("Keyless Pipeline"));
    library->LogPipelineUsage(MakeDescriptor("Keyless Pipeline"));
    auto context = MakeContext(library, Context::BackendType::kVulkan);
    recorder.Harvest(*context, {});
  }

  // The next harvest prunes the freed library.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Warmed Pipeline"));
  auto context = MakeContext(library, Context::BackendType::kVulkan);
  recorder.Harvest(*context, {Warmed("Warmed Pipeline")});

  EXPECT_THAT(Report(recorder),
              HasSubstr("Draws covered by warmed variants: 1 of 3"));
}

TEST_F(PipelineVariantRecorderTest, StripsTheVariantSuffixFromLabels) {
  // A warmed default carries the bare name while a lazily created variant is
  // labelled with its index in the container, which depends on request order.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Suffixed Pipeline V#3"));
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Suffixed Pipeline", 0),
                              Lazy("Suffixed Pipeline V#3", 1)});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, Not(HasSubstr("V#")));
  EXPECT_THAT(report, HasSubstr("2 variants: 1 warmed (0 drawn)"));
  // The draw is attributed to the same pipeline as the warmed default.
  EXPECT_THAT(report, HasSubstr("Suffixed Pipeline  drawn as: blend Clear -> "
                                "Src (1 draws)"));
}

TEST_F(PipelineVariantRecorderTest, KeepsLabelsThatOnlyResembleAVariantSuffix) {
  // Only a real suffix may be stripped: " V#" followed by decimal digits.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Hex V#abc", 1), Warmed("Empty V#", 2)});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, HasSubstr("Hex V#abc"));
  EXPECT_THAT(report, HasSubstr("Empty V#"));
}

TEST_F(PipelineVariantRecorderTest, ReportsRunDetailsWithoutWarnings) {
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Warmed Pipeline")});

  // A partial run is described once, in the header, and not warned about.
  const std::string report = Report(recorder, {.gtest_filter = "*Blur*",
                                               .tests_run = 10,
                                               .tests_skipped = 3,
                                               .tests_failed = 1});
  EXPECT_THAT(report,
              HasSubstr("10 tests run, 3 skipped, 1 failed, filter '*Blur*'"));
  EXPECT_THAT(report, Not(HasSubstr("!!")));
  EXPECT_THAT(report, Not(HasSubstr("Note:")));
}

TEST_F(PipelineVariantRecorderTest, ExplainsWhyWarmedVariantsWentUnused) {
  // The warmed default and the drawn variant are the same pipeline with
  // different options, and the report has to point at the difference.
  ContentContextOptions warmed_options;
  warmed_options.depth_compare = CompareFunction::kAlways;
  ContentContextOptions drawn_options = warmed_options;
  drawn_options.depth_compare = CompareFunction::kGreaterEqual;

  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  for (int i = 0; i < 5; i++) {
    library->LogPipelineUsage(MakeDescriptor("Fill Pipeline V#1"));
  }
  auto context = MakeContext(library, Context::BackendType::kMetal);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(
      *context,
      {RecordedVariant{.descriptor = MakeDescriptor("Fill Pipeline"),
                       .options = warmed_options,
                       .warmed = true},
       RecordedVariant{.descriptor = MakeDescriptor("Fill Pipeline V#1"),
                       .options = drawn_options,
                       .warmed = false}});

  const std::string report = Report(recorder);
  EXPECT_THAT(report, HasSubstr("Likely cause: 1 of 1 were drawn, but only "
                                "with other options:"));
  EXPECT_THAT(report, HasSubstr("1  depth Always -> GreaterEqual\n"));
  EXPECT_THAT(report, HasSubstr("Fill Pipeline  drawn as: depth Always -> "
                                "GreaterEqual (5 draws)"));
  // Everything but the depth compare is shared, so it is only printed once.
  EXPECT_THAT(report, HasSubstr("Every variant: msaa=1x blend="));
  EXPECT_THAT(report, HasSubstr("\n    depth=Always\n"));
}

TEST_F(PipelineVariantRecorderTest, SkipsCrossBackendComparisonForOneBackend) {
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto context = MakeContext(library, Context::BackendType::kMetal);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Warmed Pipeline")});

  const std::string report = Report(recorder);
  EXPECT_THAT(report,
              HasSubstr("Cross-backend comparison skipped: only Metal ran."));
  EXPECT_THAT(report, Not(HasSubstr("WARMED ON EVERY BACKEND")));
}

TEST_F(PipelineVariantRecorderTest, OrdersTheReportDeterministically) {
  // The same variants harvested in a different order must print identically.
  auto make_report = [this](bool reversed) {
    auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
    library->LogPipelineUsage(MakeDescriptor("B Pipeline"));
    library->LogPipelineUsage(MakeDescriptor("A Pipeline"));
    auto context = MakeContext(library, Context::BackendType::kMetal);
    std::vector<RecordedVariant> variants = {
        Warmed("Z Pipeline", 1), Warmed("Y Pipeline", 1), Lazy("B Pipeline", 2),
        Lazy("A Pipeline", 2)};
    if (reversed) {
      std::reverse(variants.begin(), variants.end());
    }
    PipelineVariantRecorder recorder;
    recorder.Enable();
    recorder.Harvest(*context, variants);
    return Report(recorder);
  };

  const std::string report = make_report(false);
  EXPECT_EQ(report, make_report(true));
  EXPECT_LT(report.find("Y Pipeline"), report.find("Z Pipeline"));
}

TEST_F(PipelineVariantRecorderTest, ReportsShadersNeverDrawnWithAnyOptions) {
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Drawn Pipeline V#1"));
  auto context = MakeContext(library, Context::BackendType::kVulkan);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  // The warmed variant of "Drawn Pipeline" is never drawn, but another variant
  // of the same shader is, so only "Idle Pipeline" is unused.
  recorder.Harvest(*context,
                   {Warmed("Drawn Pipeline", 0), Lazy("Drawn Pipeline V#1", 1),
                    Warmed("Idle Pipeline", 0), Lazy("Idle Pipeline V#1", 1)});

  const std::vector<PipelineVariantRecorder::UnusedShader> expected = {
      {.label = "Idle Pipeline", .created_on = {"Vulkan"}}};
  EXPECT_EQ(recorder.GetUnusedShaders(), expected);
}

TEST_F(PipelineVariantRecorderTest, CountsAShaderDrawnOnAnyBackendAsUsed) {
  // Some shaders only get drawn on some backends, which is not a reason to
  // fail.
  auto metal_library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto metal_context = MakeContext(metal_library, Context::BackendType::kMetal);
  auto vulkan_library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  vulkan_library->LogPipelineUsage(MakeDescriptor("Split Pipeline"));
  auto vulkan_context =
      MakeContext(vulkan_library, Context::BackendType::kVulkan);
  auto gles_library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  auto gles_context =
      MakeContext(gles_library, Context::BackendType::kOpenGLES);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*metal_context,
                   {Warmed("Split Pipeline"), Warmed("Idle Pipeline")});
  recorder.Harvest(*vulkan_context, {Warmed("Split Pipeline")});
  recorder.Harvest(*gles_context, {Warmed("Idle Pipeline")});

  const std::vector<PipelineVariantRecorder::UnusedShader> expected = {
      {.label = "Idle Pipeline", .created_on = {"Metal", "OpenGLES"}}};
  EXPECT_EQ(recorder.GetUnusedShaders(), expected);
}

TEST_F(PipelineVariantRecorderTest, TellsSpecializationsOfAShaderApart) {
  PipelineDescriptor drawn = MakeDescriptor("Specialized Pipeline");
  drawn.SetSpecializationConstants({0.0f});
  PipelineDescriptor idle = MakeDescriptor("Specialized Pipeline");
  idle.SetSpecializationConstants({1.0f});

  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(drawn);
  auto context = MakeContext(library, Context::BackendType::kMetal);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(
      *context,
      {RecordedVariant{
           .descriptor = drawn, .options = MakeOptions(0), .warmed = true},
       RecordedVariant{
           .descriptor = idle, .options = MakeOptions(0), .warmed = true}});

  const std::vector<PipelineVariantRecorder::UnusedShader> expected = {
      {.label = "Specialized Pipeline",
       .specialization_constants = {1.0f},
       .created_on = {"Metal"}}};
  EXPECT_EQ(recorder.GetUnusedShaders(), expected);
}

TEST_F(PipelineVariantRecorderTest, IgnoresDrawsOfPipelinesItDidNotCreate) {
  // Runtime effects and pipelines built by tests are never required to be
  // drawn.
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Keyless Pipeline"));
  auto context = MakeContext(library, Context::BackendType::kMetal);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {});

  EXPECT_TRUE(recorder.GetUnusedShaders().empty());
}

TEST_F(PipelineVariantRecorderTest, PrintsUnusedShaders) {
  auto library = std::make_shared<NiceMock<MockPipelineLibrary>>();
  library->LogPipelineUsage(MakeDescriptor("Drawn Pipeline"));
  auto context = MakeContext(library, Context::BackendType::kMetal);

  PipelineVariantRecorder recorder;
  recorder.Enable();
  recorder.Harvest(*context, {Warmed("Drawn Pipeline")});

  std::stringstream none;
  EXPECT_EQ(recorder.PrintUnusedShaders(none), 0u);
  EXPECT_THAT(none.str(), HasSubstr("Every shader a ContentContext created"));

  recorder.Harvest(*context, {Warmed("Idle Pipeline", 1)});
  std::stringstream some;
  EXPECT_EQ(recorder.PrintUnusedShaders(some), 1u);
  EXPECT_THAT(some.str(), HasSubstr("1 shaders were created"));
  EXPECT_THAT(some.str(), HasSubstr("Idle Pipeline  [Metal]\n"));
  EXPECT_THAT(some.str(), Not(HasSubstr("Drawn Pipeline")));
}

}  // namespace testing
}  // namespace impeller
