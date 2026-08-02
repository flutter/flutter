// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/timestamp_query_pool_mtl.h"

#include "impeller/base/validation.h"

namespace impeller {

API_AVAILABLE(ios(14.0), macos(11.0), tvos(14.0))
static id<MTLCounterSet> FindTimestampCounterSet(id<MTLDevice> device) {
  for (id<MTLCounterSet> counter_set in device.counterSets) {
    if ([counter_set.name isEqualToString:MTLCommonCounterSetTimestamp]) {
      return counter_set;
    }
  }
  return nil;
}

bool TimestampQueryPoolMTL::IsSupported(id<MTLDevice> device) {
  if (device == nil) {
    return false;
  }
  if (@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)) {
    return
        [device
            supportsCounterSampling:MTLCounterSamplingPointAtStageBoundary] &&
        FindTimestampCounterSet(device) != nil;
  }
  return false;
}

std::shared_ptr<TimestampQueryPoolMTL> TimestampQueryPoolMTL::Create(
    id<MTLDevice> device,
    size_t query_count) {
  if (query_count == 0u || !IsSupported(device)) {
    return nullptr;
  }
  if (@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)) {
    MTLCounterSampleBufferDescriptor* descriptor =
        [[MTLCounterSampleBufferDescriptor alloc] init];
    descriptor.counterSet = FindTimestampCounterSet(device);
    descriptor.sampleCount = query_count;
    descriptor.storageMode = MTLStorageModeShared;

    NSError* error = nil;
    id<MTLCounterSampleBuffer> buffer =
        [device newCounterSampleBufferWithDescriptor:descriptor error:&error];
    if (buffer == nil) {
      VALIDATION_LOG << "Could not create timestamp counter sample buffer: "
                     << (error != nil ? error.localizedDescription.UTF8String
                                      : "unknown error");
      return nullptr;
    }
    return std::shared_ptr<TimestampQueryPoolMTL>(
        new TimestampQueryPoolMTL(device, buffer, query_count));
  }
  return nullptr;
}

TimestampQueryPoolMTL::TimestampQueryPoolMTL(id<MTLDevice> device,
                                             id buffer,
                                             size_t query_count)
    : TimestampQueryPool(query_count), device_(device), buffer_(buffer) {
  if (@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)) {
    MTLTimestamp cpu = 0;
    MTLTimestamp gpu = 0;
    [device_ sampleTimestamps:&cpu gpuTimestamp:&gpu];
    base_cpu_timestamp_ = cpu;
    base_gpu_timestamp_ = gpu;
  }
}

TimestampQueryPoolMTL::~TimestampQueryPoolMTL() = default;

void TimestampQueryPoolMTL::AttachTo(
    MTLRenderPassDescriptor* descriptor,
    std::optional<size_t> beginning_of_pass_write_index,
    std::optional<size_t> end_of_pass_write_index) const {
  if (@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)) {
    MTLRenderPassSampleBufferAttachmentDescriptor* attachment =
        descriptor.sampleBufferAttachments[0];
    attachment.sampleBuffer = buffer_;
    // The vertex stage starts the pass and the fragment stage ends it, so
    // these two points bracket the pass's execution on the GPU.
    attachment.startOfVertexSampleIndex =
        beginning_of_pass_write_index.value_or(MTLCounterDontSample);
    attachment.endOfVertexSampleIndex = MTLCounterDontSample;
    attachment.startOfFragmentSampleIndex = MTLCounterDontSample;
    attachment.endOfFragmentSampleIndex =
        end_of_pass_write_index.value_or(MTLCounterDontSample);
  }
}

TimestampQueryResults TimestampQueryPoolMTL::Resolve() const {
  TimestampQueryResults results;
  results.timestamps.resize(query_count_);

  if (@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)) {
    id<MTLCounterSampleBuffer> buffer = buffer_;
    NSData* data = [buffer resolveCounterRange:NSMakeRange(0, query_count_)];
    if (data == nil ||
        data.length < query_count_ * sizeof(MTLCounterResultTimestamp)) {
      return results;
    }

    // GPU ticks are not nanoseconds and the ratio is not fixed, so it is
    // derived from two correlated samples. The CPU side of
    // `sampleTimestamps:gpuTimestamp:` is already in nanoseconds.
    MTLTimestamp cpu_now = 0;
    MTLTimestamp gpu_now = 0;
    [device_ sampleTimestamps:&cpu_now gpuTimestamp:&gpu_now];
    double nanoseconds_per_tick = 1.0;
    if (gpu_now > base_gpu_timestamp_ && cpu_now > base_cpu_timestamp_) {
      nanoseconds_per_tick =
          static_cast<double>(cpu_now - base_cpu_timestamp_) /
          static_cast<double>(gpu_now - base_gpu_timestamp_);
    }

    const MTLCounterResultTimestamp* samples =
        static_cast<const MTLCounterResultTimestamp*>(data.bytes);
    for (size_t i = 0u; i < query_count_; i++) {
      const MTLTimestamp sample = samples[i].timestamp;
      if (sample == MTLCounterErrorValue || sample < base_gpu_timestamp_) {
        continue;
      }
      // Rebased onto the CPU nanosecond clock so the origin stays put across
      // resolves. Only differences between timestamps are meaningful.
      results.timestamps[i] =
          base_cpu_timestamp_ +
          static_cast<uint64_t>(
              static_cast<double>(sample - base_gpu_timestamp_) *
              nanoseconds_per_tick);
    }
  }
  return results;
}

}  // namespace impeller
