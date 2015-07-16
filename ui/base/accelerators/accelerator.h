// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This class describe a keyboard accelerator (or keyboard shortcut).
// Keyboard accelerators are registered with the FocusManager.
// It has a copy constructor and assignment operator so that it can be copied.
// It also defines the < operator so that it can be used as a key in a std::map.
//

#ifndef UI_BASE_ACCELERATORS_ACCELERATOR_H_
#define UI_BASE_ACCELERATORS_ACCELERATOR_H_

#include "base/memory/scoped_ptr.h"
#include "base/strings/string16.h"
#include "ui/base/accelerators/platform_accelerator.h"
#include "ui/events/event_constants.h"
#include "ui/events/event_target.h"
#include "ui/events/keycodes/keyboard_codes.h"

namespace mojo {
class View;
}

namespace ui {

class PlatformAccelerator;

// This is a cross-platform class for accelerator keys used in menus.
// |platform_accelerator| should be used to store platform specific data.
class Accelerator {
 public:
  Accelerator();
  Accelerator(ui::KeyboardCode keycode, int modifiers);
  Accelerator(const Accelerator& accelerator);
  ~Accelerator();

  Accelerator& operator=(const Accelerator& accelerator);

  // Define the < operator so that the KeyboardShortcut can be used as a key in
  // a std::map.
  bool operator <(const Accelerator& rhs) const;

  bool operator ==(const Accelerator& rhs) const;

  bool operator !=(const Accelerator& rhs) const;

  ui::KeyboardCode key_code() const { return key_code_; }

  // Sets the event type if the accelerator should be processed on an event
  // other than ui::ET_KEY_PRESSED.
  void set_type(ui::EventType type) { type_ = type; }
  ui::EventType type() const { return type_; }

  int modifiers() const { return modifiers_; }

  bool IsShiftDown() const;
  bool IsCtrlDown() const;
  bool IsAltDown() const;
  bool IsCmdDown() const;
  bool IsRepeat() const;

  void set_platform_accelerator(scoped_ptr<PlatformAccelerator> p) {
    platform_accelerator_ = p.Pass();
  }

  // This class keeps ownership of the returned object.
  const PlatformAccelerator* platform_accelerator() const {
    return platform_accelerator_.get();
  }

  void set_is_repeat(bool is_repeat) { is_repeat_ = is_repeat; }

 protected:
  // The keycode (VK_...).
  KeyboardCode key_code_;

  // The event type (usually ui::ET_KEY_PRESSED).
  EventType type_;

  // The state of the Shift/Ctrl/Alt keys.
  int modifiers_;

  // True if the accelerator is created for an auto repeated key event.
  bool is_repeat_;

  // Stores platform specific data. May be NULL.
  scoped_ptr<PlatformAccelerator> platform_accelerator_;
};

// An interface that classes that want to register for keyboard accelerators
// should implement.
class AcceleratorTarget {
 public:
  // Should return true if the accelerator was processed.
  virtual bool AcceleratorPressed(const Accelerator& accelerator,
                                  mojo::View* target) = 0;

  // Should return true if the target can handle the accelerator events. The
  // AcceleratorPressed method is invoked only for targets for which
  // CanHandleAccelerators returns true.
  virtual bool CanHandleAccelerators() const = 0;

 protected:
  virtual ~AcceleratorTarget() {}
};

// Since accelerator code is one of the few things that can't be cross platform
// in the chrome UI, separate out just the GetAcceleratorForCommandId() from
// the menu delegates.
class AcceleratorProvider {
 public:
  // Gets the accelerator for the specified command id. Returns true if the
  // command id has a valid accelerator, false otherwise.
  virtual bool GetAcceleratorForCommandId(int command_id,
                                          ui::Accelerator* accelerator) = 0;

 protected:
  virtual ~AcceleratorProvider() {}
};

}  // namespace ui

#endif  // UI_BASE_ACCELERATORS_ACCELERATOR_H_
