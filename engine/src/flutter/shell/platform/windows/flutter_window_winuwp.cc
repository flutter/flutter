// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_window_winuwp.h"

namespace flutter {

// Multipler used to map controller velocity to an appropriate scroll input.
static constexpr double kControllerScrollMultiplier = 3;

FlutterWindowWinUWP::FlutterWindowWinUWP(
    ABI::Windows::ApplicationModel::Core::CoreApplicationView*
        applicationview) {
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
  // TODO(clarkezone): add support for Flutter cursors:
  // https://github.com/flutter/flutter/issues/70199
}

void FlutterWindowWinUWP::OnCursorRectUpdated(const Rect& rect) {
  // TODO(cbracken): Implement IMM candidate window positioning.
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
  return window_.Visible();
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

  binding_handler_delegate_->OnPointerDown(
      x, y, device_kind,
      FlutterPointerMouseButtons::kFlutterPointerButtonMousePrimary);
}

void FlutterWindowWinUWP::OnPointerReleased(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  double x = GetPosX(args);
  double y = GetPosY(args);
  FlutterPointerDeviceKind device_kind = GetPointerDeviceKind(args);

  binding_handler_delegate_->OnPointerUp(
      x, y, device_kind,
      FlutterPointerMouseButtons::kFlutterPointerButtonMousePrimary);
}

void FlutterWindowWinUWP::OnPointerMoved(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  double x = GetPosX(args);
  double y = GetPosY(args);
  FlutterPointerDeviceKind device_kind = GetPointerDeviceKind(args);

  binding_handler_delegate_->OnPointerMove(x, y, device_kind);
}

void FlutterWindowWinUWP::OnPointerWheelChanged(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::UI::Core::PointerEventArgs const& args) {
  double x = GetPosX(args);
  double y = GetPosY(args);
  int delta = args.CurrentPoint().Properties().MouseWheelDelta();
  binding_handler_delegate_->OnScroll(x, y, 0, -delta, 1);
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

bool FlutterWindowWinUWP::OnBitmapSurfaceUpdated(const void* allocation,
                                                 size_t row_bytes,
                                                 size_t height) {
  // TODO(gw280): Support software rendering fallback on UWP
  return false;
}

}  // namespace flutter
