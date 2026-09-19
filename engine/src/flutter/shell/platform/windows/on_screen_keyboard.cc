// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/on_screen_keyboard.h"

#include <inputpaneinterop.h>
#include <roapi.h>
#include <windows.ui.viewmanagement.h>
#include <winstring.h>
#include <wrl/client.h>
#include <wrl/event.h>

#include <algorithm>
#include <cmath>
#include <cwchar>
#include <mutex>
#include <unordered_map>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/windows/dpi_utils.h"

namespace flutter {

namespace {

using ABI::Windows::Foundation::Rect;
using ABI::Windows::UI::ViewManagement::IInputPane;
using ABI::Windows::UI::ViewManagement::IInputPane2;
using ABI::Windows::UI::ViewManagement::IInputPaneVisibilityEventArgs;
using ABI::Windows::UI::ViewManagement::InputPane;
using ABI::Windows::UI::ViewManagement::InputPaneVisibilityEventArgs;
using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

using InputPaneVisibilityHandler =
    ABI::Windows::Foundation::ITypedEventHandler<InputPane*,
                                                 InputPaneVisibilityEventArgs*>;

using RoGetActivationFactoryFn = HRESULT(WINAPI*)(HSTRING, REFIID, void**);
using WindowsCreateStringReferenceFn = HRESULT(WINAPI*)(PCWSTR,
                                                        UINT32,
                                                        HSTRING_HEADER*,
                                                        HSTRING*);

std::mutex g_move_size_hooks_mutex;
std::unordered_map<HWINEVENTHOOK, OnScreenKeyboardWin*> g_move_size_hooks;

void CALLBACK OnMoveSizeWinEvent(HWINEVENTHOOK hook,
                                 DWORD event,
                                 HWND hwnd,
                                 LONG /*object_id*/,
                                 LONG /*child_id*/,
                                 DWORD /*event_thread*/,
                                 DWORD /*event_time*/) {
  if (event != EVENT_SYSTEM_MOVESIZEEND || hwnd == nullptr) {
    return;
  }
  OnScreenKeyboardWin* keyboard = nullptr;
  {
    std::lock_guard<std::mutex> lock(g_move_size_hooks_mutex);
    const auto iterator = g_move_size_hooks.find(hook);
    if (iterator != g_move_size_hooks.end()) {
      keyboard = iterator->second;
    }
  }
  if (keyboard != nullptr) {
    keyboard->OnRootWindowMoveSizeEnded(hwnd);
  }
}

HMODULE CombaseModule() {
  static HMODULE module = LoadLibraryW(L"combase.dll");
  return module;
}

HRESULT RoGetActivationFactoryDyn(HSTRING class_id, REFIID iid, void** out) {
  static RoGetActivationFactoryFn fn = []() -> RoGetActivationFactoryFn {
    HMODULE module = CombaseModule();
    if (!module) {
      return nullptr;
    }
    return reinterpret_cast<RoGetActivationFactoryFn>(
        GetProcAddress(module, "RoGetActivationFactory"));
  }();
  if (!fn) {
    return HRESULT_FROM_WIN32(ERROR_PROC_NOT_FOUND);
  }
  return fn(class_id, iid, out);
}

HRESULT CreateHStringReference(const wchar_t* source,
                               HSTRING_HEADER* header,
                               HSTRING* out) {
  static WindowsCreateStringReferenceFn fn =
      []() -> WindowsCreateStringReferenceFn {
    HMODULE module = CombaseModule();
    if (!module) {
      return nullptr;
    }
    return reinterpret_cast<WindowsCreateStringReferenceFn>(
        GetProcAddress(module, "WindowsCreateStringReference"));
  }();
  if (!fn) {
    return HRESULT_FROM_WIN32(ERROR_PROC_NOT_FOUND);
  }
  return fn(source, static_cast<UINT32>(wcslen(source)), header, out);
}

void LogInputPaneFailure(const char* api, HRESULT hr) {
  FML_LOG(WARNING) << "On-screen keyboard " << api << " failed: 0x" << std::hex
                   << static_cast<unsigned long>(hr);
}

HWND RootWindow(HWND hwnd) {
  HWND root = GetAncestor(hwnd, GA_ROOT);
  return root ? root : hwnd;
}

bool MapClientRectToScreen(HWND hwnd, RECT* client_screen) {
  RECT client{};
  if (!GetClientRect(hwnd, &client)) {
    return false;
  }
  POINT top_left{client.left, client.top};
  POINT bottom_right{client.right, client.bottom};
  if (!ClientToScreen(hwnd, &top_left) ||
      !ClientToScreen(hwnd, &bottom_right)) {
    return false;
  }
  client_screen->left = top_left.x;
  client_screen->top = top_left.y;
  client_screen->right = bottom_right.x;
  client_screen->bottom = bottom_right.y;
  return true;
}

HRESULT GetInputPaneForWindow(HWND hwnd, IInputPane** pane) {
  HSTRING_HEADER header;
  HSTRING class_id = nullptr;
  HRESULT hr = CreateHStringReference(
      RuntimeClass_Windows_UI_ViewManagement_InputPane, &header, &class_id);
  if (FAILED(hr)) {
    return hr;
  }

  ComPtr<IInputPaneInterop> interop;
  hr = RoGetActivationFactoryDyn(class_id, IID_PPV_ARGS(&interop));
  if (FAILED(hr)) {
    return hr;
  }
  return interop->GetForWindow(RootWindow(hwnd), IID_PPV_ARGS(pane));
}

class OnScreenKeyboardWin32ApiWin final : public OnScreenKeyboardWin32Api {
 public:
  HWND GetRootWindow(HWND hwnd) const override;
  bool IsWindowValid(HWND hwnd) const override;
  bool IsWindowMaximized(HWND hwnd) const override;
  bool IsWindowMinimized(HWND hwnd) const override;
  bool GetClientScreenRect(HWND hwnd, RECT* rect) const override;
  bool GetWindowWorkArea(HWND hwnd, RECT* rect) const override;
  bool GetWindowScreenRect(HWND hwnd, RECT* rect) const override;
  bool GetPlacement(HWND hwnd, WINDOWPLACEMENT* placement) const override;
  bool SetPlacement(HWND hwnd, const WINDOWPLACEMENT& placement) const override;
  bool SetPosition(HWND hwnd, const RECT& rect) const override;
  HWINEVENTHOOK SetMoveSizeEndHook(WINEVENTPROC callback) const override;
  void RemoveWinEventHook(HWINEVENTHOOK hook) const override;
};

HWND OnScreenKeyboardWin32ApiWin::GetRootWindow(HWND hwnd) const {
  return RootWindow(hwnd);
}

bool OnScreenKeyboardWin32ApiWin::IsWindowValid(HWND hwnd) const {
  return IsWindow(hwnd);
}

bool OnScreenKeyboardWin32ApiWin::IsWindowMaximized(HWND hwnd) const {
  return IsZoomed(hwnd);
}

bool OnScreenKeyboardWin32ApiWin::IsWindowMinimized(HWND hwnd) const {
  return IsIconic(hwnd);
}

bool OnScreenKeyboardWin32ApiWin::GetClientScreenRect(HWND hwnd,
                                                      RECT* rect) const {
  return MapClientRectToScreen(hwnd, rect);
}

bool OnScreenKeyboardWin32ApiWin::GetWindowWorkArea(HWND hwnd,
                                                    RECT* rect) const {
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(monitor_info);
  HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  if (monitor == nullptr || !GetMonitorInfo(monitor, &monitor_info)) {
    return false;
  }
  *rect = monitor_info.rcWork;
  return true;
}

bool OnScreenKeyboardWin32ApiWin::GetWindowScreenRect(HWND hwnd,
                                                      RECT* rect) const {
  return GetWindowRect(hwnd, rect);
}

bool OnScreenKeyboardWin32ApiWin::GetPlacement(
    HWND hwnd,
    WINDOWPLACEMENT* placement) const {
  return GetWindowPlacement(hwnd, placement);
}

bool OnScreenKeyboardWin32ApiWin::SetPlacement(
    HWND hwnd,
    const WINDOWPLACEMENT& placement) const {
  return SetWindowPlacement(hwnd, &placement);
}

bool OnScreenKeyboardWin32ApiWin::SetPosition(HWND hwnd,
                                              const RECT& rect) const {
  return SetWindowPos(hwnd, nullptr, rect.left, rect.top,
                      rect.right - rect.left, rect.bottom - rect.top,
                      SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOZORDER);
}

HWINEVENTHOOK OnScreenKeyboardWin32ApiWin::SetMoveSizeEndHook(
    WINEVENTPROC callback) const {
  return SetWinEventHook(EVENT_SYSTEM_MOVESIZEEND, EVENT_SYSTEM_MOVESIZEEND,
                         nullptr, callback, GetCurrentProcessId(), 0,
                         WINEVENT_OUTOFCONTEXT);
}

void OnScreenKeyboardWin32ApiWin::RemoveWinEventHook(HWINEVENTHOOK hook) const {
  UnhookWinEvent(hook);
}

}  // namespace

struct OnScreenKeyboardWin::InputPaneSession {
  HWND view_hwnd = nullptr;
  ComPtr<IInputPane> pane;
  EventRegistrationToken showing_token{};
  EventRegistrationToken hiding_token{};
  bool showing_subscribed = false;
  bool hiding_subscribed = false;

  ~InputPaneSession() {
    if (!pane) {
      return;
    }
    if (showing_subscribed) {
      pane->remove_Showing(showing_token);
    }
    if (hiding_subscribed) {
      pane->remove_Hiding(hiding_token);
    }
  }
};

OnScreenKeyboardWin::OnScreenKeyboardWin(TaskRunner* task_runner)
    : OnScreenKeyboardWin(task_runner,
                          std::make_unique<OnScreenKeyboardWin32ApiWin>()) {}

OnScreenKeyboardWin::OnScreenKeyboardWin(
    TaskRunner* task_runner,
    std::unique_ptr<OnScreenKeyboardWin32Api> window_api)
    : task_runner_(task_runner),
      window_api_(std::move(window_api)),
      weak_factory_(this) {
  FML_DCHECK(task_runner_);
  FML_DCHECK(window_api_);
}

OnScreenKeyboardWin::~OnScreenKeyboardWin() {
  RestoreWindowAfterKeyboard();
}

void OnScreenKeyboardWin::SetVisibilityChangedCallback(
    VisibilityChanged callback) {
  callback_ = std::move(callback);
}

void OnScreenKeyboardWin::Display(HWND hwnd) {
  RequestVisibility(hwnd, true);
}

void OnScreenKeyboardWin::Dismiss(HWND hwnd) {
  if (!shown_ && !pending_show_ && !show_request_in_flight_) {
    return;
  }
  RequestVisibility(hwnd, false);
}

void OnScreenKeyboardWin::OnClientCleared() {
  CancelPendingDisplay();
}

bool OnScreenKeyboardWin::shown() const {
  return shown_;
}

double OnScreenKeyboardWin::physical_bottom_inset() const {
  return physical_bottom_inset_;
}

RECT OnScreenKeyboardWin::OccludedDipToPhysicalScreenRect(
    const DipRect& occluded_dip,
    double dpi_scale,
    POINT root_client_origin_screen) {
  const double physical_x = occluded_dip.x * dpi_scale;
  const double physical_y = occluded_dip.y * dpi_scale;
  const double physical_width = occluded_dip.width * dpi_scale;
  const double physical_height = occluded_dip.height * dpi_scale;
  RECT result;
  result.left =
      static_cast<LONG>(std::lround(physical_x + root_client_origin_screen.x));
  result.top =
      static_cast<LONG>(std::lround(physical_y + root_client_origin_screen.y));
  result.right = static_cast<LONG>(
      std::lround(physical_x + physical_width + root_client_origin_screen.x));
  result.bottom = static_cast<LONG>(
      std::lround(physical_y + physical_height + root_client_origin_screen.y));
  return result;
}

double OnScreenKeyboardWin::ComputeBottomInset(
    const RECT& view_client_screen,
    const RECT& occluded_physical_screen) {
  const LONG intersect_left =
      std::max(view_client_screen.left, occluded_physical_screen.left);
  const LONG intersect_top =
      std::max(view_client_screen.top, occluded_physical_screen.top);
  const LONG intersect_right =
      std::min(view_client_screen.right, occluded_physical_screen.right);
  const LONG intersect_bottom =
      std::min(view_client_screen.bottom, occluded_physical_screen.bottom);
  if (intersect_right <= intersect_left || intersect_bottom <= intersect_top) {
    return 0.0;
  }

  const double client_height =
      static_cast<double>(view_client_screen.bottom - view_client_screen.top);
  if (client_height <= 0.0) {
    return 0.0;
  }

  const double inset = static_cast<double>(view_client_screen.bottom) -
                       static_cast<double>(intersect_top);
  return std::clamp(inset, 0.0, client_height);
}

double OnScreenKeyboardWin::ComputePhysicalBottomInset(
    const DipRect& occluded_dip,
    double dpi_scale,
    POINT root_client_origin_screen,
    const RECT& view_client_screen) {
  const RECT occluded_screen = OccludedDipToPhysicalScreenRect(
      occluded_dip, dpi_scale, root_client_origin_screen);
  return ComputeBottomInset(view_client_screen, occluded_screen);
}

RECT OnScreenKeyboardWin::ComputeWindowRectAboveOcclusion(
    const RECT& window_screen,
    const RECT& work_area,
    const RECT& occluded_screen) {
  const bool overlaps_horizontally =
      window_screen.left < occluded_screen.right &&
      window_screen.right > occluded_screen.left;
  const LONG available_bottom = std::min(work_area.bottom, occluded_screen.top);
  if (!overlaps_horizontally || available_bottom <= work_area.top ||
      window_screen.bottom <= available_bottom) {
    return window_screen;
  }

  RECT result = window_screen;
  const LONG window_height = window_screen.bottom - window_screen.top;
  const LONG available_height = available_bottom - work_area.top;
  if (window_height <= available_height) {
    result.bottom = available_bottom;
    result.top = available_bottom - window_height;
  } else {
    result.top = work_area.top;
    result.bottom = available_bottom;
  }
  return result;
}

void OnScreenKeyboardWin::ApplyVisibility(HWND hwnd, bool show) {
  if (hwnd == nullptr || !window_api_->IsWindowValid(hwnd)) {
    return;
  }
  if (!EnsureInputPane(hwnd) || !pane_session_ || !pane_session_->pane) {
    return;
  }

  ComPtr<IInputPane2> pane2;
  HRESULT hr = pane_session_->pane.As(&pane2);
  if (FAILED(hr) || !pane2) {
    LogInputPaneFailure("QueryInterface(IInputPane2)", hr);
    return;
  }

  boolean succeeded = FALSE;
  hr = show ? pane2->TryShow(&succeeded) : pane2->TryHide(&succeeded);
  if (FAILED(hr)) {
    LogInputPaneFailure(show ? "TryShow" : "TryHide", hr);
  }
}

void OnScreenKeyboardWin::NotifyVisibilityChanged() {
  if (callback_) {
    callback_();
  }
}

void OnScreenKeyboardWin::RequestVisibility(HWND hwnd, bool show) {
  if (hwnd == nullptr) {
    return;
  }

  pending_hwnd_ = hwnd;
  pending_show_ = show;
  const uint64_t generation = ++generation_;
  task_runner_->PostDelayedTask(
      [weak = weak_factory_.GetWeakPtr(), generation]() {
        if (!weak || generation != weak->generation_) {
          return;
        }
        const bool show = weak->pending_show_;
        const HWND hwnd = weak->pending_hwnd_;
        weak->pending_show_ = false;
        // A Dismiss may supersede an applied Display before Showing arrives.
        weak->show_request_in_flight_ = show;
        weak->ApplyVisibility(hwnd, show);
      },
      kDisplayDismissDebounce);
}

void OnScreenKeyboardWin::CancelPendingDisplay() {
  if (!pending_show_) {
    return;
  }
  ++generation_;
  pending_show_ = false;
}

bool OnScreenKeyboardWin::EnsureInputPane(HWND hwnd) {
  if (pane_session_ && pane_session_->view_hwnd == hwnd &&
      pane_session_->pane) {
    return true;
  }

  pane_session_.reset();
  if (!window_api_->IsWindowValid(hwnd)) {
    return false;
  }

  ComPtr<IInputPane> pane;
  HRESULT hr = GetInputPaneForWindow(hwnd, &pane);
  if (FAILED(hr) || !pane) {
    LogInputPaneFailure("GetForWindow", hr);
    return false;
  }
  auto session = std::make_unique<InputPaneSession>();
  session->view_hwnd = hwnd;
  session->pane = pane;

  auto showing_handler = Callback<InputPaneVisibilityHandler>(
      [runner = task_runner_, weak = weak_factory_.GetWeakPtr(),
       view_hwnd = hwnd](IInputPane* /*sender*/,
                         IInputPaneVisibilityEventArgs* args) {
        DipRect occluded_dip{};
        if (args) {
          Rect occluded{};
          if (SUCCEEDED(args->get_OccludedRect(&occluded))) {
            occluded_dip.x = occluded.X;
            occluded_dip.y = occluded.Y;
            occluded_dip.width = occluded.Width;
            occluded_dip.height = occluded.Height;
          }
        }
        // Capture the coordinate-space conversion with the event. The root
        // window may move before the marshalled task runs.
        HWND root = RootWindow(view_hwnd);
        const double scale = static_cast<double>(GetDpiForHWND(root)) /
                             static_cast<double>(kDefaultDpi);
        POINT origin{0, 0};
        ClientToScreen(root, &origin);
        // InputPane is not agile; marshal before touching engine state.
        runner->RunNowOrPostTask(
            [weak, view_hwnd, occluded_dip, scale, origin]() {
              if (!weak || !weak->window_api_->IsWindowValid(view_hwnd)) {
                return;
              }
              RECT view_client{};
              if (!weak->window_api_->GetClientScreenRect(view_hwnd,
                                                          &view_client)) {
                return;
              }
              weak->HandleVisibilityEvent(view_hwnd, true, occluded_dip, scale,
                                          origin, view_client);
            });
        return S_OK;
      });
  auto hiding_handler = Callback<InputPaneVisibilityHandler>(
      [runner = task_runner_, weak = weak_factory_.GetWeakPtr()](
          IInputPane* /*sender*/, IInputPaneVisibilityEventArgs* /*args*/) {
        runner->RunNowOrPostTask([weak]() {
          if (!weak) {
            return;
          }
          RECT empty{};
          weak->HandleVisibilityEvent(nullptr, false, DipRect{}, 1.0,
                                      POINT{0, 0}, empty);
        });
        return S_OK;
      });

  if (!showing_handler || !hiding_handler) {
    LogInputPaneFailure("Callback", E_OUTOFMEMORY);
    return false;
  }

  hr = pane->add_Showing(showing_handler.Get(), &session->showing_token);
  if (FAILED(hr)) {
    LogInputPaneFailure("add_Showing", hr);
    return false;
  }
  session->showing_subscribed = true;

  hr = pane->add_Hiding(hiding_handler.Get(), &session->hiding_token);
  if (FAILED(hr)) {
    LogInputPaneFailure("add_Hiding", hr);
    return false;
  }
  session->hiding_subscribed = true;

  pane_session_ = std::move(session);
  return true;
}

void OnScreenKeyboardWin::OnRootWindowMoveSizeEnded(HWND hwnd) {
  task_runner_->RunNowOrPostTask([weak = weak_factory_.GetWeakPtr(), hwnd]() {
    if (!weak || !weak->shown_ || hwnd != weak->tracked_root_) {
      return;
    }
    // EVENT_SYSTEM_MOVESIZEEND represents the end of an interactive move
    // or resize. Restore to that user-selected placement, rather than the
    // placement from before the keyboard opened.
    WINDOWPLACEMENT placement{};
    placement.length = sizeof(placement);
    if (weak->window_api_->GetPlacement(hwnd, &placement)) {
      weak->original_window_placement_ = placement;
      weak->original_placement_root_ = hwnd;
    }
    weak->UpdateWindowForOcclusion(hwnd, weak->tracked_view_);
    weak->NotifyVisibilityChanged();
  });
}

void OnScreenKeyboardWin::StartTrackingWindow(HWND root, HWND view) {
  if (tracked_root_ == root && tracked_view_ == view) {
    return;
  }
  if (original_window_placement_ &&
      window_api_->IsWindowValid(original_placement_root_)) {
    window_api_->SetPlacement(original_placement_root_,
                              *original_window_placement_);
    original_window_placement_.reset();
    original_placement_root_ = nullptr;
  }
  StopTrackingWindow();
  tracked_root_ = root;
  tracked_view_ = view;
  move_size_hook_ = window_api_->SetMoveSizeEndHook(OnMoveSizeWinEvent);
  if (move_size_hook_ != nullptr) {
    std::lock_guard<std::mutex> lock(g_move_size_hooks_mutex);
    g_move_size_hooks[move_size_hook_] = this;
  }
}

void OnScreenKeyboardWin::StopTrackingWindow() {
  if (move_size_hook_ != nullptr) {
    {
      std::lock_guard<std::mutex> lock(g_move_size_hooks_mutex);
      g_move_size_hooks.erase(move_size_hook_);
    }
    window_api_->RemoveWinEventHook(move_size_hook_);
    move_size_hook_ = nullptr;
  }
  tracked_root_ = nullptr;
  tracked_view_ = nullptr;
}

void OnScreenKeyboardWin::UpdateWindowForOcclusion(HWND root, HWND view) {
  if (!window_api_->IsWindowValid(root) || !has_occluded_physical_screen_) {
    return;
  }

  RECT view_client_screen{};
  if (window_api_->IsWindowMaximized(root) ||
      window_api_->IsWindowMinimized(root)) {
    // A user-initiated maximize supersedes any placement that was saved while
    // the keyboard was open.
    original_window_placement_.reset();
    original_placement_root_ = nullptr;
    if (view != nullptr &&
        window_api_->GetClientScreenRect(view, &view_client_screen)) {
      physical_bottom_inset_ =
          ComputeBottomInset(view_client_screen, occluded_physical_screen_);
    }
    return;
  }

  RECT work_area{};
  RECT window_screen{};
  if (!window_api_->GetWindowWorkArea(root, &work_area) ||
      !window_api_->GetWindowScreenRect(root, &window_screen)) {
    return;
  }

  const RECT adjusted = ComputeWindowRectAboveOcclusion(
      window_screen, work_area, occluded_physical_screen_);
  if (adjusted.left != window_screen.left ||
      adjusted.top != window_screen.top ||
      adjusted.right != window_screen.right ||
      adjusted.bottom != window_screen.bottom) {
    if (!original_window_placement_) {
      WINDOWPLACEMENT placement{};
      placement.length = sizeof(placement);
      if (window_api_->GetPlacement(root, &placement)) {
        original_window_placement_ = placement;
        original_placement_root_ = root;
      }
    }
    window_api_->SetPosition(root, adjusted);
  }

  if (view != nullptr &&
      window_api_->GetClientScreenRect(view, &view_client_screen)) {
    physical_bottom_inset_ =
        ComputeBottomInset(view_client_screen, occluded_physical_screen_);
  }
}

void OnScreenKeyboardWin::RestoreWindowAfterKeyboard() {
  StopTrackingWindow();
  if (original_window_placement_ &&
      window_api_->IsWindowValid(original_placement_root_)) {
    window_api_->SetPlacement(original_placement_root_,
                              *original_window_placement_);
  }
  original_window_placement_.reset();
  original_placement_root_ = nullptr;
  has_occluded_physical_screen_ = false;
}

void OnScreenKeyboardWin::HandleVisibilityEvent(
    HWND view_hwnd,
    bool shown,
    const DipRect& occluded_dip,
    double dpi_scale,
    POINT root_client_origin_screen,
    const RECT& view_client_screen) {
  shown_ = shown;
  bool notify_immediately = true;
  if (shown) {
    const uint64_t geometry_generation = ++geometry_generation_;
    show_request_in_flight_ = false;
    occluded_physical_screen_ = OccludedDipToPhysicalScreenRect(
        occluded_dip, dpi_scale, root_client_origin_screen);
    has_occluded_physical_screen_ = true;
    HWND root =
        view_hwnd != nullptr ? window_api_->GetRootWindow(view_hwnd) : nullptr;
    if (root != nullptr && window_api_->IsWindowValid(root)) {
      StartTrackingWindow(root, view_hwnd);
      if (window_api_->IsWindowMaximized(root)) {
        // Maximized windows remain fixed and consume the occlusion as an
        // inset, so there is no geometry animation to coalesce.
        UpdateWindowForOcclusion(root, view_hwnd);
      } else {
        // InputPane may report several intermediate rectangles while opening.
        // Apply restored-window geometry only after the final observation has
        // remained stable for the debounce interval.
        notify_immediately = false;
        task_runner_->PostDelayedTask(
            [weak = weak_factory_.GetWeakPtr(), geometry_generation, root,
             view_hwnd]() {
              if (!weak || !weak->shown_ ||
                  geometry_generation != weak->geometry_generation_ ||
                  root != weak->tracked_root_) {
                return;
              }
              weak->UpdateWindowForOcclusion(root, view_hwnd);
              weak->NotifyVisibilityChanged();
            },
            kDisplayDismissDebounce);
      }
    } else {
      physical_bottom_inset_ =
          ComputeBottomInset(view_client_screen, occluded_physical_screen_);
    }
  } else {
    show_request_in_flight_ = false;
    physical_bottom_inset_ = 0.0;
    const uint64_t geometry_generation = ++geometry_generation_;
    task_runner_->PostDelayedTask(
        [weak = weak_factory_.GetWeakPtr(), geometry_generation]() {
          if (weak && geometry_generation == weak->geometry_generation_) {
            weak->RestoreWindowAfterKeyboard();
          }
        },
        kDisplayDismissDebounce);
  }
  if (notify_immediately) {
    NotifyVisibilityChanged();
  }
}

}  // namespace flutter
