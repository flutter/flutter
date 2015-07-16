// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/common_decoder.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

TEST(CommonDecoderBucket, Basic) {
  CommonDecoder::Bucket bucket;
  EXPECT_EQ(0u, bucket.size());
  EXPECT_TRUE(NULL == bucket.GetData(0, 0));
}

TEST(CommonDecoderBucket, Size) {
  CommonDecoder::Bucket bucket;
  bucket.SetSize(24);
  EXPECT_EQ(24u, bucket.size());
  bucket.SetSize(12);
  EXPECT_EQ(12u, bucket.size());
}

TEST(CommonDecoderBucket, GetData) {
  CommonDecoder::Bucket bucket;

  bucket.SetSize(24);
  EXPECT_TRUE(NULL != bucket.GetData(0, 0));
  EXPECT_TRUE(NULL != bucket.GetData(24, 0));
  EXPECT_TRUE(NULL == bucket.GetData(25, 0));
  EXPECT_TRUE(NULL != bucket.GetData(0, 24));
  EXPECT_TRUE(NULL == bucket.GetData(0, 25));
  bucket.SetSize(23);
  EXPECT_TRUE(NULL == bucket.GetData(0, 24));
}

TEST(CommonDecoderBucket, SetData) {
  CommonDecoder::Bucket bucket;
  static const char data[] = "testing";

  bucket.SetSize(10);
  EXPECT_TRUE(bucket.SetData(data, 0, sizeof(data)));
  EXPECT_EQ(0, memcmp(data, bucket.GetData(0, sizeof(data)), sizeof(data)));
  EXPECT_TRUE(bucket.SetData(data, 2, sizeof(data)));
  EXPECT_EQ(0, memcmp(data, bucket.GetData(2, sizeof(data)), sizeof(data)));
  EXPECT_FALSE(bucket.SetData(data, 0, sizeof(data) * 2));
  EXPECT_FALSE(bucket.SetData(data, 5, sizeof(data)));
}

class TestCommonDecoder : public CommonDecoder {
 public:
  // Overridden from AsyncAPIInterface
  const char* GetCommandName(unsigned int command_id) const override {
    return GetCommonCommandName(static_cast<cmd::CommandId>(command_id));
  }

  // Overridden from AsyncAPIInterface
  error::Error DoCommand(unsigned int command,
                         unsigned int arg_count,
                         const void* cmd_data) override {
    return DoCommonCommand(command, arg_count, cmd_data);
  }

  CommonDecoder::Bucket* GetBucket(uint32 id) const {
    return CommonDecoder::GetBucket(id);
  }
};

class MockCommandBufferEngine : public CommandBufferEngine {
 public:
  static const int32 kStartValidShmId = 1;
  static const int32 kValidShmId = 2;
  static const int32 kInvalidShmId = 3;
  static const size_t kBufferSize = 1024;
  static const int32 kValidOffset = kBufferSize / 2;
  static const int32 kInvalidOffset = kBufferSize;

  MockCommandBufferEngine()
      : CommandBufferEngine(),
        token_(),
        get_offset_(0) {
    scoped_ptr<base::SharedMemory> shared_memory(new base::SharedMemory());
    shared_memory->CreateAndMapAnonymous(kBufferSize);
    buffer_ = MakeBufferFromSharedMemory(shared_memory.Pass(), kBufferSize);
  }

  // Overridden from CommandBufferEngine.
  scoped_refptr<gpu::Buffer> GetSharedMemoryBuffer(int32 shm_id) override {
    if (IsValidSharedMemoryId(shm_id))
      return buffer_;
    return NULL;
  }

  template <typename T>
  T GetSharedMemoryAs(uint32 offset) {
    DCHECK_LT(offset, kBufferSize);
    int8* buffer_memory = static_cast<int8*>(buffer_->memory());
    return reinterpret_cast<T>(&buffer_memory[offset]);
  }

  int32 GetSharedMemoryOffset(const void* memory) {
    int8* buffer_memory = static_cast<int8*>(buffer_->memory());
    ptrdiff_t offset = static_cast<const int8*>(memory) - &buffer_memory[0];
    DCHECK_GE(offset, 0);
    DCHECK_LT(static_cast<size_t>(offset), kBufferSize);
    return static_cast<int32>(offset);
  }

  // Overridden from CommandBufferEngine.
  void set_token(int32 token) override { token_ = token; }

  int32 token() const {
    return token_;
  }

  // Overridden from CommandBufferEngine.
  bool SetGetBuffer(int32 transfer_buffer_id) override {
    NOTREACHED();
    return false;
  }

  // Overridden from CommandBufferEngine.
  bool SetGetOffset(int32 offset) override {
    if (static_cast<size_t>(offset) < kBufferSize) {
      get_offset_ = offset;
      return true;
    }
    return false;
  }

  // Overridden from CommandBufferEngine.
  int32 GetGetOffset() override { return get_offset_; }

 private:
  bool IsValidSharedMemoryId(int32 shm_id) {
    return shm_id == kValidShmId || shm_id == kStartValidShmId;
  }

  scoped_refptr<gpu::Buffer> buffer_;
  int32 token_;
  int32 get_offset_;
};

const int32 MockCommandBufferEngine::kStartValidShmId;
const int32 MockCommandBufferEngine::kValidShmId;
const int32 MockCommandBufferEngine::kInvalidShmId;
const size_t MockCommandBufferEngine::kBufferSize;
const int32 MockCommandBufferEngine::kValidOffset;
const int32 MockCommandBufferEngine::kInvalidOffset;

class CommonDecoderTest : public testing::Test {
 protected:
  void SetUp() override { decoder_.set_engine(&engine_); }

  void TearDown() override {}

  template <typename T>
  error::Error ExecuteCmd(const T& cmd) {
    static_assert(T::kArgFlags == cmd::kFixed,
                  "T::kArgFlags should equal cmd::kFixed");
    return decoder_.DoCommands(
        1, (const void*)&cmd, ComputeNumEntries(sizeof(cmd)), 0);
  }

  template <typename T>
  error::Error ExecuteImmediateCmd(const T& cmd, size_t data_size) {
    static_assert(T::kArgFlags == cmd::kAtLeastN,
                  "T::kArgFlags should equal cmd::kAtLeastN");
    return decoder_.DoCommands(
        1, (const void*)&cmd, ComputeNumEntries(sizeof(cmd) + data_size), 0);
  }

  MockCommandBufferEngine engine_;
  TestCommonDecoder decoder_;
};

TEST_F(CommonDecoderTest, Initialize) {
  EXPECT_EQ(0, engine_.GetGetOffset());
}

TEST_F(CommonDecoderTest, DoCommonCommandInvalidCommand) {
  EXPECT_EQ(error::kUnknownCommand, decoder_.DoCommand(999999, 0, NULL));
}

TEST_F(CommonDecoderTest, HandleNoop) {
  cmd::Noop cmd;
  const uint32 kSkipCount = 5;
  cmd.Init(kSkipCount);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(
                cmd, kSkipCount * kCommandBufferEntrySize));
  const uint32 kSkipCount2 = 1;
  cmd.Init(kSkipCount2);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(
                cmd, kSkipCount2 * kCommandBufferEntrySize));
}

TEST_F(CommonDecoderTest, SetToken) {
  cmd::SetToken cmd;
  const int32 kTokenId = 123;
  EXPECT_EQ(0, engine_.token());
  cmd.Init(kTokenId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kTokenId, engine_.token());
}

TEST_F(CommonDecoderTest, SetBucketSize) {
  cmd::SetBucketSize cmd;
  const uint32 kBucketId = 123;
  const uint32 kBucketLength1 = 1234;
  const uint32 kBucketLength2 = 78;
  // Check the bucket does not exist.
  EXPECT_TRUE(NULL == decoder_.GetBucket(kBucketId));
  // Check we can create one.
  cmd.Init(kBucketId, kBucketLength1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  CommonDecoder::Bucket* bucket;
  bucket = decoder_.GetBucket(kBucketId);
  EXPECT_TRUE(NULL != bucket);
  EXPECT_EQ(kBucketLength1, bucket->size());
  // Check we can change it.
  cmd.Init(kBucketId, kBucketLength2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  bucket = decoder_.GetBucket(kBucketId);
  EXPECT_TRUE(NULL != bucket);
  EXPECT_EQ(kBucketLength2, bucket->size());
  // Check we can delete it.
  cmd.Init(kBucketId, 0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  bucket = decoder_.GetBucket(kBucketId);
  EXPECT_EQ(0u, bucket->size());
}

TEST_F(CommonDecoderTest, SetBucketData) {
  cmd::SetBucketSize size_cmd;
  cmd::SetBucketData cmd;

  static const char kData[] = "1234567890123456789";

  const uint32 kBucketId = 123;
  const uint32 kInvalidBucketId = 124;

  size_cmd.Init(kBucketId, sizeof(kData));
  EXPECT_EQ(error::kNoError, ExecuteCmd(size_cmd));
  CommonDecoder::Bucket* bucket = decoder_.GetBucket(kBucketId);
  // Check the data is not there.
  EXPECT_NE(0, memcmp(bucket->GetData(0, sizeof(kData)), kData, sizeof(kData)));

  // Check we can set it.
  const uint32 kSomeOffsetInSharedMemory = 50;
  void* memory = engine_.GetSharedMemoryAs<void*>(kSomeOffsetInSharedMemory);
  memcpy(memory, kData, sizeof(kData));
  cmd.Init(kBucketId, 0, sizeof(kData),
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, memcmp(bucket->GetData(0, sizeof(kData)), kData, sizeof(kData)));

  // Check we can set it partially.
  static const char kData2[] = "ABCEDFG";
  const uint32 kSomeOffsetInBucket = 5;
  memcpy(memory, kData2, sizeof(kData2));
  cmd.Init(kBucketId, kSomeOffsetInBucket, sizeof(kData2),
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, memcmp(bucket->GetData(kSomeOffsetInBucket, sizeof(kData2)),
                      kData2, sizeof(kData2)));
  const char* bucket_data = bucket->GetDataAs<const char*>(0, sizeof(kData));
  // Check that nothing was affected outside of updated area.
  EXPECT_EQ(kData[kSomeOffsetInBucket - 1],
            bucket_data[kSomeOffsetInBucket - 1]);
  EXPECT_EQ(kData[kSomeOffsetInBucket + sizeof(kData2)],
            bucket_data[kSomeOffsetInBucket + sizeof(kData2)]);

  // Check that it fails if the bucket_id is invalid
  cmd.Init(kInvalidBucketId, kSomeOffsetInBucket, sizeof(kData2),
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the offset is out of range.
  cmd.Init(kBucketId, bucket->size(), 1,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the size is out of range.
  cmd.Init(kBucketId, 0, bucket->size() + 1,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_F(CommonDecoderTest, SetBucketDataImmediate) {
  cmd::SetBucketSize size_cmd;
  int8 buffer[1024];
  cmd::SetBucketDataImmediate& cmd =
      *reinterpret_cast<cmd::SetBucketDataImmediate*>(&buffer);

  static const char kData[] = "1234567890123456789";

  const uint32 kBucketId = 123;
  const uint32 kInvalidBucketId = 124;

  size_cmd.Init(kBucketId, sizeof(kData));
  EXPECT_EQ(error::kNoError, ExecuteCmd(size_cmd));
  CommonDecoder::Bucket* bucket = decoder_.GetBucket(kBucketId);
  // Check the data is not there.
  EXPECT_NE(0, memcmp(bucket->GetData(0, sizeof(kData)), kData, sizeof(kData)));

  // Check we can set it.
  void* memory = &buffer[0] + sizeof(cmd);
  memcpy(memory, kData, sizeof(kData));
  cmd.Init(kBucketId, 0, sizeof(kData));
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(kData)));
  EXPECT_EQ(0, memcmp(bucket->GetData(0, sizeof(kData)), kData, sizeof(kData)));

  // Check we can set it partially.
  static const char kData2[] = "ABCEDFG";
  const uint32 kSomeOffsetInBucket = 5;
  memcpy(memory, kData2, sizeof(kData2));
  cmd.Init(kBucketId, kSomeOffsetInBucket, sizeof(kData2));
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(kData2)));
  EXPECT_EQ(0, memcmp(bucket->GetData(kSomeOffsetInBucket, sizeof(kData2)),
                      kData2, sizeof(kData2)));
  const char* bucket_data = bucket->GetDataAs<const char*>(0, sizeof(kData));
  // Check that nothing was affected outside of updated area.
  EXPECT_EQ(kData[kSomeOffsetInBucket - 1],
            bucket_data[kSomeOffsetInBucket - 1]);
  EXPECT_EQ(kData[kSomeOffsetInBucket + sizeof(kData2)],
            bucket_data[kSomeOffsetInBucket + sizeof(kData2)]);

  // Check that it fails if the bucket_id is invalid
  cmd.Init(kInvalidBucketId, kSomeOffsetInBucket, sizeof(kData2));
  EXPECT_NE(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(kData2)));

  // Check that it fails if the offset is out of range.
  cmd.Init(kBucketId, bucket->size(), 1);
  EXPECT_NE(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(kData2)));

  // Check that it fails if the size is out of range.
  cmd.Init(kBucketId, 0, bucket->size() + 1);
  EXPECT_NE(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(kData2)));
}

TEST_F(CommonDecoderTest, GetBucketStart) {
  cmd::SetBucketSize size_cmd;
  cmd::SetBucketData set_cmd;
  cmd::GetBucketStart cmd;

  static const char kData[] = "1234567890123456789";
  static const char zero[sizeof(kData)] = { 0, };

  const uint32 kBucketSize = sizeof(kData);
  const uint32 kBucketId = 123;
  const uint32 kInvalidBucketId = 124;

  // Put data in the bucket.
  size_cmd.Init(kBucketId, sizeof(kData));
  EXPECT_EQ(error::kNoError, ExecuteCmd(size_cmd));
  const uint32 kSomeOffsetInSharedMemory = 50;
  uint8* start = engine_.GetSharedMemoryAs<uint8*>(kSomeOffsetInSharedMemory);
  memcpy(start, kData, sizeof(kData));
  set_cmd.Init(kBucketId, 0, sizeof(kData),
               MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(set_cmd));

  // Check that the size is correct with no data buffer.
  uint32* memory =
      engine_.GetSharedMemoryAs<uint32*>(kSomeOffsetInSharedMemory);
  *memory = 0x0;
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           0, 0, 0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kBucketSize, *memory);

  // Check that the data is copied with data buffer.
  const uint32 kDataOffsetInSharedMemory = 54;
  uint8* data = engine_.GetSharedMemoryAs<uint8*>(kDataOffsetInSharedMemory);
  *memory = 0x0;
  memset(data, 0, sizeof(kData));
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           kBucketSize, MockCommandBufferEngine::kValidShmId,
           kDataOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kBucketSize, *memory);
  EXPECT_EQ(0, memcmp(data, kData, kBucketSize));

  // Check that we can get a piece.
  *memory = 0x0;
  memset(data, 0, sizeof(kData));
  const uint32 kPieceSize = kBucketSize / 2;
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           kPieceSize, MockCommandBufferEngine::kValidShmId,
           kDataOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kBucketSize, *memory);
  EXPECT_EQ(0, memcmp(data, kData, kPieceSize));
  EXPECT_EQ(0, memcmp(data + kPieceSize, zero, sizeof(kData) - kPieceSize));

  // Check that it fails if the result_id is invalid
  cmd.Init(kInvalidBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           0, 0, 0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the data_id is invalid
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           1, MockCommandBufferEngine::kInvalidShmId, 0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the data_size is invalid
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           1, 0, 0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           MockCommandBufferEngine::kBufferSize + 1,
           MockCommandBufferEngine::kValidShmId, 0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the data_offset is invalid
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           0, 0, 1);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           MockCommandBufferEngine::kBufferSize,
           MockCommandBufferEngine::kValidShmId, 1);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the result size is not set to zero
  *memory = 0x1;
  cmd.Init(kBucketId,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory,
           0, 0, 0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_F(CommonDecoderTest, GetBucketData) {
  cmd::SetBucketSize size_cmd;
  cmd::SetBucketData set_cmd;
  cmd::GetBucketData cmd;

  static const char kData[] = "1234567890123456789";
  static const char zero[sizeof(kData)] = { 0, };

  const uint32 kBucketId = 123;
  const uint32 kInvalidBucketId = 124;

  size_cmd.Init(kBucketId, sizeof(kData));
  EXPECT_EQ(error::kNoError, ExecuteCmd(size_cmd));
  const uint32 kSomeOffsetInSharedMemory = 50;
  uint8* memory = engine_.GetSharedMemoryAs<uint8*>(kSomeOffsetInSharedMemory);
  memcpy(memory, kData, sizeof(kData));
  set_cmd.Init(kBucketId, 0, sizeof(kData),
               MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(set_cmd));

  // Check we can get the whole thing.
  memset(memory, 0, sizeof(kData));
  cmd.Init(kBucketId, 0, sizeof(kData),
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, memcmp(memory, kData, sizeof(kData)));

  // Check we can get a piece.
  const uint32 kSomeOffsetInBucket = 5;
  const uint32 kLengthOfPiece = 6;
  const uint8 kSentinel = 0xff;
  memset(memory, 0, sizeof(kData));
  memory[-1] = kSentinel;
  cmd.Init(kBucketId, kSomeOffsetInBucket, kLengthOfPiece,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, memcmp(memory, kData + kSomeOffsetInBucket, kLengthOfPiece));
  EXPECT_EQ(0, memcmp(memory + kLengthOfPiece, zero,
                      sizeof(kData) - kLengthOfPiece));
  EXPECT_EQ(kSentinel, memory[-1]);

  // Check that it fails if the bucket_id is invalid
  cmd.Init(kInvalidBucketId, kSomeOffsetInBucket, sizeof(kData),
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the offset is invalid
  cmd.Init(kBucketId, sizeof(kData) + 1, 1,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));

  // Check that it fails if the size is invalid
  cmd.Init(kBucketId, 0, sizeof(kData) + 1,
           MockCommandBufferEngine::kValidShmId, kSomeOffsetInSharedMemory);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

}  // namespace gpu
