// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/query_manager.h"

#include "base/atomicops.h"
#include "base/bind.h"
#include "base/logging.h"
#include "base/memory/shared_memory.h"
#include "base/numerics/safe_math.h"
#include "base/synchronization/lock.h"
#include "base/time/time.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"
#include "gpu/command_buffer/service/error_state.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "ui/gl/gl_fence.h"

namespace gpu {
namespace gles2 {

namespace {

class AsyncPixelTransferCompletionObserverImpl
    : public AsyncPixelTransferCompletionObserver {
 public:
  AsyncPixelTransferCompletionObserverImpl(base::subtle::Atomic32 submit_count)
      : submit_count_(submit_count), cancelled_(false) {}

  void Cancel() {
    base::AutoLock locked(lock_);
    cancelled_ = true;
  }

  void DidComplete(const AsyncMemoryParams& mem_params) override {
    base::AutoLock locked(lock_);
    if (!cancelled_) {
      DCHECK(mem_params.buffer().get());
      void* data = mem_params.GetDataAddress();
      QuerySync* sync = static_cast<QuerySync*>(data);
      base::subtle::Release_Store(&sync->process_count, submit_count_);
    }
  }

 private:
  ~AsyncPixelTransferCompletionObserverImpl() override {}

  base::subtle::Atomic32 submit_count_;

  base::Lock lock_;
  bool cancelled_;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferCompletionObserverImpl);
};

class AsyncPixelTransfersCompletedQuery
    : public QueryManager::Query,
      public base::SupportsWeakPtr<AsyncPixelTransfersCompletedQuery> {
 public:
  AsyncPixelTransfersCompletedQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset);

  bool Begin() override;
  bool End(base::subtle::Atomic32 submit_count) override;
  bool Process(bool did_finish) override;
  void Destroy(bool have_context) override;

 protected:
  ~AsyncPixelTransfersCompletedQuery() override;

  scoped_refptr<AsyncPixelTransferCompletionObserverImpl> observer_;
};

AsyncPixelTransfersCompletedQuery::AsyncPixelTransfersCompletedQuery(
    QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset)
    : Query(manager, target, shm_id, shm_offset) {
}

bool AsyncPixelTransfersCompletedQuery::Begin() {
  return true;
}

bool AsyncPixelTransfersCompletedQuery::End(
    base::subtle::Atomic32 submit_count) {
  // Get the real shared memory since it might need to be duped to prevent
  // use-after-free of the memory.
  scoped_refptr<Buffer> buffer =
      manager()->decoder()->GetSharedMemoryBuffer(shm_id());
  if (!buffer.get())
    return false;
  AsyncMemoryParams mem_params(buffer, shm_offset(), sizeof(QuerySync));
  if (!mem_params.GetDataAddress())
    return false;

  observer_ = new AsyncPixelTransferCompletionObserverImpl(submit_count);

  // Ask AsyncPixelTransferDelegate to run completion callback after all
  // previous async transfers are done. No guarantee that callback is run
  // on the current thread.
  manager()->decoder()->GetAsyncPixelTransferManager()->AsyncNotifyCompletion(
      mem_params, observer_.get());

  return AddToPendingTransferQueue(submit_count);
}

bool AsyncPixelTransfersCompletedQuery::Process(bool did_finish) {
  QuerySync* sync = manager()->decoder()->GetSharedMemoryAs<QuerySync*>(
      shm_id(), shm_offset(), sizeof(*sync));
  if (!sync)
    return false;

  // Check if completion callback has been run. sync->process_count atomicity
  // is guaranteed as this is already used to notify client of a completed
  // query.
  if (base::subtle::Acquire_Load(&sync->process_count) != submit_count())
    return true;

  UnmarkAsPending();
  return true;
}

void AsyncPixelTransfersCompletedQuery::Destroy(bool /* have_context */) {
  if (!IsDeleted()) {
    MarkAsDeleted();
  }
}

AsyncPixelTransfersCompletedQuery::~AsyncPixelTransfersCompletedQuery() {
  if (observer_.get())
    observer_->Cancel();
}

}  // namespace

class AllSamplesPassedQuery : public QueryManager::Query {
 public:
  AllSamplesPassedQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset,
      GLuint service_id);
  bool Begin() override;
  bool End(base::subtle::Atomic32 submit_count) override;
  bool Process(bool did_finish) override;
  void Destroy(bool have_context) override;

 protected:
  ~AllSamplesPassedQuery() override;

 private:
  // Service side query id.
  GLuint service_id_;
};

AllSamplesPassedQuery::AllSamplesPassedQuery(
    QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset,
    GLuint service_id)
    : Query(manager, target, shm_id, shm_offset),
      service_id_(service_id) {
}

bool AllSamplesPassedQuery::Begin() {
  BeginQueryHelper(target(), service_id_);
  return true;
}

bool AllSamplesPassedQuery::End(base::subtle::Atomic32 submit_count) {
  EndQueryHelper(target());
  return AddToPendingQueue(submit_count);
}

bool AllSamplesPassedQuery::Process(bool did_finish) {
  GLuint available = 0;
  glGetQueryObjectuiv(
      service_id_, GL_QUERY_RESULT_AVAILABLE_EXT, &available);
  if (!available) {
    return true;
  }
  GLuint result = 0;
  glGetQueryObjectuiv(
      service_id_, GL_QUERY_RESULT_EXT, &result);

  return MarkAsCompleted(result != 0);
}

void AllSamplesPassedQuery::Destroy(bool have_context) {
  if (have_context && !IsDeleted()) {
    glDeleteQueries(1, &service_id_);
    MarkAsDeleted();
  }
}

AllSamplesPassedQuery::~AllSamplesPassedQuery() {
}

class CommandsIssuedQuery : public QueryManager::Query {
 public:
  CommandsIssuedQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset);

  bool Begin() override;
  bool End(base::subtle::Atomic32 submit_count) override;
  bool Process(bool did_finish) override;
  void Destroy(bool have_context) override;

 protected:
  ~CommandsIssuedQuery() override;

 private:
  base::TimeTicks begin_time_;
};

CommandsIssuedQuery::CommandsIssuedQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset)
    : Query(manager, target, shm_id, shm_offset) {
}

bool CommandsIssuedQuery::Begin() {
  begin_time_ = base::TimeTicks::Now();
  return true;
}

bool CommandsIssuedQuery::End(base::subtle::Atomic32 submit_count) {
  base::TimeDelta elapsed = base::TimeTicks::Now() - begin_time_;
  MarkAsPending(submit_count);
  return MarkAsCompleted(elapsed.InMicroseconds());
}

bool CommandsIssuedQuery::Process(bool did_finish) {
  NOTREACHED();
  return true;
}

void CommandsIssuedQuery::Destroy(bool /* have_context */) {
  if (!IsDeleted()) {
    MarkAsDeleted();
  }
}

CommandsIssuedQuery::~CommandsIssuedQuery() {
}

class CommandLatencyQuery : public QueryManager::Query {
 public:
  CommandLatencyQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset);

  bool Begin() override;
  bool End(base::subtle::Atomic32 submit_count) override;
  bool Process(bool did_finish) override;
  void Destroy(bool have_context) override;

 protected:
  ~CommandLatencyQuery() override;
};

CommandLatencyQuery::CommandLatencyQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset)
    : Query(manager, target, shm_id, shm_offset) {
}

bool CommandLatencyQuery::Begin() {
    return true;
}

bool CommandLatencyQuery::End(base::subtle::Atomic32 submit_count) {
    base::TimeDelta now = base::TimeTicks::Now() - base::TimeTicks();
    MarkAsPending(submit_count);
    return MarkAsCompleted(now.InMicroseconds());
}

bool CommandLatencyQuery::Process(bool did_finish) {
  NOTREACHED();
  return true;
}

void CommandLatencyQuery::Destroy(bool /* have_context */) {
  if (!IsDeleted()) {
    MarkAsDeleted();
  }
}

CommandLatencyQuery::~CommandLatencyQuery() {
}


class AsyncReadPixelsCompletedQuery
    : public QueryManager::Query,
      public base::SupportsWeakPtr<AsyncReadPixelsCompletedQuery> {
 public:
  AsyncReadPixelsCompletedQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset);

  bool Begin() override;
  bool End(base::subtle::Atomic32 submit_count) override;
  bool Process(bool did_finish) override;
  void Destroy(bool have_context) override;

 protected:
  void Complete();
  ~AsyncReadPixelsCompletedQuery() override;

 private:
  bool completed_;
  bool complete_result_;
};

AsyncReadPixelsCompletedQuery::AsyncReadPixelsCompletedQuery(
    QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset)
    : Query(manager, target, shm_id, shm_offset),
      completed_(false),
      complete_result_(false) {
}

bool AsyncReadPixelsCompletedQuery::Begin() {
  return true;
}

bool AsyncReadPixelsCompletedQuery::End(base::subtle::Atomic32 submit_count) {
  if (!AddToPendingQueue(submit_count)) {
    return false;
  }
  manager()->decoder()->WaitForReadPixels(
      base::Bind(&AsyncReadPixelsCompletedQuery::Complete,
                 AsWeakPtr()));

  return Process(false);
}

void AsyncReadPixelsCompletedQuery::Complete() {
  completed_ = true;
  complete_result_ = MarkAsCompleted(1);
}

bool AsyncReadPixelsCompletedQuery::Process(bool did_finish) {
  return !completed_ || complete_result_;
}

void AsyncReadPixelsCompletedQuery::Destroy(bool /* have_context */) {
  if (!IsDeleted()) {
    MarkAsDeleted();
  }
}

AsyncReadPixelsCompletedQuery::~AsyncReadPixelsCompletedQuery() {
}


class GetErrorQuery : public QueryManager::Query {
 public:
  GetErrorQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset);

  bool Begin() override;
  bool End(base::subtle::Atomic32 submit_count) override;
  bool Process(bool did_finish) override;
  void Destroy(bool have_context) override;

 protected:
  ~GetErrorQuery() override;

 private:
};

GetErrorQuery::GetErrorQuery(
      QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset)
    : Query(manager, target, shm_id, shm_offset) {
}

bool GetErrorQuery::Begin() {
  return true;
}

bool GetErrorQuery::End(base::subtle::Atomic32 submit_count) {
  MarkAsPending(submit_count);
  return MarkAsCompleted(manager()->decoder()->GetErrorState()->GetGLError());
}

bool GetErrorQuery::Process(bool did_finish) {
  NOTREACHED();
  return true;
}

void GetErrorQuery::Destroy(bool /* have_context */) {
  if (!IsDeleted()) {
    MarkAsDeleted();
  }
}

GetErrorQuery::~GetErrorQuery() {
}

class CommandsCompletedQuery : public QueryManager::Query {
 public:
  CommandsCompletedQuery(QueryManager* manager,
                         GLenum target,
                         int32 shm_id,
                         uint32 shm_offset);

  // Overridden from QueryManager::Query:
  bool Begin() override;
  bool End(base::subtle::Atomic32 submit_count) override;
  bool Process(bool did_finish) override;
  void Destroy(bool have_context) override;

 protected:
  ~CommandsCompletedQuery() override;

 private:
  scoped_ptr<gfx::GLFence> fence_;
  base::TimeTicks begin_time_;
};

CommandsCompletedQuery::CommandsCompletedQuery(QueryManager* manager,
                                               GLenum target,
                                               int32 shm_id,
                                               uint32 shm_offset)
    : Query(manager, target, shm_id, shm_offset) {}

bool CommandsCompletedQuery::Begin() {
  begin_time_ = base::TimeTicks::Now();
  return true;
}

bool CommandsCompletedQuery::End(base::subtle::Atomic32 submit_count) {
  fence_.reset(gfx::GLFence::Create());
  DCHECK(fence_);
  return AddToPendingQueue(submit_count);
}

bool CommandsCompletedQuery::Process(bool did_finish) {
  // Note: |did_finish| guarantees that the GPU has passed the fence but
  // we cannot assume that GLFence::HasCompleted() will return true yet as
  // that's not guaranteed by all GLFence implementations.
  if (!did_finish && fence_ && !fence_->HasCompleted())
    return true;

  base::TimeDelta elapsed = base::TimeTicks::Now() - begin_time_;
  return MarkAsCompleted(elapsed.InMicroseconds());
}

void CommandsCompletedQuery::Destroy(bool have_context) {
  if (have_context && !IsDeleted()) {
    fence_.reset();
    MarkAsDeleted();
  }
}

CommandsCompletedQuery::~CommandsCompletedQuery() {}

QueryManager::QueryManager(
    GLES2Decoder* decoder,
    FeatureInfo* feature_info)
    : decoder_(decoder),
      use_arb_occlusion_query2_for_occlusion_query_boolean_(
          feature_info->feature_flags(
            ).use_arb_occlusion_query2_for_occlusion_query_boolean),
      use_arb_occlusion_query_for_occlusion_query_boolean_(
          feature_info->feature_flags(
            ).use_arb_occlusion_query_for_occlusion_query_boolean),
      query_count_(0) {
  DCHECK(!(use_arb_occlusion_query_for_occlusion_query_boolean_ &&
           use_arb_occlusion_query2_for_occlusion_query_boolean_));
}

QueryManager::~QueryManager() {
  DCHECK(queries_.empty());

  // If this triggers, that means something is keeping a reference to
  // a Query belonging to this.
  CHECK_EQ(query_count_, 0u);
}

void QueryManager::Destroy(bool have_context) {
  pending_queries_.clear();
  pending_transfer_queries_.clear();
  while (!queries_.empty()) {
    Query* query = queries_.begin()->second.get();
    query->Destroy(have_context);
    queries_.erase(queries_.begin());
  }
}

QueryManager::Query* QueryManager::CreateQuery(
    GLenum target, GLuint client_id, int32 shm_id, uint32 shm_offset) {
  scoped_refptr<Query> query;
  switch (target) {
    case GL_COMMANDS_ISSUED_CHROMIUM:
      query = new CommandsIssuedQuery(this, target, shm_id, shm_offset);
      break;
    case GL_LATENCY_QUERY_CHROMIUM:
      query = new CommandLatencyQuery(this, target, shm_id, shm_offset);
      break;
    case GL_ASYNC_PIXEL_UNPACK_COMPLETED_CHROMIUM:
      // Currently async pixel transfer delegates only support uploads.
      query = new AsyncPixelTransfersCompletedQuery(
          this, target, shm_id, shm_offset);
      break;
    case GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM:
      query = new AsyncReadPixelsCompletedQuery(
          this, target, shm_id, shm_offset);
      break;
    case GL_GET_ERROR_QUERY_CHROMIUM:
      query = new GetErrorQuery(this, target, shm_id, shm_offset);
      break;
    case GL_COMMANDS_COMPLETED_CHROMIUM:
      query = new CommandsCompletedQuery(this, target, shm_id, shm_offset);
      break;
    default: {
      GLuint service_id = 0;
      glGenQueries(1, &service_id);
      DCHECK_NE(0u, service_id);
      query = new AllSamplesPassedQuery(
          this, target, shm_id, shm_offset, service_id);
      break;
    }
  }
  std::pair<QueryMap::iterator, bool> result =
      queries_.insert(std::make_pair(client_id, query));
  DCHECK(result.second);
  return query.get();
}

void QueryManager::GenQueries(GLsizei n, const GLuint* queries) {
  DCHECK_GE(n, 0);
  for (GLsizei i = 0; i < n; ++i) {
    generated_query_ids_.insert(queries[i]);
  }
}

bool QueryManager::IsValidQuery(GLuint id) {
  GeneratedQueryIds::iterator it = generated_query_ids_.find(id);
  return it != generated_query_ids_.end();
}

QueryManager::Query* QueryManager::GetQuery(
    GLuint client_id) {
  QueryMap::iterator it = queries_.find(client_id);
  return it != queries_.end() ? it->second.get() : NULL;
}

void QueryManager::RemoveQuery(GLuint client_id) {
  QueryMap::iterator it = queries_.find(client_id);
  if (it != queries_.end()) {
    Query* query = it->second.get();
    RemovePendingQuery(query);
    query->MarkAsDeleted();
    queries_.erase(it);
  }
  generated_query_ids_.erase(client_id);
}

void QueryManager::StartTracking(QueryManager::Query* /* query */) {
  ++query_count_;
}

void QueryManager::StopTracking(QueryManager::Query* /* query */) {
  --query_count_;
}

GLenum QueryManager::AdjustTargetForEmulation(GLenum target) {
  switch (target) {
    case GL_ANY_SAMPLES_PASSED_CONSERVATIVE_EXT:
    case GL_ANY_SAMPLES_PASSED_EXT:
      if (use_arb_occlusion_query2_for_occlusion_query_boolean_) {
        // ARB_occlusion_query2 does not have a
        // GL_ANY_SAMPLES_PASSED_CONSERVATIVE_EXT
        // target.
        target = GL_ANY_SAMPLES_PASSED_EXT;
      } else if (use_arb_occlusion_query_for_occlusion_query_boolean_) {
        // ARB_occlusion_query does not have a
        // GL_ANY_SAMPLES_PASSED_EXT
        // target.
        target = GL_SAMPLES_PASSED_ARB;
      }
      break;
    default:
      break;
  }
  return target;
}

void QueryManager::BeginQueryHelper(GLenum target, GLuint id) {
  target = AdjustTargetForEmulation(target);
  glBeginQuery(target, id);
}

void QueryManager::EndQueryHelper(GLenum target) {
  target = AdjustTargetForEmulation(target);
  glEndQuery(target);
}

QueryManager::Query::Query(
     QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset)
    : manager_(manager),
      target_(target),
      shm_id_(shm_id),
      shm_offset_(shm_offset),
      submit_count_(0),
      pending_(false),
      deleted_(false) {
  DCHECK(manager);
  manager_->StartTracking(this);
}

void QueryManager::Query::RunCallbacks() {
  for (size_t i = 0; i < callbacks_.size(); i++) {
    callbacks_[i].Run();
  }
  callbacks_.clear();
}

void QueryManager::Query::AddCallback(base::Closure callback) {
  if (pending_) {
    callbacks_.push_back(callback);
  } else {
    callback.Run();
  }
}

QueryManager::Query::~Query() {
  // The query is getting deleted, either by the client or
  // because the context was lost. Call any outstanding
  // callbacks to avoid leaks.
  RunCallbacks();
  if (manager_) {
    manager_->StopTracking(this);
    manager_ = NULL;
  }
}

bool QueryManager::Query::MarkAsCompleted(uint64 result) {
  DCHECK(pending_);
  QuerySync* sync = manager_->decoder_->GetSharedMemoryAs<QuerySync*>(
      shm_id_, shm_offset_, sizeof(*sync));
  if (!sync) {
    return false;
  }

  pending_ = false;
  sync->result = result;
  base::subtle::Release_Store(&sync->process_count, submit_count_);

  return true;
}

bool QueryManager::ProcessPendingQueries(bool did_finish) {
  while (!pending_queries_.empty()) {
    Query* query = pending_queries_.front().get();
    if (!query->Process(did_finish)) {
      return false;
    }
    if (query->pending()) {
      break;
    }
    query->RunCallbacks();
    pending_queries_.pop_front();
  }

  return true;
}

bool QueryManager::HavePendingQueries() {
  return !pending_queries_.empty();
}

bool QueryManager::ProcessPendingTransferQueries() {
  while (!pending_transfer_queries_.empty()) {
    Query* query = pending_transfer_queries_.front().get();
    if (!query->Process(false)) {
      return false;
    }
    if (query->pending()) {
      break;
    }
    query->RunCallbacks();
    pending_transfer_queries_.pop_front();
  }

  return true;
}

bool QueryManager::HavePendingTransferQueries() {
  return !pending_transfer_queries_.empty();
}

bool QueryManager::AddPendingQuery(Query* query,
                                   base::subtle::Atomic32 submit_count) {
  DCHECK(query);
  DCHECK(!query->IsDeleted());
  if (!RemovePendingQuery(query)) {
    return false;
  }
  query->MarkAsPending(submit_count);
  pending_queries_.push_back(query);
  return true;
}

bool QueryManager::AddPendingTransferQuery(
    Query* query,
    base::subtle::Atomic32 submit_count) {
  DCHECK(query);
  DCHECK(!query->IsDeleted());
  if (!RemovePendingQuery(query)) {
    return false;
  }
  query->MarkAsPending(submit_count);
  pending_transfer_queries_.push_back(query);
  return true;
}

bool QueryManager::RemovePendingQuery(Query* query) {
  DCHECK(query);
  if (query->pending()) {
    // TODO(gman): Speed this up if this is a common operation. This would only
    // happen if you do being/end begin/end on the same query without waiting
    // for the first one to finish.
    for (QueryQueue::iterator it = pending_queries_.begin();
         it != pending_queries_.end(); ++it) {
      if (it->get() == query) {
        pending_queries_.erase(it);
        break;
      }
    }
    for (QueryQueue::iterator it = pending_transfer_queries_.begin();
         it != pending_transfer_queries_.end(); ++it) {
      if (it->get() == query) {
        pending_transfer_queries_.erase(it);
        break;
      }
    }
    if (!query->MarkAsCompleted(0)) {
      return false;
    }
  }
  return true;
}

bool QueryManager::BeginQuery(Query* query) {
  DCHECK(query);
  if (!RemovePendingQuery(query)) {
    return false;
  }
  return query->Begin();
}

bool QueryManager::EndQuery(Query* query, base::subtle::Atomic32 submit_count) {
  DCHECK(query);
  if (!RemovePendingQuery(query)) {
    return false;
  }
  return query->End(submit_count);
}

}  // namespace gles2
}  // namespace gpu
