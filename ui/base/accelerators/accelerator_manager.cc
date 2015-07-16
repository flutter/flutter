// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/base/accelerators/accelerator_manager.h"

#include <algorithm>

#include "base/logging.h"

namespace ui {

AcceleratorManager::AcceleratorManager() {
}

AcceleratorManager::~AcceleratorManager() {
}

void AcceleratorManager::Register(const Accelerator& accelerator,
                                  HandlerPriority priority,
                                  AcceleratorTarget* target) {
  AcceleratorTargetList& targets = accelerators_[accelerator].second;
  DCHECK(std::find(targets.begin(), targets.end(), target) == targets.end())
      << "Registering the same target multiple times";

  // All priority accelerators go to the front of the line.
  if (priority) {
    DCHECK(!accelerators_[accelerator].first)
        << "Only one _priority_ handler can be registered";
    targets.push_front(target);
    // Mark that we have a priority accelerator at the front.
    accelerators_[accelerator].first = true;
    return;
  }

  // We are registering a normal priority handler. If no priority accelerator
  // handler has been registered before us, just add the new handler to the
  // front. Otherwise, register it after the first (only) priority handler.
  if (!accelerators_[accelerator].first)
    targets.push_front(target);
  else
    targets.insert(++targets.begin(), target);
}

void AcceleratorManager::Unregister(const Accelerator& accelerator,
                                    AcceleratorTarget* target) {
  AcceleratorMap::iterator map_iter = accelerators_.find(accelerator);
  if (map_iter == accelerators_.end()) {
    NOTREACHED() << "Unregistering non-existing accelerator";
    return;
  }

  AcceleratorTargetList* targets = &map_iter->second.second;
  AcceleratorTargetList::iterator target_iter =
      std::find(targets->begin(), targets->end(), target);
  if (target_iter == targets->end()) {
    NOTREACHED() << "Unregistering accelerator for wrong target";
    return;
  }

  // Check to see if we have a priority handler and whether we are removing it.
  if (accelerators_[accelerator].first && target_iter == targets->begin()) {
    // We've are taking the priority accelerator away, flip the priority flag.
    accelerators_[accelerator].first = false;
  }

  targets->erase(target_iter);
}

void AcceleratorManager::UnregisterAll(AcceleratorTarget* target) {
  for (AcceleratorMap::iterator map_iter = accelerators_.begin();
       map_iter != accelerators_.end(); ++map_iter) {
    AcceleratorTargetList* targets = &map_iter->second.second;
    targets->remove(target);
  }
}

bool AcceleratorManager::Process(const Accelerator& accelerator,
                                 mojo::View* target) {
  bool result = false;
  AcceleratorMap::iterator map_iter = accelerators_.find(accelerator);
  if (map_iter != accelerators_.end()) {
    // We have to copy the target list here, because an AcceleratorPressed
    // event handler may modify the list.
    AcceleratorTargetList targets(map_iter->second.second);
    for (AcceleratorTargetList::iterator iter = targets.begin();
         iter != targets.end(); ++iter) {
      if ((*iter)->CanHandleAccelerators() &&
          (*iter)->AcceleratorPressed(accelerator, target)) {
        result = true;
        break;
      }
    }
  }
  return result;
}

AcceleratorTarget* AcceleratorManager::GetCurrentTarget(
    const Accelerator& accelerator) const {
  AcceleratorMap::const_iterator map_iter = accelerators_.find(accelerator);
  if (map_iter == accelerators_.end() || map_iter->second.second.empty())
    return NULL;
  return map_iter->second.second.front();
}

bool AcceleratorManager::HasPriorityHandler(
    const Accelerator& accelerator) const {
  AcceleratorMap::const_iterator map_iter = accelerators_.find(accelerator);
  if (map_iter == accelerators_.end() || map_iter->second.second.empty())
    return false;

  // Check if we have a priority handler. If not, there's no more work needed.
  if (!map_iter->second.first)
    return false;

  // If the priority handler says it cannot handle the accelerator, we must not
  // count it as one.
  return map_iter->second.second.front()->CanHandleAccelerators();
}

}  // namespace ui
