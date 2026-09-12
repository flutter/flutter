// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>
#include <utility>

#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/idle_waiter.h"
#include "impeller/entity/entity_playground.h"

namespace impeller {
namespace testing {

class MockIdleWaiter : public IdleWaiter {
 public:
  MOCK_METHOD(void, WaitIdle, (), (const, override));
};

using HostBufferTest = EntityPlayground;
INSTANTIATE_PLAYGROUND_SUITE(HostBufferTest);

TEST_P(HostBufferTest, IdleWaiter) {
  auto mock_idle_waiter = std::make_shared<MockIdleWaiter>();
  {
    auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                     mock_idle_waiter, 256);
    EXPECT_CALL(*mock_idle_waiter, WaitIdle());
  }
}

TEST_P(HostBufferTest, CanEmplace) {
  struct Length2 {
    uint8_t pad[2];
  };
  static_assert(sizeof(Length2) == 2u);

  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  for (size_t i = 0; i < 12500; i++) {
    auto view = buffer->Emplace(Length2{});
    ASSERT_TRUE(view);
    ASSERT_EQ(view.GetRange(), Range(i * sizeof(Length2), 2u));
  }
}

TEST_P(HostBufferTest, CanEmplaceWithAlignment) {
  struct Length2 {
    uint8_t pad[2];
  };
  static_assert(sizeof(Length2) == 2);
  struct alignas(16) Align16 {
    uint8_t pad[2];
  };
  static_assert(alignof(Align16) == 16);
  static_assert(sizeof(Align16) == 16);

  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);
  ASSERT_TRUE(buffer);

  {
    auto view = buffer->Emplace(Length2{});
    ASSERT_TRUE(view);
    ASSERT_EQ(view.GetRange(), Range(0u, 2u));
  }

  {
    auto view = buffer->Emplace(Align16{});
    ASSERT_TRUE(view);
    ASSERT_EQ(view.GetRange().offset, 16u);
    ASSERT_EQ(view.GetRange().length, 16u);
  }
  {
    auto view = buffer->Emplace(Length2{});
    ASSERT_TRUE(view);
    ASSERT_EQ(view.GetRange(), Range(32u, 2u));
  }

  {
    auto view = buffer->Emplace(Align16{});
    ASSERT_TRUE(view);
    ASSERT_EQ(view.GetRange().offset, 48u);
    ASSERT_EQ(view.GetRange().length, 16u);
  }
}

TEST_P(HostBufferTest, HostBufferInitialState) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  EXPECT_EQ(buffer->GetStateForTest().current_buffer, 0u);
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);
  EXPECT_EQ(buffer->GetStateForTest().total_buffer_count, 1u);
}

TEST_P(HostBufferTest, ResetIncrementsFrameCounter) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);

  buffer->Reset();
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 1u);

  buffer->Reset();
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 2u);

  buffer->Reset();
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 3u);

  buffer->Reset();
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);
}

TEST_P(HostBufferTest,
       EmplacingLargerThanBlockSizeCreatesOneOffBufferCallback) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  // Emplace an amount larger than the block size, to verify that the host
  // buffer does not create a buffer.
  auto buffer_view = buffer->Emplace(1024000 + 10, 0, [](uint8_t* data) {});

  EXPECT_EQ(buffer->GetStateForTest().current_buffer, 0u);
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);
  EXPECT_EQ(buffer->GetStateForTest().total_buffer_count, 1u);
}

TEST_P(HostBufferTest, EmplacingLargerThanBlockSizeCreatesOneOffBuffer) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  // Emplace an amount larger than the block size, to verify that the host
  // buffer does not create a buffer.
  auto buffer_view = buffer->Emplace(nullptr, 1024000 + 10, 0);

  EXPECT_EQ(buffer->GetStateForTest().current_buffer, 0u);
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);
  EXPECT_EQ(buffer->GetStateForTest().total_buffer_count, 1u);
}

TEST_P(HostBufferTest, UnusedBuffersAreDiscardedWhenResetting) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  // Emplace two large allocations to force the allocation of a second buffer.
  auto buffer_view_a = buffer->Emplace(1020000, 0, [](uint8_t* data) {});
  auto buffer_view_b = buffer->Emplace(1020000, 0, [](uint8_t* data) {});

  EXPECT_EQ(buffer->GetStateForTest().current_buffer, 1u);
  EXPECT_EQ(buffer->GetStateForTest().total_buffer_count, 2u);
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);

  // Reset until we get back to this frame.
  for (auto i = 0; i < 4; i++) {
    buffer->Reset();
  }

  EXPECT_EQ(buffer->GetStateForTest().current_buffer, 0u);
  EXPECT_EQ(buffer->GetStateForTest().total_buffer_count, 2u);
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);

  // Now when we reset, the buffer should get dropped.
  // Reset until we get back to this frame.
  for (auto i = 0; i < 4; i++) {
    buffer->Reset();
  }

  EXPECT_EQ(buffer->GetStateForTest().current_buffer, 0u);
  EXPECT_EQ(buffer->GetStateForTest().total_buffer_count, 1u);
  EXPECT_EQ(buffer->GetStateForTest().current_frame, 0u);
}

TEST_P(HostBufferTest, EmplaceWithProcIsAligned) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  BufferView view = buffer->Emplace(std::array<char, 21>());
  EXPECT_EQ(view.GetRange(), Range(0, 21));

  view = buffer->Emplace(64, 16, [](uint8_t*) {});
  EXPECT_EQ(view.GetRange(), Range(32, 64));
}

static constexpr const size_t kMagicFailingAllocation = 1024000 * 2;

class FailingAllocator : public Allocator {
 public:
  explicit FailingAllocator(std::shared_ptr<Allocator> delegate)
      : Allocator(), delegate_(std::move(delegate)) {}

  ~FailingAllocator() = default;

  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) {
    // Magic number used in test below to trigger failure.
    if (desc.size == kMagicFailingAllocation) {
      return nullptr;
    }
    return delegate_->CreateBuffer(desc);
  }

  std::shared_ptr<Texture> OnCreateTexture(const TextureDescriptor& desc,
                                           bool threadsafe) {
    return delegate_->CreateTexture(desc);
  }

  ISize GetMaxTextureSizeSupported() const override {
    return delegate_->GetMaxTextureSizeSupported();
  }

 private:
  std::shared_ptr<Allocator> delegate_;
};

TEST(GpuSubmissionTrackerTest, WatermarkHandlesOutOfOrderCompletion) {
  GpuSubmissionTracker tracker;
  EXPECT_EQ(tracker.CompletedThrough(), 0u);
  uint64_t a = tracker.RecordSubmission();
  uint64_t b = tracker.RecordSubmission();
  uint64_t c = tracker.RecordSubmission();
  EXPECT_EQ(tracker.LatestSubmission(), c);

  tracker.RecordCompletion(b);
  EXPECT_EQ(tracker.CompletedThrough(), 0u);
  tracker.RecordCompletion(a);
  EXPECT_EQ(tracker.CompletedThrough(), b);
  tracker.RecordCompletion(c);
  EXPECT_EQ(tracker.CompletedThrough(), c);
}

TEST_P(HostBufferTest, PendingEntriesAreReplacedNotReused) {
  auto tracker = std::make_shared<GpuSubmissionTracker>();
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256, tracker);

  // Write to the first arena entry and pretend its GPU work never completes.
  const DeviceBuffer* first_entry = buffer->EmplaceUniform(0.0f).GetBuffer();
  uint64_t pending = tracker->RecordSubmission();
  for (size_t i = 0; i < kHostBufferArenaSize; i++) {
    buffer->Reset();
  }

  // The entry must be replaced with a fresh allocation.
  EXPECT_NE(buffer->EmplaceUniform(0.0f).GetBuffer(), first_entry);

  // Once completed, entries are reused in place.
  tracker->RecordCompletion(pending);
  const DeviceBuffer* second_entry = buffer->EmplaceUniform(0.0f).GetBuffer();
  for (size_t i = 0; i < kHostBufferArenaSize; i++) {
    buffer->Reset();
  }
  EXPECT_EQ(buffer->EmplaceUniform(0.0f).GetBuffer(), second_entry);
}

TEST_P(HostBufferTest, CompletedEntriesAreReusedWithoutTrackerChurn) {
  auto tracker = std::make_shared<GpuSubmissionTracker>();
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256, tracker);

  // Simulate frames whose GPU work completes promptly. Entries must be
  // reused, not replaced.
  const DeviceBuffer* entry = buffer->EmplaceUniform(0.0f).GetBuffer();
  for (size_t i = 0; i < kHostBufferArenaSize * 3; i++) {
    tracker->RecordCompletion(tracker->RecordSubmission());
    buffer->Reset();
  }
  EXPECT_EQ(buffer->EmplaceUniform(0.0f).GetBuffer(), entry);
}

TEST_P(HostBufferTest, EmplaceWithFailingAllocationDoesntCrash) {
  ScopedValidationDisable disable;
  std::shared_ptr<FailingAllocator> allocator =
      std::make_shared<FailingAllocator>(GetContext()->GetResourceAllocator());
  auto buffer =
      HostBuffer::Create(allocator, GetContext()->GetIdleWaiter(), 256);

  auto view = buffer->Emplace(nullptr, kMagicFailingAllocation, 0);

  EXPECT_EQ(view.GetBuffer(), nullptr);
  EXPECT_EQ(view.GetRange().offset, 0u);
  EXPECT_EQ(view.GetRange().length, 0u);
}

TEST_P(HostBufferTest, FastPathProducesCorrectRangesAndContent) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  struct alignas(16) Align16 {
    uint8_t data[16];
  };

  std::vector<BufferView> views;
  for (size_t i = 0; i < 64; i++) {
    Align16 block;
    std::fill(block.data, block.data + 16, static_cast<uint8_t>(i));
    views.push_back(buffer->Emplace(block));
  }
  for (size_t i = 0; i < views.size(); i++) {
    ASSERT_TRUE(views[i]);
    ASSERT_EQ(views[i].GetRange(), Range(i * 16u, 16u));
    const uint8_t* contents =
        views[i].GetBuffer()->OnGetContents() + views[i].GetRange().offset;
    for (size_t j = 0; j < 16; j++) {
      EXPECT_EQ(contents[j], static_cast<uint8_t>(i));
    }
  }
}

TEST_P(HostBufferTest, FastPathHandlesBufferRollover) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  const size_t big_size = kAllocatorBlockSize - 4096;
  std::vector<uint8_t> big(big_size, 0xAB);
  auto first = buffer->Emplace(big.data(), big.size(), 0);
  ASSERT_TRUE(first);
  ASSERT_EQ(first.GetRange().offset, 0u);

  // The remaining 4096 bytes can't hold this allocation, so it must move to
  // a fresh buffer at offset 0.
  std::vector<uint8_t> next(8192, 0xCD);
  auto second = buffer->Emplace(next.data(), next.size(), 0);
  ASSERT_TRUE(second);
  ASSERT_EQ(second.GetRange().offset, 0u);
  EXPECT_NE(first.GetBuffer(), second.GetBuffer());
  const uint8_t* contents =
      second.GetBuffer()->OnGetContents() + second.GetRange().offset;
  EXPECT_EQ(std::vector<uint8_t>(contents, contents + next.size()), next);
}

TEST_P(HostBufferTest, FastPathResetDoesNotClobberPreviousFrame) {
  auto buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                   GetContext()->GetIdleWaiter(), 256);

  std::vector<uint8_t> first_bytes(64, 0xAA);
  auto first = buffer->Emplace(first_bytes.data(), first_bytes.size(), 0);
  ASSERT_TRUE(first);
  const DeviceBuffer* first_buffer = first.GetBuffer();
  const size_t first_offset = first.GetRange().offset;

  buffer->Reset();

  std::vector<uint8_t> second_bytes(64, 0xBB);
  auto second = buffer->Emplace(second_bytes.data(), second_bytes.size(), 0);
  ASSERT_TRUE(second);

  const uint8_t* previous = first_buffer->OnGetContents() + first_offset;
  EXPECT_EQ(std::vector<uint8_t>(previous, previous + first_bytes.size()),
            first_bytes);

  const uint8_t* current =
      second.GetBuffer()->OnGetContents() + second.GetRange().offset;
  EXPECT_EQ(std::vector<uint8_t>(current, current + second_bytes.size()),
            second_bytes);
}

}  // namespace  testing
}  // namespace impeller
