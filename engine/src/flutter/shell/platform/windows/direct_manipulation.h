// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DIRECT_MANIPULATION_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DIRECT_MANIPULATION_H_

#include "flutter/fml/memory/ref_counted.h"

#include <wrl/client.h>
#include "directmanipulation.h"

namespace flutter {

class Window;
class WindowBindingHandlerDelegate;

class DirectManipulationEventHandler;

// Owner for a DirectManipulation event handler, contains the link between
// DirectManipulation and WindowBindingHandlerDelegate.
class DirectManipulationOwner {
 public:
  explicit DirectManipulationOwner(Window* window);
  // Initialize a DirectManipulation viewport with specified width and height.
  // These should match the width and height of the application window.
  int Init(unsigned int width, unsigned int height);
  // Resize the DirectManipulation viewport. Should be called when the
  // application window is resized.
  void ResizeViewport(unsigned int width, unsigned int height);
  // Set the WindowBindingHandlerDelegate which will receive callbacks based on
  // DirectManipulation updates.
  void SetBindingHandlerDelegate(
      WindowBindingHandlerDelegate* binding_handler_delegate);
  // Called when DM_POINTERHITTEST occurs with an acceptable pointer type. Will
  // start DirectManipulation for that interaction.
  void SetContact(UINT contactId);
  // Called to get updates from DirectManipulation. Should be called frequently
  // to provide smooth updates.
  void Update();
  // Release child event handler and OS resources.
  void Destroy();
  // The target that should be updated when DirectManipulation provides a new
  // pan/zoom transformation.
  WindowBindingHandlerDelegate* binding_handler_delegate;

 private:
  // The window gesture input is occuring on.
  Window* window_;
  // Cookie needed to register child event handler with viewport.
  DWORD viewportHandlerCookie_;
  // Object needed for operation of the DirectManipulation API.
  Microsoft::WRL::ComPtr<IDirectManipulationManager> manager_;
  // Object needed for operation of the DirectManipulation API.
  Microsoft::WRL::ComPtr<IDirectManipulationUpdateManager> updateManager_;
  // Object needed for operation of the DirectManipulation API.
  Microsoft::WRL::ComPtr<IDirectManipulationViewport> viewport_;
  // Child needed for operation of the DirectManipulation API.
  fml::RefPtr<DirectManipulationEventHandler> handler_;
};

// Implements DirectManipulation event handling interfaces, receives calls from
// system when gesture events occur.
class DirectManipulationEventHandler
    : public fml::RefCountedThreadSafe<DirectManipulationEventHandler>,
      public IDirectManipulationViewportEventHandler,
      public IDirectManipulationInteractionEventHandler {
  friend class DirectManipulationOwner;
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(DirectManipulationEventHandler);
  FML_FRIEND_MAKE_REF_COUNTED(DirectManipulationEventHandler);

 public:
  explicit DirectManipulationEventHandler(DirectManipulationOwner* owner)
      : owner_(owner) {}

  // |IUnknown|
  STDMETHODIMP QueryInterface(REFIID iid, void** ppv) override;

  // |IUnknown|
  ULONG STDMETHODCALLTYPE AddRef() override;

  // |IUnknown|
  ULONG STDMETHODCALLTYPE Release() override;

  // |IDirectManipulationViewportEventHandler|
  HRESULT STDMETHODCALLTYPE
  OnViewportStatusChanged(IDirectManipulationViewport* viewport,
                          DIRECTMANIPULATION_STATUS current,
                          DIRECTMANIPULATION_STATUS previous) override;

  // |IDirectManipulationViewportEventHandler|
  HRESULT STDMETHODCALLTYPE
  OnViewportUpdated(IDirectManipulationViewport* viewport) override;

  // |IDirectManipulationViewportEventHandler|
  HRESULT STDMETHODCALLTYPE
  OnContentUpdated(IDirectManipulationViewport* viewport,
                   IDirectManipulationContent* content) override;

  // |IDirectManipulationInteractionEventHandler|
  HRESULT STDMETHODCALLTYPE
  OnInteraction(IDirectManipulationViewport2* viewport,
                DIRECTMANIPULATION_INTERACTION_TYPE interaction) override;

 private:
  // Parent object, used to store the target for gesture event updates.
  DirectManipulationOwner* owner_;
  // We need to reset some parts of DirectManipulation after each gesture
  // A flag is needed to ensure that false events created as the reset occurs
  // are not sent to the flutter framework.
  bool during_synthesized_reset_ = false;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DIRECT_MANIPULATION_H_
