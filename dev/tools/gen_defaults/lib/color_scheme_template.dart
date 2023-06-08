// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';
import 'token_logger.dart';

class ColorSchemeTemplate extends TokenTemplate {
  ColorSchemeTemplate(this._colorTokensLight, this._colorTokensDark, super.blockName, super.fileName, super.tokens);

  // Map of light color scheme token data from tokens.
  final Map<String, dynamic> _colorTokensLight;

  // Map of dark color scheme token data from tokens.
  final Map<String, dynamic> _colorTokensDark;

  dynamic light(String tokenName) {
    tokenLogger.log(tokenName);
    return getToken(_colorTokensLight[tokenName] as String);
  }

  dynamic dark(String tokenName) {
    tokenLogger.log(tokenName);
    return getToken(_colorTokensDark[tokenName] as String);
  }

  @override
  String generate() => '''
const ColorScheme _colorSchemeLightM3 = ColorScheme(
  brightness: Brightness.light,
  primary: Color(${light('md.sys.color.primary')}),
  onPrimary: Color(${light('md.sys.color.on-primary')}),
  primaryContainer: Color(${light('md.sys.color.primary-container')}),
  onPrimaryContainer: Color(${light('md.sys.color.on-primary-container')}),
  secondary: Color(${light('md.sys.color.secondary')}),
  onSecondary: Color(${light('md.sys.color.on-secondary')}),
  secondaryContainer: Color(${light('md.sys.color.secondary-container')}),
  onSecondaryContainer: Color(${light('md.sys.color.on-secondary-container')}),
  tertiary: Color(${light('md.sys.color.tertiary')}),
  onTertiary: Color(${light('md.sys.color.on-tertiary')}),
  tertiaryContainer: Color(${light('md.sys.color.tertiary-container')}),
  onTertiaryContainer: Color(${light('md.sys.color.on-tertiary-container')}),
  error: Color(${light('md.sys.color.error')}),
  onError: Color(${light('md.sys.color.on-error')}),
  errorContainer: Color(${light('md.sys.color.error-container')}),
  onErrorContainer: Color(${light('md.sys.color.on-error-container')}),
  background: Color(${light('md.sys.color.background')}),
  onBackground: Color(${light('md.sys.color.on-background')}),
  surface: Color(${light('md.sys.color.surface')}),
  onSurface: Color(${light('md.sys.color.on-surface')}),
  surfaceVariant: Color(${light('md.sys.color.surface-variant')}),
  onSurfaceVariant: Color(${light('md.sys.color.on-surface-variant')}),
  outline: Color(${light('md.sys.color.outline')}),
  outlineVariant: Color(${light('md.sys.color.outline-variant')}),
  shadow: Color(${light('md.sys.color.shadow')}),
  scrim: Color(${light('md.sys.color.scrim')}),
  inverseSurface: Color(${light('md.sys.color.inverse-surface')}),
  onInverseSurface: Color(${light('md.sys.color.inverse-on-surface')}),
  inversePrimary: Color(${light('md.sys.color.inverse-primary')}),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(${light('md.sys.color.primary')}),
);

const ColorScheme _colorSchemeDarkM3 = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(${dark('md.sys.color.primary')}),
  onPrimary: Color(${dark('md.sys.color.on-primary')}),
  primaryContainer: Color(${dark('md.sys.color.primary-container')}),
  onPrimaryContainer: Color(${dark('md.sys.color.on-primary-container')}),
  secondary: Color(${dark('md.sys.color.secondary')}),
  onSecondary: Color(${dark('md.sys.color.on-secondary')}),
  secondaryContainer: Color(${dark('md.sys.color.secondary-container')}),
  onSecondaryContainer: Color(${dark('md.sys.color.on-secondary-container')}),
  tertiary: Color(${dark('md.sys.color.tertiary')}),
  onTertiary: Color(${dark('md.sys.color.on-tertiary')}),
  tertiaryContainer: Color(${dark('md.sys.color.tertiary-container')}),
  onTertiaryContainer: Color(${dark('md.sys.color.on-tertiary-container')}),
  error: Color(${dark('md.sys.color.error')}),
  onError: Color(${dark('md.sys.color.on-error')}),
  errorContainer: Color(${dark('md.sys.color.error-container')}),
  onErrorContainer: Color(${dark('md.sys.color.on-error-container')}),
  background: Color(${dark('md.sys.color.background')}),
  onBackground: Color(${dark('md.sys.color.on-background')}),
  surface: Color(${dark('md.sys.color.surface')}),
  onSurface: Color(${dark('md.sys.color.on-surface')}),
  surfaceVariant: Color(${dark('md.sys.color.surface-variant')}),
  onSurfaceVariant: Color(${dark('md.sys.color.on-surface-variant')}),
  outline: Color(${dark('md.sys.color.outline')}),
  outlineVariant: Color(${dark('md.sys.color.outline-variant')}),
  shadow: Color(${dark('md.sys.color.shadow')}),
  scrim: Color(${dark('md.sys.color.scrim')}),
  inverseSurface: Color(${dark('md.sys.color.inverse-surface')}),
  onInverseSurface: Color(${dark('md.sys.color.inverse-on-surface')}),
  inversePrimary: Color(${dark('md.sys.color.inverse-primary')}),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(${dark('md.sys.color.primary')}),
);
''';
}
