// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/testing/platform/webthemeengine_impl.h"

#include "skia/ext/platform_canvas.h"
#include "sky/engine/public/platform/WebRect.h"
#include "sky/engine/public/platform/WebSize.h"
#include "ui/native_theme/native_theme.h"

using blink::WebCanvas;
using blink::WebColor;
using blink::WebRect;
using blink::WebThemeEngine;

namespace sky {

static ui::NativeTheme::Part NativeThemePart(
    WebThemeEngine::Part part) {
  switch (part) {
    case WebThemeEngine::PartScrollbarDownArrow:
      return ui::NativeTheme::kScrollbarDownArrow;
    case WebThemeEngine::PartScrollbarLeftArrow:
      return ui::NativeTheme::kScrollbarLeftArrow;
    case WebThemeEngine::PartScrollbarRightArrow:
      return ui::NativeTheme::kScrollbarRightArrow;
    case WebThemeEngine::PartScrollbarUpArrow:
      return ui::NativeTheme::kScrollbarUpArrow;
    case WebThemeEngine::PartScrollbarHorizontalThumb:
      return ui::NativeTheme::kScrollbarHorizontalThumb;
    case WebThemeEngine::PartScrollbarVerticalThumb:
      return ui::NativeTheme::kScrollbarVerticalThumb;
    case WebThemeEngine::PartScrollbarHorizontalTrack:
      return ui::NativeTheme::kScrollbarHorizontalTrack;
    case WebThemeEngine::PartScrollbarVerticalTrack:
      return ui::NativeTheme::kScrollbarVerticalTrack;
    case WebThemeEngine::PartCheckbox:
      return ui::NativeTheme::kCheckbox;
    case WebThemeEngine::PartRadio:
      return ui::NativeTheme::kRadio;
    case WebThemeEngine::PartButton:
      return ui::NativeTheme::kPushButton;
    case WebThemeEngine::PartMenuList:
      return ui::NativeTheme::kMenuList;
    case WebThemeEngine::PartSliderTrack:
      return ui::NativeTheme::kSliderTrack;
    case WebThemeEngine::PartSliderThumb:
      return ui::NativeTheme::kSliderThumb;
    case WebThemeEngine::PartInnerSpinButton:
      return ui::NativeTheme::kInnerSpinButton;
    case WebThemeEngine::PartProgressBar:
      return ui::NativeTheme::kProgressBar;
    default:
      return ui::NativeTheme::kScrollbarDownArrow;
  }
}

static ui::NativeTheme::State NativeThemeState(
    WebThemeEngine::State state) {
  switch (state) {
    case WebThemeEngine::StateDisabled:
      return ui::NativeTheme::kDisabled;
    case WebThemeEngine::StateHover:
      return ui::NativeTheme::kHovered;
    case WebThemeEngine::StateNormal:
      return ui::NativeTheme::kNormal;
    case WebThemeEngine::StatePressed:
      return ui::NativeTheme::kPressed;
    default:
      return ui::NativeTheme::kDisabled;
  }
}

static void GetNativeThemeExtraParams(
    WebThemeEngine::Part part,
    WebThemeEngine::State state,
    const WebThemeEngine::ExtraParams* extra_params,
    ui::NativeTheme::ExtraParams* native_theme_extra_params) {
  switch (part) {
    case WebThemeEngine::PartScrollbarHorizontalTrack:
    case WebThemeEngine::PartScrollbarVerticalTrack:
      native_theme_extra_params->scrollbar_track.track_x =
          extra_params->scrollbarTrack.trackX;
      native_theme_extra_params->scrollbar_track.track_y =
          extra_params->scrollbarTrack.trackY;
      native_theme_extra_params->scrollbar_track.track_width =
          extra_params->scrollbarTrack.trackWidth;
      native_theme_extra_params->scrollbar_track.track_height =
          extra_params->scrollbarTrack.trackHeight;
      break;
    case WebThemeEngine::PartCheckbox:
      native_theme_extra_params->button.checked = extra_params->button.checked;
      native_theme_extra_params->button.indeterminate =
          extra_params->button.indeterminate;
      break;
    case WebThemeEngine::PartRadio:
      native_theme_extra_params->button.checked = extra_params->button.checked;
      break;
    case WebThemeEngine::PartButton:
      native_theme_extra_params->button.is_default =
          extra_params->button.isDefault;
      native_theme_extra_params->button.has_border =
          extra_params->button.hasBorder;
      // Native buttons have a different focus style.
      native_theme_extra_params->button.is_focused = false;
      native_theme_extra_params->button.background_color =
          extra_params->button.backgroundColor;
      break;
    case WebThemeEngine::PartMenuList:
      native_theme_extra_params->menu_list.has_border =
          extra_params->menuList.hasBorder;
      native_theme_extra_params->menu_list.has_border_radius =
          extra_params->menuList.hasBorderRadius;
      native_theme_extra_params->menu_list.arrow_x =
          extra_params->menuList.arrowX;
      native_theme_extra_params->menu_list.arrow_y =
          extra_params->menuList.arrowY;
      native_theme_extra_params->menu_list.background_color =
          extra_params->menuList.backgroundColor;
      break;
    case WebThemeEngine::PartSliderTrack:
    case WebThemeEngine::PartSliderThumb:
      native_theme_extra_params->slider.vertical =
          extra_params->slider.vertical;
      native_theme_extra_params->slider.in_drag = extra_params->slider.inDrag;
      break;
    case WebThemeEngine::PartInnerSpinButton:
      native_theme_extra_params->inner_spin.spin_up =
          extra_params->innerSpin.spinUp;
      native_theme_extra_params->inner_spin.read_only =
          extra_params->innerSpin.readOnly;
      break;
    case WebThemeEngine::PartProgressBar:
      native_theme_extra_params->progress_bar.determinate =
          extra_params->progressBar.determinate;
      native_theme_extra_params->progress_bar.value_rect_x =
          extra_params->progressBar.valueRectX;
      native_theme_extra_params->progress_bar.value_rect_y =
          extra_params->progressBar.valueRectY;
      native_theme_extra_params->progress_bar.value_rect_width =
          extra_params->progressBar.valueRectWidth;
      native_theme_extra_params->progress_bar.value_rect_height =
          extra_params->progressBar.valueRectHeight;
      break;
    default:
      break;  // Parts that have no extra params get here.
  }
}

blink::WebSize WebThemeEngineImpl::getSize(WebThemeEngine::Part part) {
  ui::NativeTheme::ExtraParams extra;
  return ui::NativeTheme::instance()->GetPartSize(NativeThemePart(part),
                                                   ui::NativeTheme::kNormal,
                                                   extra);
}

void WebThemeEngineImpl::paint(
    blink::WebCanvas* canvas,
    WebThemeEngine::Part part,
    WebThemeEngine::State state,
    const blink::WebRect& rect,
    const WebThemeEngine::ExtraParams* extra_params) {
  ui::NativeTheme::ExtraParams native_theme_extra_params;
  GetNativeThemeExtraParams(
      part, state, extra_params, &native_theme_extra_params);
  ui::NativeTheme::instance()->Paint(
      canvas,
      NativeThemePart(part),
      NativeThemeState(state),
      gfx::Rect(rect),
      native_theme_extra_params);
}

void WebThemeEngineImpl::paintStateTransition(blink::WebCanvas* canvas,
                                              WebThemeEngine::Part part,
                                              WebThemeEngine::State startState,
                                              WebThemeEngine::State endState,
                                              double progress,
                                              const blink::WebRect& rect) {
  ui::NativeTheme::instance()->PaintStateTransition(
      canvas,
      NativeThemePart(part),
      NativeThemeState(startState),
      NativeThemeState(endState),
      progress,
      gfx::Rect(rect));
}

}  // namespace sky
