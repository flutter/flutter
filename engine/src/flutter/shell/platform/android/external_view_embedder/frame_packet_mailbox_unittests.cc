// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/external_view_embedder/frame_packet_mailbox.h"

#include <cstdint>
#include <memory>
#include <utility>
#include <vector>

#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

using ::testing::_;

constexpr intptr_t kReaderToken = 0x5001;
constexpr intptr_t kFirstImageToken = 0x6001;
constexpr intptr_t kSecondImageToken = 0x6002;
constexpr intptr_t kThirdImageToken = 0x6003;
constexpr uint64_t kEpochOne = 1;
constexpr uint64_t kEpochTwo = 2;

std::unique_ptr<FramePacket> MakePacketWithBgImage(
    const std::shared_ptr<HybridReaderHandle>& reader_handle,
    intptr_t image_token,
    uint64_t epoch) {
  auto packet = std::make_unique<FramePacket>();
  packet->hc_epoch = epoch;
  packet->background_image = AcquiredHybridImage(
      reader_handle, HybridJavaGlobalRef::ForTest(image_token));
  return packet;
}

}  // namespace

TEST(FramePacketMailboxTest,
     CoalescesDrainScheduleAndReturnsSupersededPacketForReleaseOutsideLock) {
  auto jni_mock = std::make_shared<JNIMock>();
  std::vector<intptr_t> released_images;
  EXPECT_CALL(*jni_mock, ReleaseHybridImage(_, _))
      .WillRepeatedly(
          [&](const HybridJavaGlobalRef& reader, HybridJavaGlobalRef image) {
            EXPECT_EQ(reader.token(), kReaderToken);
            released_images.push_back(image.token());
          });
  EXPECT_CALL(*jni_mock, RetireHybridImageReader(_)).Times(1);

  auto reader_handle = std::make_shared<HybridReaderHandle>(
      HybridJavaGlobalRef::ForTest(kReaderToken), jni_mock);

  FramePacketMailbox mailbox;

  // First publish schedules a drain task and supersedes nothing.
  FramePacketMailbox::PublishResult r1 = mailbox.Publish(
      MakePacketWithBgImage(reader_handle, kFirstImageToken, kEpochOne));
  EXPECT_TRUE(r1.accepted);
  EXPECT_TRUE(r1.schedule_drain);
  EXPECT_EQ(r1.superseded_packet, nullptr);
  EXPECT_TRUE(released_images.empty());

  // Second publish before Take() coalesces drain_scheduled_ (schedule_drain ==
  // false) and returns the superseded packet without releasing under mutex_.
  FramePacketMailbox::PublishResult r2 = mailbox.Publish(
      MakePacketWithBgImage(reader_handle, kSecondImageToken, kEpochTwo));
  EXPECT_TRUE(r2.accepted);
  EXPECT_FALSE(r2.schedule_drain);
  ASSERT_NE(r2.superseded_packet, nullptr);
  EXPECT_EQ(r2.superseded_packet->hc_epoch, kEpochOne);
  // Not yet released until caller resets `r2.superseded_packet`.
  EXPECT_TRUE(released_images.empty());
  r2.superseded_packet.reset();
  ASSERT_EQ(released_images.size(), 1u);
  EXPECT_EQ(released_images[0], kFirstImageToken);

  // Take() returns the latest packet and re-arms drain scheduling.
  std::unique_ptr<FramePacket> drained = mailbox.Take();
  ASSERT_NE(drained, nullptr);
  EXPECT_EQ(drained->hc_epoch, kEpochTwo);

  // Handing the image via TakeImage() prevents automatic ReleaseHybridImage.
  HybridJavaGlobalRef handed_to_java = drained->background_image.TakeImage();
  EXPECT_EQ(handed_to_java.token(), kSecondImageToken);
  drained.reset();
  EXPECT_EQ(released_images.size(), 1u);

  // Next Publish after Take() schedules a fresh drain task.
  FramePacketMailbox::PublishResult r3 = mailbox.Publish(
      MakePacketWithBgImage(reader_handle, kThirdImageToken, kEpochTwo));
  EXPECT_TRUE(r3.accepted);
  EXPECT_TRUE(r3.schedule_drain);
  std::unique_ptr<FramePacket> drained3 = mailbox.Take();
  ASSERT_NE(drained3, nullptr);
  drained3.reset();
  ASSERT_EQ(released_images.size(), 2u);
  EXPECT_EQ(released_images[1], kThirdImageToken);
}

TEST(FramePacketMailboxTest,
     ResetAndTakeKeepsMailboxOpenWhileCloseAndTakeRejectsFuturePublishes) {
  auto jni_mock = std::make_shared<JNIMock>();
  std::vector<intptr_t> released_images;
  EXPECT_CALL(*jni_mock, ReleaseHybridImage(_, _))
      .WillRepeatedly(
          [&](const HybridJavaGlobalRef&, HybridJavaGlobalRef image) {
            released_images.push_back(image.token());
          });
  EXPECT_CALL(*jni_mock, RetireHybridImageReader(_)).Times(1);

  auto reader_handle = std::make_shared<HybridReaderHandle>(
      HybridJavaGlobalRef::ForTest(kReaderToken), jni_mock);

  FramePacketMailbox mailbox;

  FramePacketMailbox::PublishResult r1 = mailbox.Publish(
      MakePacketWithBgImage(reader_handle, kFirstImageToken, kEpochOne));
  EXPECT_TRUE(r1.accepted);
  EXPECT_TRUE(r1.schedule_drain);

  // ResetAndTake() clears pending packet and resets drain_scheduled_, but keeps
  // the mailbox open for subsequent sessions (e.g., after Teardown()).
  std::unique_ptr<FramePacket> reset_taken = mailbox.ResetAndTake();
  ASSERT_NE(reset_taken, nullptr);
  EXPECT_FALSE(mailbox.IsClosed());
  reset_taken.reset();
  ASSERT_EQ(released_images.size(), 1u);
  EXPECT_EQ(released_images[0], kFirstImageToken);

  // Publishing after ResetAndTake() succeeds and schedules drain again.
  FramePacketMailbox::PublishResult r2 = mailbox.Publish(
      MakePacketWithBgImage(reader_handle, kSecondImageToken, kEpochTwo));
  EXPECT_TRUE(r2.accepted);
  EXPECT_TRUE(r2.schedule_drain);

  // CloseAndTake() permanently closes the mailbox and returns pending packet.
  std::unique_ptr<FramePacket> closed_taken = mailbox.CloseAndTake();
  ASSERT_NE(closed_taken, nullptr);
  EXPECT_TRUE(mailbox.IsClosed());
  closed_taken.reset();
  ASSERT_EQ(released_images.size(), 2u);
  EXPECT_EQ(released_images[1], kSecondImageToken);

  // Publishing to a closed mailbox rejects and immediately releases the packet.
  FramePacketMailbox::PublishResult r3 = mailbox.Publish(
      MakePacketWithBgImage(reader_handle, kThirdImageToken, kEpochTwo));
  EXPECT_FALSE(r3.accepted);
  EXPECT_FALSE(r3.schedule_drain);
  ASSERT_EQ(released_images.size(), 3u);
  EXPECT_EQ(released_images[2], kThirdImageToken);
}

}  // namespace testing
}  // namespace flutter
