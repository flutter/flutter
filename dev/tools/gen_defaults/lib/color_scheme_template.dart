// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ColorSchemeTemplate extends TokenTemplate {
  ColorSchemeTemplate(super.blockName, super.fileName, super.tokens);

  // Map of light color scheme token data from tokens.
  late Map<String, dynamic> colorTokensLight = tokens['colorsLight'] as Map<String, dynamic>;

  // Map of dark color scheme token data from tokens.
  late Map<String, dynamic> colorTokensDark = tokens['colorsDark'] as Map<String, dynamic>;

  @override
  String generate() => '''
const ColorScheme _colorSchemeLightM3 = ColorScheme(
  brightness: Brightness.light,
  primary: Color(${tokens[colorTokensLight['md.sys.color.primary']]}),
  onPrimary: Color(${tokens[colorTokensLight['md.sys.color.on-primary']]}),
  primaryContainer: Color(${tokens[colorTokensLight['md.sys.color.primary-container']]}),
  onPrimaryContainer: Color(${tokens[colorTokensLight['md.sys.color.on-primary-container']]}),
  secondary: Color(${tokens[colorTokensLight['md.sys.color.secondary']]}),
  onSecondary: Color(${tokens[colorTokensLight['md.sys.color.on-secondary']]}),
  secondaryContainer: Color(${tokens[colorTokensLight['md.sys.color.secondary-container']]}),
  onSecondaryContainer: Color(${tokens[colorTokensLight['md.sys.color.on-secondary-container']]}),
  tertiary: Color(${tokens[colorTokensLight['md.sys.color.tertiary']]}),
  onTertiary: Color(${tokens[colorTokensLight['md.sys.color.on-tertiary']]}),
  tertiaryContainer: Color(${tokens[colorTokensLight['md.sys.color.tertiary-container']]}),
  onTertiaryContainer: Color(${tokens[colorTokensLight['md.sys.color.on-tertiary-container']]}),
  error: Color(${tokens[colorTokensLight['md.sys.color.error']]}),
  onError: Color(${tokens[colorTokensLight['md.sys.color.on-error']]}),
  errorContainer: Color(${tokens[colorTokensLight['md.sys.color.error-container']]}),
  onErrorContainer: Color(${tokens[colorTokensLight['md.sys.color.on-error-container']]}),
  background: Color(${tokens[colorTokensLight['md.sys.color.background']]}),
  onBackground: Color(${tokens[colorTokensLight['md.sys.color.on-background']]}),
  surface: Color(${tokens[colorTokensLight['md.sys.color.surface']]}),
  onSurface: Color(${tokens[colorTokensLight['md.sys.color.on-surface']]}),
  surfaceVariant: Color(${tokens[colorTokensLight['md.sys.color.surface-variant']]}),
  onSurfaceVariant: Color(${tokens[colorTokensLight['md.sys.color.on-surface-variant']]}),
  outline: Color(${tokens[colorTokensLight['md.sys.color.outline']]}),
  outlineVariant: Color(${tokens[colorTokensLight['md.sys.color.outline-variant']]}),
  shadow: Color(${tokens[colorTokensLight['md.sys.color.shadow']]}),
  scrim: Color(${tokens[colorTokensLight['md.sys.color.scrim']]}),
  inverseSurface: Color(${tokens[colorTokensLight['md.sys.color.inverse-surface']]}),
  onInverseSurface: Color(${tokens[colorTokensLight['md.sys.color.inverse-on-surface']]}),
  inversePrimary: Color(${tokens[colorTokensLight['md.sys.color.inverse-primary']]}),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(${tokens[colorTokensLight['md.sys.color.primary']]}),
);

const ColorScheme _colorSchemeDarkM3 = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(${tokens[colorTokensDark['md.sys.color.primary']]}),
  onPrimary: Color(${tokens[colorTokensDark['md.sys.color.on-primary']]}),
  primaryContainer: Color(${tokens[colorTokensDark['md.sys.color.primary-container']]}),
  onPrimaryContainer: Color(${tokens[colorTokensDark['md.sys.color.on-primary-container']]}),
  secondary: Color(${tokens[colorTokensDark['md.sys.color.secondary']]}),
  onSecondary: Color(${tokens[colorTokensDark['md.sys.color.on-secondary']]}),
  secondaryContainer: Color(${tokens[colorTokensDark['md.sys.color.secondary-container']]}),
  onSecondaryContainer: Color(${tokens[colorTokensDark['md.sys.color.on-secondary-container']]}),
  tertiary: Color(${tokens[colorTokensDark['md.sys.color.tertiary']]}),
  onTertiary: Color(${tokens[colorTokensDark['md.sys.color.on-tertiary']]}),
  tertiaryContainer: Color(${tokens[colorTokensDark['md.sys.color.tertiary-container']]}),
  onTertiaryContainer: Color(${tokens[colorTokensDark['md.sys.color.on-tertiary-container']]}),
  error: Color(${tokens[colorTokensDark['md.sys.color.error']]}),
  onError: Color(${tokens[colorTokensDark['md.sys.color.on-error']]}),
  errorContainer: Color(${tokens[colorTokensDark['md.sys.color.error-container']]}),
  onErrorContainer: Color(${tokens[colorTokensDark['md.sys.color.on-error-container']]}),
  background: Color(${tokens[colorTokensDark['md.sys.color.background']]}),
  onBackground: Color(${tokens[colorTokensDark['md.sys.color.on-background']]}),
  surface: Color(${tokens[colorTokensDark['md.sys.color.surface']]}),
  onSurface: Color(${tokens[colorTokensDark['md.sys.color.on-surface']]}),
  surfaceVariant: Color(${tokens[colorTokensDark['md.sys.color.surface-variant']]}),
  onSurfaceVariant: Color(${tokens[colorTokensDark['md.sys.color.on-surface-variant']]}),
  outline: Color(${tokens[colorTokensDark['md.sys.color.outline']]}),
  outlineVariant: Color(${tokens[colorTokensDark['md.sys.color.outline-variant']]}),
  shadow: Color(${tokens[colorTokensDark['md.sys.color.shadow']]}),
  scrim: Color(${tokens[colorTokensDark['md.sys.color.scrim']]}),
  inverseSurface: Color(${tokens[colorTokensDark['md.sys.color.inverse-surface']]}),
  onInverseSurface: Color(${tokens[colorTokensDark['md.sys.color.inverse-on-surface']]}),
  inversePrimary: Color(${tokens[colorTokensDark['md.sys.color.inverse-primary']]}),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(${tokens[colorTokensDark['md.sys.color.primary']]}),
);
''';
}
