// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/command_buffer_mtl.h"

#include "impeller/renderer/backend/metal/render_pass_mtl.h"

namespace impeller {
namespace {

// NOLINTBEGIN(readability-identifier-naming)

// TODO(dnfield): remove this declaration when we no longer need to build on
// machines with lower SDK versions than 11.0.
#if !defined(MAC_OS_VERSION_11_0) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_VERSION_11_0
typedef NS_ENUM(NSInteger, MTLCommandEncoderErrorState) {
  MTLCommandEncoderErrorStateUnknown = 0,
  MTLCommandEncoderErrorStateCompleted = 1,
  MTLCommandEncoderErrorStateAffected = 2,
  MTLCommandEncoderErrorStatePending = 3,
  MTLCommandEncoderErrorStateFaulted = 4,
} API_AVAILABLE(macos(11.0), ios(14.0));
#endif

// NOLINTEND(readability-identifier-naming)

API_AVAILABLE(ios(14.0), macos(11.0))
NSString* MTLCommandEncoderErrorStateToString(
    MTLCommandEncoderErrorState state) {
  switch (state) {
    case MTLCommandEncoderErrorStateUnknown:
      return @"unknown";
    case MTLCommandEncoderErrorStateCompleted:
      return @"completed";
    case MTLCommandEncoderErrorStateAffected:
      return @"affected";
    case MTLCommandEncoderErrorStatePending:
      return @"pending";
    case MTLCommandEncoderErrorStateFaulted:
      return @"faulted";
  }
  return @"unknown";
}

// NOLINTBEGIN(readability-identifier-naming)

// TODO(dnfield): This can be removed when all bots have been sufficiently
// upgraded for MAC_OS_VERSION_12_0.
#if !defined(MAC_OS_VERSION_12_0) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_VERSION_12_0
constexpr int MTLCommandBufferErrorAccessRevoked = 4;
constexpr int MTLCommandBufferErrorStackOverflow = 12;
#endif

// NOLINTEND(readability-identifier-naming)

static NSString* MTLCommandBufferErrorToString(MTLCommandBufferError code) {
  switch (code) {
    case MTLCommandBufferErrorNone:
      return @"none";
    case MTLCommandBufferErrorInternal:
      return @"internal";
    case MTLCommandBufferErrorTimeout:
      return @"timeout";
    case MTLCommandBufferErrorPageFault:
      return @"page fault";
    case MTLCommandBufferErrorAccessRevoked:
      return @"access revoked / blacklisted";
    case MTLCommandBufferErrorNotPermitted:
      return @"not permitted";
    case MTLCommandBufferErrorOutOfMemory:
      return @"out of memory";
    case MTLCommandBufferErrorInvalidResource:
      return @"invalid resource";
    case MTLCommandBufferErrorMemoryless:
      return @"memory-less";
    case MTLCommandBufferErrorStackOverflow:
      return @"stack overflow";
    default:
      break;
  }

  return [NSString stringWithFormat:@"<unknown> %zu", code];
}

static void LogMTLCommandBufferErrorIfPresent(id<MTLCommandBuffer> buffer) {
  if (!buffer) {
    return;
  }

  if (buffer.status == MTLCommandBufferStatusCompleted) {
    return;
  }

  std::stringstream stream;
  stream << ">>>>>>>" << std::endl;
  stream << "Impeller command buffer could not be committed!" << std::endl;

  if (auto desc = buffer.error.localizedDescription) {
    stream << desc.UTF8String << std::endl;
  }

  if (buffer.error) {
    stream << "Domain: "
           << (buffer.error.domain.length > 0u ? buffer.error.domain.UTF8String
                                               : "<unknown>")
           << " Code: "
           << MTLCommandBufferErrorToString(
                  static_cast<MTLCommandBufferError>(buffer.error.code))
                  .UTF8String
           << std::endl;
  }

  if (@available(iOS 14.0, macOS 11.0, *)) {
    NSArray<id<MTLCommandBufferEncoderInfo>>* infos =
        buffer.error.userInfo[MTLCommandBufferEncoderInfoErrorKey];
    for (id<MTLCommandBufferEncoderInfo> info in infos) {
      stream << (info.label.length > 0u ? info.label.UTF8String
                                        : "<Unlabelled Render Pass>")
             << ": "
             << MTLCommandEncoderErrorStateToString(info.errorState).UTF8String
             << std::endl;

      auto signposts = [info.debugSignposts componentsJoinedByString:@", "];
      if (signposts.length > 0u) {
        stream << signposts.UTF8String << std::endl;
      }
    }

    for (id<MTLFunctionLog> log in buffer.logs) {
      auto desc = log.description;
      if (desc.length > 0u) {
        stream << desc.UTF8String << std::endl;
      }
    }
  }

  stream << "<<<<<<<";
  VALIDATION_LOG << stream.str();
}
}  // namespace

id<MTLCommandBuffer> CreateCommandBuffer(id<MTLCommandQueue> queue) {
  if (@available(iOS 14.0, macOS 11.0, *)) {
    auto desc = [[MTLCommandBufferDescriptor alloc] init];
    // Degrades CPU performance slightly but is well worth the cost for typical
    // Impeller workloads.
    desc.errorOptions = MTLCommandBufferErrorOptionEncoderExecutionStatus;
    return [queue commandBufferWithDescriptor:desc];
  }
  return [queue commandBuffer];
}

CommandBufferMTL::CommandBufferMTL(id<MTLCommandQueue> queue)
    : buffer_(CreateCommandBuffer(queue)) {}

CommandBufferMTL::~CommandBufferMTL() = default;

bool CommandBufferMTL::IsValid() const {
  return buffer_ != nil;
}

void CommandBufferMTL::SetLabel(const std::string& label) const {
  if (label.empty()) {
    return;
  }

  [buffer_ setLabel:@(label.data())];
}

static CommandBuffer::Status ToCommitResult(MTLCommandBufferStatus status) {
  switch (status) {
    case MTLCommandBufferStatusCompleted:
      return CommandBufferMTL::Status::kCompleted;
    case MTLCommandBufferStatusEnqueued:
      return CommandBufferMTL::Status::kPending;
    default:
      break;
  }
  return CommandBufferMTL::Status::kError;
}

bool CommandBufferMTL::SubmitCommands(CompletionCallback callback) {
  if (!IsValid()) {
    // Already committed or was never valid. Either way, this is caller error.
    if (callback) {
      callback(Status::kError);
    }
    return false;
  }

  if (callback) {
    [buffer_ addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
      LogMTLCommandBufferErrorIfPresent(buffer);
      callback(ToCommitResult(buffer.status));
    }];
  }

  [buffer_ commit];
  [buffer_ waitUntilScheduled];
  buffer_ = nil;
  return true;
}

std::shared_ptr<RenderPass> CommandBufferMTL::OnCreateRenderPass(
    RenderTarget target) const {
  if (!buffer_) {
    return nullptr;
  }

  auto pass = std::shared_ptr<RenderPassMTL>(
      new RenderPassMTL(buffer_, std::move(target)));
  if (!pass->IsValid()) {
    return nullptr;
  }

  return pass;
}

}  // namespace impeller
