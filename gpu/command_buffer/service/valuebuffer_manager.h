// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_VALUEBUFFER_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_VALUEBUFFER_MANAGER_H_

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/observer_list.h"
#include "gpu/command_buffer/common/value_state.h"
#include "gpu/gpu_export.h"

namespace content {
class GpuChannel;
}

namespace gpu {
namespace gles2 {

class ValuebufferManager;

class GPU_EXPORT SubscriptionRefSet
    : public base::RefCounted<SubscriptionRefSet> {
 public:
  class GPU_EXPORT Observer {
   public:
    virtual ~Observer();

    virtual void OnAddSubscription(unsigned int target) = 0;
    virtual void OnRemoveSubscription(unsigned int target) = 0;
  };

  SubscriptionRefSet();

  void AddObserver(Observer* observer);
  void RemoveObserver(Observer* observer);

 protected:
  virtual ~SubscriptionRefSet();

 private:
  friend class base::RefCounted<SubscriptionRefSet>;
  friend class ValuebufferManager;

  typedef base::hash_map<unsigned int, int> RefSet;

  void AddSubscription(unsigned int target);
  void RemoveSubscription(unsigned int target);

  RefSet reference_set_;

  base::ObserverList<Observer, true> observers_;

  DISALLOW_COPY_AND_ASSIGN(SubscriptionRefSet);
};

class GPU_EXPORT Valuebuffer : public base::RefCounted<Valuebuffer> {
 public:
  Valuebuffer(ValuebufferManager* manager, unsigned int client_id);

  unsigned int client_id() const { return client_id_; }

  bool IsDeleted() const { return client_id_ == 0; }

  void MarkAsValid() { has_been_bound_ = true; }

  bool IsValid() const { return has_been_bound_ && !IsDeleted(); }

  void AddSubscription(unsigned int subscription);
  void RemoveSubscription(unsigned int subscription);

  // Returns true if this Valuebuffer is subscribed to subscription
  bool IsSubscribed(unsigned int subscription);

  // Returns the active state for a given target in this Valuebuffer
  // returns NULL if target state doesn't exist
  const ValueState* GetState(unsigned int target) const;

 private:
  friend class ValuebufferManager;
  friend class base::RefCounted<Valuebuffer>;

  typedef base::hash_set<unsigned int> SubscriptionSet;

  ~Valuebuffer();

  void UpdateState(const ValueStateMap* pending_state);

  void MarkAsDeleted() { client_id_ = 0; }

  // ValuebufferManager that owns this Valuebuffer.
  ValuebufferManager* manager_;

  // Client side Valuebuffer id.
  unsigned int client_id_;

  // Whether this Valuebuffer has ever been bound.
  bool has_been_bound_;

  SubscriptionSet subscriptions_;

  scoped_refptr<ValueStateMap> active_state_map_;
};

class GPU_EXPORT ValuebufferManager {
 public:
  ValuebufferManager(SubscriptionRefSet* ref_set, ValueStateMap* state_map);
  ~ValuebufferManager();

  // Must call before destruction.
  void Destroy();

  // Creates a Valuebuffer for the given Valuebuffer ids.
  void CreateValuebuffer(unsigned int client_id);

  // Gets the Valuebuffer for the given Valuebuffer id.
  Valuebuffer* GetValuebuffer(unsigned int client_id);

  // Removes a Valuebuffer for the given Valuebuffer id.
  void RemoveValuebuffer(unsigned int client_id);

  // Updates the value state for the given Valuebuffer
  void UpdateValuebufferState(Valuebuffer* valuebuffer);

  static uint32 ApiTypeForSubscriptionTarget(unsigned int target);

 private:
  friend class Valuebuffer;

  typedef base::hash_map<unsigned int, scoped_refptr<Valuebuffer>>
      ValuebufferMap;

  void StartTracking(Valuebuffer* valuebuffer);
  void StopTracking(Valuebuffer* valuebuffer);

  void NotifyAddSubscription(unsigned int target);
  void NotifyRemoveSubscription(unsigned int target);

  // Counts the number of Valuebuffer allocated with 'this' as its manager.
  // Allows to check no Valuebuffer will outlive this.
  unsigned int valuebuffer_count_;

  // Info for each Valuebuffer in the system.
  ValuebufferMap valuebuffer_map_;

  // Current value state in the system
  // Updated by GpuChannel
  scoped_refptr<ValueStateMap> pending_state_map_;

  // Subscription targets which are currently subscribed and how
  // many value buffers are currently subscribed to each
  scoped_refptr<SubscriptionRefSet> subscription_ref_set_;

  DISALLOW_COPY_AND_ASSIGN(ValuebufferManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_VALUEBUFFER_MANAGER_H_
