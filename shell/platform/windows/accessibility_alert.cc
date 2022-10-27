// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/accessibility_alert.h"

#include "flutter/shell/platform/windows/accessibility_root_node.h"

namespace flutter {

AccessibilityAlert::AccessibilityAlert() : text_(L""), parent_(nullptr) {}

// IAccessible methods.

IFACEMETHODIMP AccessibilityAlert::accHitTest(LONG screen_physical_pixel_x,
                                              LONG screen_physical_pixel_y,
                                              VARIANT* child) {
  child->vt = VT_EMPTY;
  return S_FALSE;
}

// Performs the object's default action.
IFACEMETHODIMP AccessibilityAlert::accDoDefaultAction(VARIANT var_id) {
  return E_FAIL;
}

// Retrieves an IDispatch interface pointer for the specified child.
IFACEMETHODIMP AccessibilityAlert::get_accChild(VARIANT var_child,
                                                IDispatch** disp_child) {
  if (V_VT(&var_child) == VT_I4 && V_I4(&var_child) == CHILDID_SELF) {
    *disp_child = this;
    AddRef();
    return S_OK;
  }
  *disp_child = nullptr;
  return E_FAIL;
}

// Retrieves the number of accessible children.
IFACEMETHODIMP AccessibilityAlert::get_accChildCount(LONG* child_count) {
  *child_count = 0;
  return S_OK;
}

// Retrieves the tooltip description.
IFACEMETHODIMP AccessibilityAlert::get_accDescription(VARIANT var_id,
                                                      BSTR* desc) {
  *desc = SysAllocString(text_.c_str());
  return S_OK;
}

// Retrieves the name of the specified object.
IFACEMETHODIMP AccessibilityAlert::get_accName(VARIANT var_id, BSTR* name) {
  *name = SysAllocString(text_.c_str());
  return S_OK;
}

// Retrieves the IDispatch interface of the object's parent.
IFACEMETHODIMP AccessibilityAlert::get_accParent(IDispatch** disp_parent) {
  *disp_parent = parent_;
  if (*disp_parent) {
    (*disp_parent)->AddRef();
    return S_OK;
  }
  return S_FALSE;
}

// Retrieves information describing the role of the specified object.
IFACEMETHODIMP AccessibilityAlert::get_accRole(VARIANT var_id, VARIANT* role) {
  *role = {.vt = VT_I4, .lVal = ROLE_SYSTEM_ALERT};
  return S_OK;
}

// Retrieves the current state of the specified object.
IFACEMETHODIMP AccessibilityAlert::get_accState(VARIANT var_id,
                                                VARIANT* state) {
  *state = {.vt = VT_I4, .lVal = STATE_SYSTEM_DEFAULT};
  return S_OK;
}

// Gets the help string for the specified object.
IFACEMETHODIMP AccessibilityAlert::get_accHelp(VARIANT var_id, BSTR* help) {
  *help = SysAllocString(L"");
  return S_OK;
}

// Retrieve or set the string value associated with the specified object.
// Setting the value is not typically used by screen readers, but it's
// used frequently by automation software.
IFACEMETHODIMP AccessibilityAlert::get_accValue(VARIANT var_id, BSTR* value) {
  *value = SysAllocString(text_.c_str());
  return S_OK;
}

// IAccessible methods not implemented.
IFACEMETHODIMP AccessibilityAlert::get_accSelection(VARIANT* selected) {
  selected->vt = VT_EMPTY;
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::accSelect(LONG flags_sel, VARIANT var_id) {
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::put_accValue(VARIANT var_id,
                                                BSTR new_value) {
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::get_accFocus(VARIANT* focus_child) {
  focus_child->vt = VT_EMPTY;
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::get_accHelpTopic(BSTR* help_file,
                                                    VARIANT var_id,
                                                    LONG* topic_id) {
  if (help_file) {
    *help_file = nullptr;
  }
  if (topic_id) {
    *topic_id = 0;
  }
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::put_accName(VARIANT var_id, BSTR put_name) {
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::get_accKeyboardShortcut(VARIANT var_id,
                                                           BSTR* access_key) {
  *access_key = nullptr;
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::accLocation(LONG* physical_pixel_left,
                                               LONG* physical_pixel_top,
                                               LONG* width,
                                               LONG* height,
                                               VARIANT var_id) {
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::accNavigate(LONG nav_dir,
                                               VARIANT start,
                                               VARIANT* end) {
  end->vt = VT_EMPTY;
  return E_NOTIMPL;
}

IFACEMETHODIMP AccessibilityAlert::get_accDefaultAction(VARIANT var_id,
                                                        BSTR* default_action) {
  *default_action = nullptr;
  return E_NOTIMPL;
}

// End of IAccessible methods.

void AccessibilityAlert::SetText(const std::wstring& text) {
  text_ = text;
}

void AccessibilityAlert::SetParent(AccessibilityRootNode* parent) {
  parent_ = parent;
}

}  // namespace flutter
