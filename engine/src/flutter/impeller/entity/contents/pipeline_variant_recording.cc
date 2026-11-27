// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/pipeline_variant_recording.h"

// Everything in this file is a test diagnostic that is compiled out of
// everything but debug builds.
#if IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()

#include <atomic>
#include <optional>
#include <unordered_map>
#include <utility>

#include "impeller/base/thread.h"
#include "impeller/base/thread_safety.h"
#include "impeller/renderer/pipeline.h"

namespace impeller {

namespace {

struct Registry {
  Mutex mutex;
  PipelineVariantObserver observer IPLR_GUARDED_BY(mutex);
  /// The variants recorded so far for every `ContentContext` that was created
  /// while an observer was set and has not been destroyed yet.
  std::unordered_map<const ContentContext*,
                     std::vector<RecordedPipelineVariant>>
      variants IPLR_GUARDED_BY(mutex);
};

Registry& GetRegistry() {
  static Registry* registry = new Registry();
  return *registry;
}

/// The size of `Registry::variants`, so that recording and reporting can skip
/// taking the lock when nothing is being recorded, which is almost always.
std::atomic<size_t> gRegisteredCount = 0;

/// Set by the innermost `Scope` on this thread.
thread_local const ContentContext* tContentContext = nullptr;
thread_local bool tWarmed = false;

}  // namespace

void SetPipelineVariantObserver(PipelineVariantObserver observer) {
  Registry& registry = GetRegistry();
  Lock lock(registry.mutex);
  registry.observer = std::move(observer);
}

namespace pipeline_variant_recording {

const ContentContext* Register(const ContentContext* content_context) {
  Registry& registry = GetRegistry();
  Lock lock(registry.mutex);
  if (!registry.observer) {
    return nullptr;
  }
  // Replaces anything left behind at this address, although `Report` should
  // always have removed it.
  registry.variants[content_context].clear();
  gRegisteredCount = registry.variants.size();
  return content_context;
}

void Record(const ContentContextOptions& options,
            const GenericRenderPipelineHandle* pipeline) {
  if (tContentContext == nullptr || pipeline == nullptr ||
      gRegisteredCount == 0u) {
    return;
  }
  std::optional<PipelineDescriptor> descriptor = pipeline->GetDescriptor();
  if (!descriptor.has_value()) {
    return;
  }
  Registry& registry = GetRegistry();
  Lock lock(registry.mutex);
  auto found = registry.variants.find(tContentContext);
  if (found == registry.variants.end()) {
    return;
  }
  found->second.push_back(RecordedPipelineVariant{
      .descriptor = descriptor.value(), .options = options, .warmed = tWarmed});
}

void Report(const ContentContext* content_context,
            const std::shared_ptr<Context>& context) {
  if (gRegisteredCount == 0u) {
    return;
  }
  std::vector<RecordedPipelineVariant> variants;
  PipelineVariantObserver observer;
  {
    Registry& registry = GetRegistry();
    Lock lock(registry.mutex);
    auto found = registry.variants.find(content_context);
    if (found == registry.variants.end()) {
      return;
    }
    // Removed even if there is nothing to report, so that a `ContentContext`
    // later created at the same address starts from scratch.
    variants = std::move(found->second);
    registry.variants.erase(found);
    gRegisteredCount = registry.variants.size();
    observer = registry.observer;
  }
  // Called without the lock held so that the observer is free to do anything.
  if (observer && context && !variants.empty()) {
    observer(*context, variants);
  }
}

Scope::Scope(const ContentContext* content_context, bool warmed)
    : previous_content_context_(tContentContext), previous_warmed_(tWarmed) {
  tContentContext = content_context;
  tWarmed = warmed;
}

Scope::~Scope() {
  tContentContext = previous_content_context_;
  tWarmed = previous_warmed_;
}

}  // namespace pipeline_variant_recording

}  // namespace impeller

#endif  // IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()
