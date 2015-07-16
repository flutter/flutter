// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_QUERY_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_QUERY_MANAGER_H_

#include <deque>
#include <vector>
#include "base/atomicops.h"
#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/gpu_export.h"

namespace gpu {

class GLES2Decoder;

namespace gles2 {

class FeatureInfo;

// This class keeps track of the queries and their state
// As Queries are not shared there is one QueryManager per context.
class GPU_EXPORT QueryManager {
 public:
  class GPU_EXPORT Query : public base::RefCounted<Query> {
   public:
    Query(
        QueryManager* manager, GLenum target, int32 shm_id, uint32 shm_offset);

    GLenum target() const {
      return target_;
    }

    bool IsDeleted() const {
      return deleted_;
    }

    bool IsValid() const {
      return target() && !IsDeleted();
    }

    bool pending() const {
      return pending_;
    }

    int32 shm_id() const {
      return shm_id_;
    }

    uint32 shm_offset() const {
      return shm_offset_;
    }

    // Returns false if shared memory for sync is invalid.
    virtual bool Begin() = 0;

    // Returns false if shared memory for sync is invalid.
    virtual bool End(base::subtle::Atomic32 submit_count) = 0;

    // Returns false if shared memory for sync is invalid.
    virtual bool Process(bool did_finish) = 0;

    virtual void Destroy(bool have_context) = 0;

    void AddCallback(base::Closure callback);

   protected:
    virtual ~Query();

    QueryManager* manager() const {
      return manager_;
    }

    void MarkAsDeleted() {
      deleted_ = true;
    }

    // Returns false if shared memory for sync is invalid.
    bool MarkAsCompleted(uint64 result);

    void MarkAsPending(base::subtle::Atomic32 submit_count) {
      DCHECK(!pending_);
      pending_ = true;
      submit_count_ = submit_count;
    }

    void UnmarkAsPending() {
      DCHECK(pending_);
      pending_ = false;
    }

    // Returns false if shared memory for sync is invalid.
    bool AddToPendingQueue(base::subtle::Atomic32 submit_count) {
      return manager_->AddPendingQuery(this, submit_count);
    }

    // Returns false if shared memory for sync is invalid.
    bool AddToPendingTransferQueue(base::subtle::Atomic32 submit_count) {
      return manager_->AddPendingTransferQuery(this, submit_count);
    }

    void BeginQueryHelper(GLenum target, GLuint id) {
      manager_->BeginQueryHelper(target, id);
    }

    void EndQueryHelper(GLenum target) {
      manager_->EndQueryHelper(target);
    }

    base::subtle::Atomic32 submit_count() const { return submit_count_; }

   private:
    friend class QueryManager;
    friend class QueryManagerTest;
    friend class base::RefCounted<Query>;

    void RunCallbacks();

    // The manager that owns this Query.
    QueryManager* manager_;

    // The type of query.
    GLenum target_;

    // The shared memory used with this Query.
    int32 shm_id_;
    uint32 shm_offset_;

    // Count to set process count do when completed.
    base::subtle::Atomic32 submit_count_;

    // True if in the queue.
    bool pending_;

    // True if deleted.
    bool deleted_;

    // List of callbacks to run when result is available.
    std::vector<base::Closure> callbacks_;
  };

  QueryManager(
      GLES2Decoder* decoder,
      FeatureInfo* feature_info);
  ~QueryManager();

  // Must call before destruction.
  void Destroy(bool have_context);

  // Creates a Query for the given query.
  Query* CreateQuery(
      GLenum target, GLuint client_id, int32 shm_id, uint32 shm_offset);

  // Gets the query info for the given query.
  Query* GetQuery(GLuint client_id);

  // Removes a query info for the given query.
  void RemoveQuery(GLuint client_id);

  // Returns false if any query is pointing to invalid shared memory.
  bool BeginQuery(Query* query);

  // Returns false if any query is pointing to invalid shared memory.
  bool EndQuery(Query* query, base::subtle::Atomic32 submit_count);

  // Processes pending queries. Returns false if any queries are pointing
  // to invalid shared memory. |did_finish| is true if this is called as
  // a result of calling glFinish().
  bool ProcessPendingQueries(bool did_finish);

  // True if there are pending queries.
  bool HavePendingQueries();

  // Processes pending transfer queries. Returns false if any queries are
  // pointing to invalid shared memory.
  bool ProcessPendingTransferQueries();

  // True if there are pending transfer queries.
  bool HavePendingTransferQueries();

  GLES2Decoder* decoder() const {
    return decoder_;
  }

  void GenQueries(GLsizei n, const GLuint* queries);
  bool IsValidQuery(GLuint id);

 private:
  void StartTracking(Query* query);
  void StopTracking(Query* query);

  // Wrappers for BeginQueryARB and EndQueryARB to hide differences between
  // ARB_occlusion_query2 and EXT_occlusion_query_boolean.
  void BeginQueryHelper(GLenum target, GLuint id);
  void EndQueryHelper(GLenum target);

  // Adds to queue of queries waiting for completion.
  // Returns false if any query is pointing to invalid shared memory.
  bool AddPendingQuery(Query* query, base::subtle::Atomic32 submit_count);

  // Adds to queue of transfer queries waiting for completion.
  // Returns false if any query is pointing to invalid shared memory.
  bool AddPendingTransferQuery(Query* query,
                               base::subtle::Atomic32 submit_count);

  // Removes a query from the queue of pending queries.
  // Returns false if any query is pointing to invalid shared memory.
  bool RemovePendingQuery(Query* query);

  // Returns a target used for the underlying GL extension
  // used to emulate a query.
  GLenum AdjustTargetForEmulation(GLenum target);

  // Used to validate shared memory and get GL errors.
  GLES2Decoder* decoder_;

  bool use_arb_occlusion_query2_for_occlusion_query_boolean_;
  bool use_arb_occlusion_query_for_occlusion_query_boolean_;

  // Counts the number of Queries allocated with 'this' as their manager.
  // Allows checking no Query will outlive this.
  unsigned query_count_;

  // Info for each query in the system.
  typedef base::hash_map<GLuint, scoped_refptr<Query> > QueryMap;
  QueryMap queries_;

  typedef base::hash_set<GLuint> GeneratedQueryIds;
  GeneratedQueryIds generated_query_ids_;

  // Queries waiting for completion.
  typedef std::deque<scoped_refptr<Query> > QueryQueue;
  QueryQueue pending_queries_;

  // Async pixel transfer queries waiting for completion.
  QueryQueue pending_transfer_queries_;

  DISALLOW_COPY_AND_ASSIGN(QueryManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_QUERY_MANAGER_H_
