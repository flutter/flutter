// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/query_tracker.h"

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include "base/atomicops.h"
#include "base/numerics/safe_conversions.h"
#include "gpu/command_buffer/client/gles2_cmd_helper.h"
#include "gpu/command_buffer/client/gles2_implementation.h"
#include "gpu/command_buffer/client/mapped_memory.h"
#include "gpu/command_buffer/common/time.h"

namespace gpu {
namespace gles2 {

QuerySyncManager::QuerySyncManager(MappedMemoryManager* manager)
    : mapped_memory_(manager) {
  DCHECK(manager);
}

QuerySyncManager::~QuerySyncManager() {
  while (!buckets_.empty()) {
    mapped_memory_->Free(buckets_.front()->syncs);
    delete buckets_.front();
    buckets_.pop_front();
  }
}

bool QuerySyncManager::Alloc(QuerySyncManager::QueryInfo* info) {
  DCHECK(info);
  if (free_queries_.empty()) {
    int32 shm_id;
    unsigned int shm_offset;
    void* mem = mapped_memory_->Alloc(
        kSyncsPerBucket * sizeof(QuerySync), &shm_id, &shm_offset);
    if (!mem) {
      return false;
    }
    QuerySync* syncs = static_cast<QuerySync*>(mem);
    Bucket* bucket = new Bucket(syncs);
    buckets_.push_back(bucket);
    for (size_t ii = 0; ii < kSyncsPerBucket; ++ii) {
      free_queries_.push_back(QueryInfo(bucket, shm_id, shm_offset, syncs));
      ++syncs;
      shm_offset += sizeof(*syncs);
    }
  }
  *info = free_queries_.front();
  ++(info->bucket->used_query_count);
  info->sync->Reset();
  free_queries_.pop_front();
  return true;
}

void QuerySyncManager::Free(const QuerySyncManager::QueryInfo& info) {
  DCHECK_GT(info.bucket->used_query_count, 0u);
  --(info.bucket->used_query_count);
  free_queries_.push_back(info);
}

void QuerySyncManager::Shrink() {
  std::deque<QueryInfo> new_queue;
  while (!free_queries_.empty()) {
    if (free_queries_.front().bucket->used_query_count)
      new_queue.push_back(free_queries_.front());
    free_queries_.pop_front();
  }
  free_queries_.swap(new_queue);

  std::deque<Bucket*> new_buckets;
  while (!buckets_.empty()) {
    Bucket* bucket = buckets_.front();
    if (bucket->used_query_count) {
      new_buckets.push_back(bucket);
    } else {
      mapped_memory_->Free(bucket->syncs);
      delete bucket;
    }
    buckets_.pop_front();
  }
  buckets_.swap(new_buckets);
}

QueryTracker::Query::Query(GLuint id, GLenum target,
                           const QuerySyncManager::QueryInfo& info)
    : id_(id),
      target_(target),
      info_(info),
      state_(kUninitialized),
      submit_count_(0),
      token_(0),
      flush_count_(0),
      client_begin_time_us_(0),
      result_(0) {
    }


void QueryTracker::Query::Begin(GLES2Implementation* gl) {
  // init memory, inc count
  MarkAsActive();

  switch (target()) {
    case GL_GET_ERROR_QUERY_CHROMIUM:
      // To nothing on begin for error queries.
      break;
    case GL_LATENCY_QUERY_CHROMIUM:
      client_begin_time_us_ = MicrosecondsSinceOriginOfTime();
      // tell service about id, shared memory and count
      gl->helper()->BeginQueryEXT(target(), id(), shm_id(), shm_offset());
      break;
    case GL_ASYNC_PIXEL_UNPACK_COMPLETED_CHROMIUM:
    case GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM:
    default:
      // tell service about id, shared memory and count
      gl->helper()->BeginQueryEXT(target(), id(), shm_id(), shm_offset());
      break;
  }
}

void QueryTracker::Query::End(GLES2Implementation* gl) {
  switch (target()) {
    case GL_GET_ERROR_QUERY_CHROMIUM: {
      GLenum error = gl->GetClientSideGLError();
      if (error == GL_NO_ERROR) {
        // There was no error so start the query on the service.
        // it will end immediately.
        gl->helper()->BeginQueryEXT(target(), id(), shm_id(), shm_offset());
      } else {
        // There's an error on the client, no need to bother the service. Just
        // set the query as completed and return the error.
        if (error != GL_NO_ERROR) {
          state_ = kComplete;
          result_ = error;
          return;
        }
      }
    }
  }
  flush_count_ = gl->helper()->flush_generation();
  gl->helper()->EndQueryEXT(target(), submit_count());
  MarkAsPending(gl->helper()->InsertToken());
}

bool QueryTracker::Query::CheckResultsAvailable(
    CommandBufferHelper* helper) {
  if (Pending()) {
    if (base::subtle::Acquire_Load(&info_.sync->process_count) ==
            submit_count_ ||
        helper->IsContextLost()) {
      switch (target()) {
        case GL_COMMANDS_ISSUED_CHROMIUM:
          result_ = base::saturated_cast<uint32>(info_.sync->result);
          break;
        case GL_LATENCY_QUERY_CHROMIUM:
          // Disabled DCHECK because of http://crbug.com/419236.
          //DCHECK(info_.sync->result >= client_begin_time_us_);
          result_ = base::saturated_cast<uint32>(
              info_.sync->result - client_begin_time_us_);
          break;
        case GL_ASYNC_PIXEL_UNPACK_COMPLETED_CHROMIUM:
        case GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM:
        default:
          result_ = static_cast<uint32>(info_.sync->result);
          break;
      }
      state_ = kComplete;
    } else {
      if ((helper->flush_generation() - flush_count_ - 1) >= 0x80000000) {
        helper->Flush();
      } else {
        // Insert no-ops so that eventually the GPU process will see more work.
        helper->Noop(1);
      }
    }
  }
  return state_ == kComplete;
}

uint32 QueryTracker::Query::GetResult() const {
  DCHECK(state_ == kComplete || state_ == kUninitialized);
  return result_;
}

QueryTracker::QueryTracker(MappedMemoryManager* manager)
    : query_sync_manager_(manager) {
}

QueryTracker::~QueryTracker() {
  while (!queries_.empty()) {
    delete queries_.begin()->second;
    queries_.erase(queries_.begin());
  }
  while (!removed_queries_.empty()) {
    delete removed_queries_.front();
    removed_queries_.pop_front();
  }
}

QueryTracker::Query* QueryTracker::CreateQuery(GLuint id, GLenum target) {
  DCHECK_NE(0u, id);
  FreeCompletedQueries();
  QuerySyncManager::QueryInfo info;
  if (!query_sync_manager_.Alloc(&info)) {
    return NULL;
  }
  Query* query = new Query(id, target, info);
  std::pair<QueryMap::iterator, bool> result =
      queries_.insert(std::make_pair(id, query));
  DCHECK(result.second);
  return query;
}

QueryTracker::Query* QueryTracker::GetQuery(
    GLuint client_id) {
  QueryMap::iterator it = queries_.find(client_id);
  return it != queries_.end() ? it->second : NULL;
}

void QueryTracker::RemoveQuery(GLuint client_id) {
  QueryMap::iterator it = queries_.find(client_id);
  if (it != queries_.end()) {
    Query* query = it->second;
    // When you delete a query you can't mark its memory as unused until it's
    // completed.
    // Note: If you don't do this you won't mess up the service but you will
    // mess up yourself.
    removed_queries_.push_back(query);
    queries_.erase(it);
    FreeCompletedQueries();
  }
}

void QueryTracker::Shrink() {
  FreeCompletedQueries();
  query_sync_manager_.Shrink();
}

void QueryTracker::FreeCompletedQueries() {
  QueryList::iterator it = removed_queries_.begin();
  while (it != removed_queries_.end()) {
    Query* query = *it;
    if (query->Pending() &&
        base::subtle::Acquire_Load(&query->info_.sync->process_count) !=
            query->submit_count()) {
      ++it;
      continue;
    }

    query_sync_manager_.Free(query->info_);
    it = removed_queries_.erase(it);
    delete query;
  }
}

}  // namespace gles2
}  // namespace gpu
