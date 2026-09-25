// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/pipeline_variant_recorder.h"

#include <algorithm>
#include <array>
#include <bit>
#include <format>
#include <functional>
#include <set>
#include <sstream>
#include <string_view>
#include <tuple>
#include <utility>

#include "flutter/fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/geometry/color.h"

namespace impeller {

namespace {

std::string BackendTypeToString(Context::BackendType type) {
  switch (type) {
    case Context::BackendType::kMetal:
      return "Metal";
    case Context::BackendType::kOpenGLES:
      return "OpenGLES";
    case Context::BackendType::kVulkan:
      return "Vulkan";
  }
  FML_UNREACHABLE();
}

std::string SampleCountToString(SampleCount count) {
  switch (count) {
    case SampleCount::kCount1:
      return "1x";
    case SampleCount::kCount4:
      return "4x";
  }
  FML_UNREACHABLE();
}

std::string PrimitiveTypeToString(PrimitiveType type) {
  switch (type) {
    case PrimitiveType::kTriangle:
      return "Triangle";
    case PrimitiveType::kTriangleStrip:
      return "TriangleStrip";
    case PrimitiveType::kLine:
      return "Line";
    case PrimitiveType::kLineStrip:
      return "LineStrip";
    case PrimitiveType::kPoint:
      return "Point";
    case PrimitiveType::kTriangleFan:
      return "TriangleFan";
  }
  FML_UNREACHABLE();
}

std::string CompareFunctionToString(CompareFunction function) {
  switch (function) {
    case CompareFunction::kNever:
      return "Never";
    case CompareFunction::kAlways:
      return "Always";
    case CompareFunction::kLess:
      return "Less";
    case CompareFunction::kEqual:
      return "Equal";
    case CompareFunction::kLessEqual:
      return "LessEqual";
    case CompareFunction::kGreater:
      return "Greater";
    case CompareFunction::kNotEqual:
      return "NotEqual";
    case CompareFunction::kGreaterEqual:
      return "GreaterEqual";
  }
  FML_UNREACHABLE();
}

std::string StencilModeToString(ContentContextOptions::StencilMode mode) {
  switch (mode) {
    case ContentContextOptions::StencilMode::kIgnore:
      return "Ignore";
    case ContentContextOptions::StencilMode::kStencilNonZeroFill:
      return "StencilNonZeroFill";
    case ContentContextOptions::StencilMode::kStencilEvenOddFill:
      return "StencilEvenOddFill";
    case ContentContextOptions::StencilMode::kStencilIncrementAll:
      return "StencilIncrementAll";
    case ContentContextOptions::StencilMode::kCoverCompare:
      return "CoverCompare";
    case ContentContextOptions::StencilMode::kCoverCompareInverted:
      return "CoverCompareInverted";
  }
  FML_UNREACHABLE();
}

/// `1234567` as `"1,234,567"`.
std::string WithThousandsSeparators(uint64_t value) {
  const std::string digits = std::to_string(value);
  std::string result;
  for (size_t i = 0; i < digits.size(); i++) {
    if (i > 0 && (digits.size() - i) % 3 == 0) {
      result += ',';
    }
    result += digits[i];
  }
  return result;
}

/// The individually printable fields of a `ContentContextOptions`, as bits so
/// that a set of them can be passed around as a mask.
enum OptionField : uint32_t {
  kFieldMsaa = 1u << 0,
  kFieldBlend = 1u << 1,
  kFieldDepth = 1u << 2,
  kFieldStencil = 1u << 3,
  kFieldPrimitive = 1u << 4,
  kFieldFormat = 1u << 5,
  kFieldDepthStencil = 1u << 6,
  kFieldDepthWrite = 1u << 7,
  kFieldRRectBlurClear = 1u << 8,
};

/// Every field, in the order they are printed.
constexpr std::array<OptionField, 9> kOptionFields = {
    kFieldMsaa,         kFieldBlend,      kFieldDepth,
    kFieldStencil,      kFieldPrimitive,  kFieldFormat,
    kFieldDepthStencil, kFieldDepthWrite, kFieldRRectBlurClear,
};

constexpr uint32_t kAllOptionFields = (1u << kOptionFields.size()) - 1u;

std::string_view FieldName(OptionField field) {
  switch (field) {
    case kFieldMsaa:
      return "msaa";
    case kFieldBlend:
      return "blend";
    case kFieldDepth:
      return "depth";
    case kFieldStencil:
      return "stencil";
    case kFieldPrimitive:
      return "prim";
    case kFieldFormat:
      return "format";
    case kFieldDepthStencil:
      return "depth_stencil";
    case kFieldDepthWrite:
      return "depth_write";
    case kFieldRRectBlurClear:
      return "rrect_blur_clear";
  }
  FML_UNREACHABLE();
}

/// Whether `field` is a boolean, which is printed as `+name` when set and not
/// at all otherwise.
bool IsFlag(OptionField field) {
  return field == kFieldDepthStencil || field == kFieldDepthWrite ||
         field == kFieldRRectBlurClear;
}

std::string FieldValue(const ContentContextOptions& options,
                       OptionField field) {
  switch (field) {
    case kFieldMsaa:
      return SampleCountToString(options.sample_count);
    case kFieldBlend:
      return BlendModeToString(options.blend_mode);
    case kFieldDepth:
      return CompareFunctionToString(options.depth_compare);
    case kFieldStencil:
      return StencilModeToString(options.stencil_mode);
    case kFieldPrimitive:
      return PrimitiveTypeToString(options.primitive_type);
    case kFieldFormat:
      return PixelFormatToString(options.color_attachment_pixel_format);
    case kFieldDepthStencil:
      return options.has_depth_stencil_attachments ? "on" : "off";
    case kFieldDepthWrite:
      return options.depth_write_enabled ? "on" : "off";
    case kFieldRRectBlurClear:
      return options.is_for_rrect_blur_clear ? "on" : "off";
  }
  FML_UNREACHABLE();
}

/// The fields in which `a` and `b` differ, as a mask.
uint32_t DifferingFields(const ContentContextOptions& a,
                         const ContentContextOptions& b) {
  uint32_t differing = 0u;
  for (OptionField field : kOptionFields) {
    if (FieldValue(a, field) != FieldValue(b, field)) {
      differing |= field;
    }
  }
  return differing;
}

/// E.g. `"depth Always -> GreaterEqual"`.
std::string DescribeChange(OptionField field,
                           const ContentContextOptions& from,
                           const ContentContextOptions& to) {
  return std::format("{} {} -> {}", FieldName(field), FieldValue(from, field),
                     FieldValue(to, field));
}

std::string FormatSpecializationConstants(const std::vector<Scalar>& values) {
  std::stringstream stream;
  stream << "[";
  for (size_t i = 0; i < values.size(); i++) {
    stream << (i > 0 ? "," : "") << values[i];
  }
  stream << "]";
  return stream.str();
}

/// The pipeline's label with the variant suffix removed.
///
/// `CreateIfNeeded` labels each lazily created variant `"<name> V#<index>"`,
/// while a warmed default keeps the bare name. The index is only the variant's
/// position in its container, which depends on the order the variants were
/// requested in, so keeping it would make the same variant read as different
/// entries depending on which test created it.
std::string BaseLabel(std::string_view label) {
  constexpr std::string_view kMarker = " V#";
  const size_t marker = label.rfind(kMarker);
  if (marker == std::string_view::npos) {
    return std::string{label};
  }
  const std::string_view index = label.substr(marker + kMarker.size());
  if (index.empty() ||
      index.find_first_not_of("0123456789") != std::string_view::npos) {
    return std::string{label};
  }
  return std::string{label.substr(0, marker)};
}

/// The fields of `options` selected by `mask`, on one line.
///
/// Kept to a single line so that the output can be grepped and diffed. The
/// three booleans are only mentioned when they are true, which keeps the common
/// case readable.
std::string FormatOptions(const ContentContextOptions& options,
                          uint32_t mask = kAllOptionFields) {
  std::string result;
  for (OptionField field : kOptionFields) {
    if ((mask & field) == 0u) {
      continue;
    }
    std::string part;
    if (IsFlag(field)) {
      if (FieldValue(options, field) != "on") {
        continue;
      }
      part = std::format("+{}", FieldName(field));
    } else {
      part = std::format("{}={}", FieldName(field), FieldValue(options, field));
    }
    if (!result.empty()) {
      result += ' ';
    }
    result += part;
  }
  return result;
}

}  // namespace

PipelineVariantRecorder::PipelineVariantRecorder() = default;

PipelineVariantRecorder::~PipelineVariantRecorder() = default;

PipelineVariantRecorder& PipelineVariantRecorder::GetInstance() {
  static PipelineVariantRecorder* recorder = new PipelineVariantRecorder();
  return *recorder;
}

void PipelineVariantRecorder::InstallForProcess() {
  if (!ContentContext::IsPipelineVariantRecordingSupported()) {
    FML_LOG(ERROR) << "A pipeline variant report was requested but pipeline "
                      "variant recording is only compiled into debug builds. "
                      "The report will be empty.";
    return;
  }
  GetInstance().Enable();
  ContentContext::SetPipelineVariantObserver(
      [](const Context& context,
         const std::vector<ContentContext::RecordedVariant>& variants) {
        GetInstance().Harvest(context, variants);
      });
}

void PipelineVariantRecorder::Enable() {
#if FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_DEBUG && \
    FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_PROFILE
  FML_LOG(ERROR)
      << "A pipeline variant report was requested but pipeline usage is only "
         "recorded in the debug and profile runtime modes. Every warmed "
         "variant will be reported as never drawn.";
#endif
  Lock lock(mutex_);
  enabled_ = true;
}

bool PipelineVariantRecorder::IsEnabled() const {
  Lock lock(mutex_);
  return enabled_;
}

PipelineVariantRecorder::Entry& PipelineVariantRecorder::GetEntry(
    BackendEntries& entries,
    const PipelineDescriptor& descriptor,
    const std::optional<ContentContextOptions>& options) {
  // Two entries that agree on this are the same variant and are merged, even
  // though they were observed through different contexts.
  std::string label = BaseLabel(descriptor.GetLabel());
  const std::vector<Scalar>& constants =
      descriptor.GetSpecializationConstants();
  std::string identity =
      std::format("{}|{}|{}", label, FormatSpecializationConstants(constants),
                  options.has_value() ? FormatOptions(options.value()) : "");
  Entry& entry = entries[identity];
  if (entry.label.empty()) {
    entry.label = std::move(label);
    entry.options = options;
    entry.specialization_constants = constants;
  }
  return entry;
}

void PipelineVariantRecorder::Harvest(
    const Context& context,
    const std::vector<ContentContext::RecordedVariant>& variants) {
  if (!IsEnabled()) {
    return;
  }

  const std::shared_ptr<PipelineLibrary> library = context.GetPipelineLibrary();
  if (!library) {
    return;
  }
  const auto use_counts = library->GetPipelineUseCounts();
  const std::string backend = BackendTypeToString(context.GetBackendType());

  Lock lock(mutex_);

  // Done first so that a library allocated at the address of a freed one never
  // finds, and overwrites, the freed library's record.
  PruneExpiredLibraries();

  LibraryRecord& record = libraries_[library.get()];
  if (record.library.expired()) {
    // The first sighting of this library.
    record = LibraryRecord{.library = library, .backend = backend};
  }

  BackendEntries& entries = backends_[backend];
  for (const ContentContext::RecordedVariant& variant : variants) {
    KnownVariant& known = record.known[variant.descriptor];
    known.options = variant.options;
    known.warmed = known.warmed || variant.warmed;
    // A variant is warmed if any context ever warmed it. Recording it here
    // also makes variants that were never drawn show up at all.
    Entry& entry = GetEntry(entries, variant.descriptor, variant.options);
    entry.warmed = entry.warmed || variant.warmed;
  }

  record.latest.clear();
  for (const auto& [descriptor, count] : use_counts) {
    if (count <= 0) {
      continue;
    }
    const uint64_t total = static_cast<uint64_t>(count);
    record.latest[descriptor] = total;
    auto known = record.known.find(descriptor);
    if (known == record.known.end()) {
      // Possibly created by a `ContentContext` that has not been destroyed
      // yet. Held back until it is claimed, the library is freed, or the report
      // is printed.
      continue;
    }
    uint64_t& already_counted = record.counted[descriptor];
    // Draw counts on a library only ever grow, so anything else means this is
    // not the same run of counters that was seen before.
    GetEntry(entries, descriptor, known->second.options).draw_count +=
        total >= already_counted ? total - already_counted : total;
    already_counted = total;
  }
}

void PipelineVariantRecorder::AddUnclaimedDraws(const LibraryRecord& record,
                                                BackendEntries& entries) {
  for (const auto& [descriptor, total] : record.latest) {
    if (record.known.contains(descriptor)) {
      continue;
    }
    auto counted = record.counted.find(descriptor);
    const uint64_t already_counted =
        counted == record.counted.end() ? 0u : counted->second;
    if (total > already_counted) {
      GetEntry(entries, descriptor, std::nullopt).draw_count +=
          total - already_counted;
    }
  }
}

void PipelineVariantRecorder::PruneExpiredLibraries() {
  // A freed library cannot draw again, and no `ContentContext` is left to
  // claim its held back draws, so they are final. Keeping the record would
  // only keep its descriptors, and the shader functions they reference, alive.
  for (auto it = libraries_.begin(); it != libraries_.end();) {
    const LibraryRecord& record = it->second;
    if (!record.library.expired()) {
      ++it;
      continue;
    }
    AddUnclaimedDraws(record, backends_[record.backend]);
    it = libraries_.erase(it);
  }
}

std::map<std::string, PipelineVariantRecorder::BackendEntries>
PipelineVariantRecorder::GetBackendsWithUnclaimedDraws() const {
  std::map<std::string, BackendEntries> backends = backends_;
  for (const auto& [address, record] : libraries_) {
    AddUnclaimedDraws(record, backends[record.backend]);
  }
  return backends;
}

std::vector<PipelineVariantRecorder::UnusedShader>
PipelineVariantRecorder::GetUnusedShaders() const {
  Lock lock(mutex_);
  struct Shader {
    std::set<std::string> created_on;
    bool drawn = false;
  };
  std::map<std::pair<std::string, std::vector<Scalar>>, Shader> shaders;
  for (const auto& [backend, entries] : GetBackendsWithUnclaimedDraws()) {
    for (const auto& [identity, entry] : entries) {
      Shader& shader = shaders[{entry.label, entry.specialization_constants}];
      // Only a `ContentContext` makes a shader one that has to be used. A
      // draw of a pipeline it did not create still uses a shader it did, if
      // the label and constants match.
      if (entry.options.has_value()) {
        shader.created_on.insert(backend);
      }
      shader.drawn = shader.drawn || entry.draw_count > 0u;
    }
  }

  std::vector<UnusedShader> unused;
  for (const auto& [key, shader] : shaders) {
    if (shader.drawn || shader.created_on.empty()) {
      continue;
    }
    unused.push_back(UnusedShader{
        .label = key.first,
        .specialization_constants = key.second,
        .created_on = {shader.created_on.begin(), shader.created_on.end()},
    });
  }
  return unused;
}

size_t PipelineVariantRecorder::PrintUnusedShaders(std::ostream& out) const {
  const std::vector<UnusedShader> unused = GetUnusedShaders();
  out << "\n" << std::string(kRuleWidth, '=') << "\n";
  out << "Unused Impeller shaders\n";
  out << std::string(kRuleWidth, '=') << "\n";
  if (unused.empty()) {
    out << "  Every shader a ContentContext created was drawn with.\n\n";
    return 0u;
  }

  out << std::format(
      "  {} shaders were created by a ContentContext but never drawn with, "
      "with\n  any options, on any backend (SC = specialization "
      "constants):\n\n",
      unused.size());
  std::vector<std::string> names;
  size_t width = 0u;
  for (const UnusedShader& shader : unused) {
    std::string name = shader.label;
    if (!shader.specialization_constants.empty()) {
      name += " SC=" +
              FormatSpecializationConstants(shader.specialization_constants);
    }
    width = std::max(width, name.size());
    names.push_back(std::move(name));
  }
  for (size_t i = 0; i < unused.size(); i++) {
    std::string backends;
    for (const std::string& backend : unused[i].created_on) {
      backends += backends.empty() ? "" : ", ";
      backends += backend;
    }
    out << std::format("    {:<{}}  [{}]\n", names[i], width, backends);
  }
  out << "\n  Add a golden test that draws with each of them, or stop creating "
         "them.\n\n";
  return unused.size();
}

class PipelineVariantRecorder::ReportPrinter {
 public:
  static void PrintBackend(std::ostream& out,
                           const std::string& backend,
                           const BackendEntries& entries);

  static void PrintCrossBackend(
      std::ostream& out,
      const std::map<std::string, BackendEntries>& backends);

 private:
  /// At most this many distinct option changes are listed as likely causes.
  static constexpr size_t kMaxLikelyCauses = 8u;
  /// Labels longer than this are not padded to line up with the others.
  static constexpr size_t kMaxNameWidth = 56u;

  /// A complete order on entries: by options, then label, then specialization
  /// constants. Distinct entries never compare equal, so the report comes out
  /// in the same order every run.
  ///
  /// Only used on entries created by a `ContentContext`, which have options.
  static bool Before(const Entry* a, const Entry* b) {
    FML_DCHECK(a->options.has_value() && b->options.has_value());
    return std::make_tuple(a->options->ToKey(), std::cref(a->label),
                           std::cref(a->specialization_constants)) <
           std::make_tuple(b->options->ToKey(), std::cref(b->label),
                           std::cref(b->specialization_constants));
  }

  /// The label, plus the specialization constants if there are any.
  static std::string Name(const Entry& entry) {
    if (entry.specialization_constants.empty()) {
      return entry.label;
    }
    return std::format(
        "{} SC={}", entry.label,
        FormatSpecializationConstants(entry.specialization_constants));
  }

  /// The heading of the group `entry` is printed in, showing only the option
  /// fields in `mask`. Only used on entries that have options.
  static std::string Heading(const Entry& entry, uint32_t mask) {
    FML_DCHECK(entry.options.has_value());
    std::string heading = FormatOptions(entry.options.value(), mask);
    return heading.empty() ? "(options shared by every variant)" : heading;
  }

  /// The option fields that have the same value in every entry with options.
  /// Only meaningful with at least two such entries, so empty otherwise.
  static uint32_t CommonFields(const BackendEntries& entries) {
    const ContentContextOptions* first = nullptr;
    size_t count = 0u;
    uint32_t common = kAllOptionFields;
    for (const auto& [identity, entry] : entries) {
      if (!entry.options.has_value()) {
        continue;
      }
      if (first == nullptr) {
        first = &entry.options.value();
      } else {
        common &= ~DifferingFields(*first, entry.options.value());
      }
      count++;
    }
    return count >= 2u ? common : 0u;
  }

  static void PrintWarmedNotDrawn(std::ostream& out,
                                  const std::vector<const Entry*>& warmed,
                                  const BackendEntries& entries,
                                  uint32_t mask);
};

void PipelineVariantRecorder::PrintReport(std::ostream& out,
                                          const RunInfo& run_info) const {
  Lock lock(mutex_);
  const std::map<std::string, BackendEntries> backends =
      GetBackendsWithUnclaimedDraws();

  out << "\n" << std::string(kRuleWidth, '=') << "\n";
  out << "Impeller pipeline variant usage\n";
  out << std::string(kRuleWidth, '=') << "\n";

  out << std::format(
      "  {} tests run, {} skipped, {} failed, filter '{}'\n",
      run_info.tests_run, run_info.tests_skipped, run_info.tests_failed,
      run_info.gtest_filter.empty() ? "*" : run_info.gtest_filter);
  // Unlike the run details above, these make the whole report meaningless and
  // are not otherwise visible, so they are called out.
#if FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_DEBUG && \
    FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_PROFILE
  out << "  Note: draws are only recorded in the debug and profile runtime "
         "modes.\n";
#endif
  if (!ContentContext::IsPipelineVariantRecordingSupported()) {
    out << "  Note: pipeline variant recording is only compiled into debug "
           "builds.\n";
  }

  if (backends.empty()) {
    out << "\n  Nothing recorded: no ContentContext was destroyed while "
           "recording\n  (did any playground tests run?)\n\n";
    return;
  }

  out << "\n  Legend: SC = specialization constants, +flag = option "
         "enabled,\n          \"drawn as\" = how the same pipeline was "
         "actually drawn.\n";

  for (const auto& [backend, entries] : backends) {
    ReportPrinter::PrintBackend(out, backend, entries);
  }

  ReportPrinter::PrintCrossBackend(out, backends);
}

void PipelineVariantRecorder::ReportPrinter::PrintBackend(
    std::ostream& out,
    const std::string& backend,
    const BackendEntries& entries) {
  std::vector<const Entry*> warmed_not_drawn;
  size_t warmed = 0u;
  size_t warmed_and_drawn = 0u;
  size_t lazy_not_drawn = 0u;
  uint64_t total_draws = 0u;
  uint64_t warmed_draws = 0u;
  for (const auto& [identity, entry] : entries) {
    total_draws += entry.draw_count;
    if (entry.warmed) {
      warmed++;
      warmed_draws += entry.draw_count;
      if (entry.draw_count == 0u) {
        warmed_not_drawn.push_back(&entry);
      } else {
        warmed_and_drawn++;
      }
    } else if (entry.draw_count == 0u) {
      lazy_not_drawn++;
    }
  }
  // The "stop warming" list is printed grouped by options, so sort on the
  // options first to make equal-options entries adjacent.
  std::sort(warmed_not_drawn.begin(), warmed_not_drawn.end(), Before);

  // Fields that never vary on this backend are printed once, rather than on
  // every line where they drown out the fields that do.
  const uint32_t common = CommonFields(entries);
  const uint32_t mask = kAllOptionFields & ~common;

  out << "\n" << std::string(kRuleWidth, '-') << "\n";
  out << backend << "\n";
  out << std::format(
      "  {} variants: {} warmed ({} drawn) | {} created lazily, never drawn\n",
      entries.size(), warmed, warmed_and_drawn, lazy_not_drawn);
  out << std::format(
      "  Draws covered by warmed variants: {} of {} ({:.1f}%)\n",
      WithThousandsSeparators(warmed_draws),
      WithThousandsSeparators(total_draws),
      total_draws == 0u ? 0.0 : 100.0 * warmed_draws / total_draws);
  if (common != 0u) {
    for (const auto& [identity, entry] : entries) {
      if (entry.options.has_value()) {
        const std::string shared = FormatOptions(entry.options.value(), common);
        if (!shared.empty()) {
          out << "  Every variant: " << shared << "\n";
        }
        break;
      }
    }
  }

  PrintWarmedNotDrawn(out, warmed_not_drawn, entries, mask);
}

void PipelineVariantRecorder::ReportPrinter::PrintWarmedNotDrawn(
    std::ostream& out,
    const std::vector<const Entry*>& warmed,
    const BackendEntries& entries,
    uint32_t mask) {
  out << std::format(
      "\n  WARMED BUT NEVER DRAWN ({}) - candidates to stop warming\n",
      warmed.size());
  if (warmed.empty()) {
    out << "    (none)\n";
    return;
  }

  // A warmed variant that is never drawn is usually the same pipeline being
  // drawn with slightly different options. Finding that drawn "twin" says why
  // the warmup missed, which is far more useful than the bare list.
  std::map<std::pair<std::string, std::vector<Scalar>>,
           std::vector<const Entry*>>
      drawn_by_pipeline;
  for (const auto& [identity, entry] : entries) {
    if (entry.draw_count > 0u && entry.options.has_value()) {
      drawn_by_pipeline[{entry.label, entry.specialization_constants}]
          .push_back(&entry);
    }
  }

  struct Twin {
    const Entry* drawn = nullptr;
    uint32_t differing = 0u;
  };
  std::vector<Twin> twins(warmed.size());
  std::map<std::string, size_t> change_counts;
  size_t without_twin = 0u;
  for (size_t i = 0; i < warmed.size(); i++) {
    const Entry& entry = *warmed[i];
    auto candidates =
        drawn_by_pipeline.find({entry.label, entry.specialization_constants});
    // Warmed variants are created by a `ContentContext`, so have options.
    FML_DCHECK(entry.options.has_value());
    if (candidates == drawn_by_pipeline.end()) {
      without_twin++;
      continue;
    }
    // The closest twin: fewest differing fields, then most drawn, then the
    // usual order so that ties are broken the same way every run.
    Twin& best = twins[i];
    for (const Entry* candidate : candidates->second) {
      const uint32_t differing =
          DifferingFields(entry.options.value(), candidate->options.value());
      const int by_fields =
          best.drawn == nullptr
              ? -1
              : std::popcount(differing) - std::popcount(best.differing);
      if (by_fields < 0 || (by_fields == 0 &&
                            (candidate->draw_count > best.drawn->draw_count ||
                             (candidate->draw_count == best.drawn->draw_count &&
                              Before(candidate, best.drawn))))) {
        best = Twin{.drawn = candidate, .differing = differing};
      }
    }
    for (OptionField field : kOptionFields) {
      if ((best.differing & field) != 0u) {
        change_counts[DescribeChange(field, entry.options.value(),
                                     best.drawn->options.value())]++;
      }
    }
  }

  if (without_twin < warmed.size()) {
    std::vector<std::pair<std::string, size_t>> changes(change_counts.begin(),
                                                        change_counts.end());
    std::sort(changes.begin(), changes.end(), [](const auto& a, const auto& b) {
      return std::tie(b.second, a.first) < std::tie(a.second, b.first);
    });
    out << std::format(
        "    Likely cause: {} of {} were drawn, but only with other options:\n",
        warmed.size() - without_twin, warmed.size());
    for (size_t i = 0; i < changes.size() && i < kMaxLikelyCauses; i++) {
      out << std::format("      {:>6}  {}\n", changes[i].second,
                         changes[i].first);
    }
    if (changes.size() > kMaxLikelyCauses) {
      out << std::format("      ... {} other changes\n",
                         changes.size() - kMaxLikelyCauses);
    }
  }
  if (without_twin > 0u) {
    out << std::format("    {} of {} were never drawn with any options.\n",
                       without_twin, warmed.size());
  }

  size_t width = 0u;
  for (const Entry* entry : warmed) {
    width = std::max(width, std::min(Name(*entry).size(), kMaxNameWidth));
  }

  // These entries overwhelmingly share a handful of option sets, so printing
  // the options once per group instead of once per entry is the difference
  // between seeing the pattern and scrolling past it.
  std::optional<std::string> current_heading;
  for (size_t i = 0; i < warmed.size(); i++) {
    const Entry& entry = *warmed[i];
    std::string heading = Heading(entry, mask);
    if (current_heading != heading) {
      out << "\n    " << heading << "\n";
      current_heading = std::move(heading);
    }
    const Twin& twin = twins[i];
    std::string drawn_as = "never drawn with any options";
    if (twin.drawn != nullptr) {
      std::string changes;
      for (OptionField field : kOptionFields) {
        if ((twin.differing & field) != 0u) {
          changes += changes.empty() ? "" : ", ";
          changes += DescribeChange(field, entry.options.value(),
                                    twin.drawn->options.value());
        }
      }
      drawn_as = std::format("drawn as: {} ({} draws)", changes,
                             WithThousandsSeparators(twin.drawn->draw_count));
    }
    out << std::format("      {:<{}}  {}\n", Name(entry), width, drawn_as);
  }
}

void PipelineVariantRecorder::ReportPrinter::PrintCrossBackend(
    std::ostream& out,
    const std::map<std::string, BackendEntries>& backends) {
  out << "\n" << std::string(kRuleWidth, '-') << "\n";
  if (backends.size() < 2u) {
    out << std::format(
        "Cross-backend comparison skipped: only {} ran.\n\n",
        backends.empty() ? "no backend" : backends.begin()->first);
    return;
  }

  // Group by everything except the backend. A variant warmed on every backend
  // it shows up on, and drawn on none of them, is the strongest signal that the
  // warmup itself is wrong rather than the workload being unrepresentative.
  struct Group {
    const Entry* example = nullptr;
    std::vector<std::string> seen_on;
    std::vector<std::string> warmed_on;
    bool drawn_anywhere = false;
  };
  std::map<std::string, Group> groups;
  for (const auto& [backend, entries] : backends) {
    for (const auto& [identity, entry] : entries) {
      Group& group = groups[identity];
      group.example = &entry;
      group.seen_on.push_back(backend);
      if (entry.warmed) {
        group.warmed_on.push_back(backend);
      }
      if (entry.draw_count > 0u) {
        group.drawn_anywhere = true;
      }
    }
  }

  std::vector<const Group*> unanimous;
  size_t partial = 0u;
  for (const auto& [identity, group] : groups) {
    if (group.drawn_anywhere || group.warmed_on.empty()) {
      continue;
    }
    if (group.warmed_on.size() == group.seen_on.size()) {
      unanimous.push_back(&group);
    } else {
      partial++;
    }
  }

  // Sorted and grouped by options for the same reason as the per-backend
  // lists, and for one more: two variants of the same pipeline that differ
  // only in, say, pixel format would otherwise print as byte-identical lines
  // and read as an accidental duplicate rather than two distinct PSOs.
  std::sort(unanimous.begin(), unanimous.end(),
            [](const Group* a, const Group* b) {
              return Before(a->example, b->example);
            });

  out << std::format(
      "WARMED ON EVERY BACKEND IT APPEARS ON, DRAWN ON NONE ({})\n",
      unanimous.size());
  if (unanimous.empty()) {
    out << "  (none)\n";
  }
  std::optional<std::string> current_heading;
  for (const Group* group : unanimous) {
    std::string heading = Heading(*group->example, kAllOptionFields);
    if (current_heading != heading) {
      out << "    " << heading << "\n";
      current_heading = std::move(heading);
    }
    out << "      " << Name(*group->example) << " [";
    for (size_t i = 0; i < group->warmed_on.size(); i++) {
      out << (i > 0 ? ", " : "") << group->warmed_on[i];
    }
    out << "]\n";
  }
  if (partial > 0u) {
    // Warmup is capability gated (SSBO, framebuffer fetch, decal sampling,
    // GLES-only shaders), so these are per-backend decisions.
    out << std::format(
        "  ({} more never-drawn variants are warmed on only some backends;\n"
        "  warmup is capability gated, so decide those per backend.)\n",
        partial);
  }
  out << "\n";
}

}  // namespace impeller
