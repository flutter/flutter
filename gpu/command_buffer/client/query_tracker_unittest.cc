// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Tests for the QueryTracker.

#include "gpu/command_buffer/client/query_tracker.h"

#include <GLES2/gl2ext.h>
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/client/client_test_helper.h"
#include "gpu/command_buffer/client/gles2_cmd_helper.h"
#include "gpu/command_buffer/client/mapped_memory.h"
#include "gpu/command_buffer/common/command_buffer.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace gpu {
namespace gles2 {

namespace {
void EmptyPoll() {
}
}

class QuerySyncManagerTest : public testing::Test {
 protected:
  static const int32 kNumCommandEntries = 400;
  static const int32 kCommandBufferSizeBytes =
      kNumCommandEntries * sizeof(CommandBufferEntry);

  void SetUp() override {
    command_buffer_.reset(new MockClientCommandBuffer());
    helper_.reset(new GLES2CmdHelper(command_buffer_.get()));
    helper_->Initialize(kCommandBufferSizeBytes);
    mapped_memory_.reset(new MappedMemoryManager(
        helper_.get(), base::Bind(&EmptyPoll), MappedMemoryManager::kNoLimit));
    sync_manager_.reset(new QuerySyncManager(mapped_memory_.get()));
  }

  void TearDown() override {
    sync_manager_.reset();
    mapped_memory_.reset();
    helper_.reset();
    command_buffer_.reset();
  }

  scoped_ptr<CommandBuffer> command_buffer_;
  scoped_ptr<GLES2CmdHelper> helper_;
  scoped_ptr<MappedMemoryManager> mapped_memory_;
  scoped_ptr<QuerySyncManager> sync_manager_;
};

TEST_F(QuerySyncManagerTest, Basic) {
  QuerySyncManager::QueryInfo infos[4];
  memset(&infos, 0xBD, sizeof(infos));

  for (size_t ii = 0; ii < arraysize(infos); ++ii) {
    EXPECT_TRUE(sync_manager_->Alloc(&infos[ii]));
    EXPECT_NE(0, infos[ii].shm_id);
    ASSERT_TRUE(infos[ii].sync != NULL);
    EXPECT_EQ(0, infos[ii].sync->process_count);
    EXPECT_EQ(0u, infos[ii].sync->result);
  }

  for (size_t ii = 0; ii < arraysize(infos); ++ii) {
    sync_manager_->Free(infos[ii]);
  }
}

TEST_F(QuerySyncManagerTest, DontFree) {
  QuerySyncManager::QueryInfo infos[4];
  memset(&infos, 0xBD, sizeof(infos));

  for (size_t ii = 0; ii < arraysize(infos); ++ii) {
    EXPECT_TRUE(sync_manager_->Alloc(&infos[ii]));
  }
}

class QueryTrackerTest : public testing::Test {
 protected:
  static const int32 kNumCommandEntries = 400;
  static const int32 kCommandBufferSizeBytes =
      kNumCommandEntries * sizeof(CommandBufferEntry);

  void SetUp() override {
    command_buffer_.reset(new MockClientCommandBuffer());
    helper_.reset(new GLES2CmdHelper(command_buffer_.get()));
    helper_->Initialize(kCommandBufferSizeBytes);
    mapped_memory_.reset(new MappedMemoryManager(
        helper_.get(), base::Bind(&EmptyPoll), MappedMemoryManager::kNoLimit));
    query_tracker_.reset(new QueryTracker(mapped_memory_.get()));
  }

  void TearDown() override {
    query_tracker_.reset();
    mapped_memory_.reset();
    helper_.reset();
    command_buffer_.reset();
  }

  QuerySync* GetSync(QueryTracker::Query* query) {
    return query->info_.sync;
  }

  QuerySyncManager::Bucket* GetBucket(QueryTracker::Query* query) {
    return query->info_.bucket;
  }

  uint32 GetFlushGeneration() { return helper_->flush_generation(); }

  scoped_ptr<CommandBuffer> command_buffer_;
  scoped_ptr<GLES2CmdHelper> helper_;
  scoped_ptr<MappedMemoryManager> mapped_memory_;
  scoped_ptr<QueryTracker> query_tracker_;
};

TEST_F(QueryTrackerTest, Basic) {
  const GLuint kId1 = 123;
  const GLuint kId2 = 124;

  // Check we can create a Query.
  QueryTracker::Query* query = query_tracker_->CreateQuery(
      kId1, GL_ANY_SAMPLES_PASSED_EXT);
  ASSERT_TRUE(query != NULL);
  // Check we can get the same Query.
  EXPECT_EQ(query, query_tracker_->GetQuery(kId1));
  // Check we get nothing for a non-existent query.
  EXPECT_TRUE(query_tracker_->GetQuery(kId2) == NULL);
  // Check we can delete the query.
  query_tracker_->RemoveQuery(kId1);
  // Check we get nothing for a non-existent query.
  EXPECT_TRUE(query_tracker_->GetQuery(kId1) == NULL);
}

TEST_F(QueryTrackerTest, Query) {
  const GLuint kId1 = 123;
  const int32 kToken = 46;
  const uint32 kResult = 456;

  // Create a Query.
  QueryTracker::Query* query = query_tracker_->CreateQuery(
      kId1, GL_ANY_SAMPLES_PASSED_EXT);
  ASSERT_TRUE(query != NULL);
  EXPECT_TRUE(query->NeverUsed());
  EXPECT_FALSE(query->Pending());
  EXPECT_EQ(0, query->token());
  EXPECT_EQ(0, query->submit_count());

  // Check MarkAsActive.
  query->MarkAsActive();
  EXPECT_FALSE(query->NeverUsed());
  EXPECT_FALSE(query->Pending());
  EXPECT_EQ(0, query->token());
  EXPECT_EQ(1, query->submit_count());

  // Check MarkAsPending.
  query->MarkAsPending(kToken);
  EXPECT_FALSE(query->NeverUsed());
  EXPECT_TRUE(query->Pending());
  EXPECT_EQ(kToken, query->token());
  EXPECT_EQ(1, query->submit_count());

  // Flush only once if no more flushes happened between a call to
  // EndQuery command and CheckResultsAvailable
  // Advance put_ so flush calls in CheckResultsAvailable go through
  // and updates flush_generation count
  helper_->Noop(1);

  // Store FlushGeneration count after EndQuery is called
  uint32 gen1 = GetFlushGeneration();

  // Check CheckResultsAvailable.
  EXPECT_FALSE(query->CheckResultsAvailable(helper_.get()));
  EXPECT_FALSE(query->NeverUsed());
  EXPECT_TRUE(query->Pending());

  uint32 gen2 = GetFlushGeneration();
  EXPECT_NE(gen1, gen2);

  // Repeated calls to CheckResultsAvailable should not flush unnecessarily
  EXPECT_FALSE(query->CheckResultsAvailable(helper_.get()));
  gen1 = GetFlushGeneration();
  EXPECT_EQ(gen1, gen2);
  EXPECT_FALSE(query->CheckResultsAvailable(helper_.get()));
  gen1 = GetFlushGeneration();
  EXPECT_EQ(gen1, gen2);

  // Simulate GPU process marking it as available.
  QuerySync* sync = GetSync(query);
  sync->process_count = query->submit_count();
  sync->result = kResult;

  // Check CheckResultsAvailable.
  EXPECT_TRUE(query->CheckResultsAvailable(helper_.get()));
  EXPECT_EQ(kResult, query->GetResult());
  EXPECT_FALSE(query->NeverUsed());
  EXPECT_FALSE(query->Pending());
}

TEST_F(QueryTrackerTest, Remove) {
  const GLuint kId1 = 123;
  const int32 kToken = 46;
  const uint32 kResult = 456;

  // Create a Query.
  QueryTracker::Query* query = query_tracker_->CreateQuery(
      kId1, GL_ANY_SAMPLES_PASSED_EXT);
  ASSERT_TRUE(query != NULL);

  QuerySyncManager::Bucket* bucket = GetBucket(query);
  EXPECT_EQ(1u, bucket->used_query_count);

  query->MarkAsActive();
  query->MarkAsPending(kToken);

  query_tracker_->RemoveQuery(kId1);
  // Check we get nothing for a non-existent query.
  EXPECT_TRUE(query_tracker_->GetQuery(kId1) == NULL);

  // Check that memory was not freed.
  EXPECT_EQ(1u, bucket->used_query_count);

  // Simulate GPU process marking it as available.
  QuerySync* sync = GetSync(query);
  sync->process_count = query->submit_count();
  sync->result = kResult;

  // Check FreeCompletedQueries.
  query_tracker_->FreeCompletedQueries();
  EXPECT_EQ(0u, bucket->used_query_count);
}

}  // namespace gles2
}  // namespace gpu


