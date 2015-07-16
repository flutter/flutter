// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/base/accelerators/accelerator.h"

#include "base/i18n/rtl.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"

#if defined(USE_AURA)
#include "ui/events/keycodes/keyboard_code_conversion.h"
#endif

namespace ui {

Accelerator::Accelerator()
    : key_code_(ui::VKEY_UNKNOWN),
      type_(ui::ET_KEY_PRESSED),
      modifiers_(0),
      is_repeat_(false) {
}

Accelerator::Accelerator(KeyboardCode keycode, int modifiers)
    : key_code_(keycode),
      type_(ui::ET_KEY_PRESSED),
      modifiers_(modifiers),
      is_repeat_(false) {
}

Accelerator::Accelerator(const Accelerator& accelerator) {
  key_code_ = accelerator.key_code_;
  type_ = accelerator.type_;
  modifiers_ = accelerator.modifiers_;
  is_repeat_ = accelerator.is_repeat_;
  if (accelerator.platform_accelerator_.get())
    platform_accelerator_ = accelerator.platform_accelerator_->CreateCopy();
}

Accelerator::~Accelerator() {
}

Accelerator& Accelerator::operator=(const Accelerator& accelerator) {
  if (this != &accelerator) {
    key_code_ = accelerator.key_code_;
    type_ = accelerator.type_;
    modifiers_ = accelerator.modifiers_;
    is_repeat_ = accelerator.is_repeat_;
    if (accelerator.platform_accelerator_.get())
      platform_accelerator_ = accelerator.platform_accelerator_->CreateCopy();
    else
      platform_accelerator_.reset();
  }
  return *this;
}

bool Accelerator::operator <(const Accelerator& rhs) const {
  if (key_code_ != rhs.key_code_)
    return key_code_ < rhs.key_code_;
  if (type_ != rhs.type_)
    return type_ < rhs.type_;
  return modifiers_ < rhs.modifiers_;
}

bool Accelerator::operator ==(const Accelerator& rhs) const {
  if ((key_code_ == rhs.key_code_) && (type_ == rhs.type_) &&
      (modifiers_ == rhs.modifiers_))
    return true;

  bool platform_equal =
      platform_accelerator_.get() && rhs.platform_accelerator_.get() &&
      platform_accelerator_.get() == rhs.platform_accelerator_.get();

  return platform_equal;
}

bool Accelerator::operator !=(const Accelerator& rhs) const {
  return !(*this == rhs);
}

bool Accelerator::IsShiftDown() const {
  return (modifiers_ & EF_SHIFT_DOWN) != 0;
}

bool Accelerator::IsCtrlDown() const {
  return (modifiers_ & EF_CONTROL_DOWN) != 0;
}

bool Accelerator::IsAltDown() const {
  return (modifiers_ & EF_ALT_DOWN) != 0;
}

bool Accelerator::IsCmdDown() const {
  return (modifiers_ & EF_COMMAND_DOWN) != 0;
}

bool Accelerator::IsRepeat() const {
  return is_repeat_;
}

}  // namespace ui
