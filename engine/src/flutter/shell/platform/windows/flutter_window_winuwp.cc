// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_window_winuwp.h"

#include <map>

namespace flutter {

// Multipler used to map controller velocity to an appropriate scroll input.
static constexpr double kControllerScrollMultiplier = 3;

// Minimum pointer ID that gets emitted by the pointer ID generator.
static constexpr uint32_t kMinPointerId = 0;

// Maximum pointer ID that gets emitted by the pointer ID generator.
static constexpr uint32_t kMaxPointerId = 128;

// Maps a Flutter cursor name to a CoreCursor.
//
// Returns the arrow cursor for unknown constants.
//
// This map must be kept in sync with Flutter framework's
// services/mouse_cursor.dart.
namespace {
using winrt::Windows::UI::Core::CoreCursorType;

std::map<std::string, const CoreCursorType> cursors{
    {"allScroll", CoreCursorType::SizeAll},
    {"basic", CoreCursorType::Arrow},
    {"click", CoreCursorType::Hand},
    {"forbidden", CoreCursorType::UniversalNo},
    {"help", CoreCursorType::Help},
    {"move", CoreCursorType::SizeAll},
    {"noDrop", CoreCursorType::UniversalNo},
    {"precise", CoreCursorType::Cross},
    {"text", CoreCursorType::IBeam},
    {"resizeColumn", CoreCursorType::SizeWestEast},
    {"resizeDown", CoreCursorType::SizeNorthSouth},
    {"resizeDownLeft", CoreCursorType::SizeNortheastSouthwest},
    {"resizeDownRight", CoreCursorType::SizeNorthwestSoutheast},
    {"resizeLeft", CoreCursorType::SizeWestEast},
    {"resizeLeftRight", CoreCursorType::SizeWestEast},
    {"resizeRight", CoreCursorType::SizeWestEast},
    {"resizeRow", CoreCursorType::SizeNorthSouth},
    {"resizeUp", CoreCursorType::SizeNorthSouth},
    {"resizeUpDown", CoreCursorType::SizeNorthSouth},
    {"resizeUpLeft", CoreCursorType::SizeNorthwestSoutheast},
    {"resizeUpRight", CoreCursorType::SizeNortheastSouthwest},
    {"resizeUpLeftDownRight", CoreCursorType::SizeNorthwestSoutheast},
    {"resizeUpRightDownLeft", CoreCursorType::SizeNortheastSouthwest},
    {"wait", CoreCursorType::Wait},
};

winrt::Windows::UI::Core::CoreCursor GetCursorByName(
    const std::string& cursor_name) {
  if (cursor_name == "none") {
    return winrt::Windows::UI::Core::CoreCursor{nullptr};
  } else {
    auto cursor_type = CoreCursorType::Arrow;
    auto it = cursors.find(cursor_name);
    if (it != cursors.end()) {
      cursor_type = it->second;
    }
    return winrt::Windows::UI::Core::CoreCursor(cursor_type, 0);
  }
}

}  // namespace

FlutterWindowWinUWP::FlutterWindowWinUWP(
    ABI::Windows::ApplicationModel::Core::CoreApplicationView* applicationview)
    : pointer_id_generator_(kMinPointerId, kMaxPointerId) {
  winrt::Windows::ApplicationModel::Core::CoreApplicationView cav{nullptr};
  winrt::copy_from_abi(cav, applicationview);

  application_view_ = cav;
  window_ = application_view_.CoreWindow();

  SetEventHandlers();

  display_helper_ = std::make_unique<DisplayHelperWinUWP>();
}

WindowsRenderTarget FlutterWindowWinUWP::GetRenderTarget() {
#ifdef USECOREWINDOW
  return WindowsRenderTarget(window_);
#else
  compositor_ = winrt::Windows::UI::Composition::Compositor();
  target_ = compositor_.CreateTargetForCurrentView();
  visual_tree_root_ = compositor_.CreateContainerVisual();
  target_.Root(visual_tree_root_);

  render_target_ = compositor_.CreateSpriteVisual();
  render_target_.Offset({display_helper_->GetRenderTargetXOffset(),
                         display_helper_->GetRenderTargetYOffset(), 1.0});
  if (!display_helper_->IsRunningOnLargeScreenDevice()) {
    ApplyInverseDpiScalingTransform();
  }
  visual_tree_root_.Children().InsertAtBottom(render_target_);
  game_pad_cursor_ = std::make_unique<GamepadCursorWinUWP>(
      binding_handler_delegate_, display_helper_.get(), window_, compositor_,
      visual_tree_root_.Children());
  WindowBoundsWinUWP bounds = display_helper_->GetPhysicalBounds();

  render_target_.Size({bounds.width, bounds.height});
  return WindowsRenderTarget(render_target_);
#endif
}

PlatformWindow FlutterWindowWinUWP::GetPlatformWindow() {
  return application_view_;
}

void FlutterWindowWinUWP::ApplyInverseDpiScalingTransform() {
  // Apply inverse transform to negate built in DPI scaling in order to render
  // at native scale.
  auto dpiScale = GetDpiScale();
  render_target_.Scale({1 / dpiScale, 1 / dpiScale, 1 / dpiScale});
}

PhysicalWindowBounds FlutterWindowWinUWP::GetPhysicalWindowBounds() {
  WindowBoundsWinUWP bounds = display_helper_->GetPhysicalBounds();
  return {static_cast<size_t>(bounds.width),
          static_cast<size_t>(bounds.height)};
}

void FlutterWindowWinUWP::UpdateFlutterCursor(const std::string& cursor_name) {
  window_.PointerCursor(GetCursorByName(cursor_name));
}

void FlutterWindowWinUWP::OnCursorRectUpdated(const Rect& rect) {
  // TODO(cbracken): Implement IMM candidate window positioning.
}

void FlutterWindowWinUWP::OnResetImeComposing() {
  // TODO(cbracken): Cancel composing, close the candidates view, and clear the
  // composing text.
}

void FlutterWindowWinUWP::OnWindowResized() {}

FlutterWindowWinUWP::~FlutterWindowWinUWP() {}

void FlutterWindowWinUWP::SetView(WindowBindingHandlerDelegate* view) {
  binding_handler_delegate_ = view;
}

void FlutterWindowWinUWP::SetEventHandlers() {
  auto app_view =
      winrt::Windows::UI::ViewManagement::ApplicationView::GetForCurrentView();

  app_view.SetDesiredBoundsMode(winrt::Windows::UI::ViewManagement::
                                    ApplicationViewBoundsMode::UseCoreWindow);

  app_view.VisibleBoundsChanged({this, &FlutterWindowWinUWP::OnBoundsChanged});

  window_.PointerPressed({this, &FlutterWindowWinUWP::OnPointerPressed});
  window_.PointerReleased({this, &FlutterWindowWinUWP::OnPointerReleased});
  window_.PointerMoved({this, &FlutterWindowWinUWP::OnPointerMoved});
  window_.PointerWheelChanged(
      {this, &FlutterWindowWinUWP::OnPointerWheelChanged});

  ui_settings_.ColorValuesChanged(
      {this, &FlutterWindowWinUWP::OnColorValuesChanged});

  // TODO(clarkezone) support mouse leave handling
  // https://github.com/flutter/flutter/issues/70199

  // TODO(clarkezone) support system font changed
  // https://github.com/flutter/flutter/issues/70198

  window_.KeyUp({this, &FlutterWindowWinUWP::OnKeyUp});
  window_.KeyDown({this, &FlutterWindowWinUWP::OnKeyDown});
  window_.CharacterReceived({this, &FlutterWindowWinUWP::OnCharacterReceived});

  auto display = winrt::Windows::Graphics::Display::DisplayInformation::
      GetForCurrentView();
  display.DpiChanged({this, &FlutterWindowWinUWP::OnDpiChanged});
}

float FlutterWindowWinUWP::GetDpiScale() {
  return display_helper_->GetDpiScale();
}

bool FlutterWindowWinUWP::IsVisible() {
  // This is called from raster thread as an optimization to not wait for vsync
  // if window is invisible. However CoreWindow is not agile so we can't call
  // Visible() from raster thread. For now assume window is always visible.
  // Possible solution would be to register a VisibilityChanged handler and
  // store the visiblity state in a variable. TODO(knopp)
  // https://github.com/flutter/flutter/issues/87870
  return true;
}

void FlutterWindowWinUWP::OnDpiChanged(
    winrt::Windows::Graphics::Display::DisplayInformation const& args,
    winrt::Windows::Foundation::IInspectable const&) {
  ApplyInverseDpiScalingTransform();

  WindowBoundsWinUWP bounds = display_helper_->GetPhysicalBounds();

  binding_handler_delegate_->OnWindowSizeChanged(
      static_cast<size_t>(bounds.width), static_cast<size_t>(bounds.height));
}

void FlutterWindowWinUWP::OnPointerPressed(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  double x = GetPosX(args);
  double y = GetPosY(args);
  FlutterPointerDeviceKind device_kind = GetPointerDeviceKind(args);
  FlutterPointerMouseButtons mouse_button = GetPointerMouseButton(args);
  auto pointer_id = GetPointerId(args);

  binding_handler_delegate_->OnPointerDown(x, y, device_kind, pointer_id,
                                           mouse_button);
}

void FlutterWindowWinUWP::OnPointerReleased(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  double x = GetPosX(args);
  double y = GetPosY(args);
  FlutterPointerDeviceKind device_kind = GetPointerDeviceKind(args);
  FlutterPointerMouseButtons mouse_button = GetPointerMouseButton(args);
  auto pointer_id = GetPointerId(args);

  binding_handler_delegate_->OnPointerUp(x, y, device_kind, pointer_id,
                                         mouse_button);
  ReleasePointer(args);
}

void FlutterWindowWinUWP::OnPointerMoved(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  double x = GetPosX(args);
  double y = GetPosY(args);
  FlutterPointerDeviceKind device_kind = GetPointerDeviceKind(args);
  auto pointer_id = GetPointerId(args);

  binding_handler_delegate_->OnPointerMove(x, y, device_kind, pointer_id);
}

void FlutterWindowWinUWP::OnPointerWheelChanged(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  double x = GetPosX(args);
  double y = GetPosY(args);
  FlutterPointerDeviceKind device_kind = GetPointerDeviceKind(args);
  auto pointer_id = GetPointerId(args);
  int delta = args.CurrentPoint().Properties().MouseWheelDelta();
  binding_handler_delegate_->OnScroll(x, y, 0, -delta, 1, device_kind,
                                      pointer_id);
}

double FlutterWindowWinUWP::GetPosX(
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  const double inverse_dpi_scale = GetDpiScale();

  return (args.CurrentPoint().Position().X -
          display_helper_->GetRenderTargetXOffset()) *
         inverse_dpi_scale;
}

double FlutterWindowWinUWP::GetPosY(
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  const double inverse_dpi_scale = GetDpiScale();
  return static_cast<double>((args.CurrentPoint().Position().Y -
                              display_helper_->GetRenderTargetYOffset()) *
                             inverse_dpi_scale);
}

FlutterPointerDeviceKind FlutterWindowWinUWP::GetPointerDeviceKind(
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  switch (args.CurrentPoint().PointerDevice().PointerDeviceType()) {
    case winrt::Windows::Devices::Input::PointerDeviceType::Mouse:
      return kFlutterPointerDeviceKindMouse;
    case winrt::Windows::Devices::Input::PointerDeviceType::Pen:
      return kFlutterPointerDeviceKindStylus;
    case winrt::Windows::Devices::Input::PointerDeviceType::Touch:
      return kFlutterPointerDeviceKindTouch;
  }
  return kFlutterPointerDeviceKindMouse;
}

FlutterPointerMouseButtons FlutterWindowWinUWP::GetPointerMouseButton(
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  switch (args.CurrentPoint().Properties().PointerUpdateKind()) {
    case winrt::Windows::UI::Input::PointerUpdateKind::LeftButtonPressed:
    case winrt::Windows::UI::Input::PointerUpdateKind::LeftButtonReleased:
      return kFlutterPointerButtonMousePrimary;
    case winrt::Windows::UI::Input::PointerUpdateKind::RightButtonPressed:
    case winrt::Windows::UI::Input::PointerUpdateKind::RightButtonReleased:
      return kFlutterPointerButtonMouseSecondary;
    case winrt::Windows::UI::Input::PointerUpdateKind::MiddleButtonPressed:
    case winrt::Windows::UI::Input::PointerUpdateKind::MiddleButtonReleased:
      return kFlutterPointerButtonMouseMiddle;
    case winrt::Windows::UI::Input::PointerUpdateKind::XButton1Pressed:
    case winrt::Windows::UI::Input::PointerUpdateKind::XButton1Released:
      return kFlutterPointerButtonMouseBack;
    case winrt::Windows::UI::Input::PointerUpdateKind::XButton2Pressed:
    case winrt::Windows::UI::Input::PointerUpdateKind::XButton2Released:
      return kFlutterPointerButtonMouseForward;
    case winrt::Windows::UI::Input::PointerUpdateKind::Other:
      return kFlutterPointerButtonMousePrimary;
  }
  return kFlutterPointerButtonMousePrimary;
}

void FlutterWindowWinUWP::ReleasePointer(
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  pointer_id_generator_.ReleaseNumber(args.CurrentPoint().PointerId());
}

uint32_t FlutterWindowWinUWP::GetPointerId(
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  // Generate a mapped ID in the interval [kMinPointerId, kMaxPointerId].
  return pointer_id_generator_.GetGeneratedId(args.CurrentPoint().PointerId());
}

void FlutterWindowWinUWP::OnBoundsChanged(
    winrt::Windows::UI::ViewManagement::ApplicationView const& app_view,
    winrt::Windows::Foundation::IInspectable const&) {
  if (binding_handler_delegate_) {
    auto bounds = display_helper_->GetPhysicalBounds();

    binding_handler_delegate_->OnWindowSizeChanged(
        static_cast<size_t>(bounds.width), static_cast<size_t>(bounds.height));
#ifndef USECOREWINDOW

    render_target_.Size({bounds.width, bounds.height});

#endif
  }
}

void FlutterWindowWinUWP::OnKeyUp(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::KeyEventArgs const& args) {
  // TODO(clarkezone) complete keyboard handling including
  // system key (back), unicode handling, shortcut support,
  // handling defered delivery, remove the need for action value.
  // https://github.com/flutter/flutter/issues/70202
  auto status = args.KeyStatus();
  unsigned int scancode = status.ScanCode;
  int key = static_cast<int>(args.VirtualKey());
  int action = 0x0101;
  binding_handler_delegate_->OnKey(key, scancode, action, 0,
                                   status.IsExtendedKey /* extended */,
                                   status.WasKeyDown /* was_down */);
}

void FlutterWindowWinUWP::OnKeyDown(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::KeyEventArgs const& args) {
  // TODO(clarkezone) complete keyboard handling including
  // system key (back), unicode handling, shortcut support
  // handling defered delivery, remove the need for action value.
  // https://github.com/flutter/flutter/issues/70202
  auto status = args.KeyStatus();
  unsigned int scancode = status.ScanCode;
  int key = static_cast<int>(args.VirtualKey());
  int action = 0x0100;
  binding_handler_delegate_->OnKey(key, scancode, action, 0,
                                   status.IsExtendedKey /* extended */,
                                   status.WasKeyDown /* was_down */);
}

void FlutterWindowWinUWP::OnCharacterReceived(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::CharacterReceivedEventArgs const& args) {
  auto key = args.KeyCode();
  wchar_t keycode = static_cast<wchar_t>(key);
  if (keycode >= u' ') {
    std::u16string text({keycode});
    binding_handler_delegate_->OnText(text);
  }
}

void FlutterWindowWinUWP::OnColorValuesChanged(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::Foundation::IInspectable const&) {
  binding_handler_delegate_->OnPlatformBrightnessChanged();
}

bool FlutterWindowWinUWP::OnBitmapSurfaceUpdated(const void* allocation,
                                                 size_t row_bytes,
                                                 size_t height) {
  // TODO(gw280): Support software rendering fallback on UWP
  return false;
}

}  // namespace flutter
