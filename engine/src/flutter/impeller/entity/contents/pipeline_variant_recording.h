// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_PIPELINE_VARIANT_RECORDING_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_PIPELINE_VARIANT_RECORDING_H_

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/pipeline_descriptor.h"

//------------------------------------------------------------------------------
/// Recording of the pipeline variants that each `ContentContext` creates, so
/// that test diagnostics can tell which of them were never drawn with. See
/// `SetPipelineVariantObserver`.
///
/// This is a test diagnostic, so it is compiled out of everything but debug
/// builds. Outside of them every macro below expands to nothing, without
/// evaluating its arguments, and the implementation file is empty.
///
/// `ContentContext` only interacts with this through the macros below.
///

/// Whether pipeline variant recording is compiled into this build. Can be used
/// both in `#if` directives and in expressions.
#if defined(FLUTTER_RUNTIME_MODE) && \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
#define IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED() 1
#else
#define IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED() 0
#endif

namespace impeller {

class Context;
class GenericRenderPipelineHandle;

//------------------------------------------------------------------------------
/// @brief      A pipeline variant created by a `ContentContext`.
///
struct RecordedPipelineVariant {
  /// The descriptor the variant's pipeline was created with. This is what
  /// `PipelineLibrary::GetPipelineUseCounts` is keyed by.
  PipelineDescriptor descriptor;
  ContentContextOptions options;
  /// True if the variant was created ahead of time (warmed) by the
  /// `ContentContext` constructor, false if it was created lazily on first
  /// request.
  bool warmed = false;
};

using PipelineVariantObserver =
    std::function<void(const Context& context,
                       const std::vector<RecordedPipelineVariant>& variants)>;

//------------------------------------------------------------------------------
/// @brief      Sets a process-wide observer that each `ContentContext` calls
///             from its destructor with every pipeline variant it created.
///             Pass an empty function to remove it.
///
///             Only `ContentContext`s created while an observer is set record
///             their variants. Intended for test diagnostics, see
///             `PipelineVariantRecorder` and the `--shader-report` and
///             `--fail-on-unused-shaders` flags of `impeller_golden_tests`.
///
///             Outside of debug builds (see
///             `IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED`) this logs an
///             error and the observer is never called.
///
#if IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()
void SetPipelineVariantObserver(PipelineVariantObserver observer);
#else
inline void SetPipelineVariantObserver(
    const PipelineVariantObserver& observer) {
  if (observer) {
    FML_LOG(ERROR) << "Pipeline variant recording is only available in debug "
                      "builds. The observer will never be called.";
  }
}
#endif  // IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()

#if IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()
/// Implementation details of the macros below. Use the macros instead.
namespace pipeline_variant_recording {

/// Starts recording the variants of `content_context` if an observer is set.
///
/// @return     `content_context` if its variants are being recorded, nullptr
///             otherwise.
const ContentContext* Register(const ContentContext* content_context);

/// Records the variant `pipeline` was created for if it was created inside a
/// `Scope` of a registered `ContentContext`.
void Record(const ContentContextOptions& options,
            const GenericRenderPipelineHandle* pipeline);

/// Stops recording the variants of `content_context` and hands them to the
/// observer.
void Report(const ContentContext* content_context,
            const std::shared_ptr<Context>& context);

/// Attributes the variants created on this thread while it is alive to
/// `content_context`. Scopes nest.
class Scope {
 public:
  Scope(const ContentContext* content_context, bool warmed);

  ~Scope();

 private:
  const ContentContext* previous_content_context_;
  bool previous_warmed_;

  Scope(const Scope&) = delete;

  Scope& operator=(const Scope&) = delete;
};

}  // namespace pipeline_variant_recording
#endif  // IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()

}  // namespace impeller

#if IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()

/// For the `ContentContext` constructor: records the variants created for
/// `content_context` until the end of the enclosing scope as warmed, and every
/// variant created for it later on as lazily created. Does nothing unless an
/// observer is set.
#define IMPELLER_PIPELINE_VARIANT_WARMING_SCOPE(content_context)             \
  ::impeller::pipeline_variant_recording::Scope                              \
      impeller_pipeline_variant_warming_scope(                               \
          ::impeller::pipeline_variant_recording::Register(content_context), \
          /*warmed=*/true)

/// For code that creates variants on demand: attributes the variants created
/// until the end of the enclosing scope to `content_context`, as lazily
/// created.
#define IMPELLER_PIPELINE_VARIANT_LAZY_SCOPE(content_context) \
  ::impeller::pipeline_variant_recording::Scope               \
  impeller_pipeline_variant_lazy_scope(content_context, /*warmed=*/false)

/// For wherever a variant is added to its container: records the variant that
/// `pipeline`, a `GenericRenderPipelineHandle*`, was created for with
/// `options`.
#define IMPELLER_RECORD_PIPELINE_VARIANT(options, pipeline) \
  ::impeller::pipeline_variant_recording::Record(options, pipeline)

/// For the `ContentContext` destructor: hands every variant recorded for
/// `content_context` to the observer, along with `context`, the
/// `std::shared_ptr<Context>` it rendered with.
#define IMPELLER_REPORT_PIPELINE_VARIANTS(content_context, context) \
  ::impeller::pipeline_variant_recording::Report(content_context, context)

#else

#define IMPELLER_PIPELINE_VARIANT_WARMING_SCOPE(content_context)
#define IMPELLER_PIPELINE_VARIANT_LAZY_SCOPE(content_context)
#define IMPELLER_RECORD_PIPELINE_VARIANT(options, pipeline)
#define IMPELLER_REPORT_PIPELINE_VARIANTS(content_context, context)

#endif  // IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_PIPELINE_VARIANT_RECORDING_H_
