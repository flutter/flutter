// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_ALERT_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_ALERT_H_

#include <atlbase.h>
#include <atlcom.h>
#include <oleacc.h>

#include <string>

namespace flutter {

class AccessibilityRootNode;

// An IAccessible node representing an alert read to the screen reader.
// When an announcement is requested by the framework, an instance of
// this class, if none exists already, is created and made a child of
// the root AccessibilityRootNode node, and is therefore also a sibling
// of the window's root node.
// This node is not interactable to the user.
class AccessibilityAlert : public CComObjectRootEx<CComMultiThreadModel>,
                           public IDispatchImpl<IAccessible> {
 public:
  BEGIN_COM_MAP(AccessibilityAlert)
  COM_INTERFACE_ENTRY(IAccessible)
  END_COM_MAP()
  //
  // IAccessible methods.
  //

  // Retrieves the child element or child object at a given point on the screen.
  IFACEMETHODIMP accHitTest(LONG screen_physical_pixel_x,
                            LONG screen_physical_pixel_y,
                            VARIANT* child) override;

  // Retrieves an IDispatch interface pointer for the specified child.
  IFACEMETHODIMP get_accChild(VARIANT var_child,
                              IDispatch** disp_child) override;

  // Retrieves the number of accessible children.
  IFACEMETHODIMP get_accChildCount(LONG* child_count) override;

  // Retrieves a string that describes the object's default action.
  IFACEMETHODIMP get_accDefaultAction(VARIANT var_id,
                                      BSTR* default_action) override;

  // Retrieves the tooltip description.
  IFACEMETHODIMP get_accDescription(VARIANT var_id, BSTR* desc) override;

  // Retrieves the name of the specified object.
  IFACEMETHODIMP get_accName(VARIANT var_id, BSTR* name) override;

  // Retrieves the IDispatch interface of the object's parent.
  IFACEMETHODIMP get_accParent(IDispatch** disp_parent) override;

  // Retrieves information describing the role of the specified object.
  IFACEMETHODIMP get_accRole(VARIANT var_id, VARIANT* role) override;

  // Retrieves the current state of the specified object.
  IFACEMETHODIMP get_accState(VARIANT var_id, VARIANT* state) override;

  // Gets the help string for the specified object.
  IFACEMETHODIMP get_accHelp(VARIANT var_id, BSTR* help) override;

  // Retrieve the string value associated with the specified object.
  IFACEMETHODIMP get_accValue(VARIANT var_id, BSTR* value) override;

  // IAccessible methods not implemented.
  IFACEMETHODIMP accLocation(LONG* physical_pixel_left,
                             LONG* physical_pixel_top,
                             LONG* width,
                             LONG* height,
                             VARIANT var_id) override;
  IFACEMETHODIMP accNavigate(LONG nav_dir,
                             VARIANT start,
                             VARIANT* end) override;
  IFACEMETHODIMP accDoDefaultAction(VARIANT var_id) override;
  IFACEMETHODIMP get_accFocus(VARIANT* focus_child) override;
  IFACEMETHODIMP get_accKeyboardShortcut(VARIANT var_id,
                                         BSTR* access_key) override;
  IFACEMETHODIMP get_accSelection(VARIANT* selected) override;
  IFACEMETHODIMP accSelect(LONG flags_sel, VARIANT var_id) override;
  IFACEMETHODIMP get_accHelpTopic(BSTR* help_file,
                                  VARIANT var_id,
                                  LONG* topic_id) override;
  IFACEMETHODIMP put_accName(VARIANT var_id, BSTR put_name) override;
  IFACEMETHODIMP put_accValue(VARIANT var_id, BSTR new_value) override;

  // End of IAccessible methods.

  AccessibilityAlert();
  ~AccessibilityAlert() = default;

  // Sets the text of this alert to the provided message.
  void SetText(const std::wstring& text);

  void SetParent(AccessibilityRootNode* parent);

 private:
  std::wstring text_;

  AccessibilityRootNode* parent_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_ALERT_H_
