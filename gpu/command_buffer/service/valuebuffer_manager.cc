// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/valuebuffer_manager.h"

namespace gpu {
namespace gles2 {

SubscriptionRefSet::Observer::~Observer() {
}

SubscriptionRefSet::SubscriptionRefSet() {
}

SubscriptionRefSet::~SubscriptionRefSet() {
  // Make sure no valuebuffers are still holding references to targets
  DCHECK(reference_set_.empty());
}

void SubscriptionRefSet::AddSubscription(unsigned int target) {
  RefSet::iterator it = reference_set_.find(target);
  if (it == reference_set_.end()) {
    reference_set_.insert(std::make_pair(target, 1));
    FOR_EACH_OBSERVER(Observer, observers_, OnAddSubscription(target));
  } else {
    ++it->second;
  }
}

void SubscriptionRefSet::RemoveSubscription(unsigned int target) {
  RefSet::iterator it = reference_set_.find(target);
  DCHECK(it != reference_set_.end());
  if (it->second == 1) {
    reference_set_.erase(it);
    FOR_EACH_OBSERVER(Observer, observers_, OnRemoveSubscription(target));
  } else {
    --it->second;
  }
}

void SubscriptionRefSet::AddObserver(Observer* observer) {
  observers_.AddObserver(observer);
}

void SubscriptionRefSet::RemoveObserver(Observer* observer) {
  observers_.RemoveObserver(observer);
}

Valuebuffer::Valuebuffer(ValuebufferManager* manager, unsigned int client_id)
    : manager_(manager), client_id_(client_id), has_been_bound_(false) {
  manager_->StartTracking(this);
  active_state_map_ = new ValueStateMap();
}

Valuebuffer::~Valuebuffer() {
  if (manager_) {
    for (SubscriptionSet::const_iterator it = subscriptions_.begin();
        it != subscriptions_.end(); ++it) {
      manager_->NotifyRemoveSubscription(*it);
    }
    manager_->StopTracking(this);
    manager_ = NULL;
  }
}

void Valuebuffer::AddSubscription(unsigned int subscription) {
  if (subscriptions_.find(subscription) == subscriptions_.end()) {
    subscriptions_.insert(subscription);
    manager_->NotifyAddSubscription(subscription);
  }
}

void Valuebuffer::RemoveSubscription(unsigned int subscription) {
  SubscriptionSet::iterator it = subscriptions_.find(subscription);
  if (subscriptions_.find(subscription) != subscriptions_.end()) {
    subscriptions_.erase(it);
    manager_->NotifyRemoveSubscription(subscription);
  }
}

bool Valuebuffer::IsSubscribed(unsigned int subscription) {
  return subscriptions_.find(subscription) != subscriptions_.end();
}

const ValueState* Valuebuffer::GetState(unsigned int target) const {
  return active_state_map_->GetState(target);
}

void Valuebuffer::UpdateState(const ValueStateMap* pending_state) {
  DCHECK(pending_state);
  for (SubscriptionSet::const_iterator it = subscriptions_.begin();
       it != subscriptions_.end(); ++it) {
    const ValueState *state = pending_state->GetState(*it);
    if (state != NULL) {
      active_state_map_->UpdateState(*it, *state);
    }
  }
}

ValuebufferManager::ValuebufferManager(SubscriptionRefSet* ref_set,
                                       ValueStateMap* state_map)
    : valuebuffer_count_(0),
      pending_state_map_(state_map),
      subscription_ref_set_(ref_set) {
}

ValuebufferManager::~ValuebufferManager() {
  DCHECK(valuebuffer_map_.empty());
  // If this triggers, that means something is keeping a reference to
  // a Valuebuffer belonging to this.
  CHECK_EQ(valuebuffer_count_, 0u);
}

void ValuebufferManager::Destroy() {
  valuebuffer_map_.clear();
}

void ValuebufferManager::StartTracking(Valuebuffer* /* valuebuffer */) {
  ++valuebuffer_count_;
}

void ValuebufferManager::StopTracking(Valuebuffer* /* valuebuffer */) {
  --valuebuffer_count_;
}

void ValuebufferManager::NotifyAddSubscription(unsigned int target) {
  subscription_ref_set_->AddSubscription(target);
}
void ValuebufferManager::NotifyRemoveSubscription(unsigned int target) {
  subscription_ref_set_->RemoveSubscription(target);
}

void ValuebufferManager::CreateValuebuffer(unsigned int client_id) {
  scoped_refptr<Valuebuffer> valuebuffer(new Valuebuffer(this, client_id));
  std::pair<ValuebufferMap::iterator, bool> result =
      valuebuffer_map_.insert(std::make_pair(client_id, valuebuffer));
  DCHECK(result.second);
}

Valuebuffer* ValuebufferManager::GetValuebuffer(unsigned int client_id) {
  ValuebufferMap::iterator it = valuebuffer_map_.find(client_id);
  return it != valuebuffer_map_.end() ? it->second.get() : NULL;
}

void ValuebufferManager::RemoveValuebuffer(unsigned int client_id) {
  ValuebufferMap::iterator it = valuebuffer_map_.find(client_id);
  if (it != valuebuffer_map_.end()) {
    Valuebuffer* valuebuffer = it->second.get();
    valuebuffer->MarkAsDeleted();
    valuebuffer_map_.erase(it);
  }
}

void ValuebufferManager::UpdateValuebufferState(Valuebuffer* valuebuffer) {
  DCHECK(valuebuffer);
  valuebuffer->UpdateState(pending_state_map_.get());
}

uint32 ValuebufferManager::ApiTypeForSubscriptionTarget(unsigned int target) {
  switch (target) {
    case GL_MOUSE_POSITION_CHROMIUM:
      return Program::kUniform2i;
  }
  NOTREACHED() << "Unhandled uniform subscription target " << target;
  return Program::kUniformNone;
}

}  // namespace gles2
}  // namespace gpu
