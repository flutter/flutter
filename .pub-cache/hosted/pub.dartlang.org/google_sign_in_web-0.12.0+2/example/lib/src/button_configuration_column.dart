// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

/// Type of the onChange function for `ButtonConfiguration`.
typedef OnWebConfigChangeFn = void Function(GSIButtonConfiguration newConfig);

/// (Incomplete) List of the locales that can be used to configure the button.
const List<String> availableLocales = <String>[
  'en_US',
  'es_ES',
  'pt_BR',
  'fr_FR',
  'it_IT',
  'de_DE',
];

/// Renders a Scrollable Column widget that allows the user to see (and change) a ButtonConfiguration.
Widget renderWebButtonConfiguration(
  GSIButtonConfiguration? currentConfig, {
  OnWebConfigChangeFn? onChange,
}) {
  final ScrollController scrollController = ScrollController();
  return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _renderLocaleCard(
                value: currentConfig?.locale,
                locales: availableLocales,
                onChanged: _onChanged<String>(currentConfig, onChange),
              ),
              _renderMinimumWidthCard(
                value: currentConfig?.minimumWidth,
                max: 500,
                actualMax: 400,
                onChanged: _onChanged<double>(currentConfig, onChange),
              ),
              _renderRadioListTileCard<GSIButtonType>(
                title: 'ButtonType',
                values: GSIButtonType.values,
                selected: currentConfig?.type,
                onChanged: _onChanged<GSIButtonType>(currentConfig, onChange),
              ),
              _renderRadioListTileCard<GSIButtonShape>(
                title: 'ButtonShape',
                values: GSIButtonShape.values,
                selected: currentConfig?.shape,
                onChanged: _onChanged<GSIButtonShape>(currentConfig, onChange),
              ),
              _renderRadioListTileCard<GSIButtonSize>(
                title: 'ButtonSize',
                values: GSIButtonSize.values,
                selected: currentConfig?.size,
                onChanged: _onChanged<GSIButtonSize>(currentConfig, onChange),
              ),
              _renderRadioListTileCard<GSIButtonTheme>(
                title: 'ButtonTheme',
                values: GSIButtonTheme.values,
                selected: currentConfig?.theme,
                onChanged: _onChanged<GSIButtonTheme>(currentConfig, onChange),
              ),
              _renderRadioListTileCard<GSIButtonText>(
                title: 'ButtonText',
                values: GSIButtonText.values,
                selected: currentConfig?.text,
                onChanged: _onChanged<GSIButtonText>(currentConfig, onChange),
              ),
              _renderRadioListTileCard<GSIButtonLogoAlignment>(
                title: 'ButtonLogoAlignment',
                values: GSIButtonLogoAlignment.values,
                selected: currentConfig?.logoAlignment,
                onChanged:
                    _onChanged<GSIButtonLogoAlignment>(currentConfig, onChange),
              ),
            ],
          )));
}

/// Renders a Config card with a dropdown of locales.
Widget _renderLocaleCard(
    {String? value,
    required List<String> locales,
    void Function(String?)? onChanged}) {
  return _renderConfigCard(title: 'locale', children: <Widget>[
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        items: locales
            .map((String locale) => DropdownMenuItem<String>(
                  value: locale,
                  child: Text(locale),
                ))
            .toList(),
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        // padding: const EdgeInsets.symmetric(horizontal: 16), // Prefer padding here!
      ),
    ),
  ]);
}

/// Renders a card with a slider
Widget _renderMinimumWidthCard(
    {double? value,
    double min = 0,
    double actualMax = 10,
    double max = 11,
    void Function(double)? onChanged}) {
  return _renderConfigCard(title: 'minimumWidth', children: <Widget>[
    Slider(
      label: value?.toString() ?? 'null',
      value: value ?? 0,
      min: min,
      max: max,
      secondaryTrackValue: actualMax,
      onChanged: onChanged,
      divisions: 10,
    )
  ]);
}

/// Renders a Config Card with the values of an Enum as radio buttons.
Widget _renderRadioListTileCard<T extends Enum>(
    {required String title,
    required List<T> values,
    T? selected,
    void Function(T?)? onChanged}) {
  return _renderConfigCard(
      title: title,
      children: values
          .map((T value) => RadioListTile<T>(
                value: value,
                groupValue: selected,
                onChanged: onChanged,
                selected: value == selected,
                title: Text(value.name),
                dense: true,
              ))
          .toList());
}

/// Renders a Card where we render some `children` that change config.
Widget _renderConfigCard(
    {required String title, required List<Widget> children}) {
  return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Card(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            dense: true,
          ),
          ...children,
        ],
      )));
}

/// Sets a `value` into an `old` configuration object.
GSIButtonConfiguration _copyConfigWith(
    GSIButtonConfiguration? old, Object? value) {
  return GSIButtonConfiguration(
    locale: value is String ? value : old?.locale,
    minimumWidth:
        value is double ? (value == 0 ? null : value) : old?.minimumWidth,
    type: value is GSIButtonType ? value : old?.type,
    theme: value is GSIButtonTheme ? value : old?.theme,
    size: value is GSIButtonSize ? value : old?.size,
    text: value is GSIButtonText ? value : old?.text,
    shape: value is GSIButtonShape ? value : old?.shape,
    logoAlignment: value is GSIButtonLogoAlignment ? value : old?.logoAlignment,
  );
}

/// Returns a function that modifies the `current` configuration with a `value`, then calls `fn` with it.
Function(T?)? _onChanged<T>(
    GSIButtonConfiguration? current, OnWebConfigChangeFn? fn) {
  if (fn == null) {
    return null;
  }
  return (T? value) {
    fn(_copyConfigWith(current, value));
  };
}
