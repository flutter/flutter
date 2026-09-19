// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_ON_SCREEN_KEYBOARD_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_ON_SCREEN_KEYBOARD_H_

#include <windows.h>

#include <chrono>
#include <cstdint>
#include <functional>
#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/platform/windows/task_runner.h"

namespace flutter {

// Win32 operations used by on-screen keyboard window placement.
//
// This interface keeps placement policy testable without creating native
// windows. It is intentionally keyed by HWND so it can be extended for
// multiple windows without moving window state into the implementation.
class OnScreenKeyboardWin32Api {
 public:
  virtual ~OnScreenKeyboardWin32Api() = default;

  virtual HWND GetRootWindow(HWND hwnd) const = 0;
  virtual bool IsWindowValid(HWND hwnd) const = 0;
  virtual bool IsWindowMaximized(HWND hwnd) const = 0;
  virtual bool IsWindowMinimized(HWND hwnd) const = 0;
  virtual bool GetClientScreenRect(HWND hwnd, RECT* rect) const = 0;
  virtual bool GetWindowWorkArea(HWND hwnd, RECT* rect) const = 0;
  virtual bool GetWindowScreenRect(HWND hwnd, RECT* rect) const = 0;
  virtual bool GetPlacement(HWND hwnd, WINDOWPLACEMENT* placement) const = 0;
  virtual bool SetPlacement(HWND hwnd,
                            const WINDOWPLACEMENT& placement) const = 0;
  virtual bool SetPosition(HWND hwnd, const RECT& rect) const = 0;
  virtual HWINEVENTHOOK SetMoveSizeEndHook(WINEVENTPROC callback) const = 0;
  virtual void RemoveWinEventHook(HWINEVENTHOOK hook) const = 0;
};

// Controls the Windows on-screen (touch) keyboard via WinRT InputPane.
//
// Chromium: ui/base/ime/win/on_screen_keyboard_display_manager_input_pane.cc
// Display and Dismiss request IInputPane2::TryShow / TryHide with a 300 ms
// debounce. For maximized windows, Showing / Hiding update the physical bottom
// inset used for viewInsets. A restored window is moved or resized above the
// keyboard and returned to its previous placement when the keyboard closes.
// InputPane events do not change TSF (Chromium never updates TSF from those
// events). TSF HWND association, not this type, owns OS SIP auto-invoke
// suppression.
class OnScreenKeyboard {
 public:
  using VisibilityChanged = std::function<void()>;

  virtual ~OnScreenKeyboard() = default;

  // Sets the callback invoked when on-screen keyboard visibility changes.
  // Consumers should read |shown()| and |physical_bottom_inset()| when
  // handling the callback.
  virtual void SetVisibilityChangedCallback(VisibilityChanged callback) = 0;

  // Requests that the on-screen keyboard be shown for |hwnd|.
  //
  // No-op if |hwnd| is null.
  virtual void Display(HWND hwnd) = 0;

  // Requests that the on-screen keyboard be hidden for |hwnd|.
  //
  // No-op if |hwnd| is null.
  virtual void Dismiss(HWND hwnd) = 0;

  // Cancels a pending Display. Does not Dismiss.
  //
  // Called from TextInput.clearClient so a debounced TryShow cannot run
  // after the text client is gone.
  virtual void OnClientCleared() = 0;

  // Returns whether the on-screen keyboard is currently shown.
  virtual bool shown() const = 0;

  // Returns the current bottom inset caused by the on-screen keyboard, in
  // physical pixels.
  virtual double physical_bottom_inset() const = 0;
};

// Default |OnScreenKeyboard| implementation.
//
// Debounces Display/Dismiss on the platform |TaskRunner|, then drives WinRT
// IInputPane2::TryShow / TryHide. Showing/Hiding update window avoidance and
// the bottom inset. Does not call TryHide from a Showing handler.
class OnScreenKeyboardWin : public OnScreenKeyboard {
 public:
  // OccludedRect from IInputPaneVisibilityEventArgs, in root-window client
  // DIPs (96 DPI).
  struct DipRect {
    double x = 0.0;
    double y = 0.0;
    double width = 0.0;
    double height = 0.0;
  };

  // Coalesces Display/Dismiss so field-to-field focus changes do not blink
  // the on-screen keyboard. Chromium chose 300 ms after experimenting with
  // users on Windows touch devices.
  static constexpr std::chrono::milliseconds kDisplayDismissDebounce{300};

  // |task_runner| must outlive this object and is used to debounce
  // Display/Dismiss and to marshal InputPane events onto the platform thread.
  explicit OnScreenKeyboardWin(TaskRunner* task_runner);

  // Creates an instance using injected Win32 operations.
  OnScreenKeyboardWin(TaskRunner* task_runner,
                      std::unique_ptr<OnScreenKeyboardWin32Api> window_api);

  ~OnScreenKeyboardWin() override;

  // |OnScreenKeyboard|
  void SetVisibilityChangedCallback(VisibilityChanged callback) override;

  // |OnScreenKeyboard|
  void Display(HWND hwnd) override;

  // |OnScreenKeyboard|
  void Dismiss(HWND hwnd) override;

  // |OnScreenKeyboard|
  void OnClientCleared() override;

  // |OnScreenKeyboard|
  bool shown() const override;

  // |OnScreenKeyboard|
  double physical_bottom_inset() const override;

  // Converts |occluded_dip| (root-window client DIPs) to a physical screen
  // RECT: multiply by |dpi_scale|, then add |root_client_origin_screen|.
  static RECT OccludedDipToPhysicalScreenRect(const DipRect& occluded_dip,
                                              double dpi_scale,
                                              POINT root_client_origin_screen);

  // Bottom inset in physical pixels: the occluded strip at the bottom of
  // |view_client_screen|, clamped to [0, client height]. Returns 0 when the
  // rectangles do not intersect.
  static double ComputeBottomInset(const RECT& view_client_screen,
                                   const RECT& occluded_physical_screen);

  // Combines DIP → physical conversion with |ComputeBottomInset|.
  static double ComputePhysicalBottomInset(const DipRect& occluded_dip,
                                           double dpi_scale,
                                           POINT root_client_origin_screen,
                                           const RECT& view_client_screen);

  // Returns the outer window rectangle that fits above |occluded_screen|
  // within |work_area|. A window that fits retains its size and is moved only
  // as far as necessary. A taller window is resized to the available height.
  // Windows that are already clear of the occlusion are unchanged.
  static RECT ComputeWindowRectAboveOcclusion(const RECT& window_screen,
                                              const RECT& work_area,
                                              const RECT& occluded_screen);

  // Applies a Showing/Hiding observation for |view_hwnd|. |occluded_dip| is
  // ignored when |shown| is false. Exposed for tests.
  void HandleVisibilityEvent(HWND view_hwnd,
                             bool shown,
                             const DipRect& occluded_dip,
                             double dpi_scale,
                             POINT root_client_origin_screen,
                             const RECT& view_client_screen);

  // Handles the end of an interactive move or resize reported by WinEvent.
  void OnRootWindowMoveSizeEnded(HWND hwnd);

 protected:
  // Applies a coalesced show or hide via IInputPane2. Failures are ignored.
  virtual void ApplyVisibility(HWND hwnd, bool show);

  // Invokes |callback_| after updating the current shown state and inset.
  void NotifyVisibilityChanged();

 private:
  struct InputPaneSession;

  void RequestVisibility(HWND hwnd, bool show);

  // Drops a queued Display without calling TryHide.
  void CancelPendingDisplay();

  // Subscribes to InputPane Showing/Hiding for |hwnd|. No-op on COM/WinRT
  // failure (CO_E_NOTINITIALIZED, REGDB_E_CLASSNOTREG, invalid HWND).
  bool EnsureInputPane(HWND hwnd);

  void UpdateWindowForOcclusion(HWND root, HWND view);
  void RestoreWindowAfterKeyboard();
  void StartTrackingWindow(HWND root, HWND view);
  void StopTrackingWindow();

  TaskRunner* task_runner_;
  std::unique_ptr<OnScreenKeyboardWin32Api> window_api_;
  VisibilityChanged callback_;
  uint64_t generation_ = 0;
  HWND pending_hwnd_ = nullptr;
  bool pending_show_ = false;
  bool show_request_in_flight_ = false;
  bool shown_ = false;
  double physical_bottom_inset_ = 0.0;
  std::unique_ptr<InputPaneSession> pane_session_;
  HWND tracked_root_ = nullptr;
  HWND tracked_view_ = nullptr;
  HWINEVENTHOOK move_size_hook_ = nullptr;
  RECT occluded_physical_screen_{};
  bool has_occluded_physical_screen_ = false;
  std::optional<WINDOWPLACEMENT> original_window_placement_;
  HWND original_placement_root_ = nullptr;
  uint64_t geometry_generation_ = 0;

  fml::WeakPtrFactory<OnScreenKeyboardWin> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(OnScreenKeyboardWin);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_ON_SCREEN_KEYBOARD_H_
