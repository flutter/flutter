// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../common/dynamic_title.dart';
import 'about_list_tile.dart';
import 'action_chip.dart';
import 'app_bar.dart';
import 'auto_complete.dart';
import 'back_button.dart';
import 'badge.dart';
import 'card.dart';
import 'check_box_list_tile.dart';
import 'close_button.dart';
import 'date_picker.dart';
import 'dialog.dart';
import 'drawer.dart';
import 'elevated_button.dart';
import 'expansion_tile.dart';
import 'filled_button.dart';
import 'floating_action_button.dart';
import 'icon_button.dart';
import 'material_banner.dart';
import 'navigation_bar.dart';
import 'navigation_drawer.dart';
import 'navigation_rail.dart';
import 'outlined_button.dart';
import 'popup_menu_button.dart';
import 'radio_list_tile.dart';
import 'range_slider.dart';
import 'segmented_button.dart';
import 'slider.dart';
import 'snack_bar.dart';
import 'switch_list_tile.dart';
import 'tab_bar_view.dart';
import 'text_button.dart';
import 'text_field.dart';
import 'text_field_password.dart';
import 'toggle_buttons.dart';

/// Tags for accessibility assessment use cases.
enum Tag {
  batch1('First batch of widgets for VPAT assessment'),
  batch2('Second batch of widgets for VPAT assessment, Q2 2026'),
  core('Essential use-cases requested for various a11y certifications'),

  /// An additional use-case that the team considers important to cover, even if
  /// nobody requested this as part of any certification process.
  additional('Additional use-cases covered by the team');

  const Tag(this.description);
  final String description;
}

abstract class UseCase {
  UseCase();

  String get name;
  String get route;
  List<Tag> get tags;

  Widget buildWithTitle(BuildContext context) {
    return DynamicTitle(title: name, child: build(context));
  }

  Widget build(BuildContext context);
}

final List<UseCase> useCases = <UseCase>[
  AboutListTileUseCase(),
  CheckBoxListTile(),
  DialogUseCase(),
  SliderUseCase(),
  RangeSliderUseCase(),
  TextFieldUseCase(),
  TextFieldPasswordUseCase(),
  DatePickerUseCase(),
  AutoCompleteUseCase(),
  BadgeUseCase(),
  MaterialBannerUseCase(),
  NavigationBarUseCase(),
  TextButtonUseCase(),
  RadioListTileUseCase(),
  ActionChipUseCase(),
  SnackBarUseCase(),
  SwitchListTileUseCase(),
  ExpansionTileUseCase(),
  CardUseCase(),
  DrawerUseCase(),
  NavigationDrawerUseCase(),
  NavigationRailUseCase(),
  AppBarUseCase(),
  TabBarViewUseCase(),
  ElevatedButtonUseCase(),
  FilledButtonUseCase(),
  OutlinedButtonUseCase(),
  IconButtonUseCase(),
  FloatingActionButtonUseCase(),
  PopupMenuButtonUseCase(),
  SegmentedButtonUseCase(),
  ToggleButtonsUseCase(),
  BackButtonUseCase(),
  CloseButtonUseCase(),
];
