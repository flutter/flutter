// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_BASE_ACCELERATORS_ACCELERATOR_MANAGER_H_
#define UI_BASE_ACCELERATORS_ACCELERATOR_MANAGER_H_

#include <list>
#include <map>
#include <utility>

#include "base/basictypes.h"
#include "ui/base/accelerators/accelerator.h"
#include "ui/events/event_constants.h"
#include "ui/events/event_target.h"

namespace mojo {
class View;
}

namespace ui {

// The AcceleratorManger is used to handle keyboard accelerators.
class AcceleratorManager {
 public:
  enum HandlerPriority {
    kNormalPriority,
    kHighPriority,
  };

  AcceleratorManager();
  ~AcceleratorManager();

  // Register a keyboard accelerator for the specified target. If multiple
  // targets are registered for an accelerator, a target registered later has
  // higher priority.
  // |accelerator| is the accelerator to register.
  // |priority| denotes the priority of the handler.
  // NOTE: In almost all cases, you should specify kNormalPriority for this
  // parameter. Setting it to kHighPriority prevents Chrome from sending the
  // shortcut to the webpage if the renderer has focus, which is not desirable
  // except for very isolated cases.
  // |target| is the AcceleratorTarget that handles the event once the
  // accelerator is pressed.
  // Note that we are currently limited to accelerators that are either:
  // - a key combination including Ctrl or Alt
  // - the escape key
  // - the enter key
  // - any F key (F1, F2, F3 ...)
  // - any browser specific keys (as available on special keyboards)
  void Register(const Accelerator& accelerator,
                HandlerPriority priority,
                AcceleratorTarget* target);

  // Unregister the specified keyboard accelerator for the specified target.
  void Unregister(const Accelerator& accelerator, AcceleratorTarget* target);

  // Unregister all keyboard accelerator for the specified target.
  void UnregisterAll(AcceleratorTarget* target);

  // Activate the target associated with the specified accelerator.
  // First, AcceleratorPressed handler of the most recently registered target
  // is called, and if that handler processes the event (i.e. returns true),
  // this method immediately returns. If not, we do the same thing on the next
  // target, and so on.
  // Returns true if an accelerator was activated.
  bool Process(const Accelerator& accelerator, mojo::View* target);

  // Returns the AcceleratorTarget that should be activated for the specified
  // keyboard accelerator, or NULL if no view is registered for that keyboard
  // accelerator.
  AcceleratorTarget* GetCurrentTarget(const Accelerator& accelerator) const;

  // Whether the given |accelerator| has a priority handler associated with it.
  bool HasPriorityHandler(const Accelerator& accelerator) const;

 private:
  // The accelerators and associated targets.
  typedef std::list<AcceleratorTarget*> AcceleratorTargetList;
  // This construct pairs together a |bool| (denoting whether the list contains
  // a priority_handler at the front) with the list of AcceleratorTargets.
  typedef std::pair<bool, AcceleratorTargetList> AcceleratorTargets;
  typedef std::map<Accelerator, AcceleratorTargets> AcceleratorMap;
  AcceleratorMap accelerators_;

  DISALLOW_COPY_AND_ASSIGN(AcceleratorManager);
};

}  // namespace ui

#endif  // UI_BASE_ACCELERATORS_ACCELERATOR_MANAGER_H_
