# Material 3 Expressive Component Migration Checklist

## Goal

This document provides actionable steps for migrating `material_ui` components to Material 3 Expressive.

For the rationale behind the migration strategy, check the Useful References section. The docs listed there explain why Material and Cupertino are moving into standalone packages, why Material 3 Expressive work happens in `material_ui`, and why this checklist uses component-level opt-in during the migration.

## Scope

Migrate at most one component per PR.

Keep Material 3 as the default. Add Material 3 Expressive behind a component-level opt-in using the component theme.

Do not add a global `ThemeData` expressive variant yet.

Start from existing generated token files under `packages/material_ui/tool/gen_defaults/data/`. The component migration PR should consume those tokens through a template and generate defaults.

## Useful References

- [Architecture of `material_ui` and `cupertino_ui`](https://docs.google.com/document/d/1TW42GcjEWoPZK7Y2cZr38zjoRQ1T4gJBujXIqPL_lOw/edit?tab=t.0)
- [Material 3 Expressive migration planning](https://docs.google.com/document/d/15XBE5xraSiMh_Oep_hclrX8rnT7rhM69L1kaMN94gdo/edit?tab=t.0)
- [Material 3 Expressive project](https://github.com/orgs/flutter/projects/250)

## 1. Confirm the Component Changes

- Check the Material Design component page for the component's M3 Expressive update.
- Check the existing token files under `packages/material_ui/tool/gen_defaults/data/`.
- List the M3E changes the PR will implement: colors, sizes, widths, shapes, states, elevation, motion, or typography.

## 2. Create the M3E Template

Create or update the component template under:

```shell
packages/material_ui/tool/gen_defaults/templates/
```

Use the existing component template file when the component already has one. Otherwise, create:

```shell
packages/material_ui/tool/gen_defaults/templates/<component>_template.dart
```

Create an M3E template class that extends `TokenTemplateM3E`.

Use the existing `M3E` suffix pattern for generated defaults class names.

Example pattern:

```dart
class IconButtonTemplateM3E extends TokenTemplateM3E {
  const IconButtonTemplateM3E();

  @override
  String get name => 'Icon Button';

  @override
  String get parentFilePath => 'icon_button.dart';

  @override
  String generateContents(String className) {
    return '''
// generated defaults
''';
  }
}
```

Generate defaults from token data whenever possible. If a required value is missing from the available token files but is specified in the Material Design documentation, use a localized hardcoded value and add a comment with a link to the source.

Do not hardcode values in component code. Keep fallback values in the template or generated-defaults path so they can be replaced when tokens become available.

## 3. Register the Template and Generate Defaults

Update:

```shell
packages/material_ui/tool/gen_defaults/bin/gen_defaults.dart
```

Add the template import:

```dart
import '../templates/<component>_template.dart';
```

Register the M3E template for the migrated component.

Example:

```dart
import '../templates/icon_button_template.dart';

// ...

const IconButtonTemplateM3E().generateFile(verbose: verbose);
```

Run the generator from the repository root:

```shell
dart packages/material_ui/tool/gen_defaults/bin/gen_defaults.dart
```

Confirm that the generated defaults are written under `packages/material_ui/lib/src/generated/` and use the filename pattern `<component>_defaults_m3e.g.dart`.

Do not manually edit generated defaults.

## 4. Add Component Theme Opt-In

Add `StyleVariant? variant` to the component theme data class.

Example:

```dart
class IconButtonThemeData with Diagnosticable {
  const IconButtonThemeData({
    this.style,
    this.variant,
  });

  final ButtonStyle? style;

  /// The style variant of Material Design used by [IconButton].
  ///
  /// Set this to [StyleVariant.material3Expressive] to opt icon buttons into
  /// the Material 3 Expressive style.
  final StyleVariant? variant;
}
```

Update the component theme data class support methods, such as `lerp`, `==`, `hashCode`, `debugFillProperties`, etc.

Default null to `StyleVariant.material3` in component behavior.

Do not add extra component theme flags unless the component needs them.

## 5. Wire the Component to M3E Defaults

Add the generated M3E defaults as a `part` directive in the component file.

Example:

```dart
part 'generated/icon_button_defaults_m3e.g.dart';
```

Select defaults using the component theme variant.

Example pattern:

```dart
final StyleVariant effectiveVariant =
    <Component>Theme.of(context).variant ?? StyleVariant.material3;

return switch (effectiveVariant) {
  StyleVariant.material3 => _<Component>DefaultsM3(context),
  StyleVariant.material3Expressive => _<Component>DefaultsM3E(context),
};
```

Keep existing Material 3 defaults unchanged.

Ensure M3E defaults apply only when the component theme variant is `StyleVariant.material3Expressive`.

## 6. Add Public Style APIs Only When Required

Prefer existing style fields in the corresponding component theme data first. Add a new style field only when an M3E update cannot be represented by existing APIs.

For example, Material 3 Expressive IconButton provides size variants that control multiple values, such as icon size and container size. Since `IconButtonThemeData.style` did not already have a single property for selecting those token groups, the migration introduced `ButtonStyle.sizeVariant`.

When adding new style fields:

- Add constructor parameters.
- Add fields.
- Update `copyWith`.
- Update `merge`.
- Update `lerp`.
- Update equality and `hashCode`.
- Update `debugFillProperties`.
- Add API docs.
- Add tests.

Use shared property names across related components when the variants have the same meaning. For example, if multiple button components expose size variants, prefer a shared `sizeVariant` property name instead of component-specific names.

## 7. Add API Docs

Document how to opt into M3E for the component.

If the component docs already describe Material 3 default values, update that documentation to include the Material 3 Expressive defaults as well.

Keep Material 3 and Material 3 Expressive defaults easy to distinguish.

Document new style fields at the API declaration site.

Avoid exposing token implementation details in user-facing docs unless the API itself is token-oriented.

## 8. Add Tests

Add focused tests for:

- Component theme `variant` opt-in.
- Generated M3E defaults.
- New style properties.
- Theme-level style defaults.
- Widget-level style overrides.
- Enabled, disabled, hovered, focused, pressed, selected, and unselected states when the component has state-specific tokens.
- Theme/style equality, `hashCode`, `lerp`, and diagnostics when public APIs changed.

## 9. Add ThemeData Documentation

Create a separate PR for a centralized `ThemeData` documentation section if the component migration PR is already large.

Add a list of components that support M3E component-level opt-in.

Update the list whenever a component migration lands.

Include the exact opt-in API for each migrated component.

Example entry:

```md
- IconButton: use `IconButtonThemeData(variant: StyleVariant.material3Expressive)`.
```

## 10. Add an Example

Create a separate PR for examples if the migration PR is already large. The example should show the Material 3 Expressive opt-in component, such as all new M3E size, width, shape, color, and state variants that apply.

Place examples under:

```shell
packages/material_ui/example/
```

Add or update example tests if required by the package. Remember to list the example path in the component documentation.

Example:

```dart
/// {@tool dartpad}
/// This sample shows creation of [IconButton] widgets for standard, filled,
/// filled tonal and outlined types, as described in: https://m3.material.io/components/icon-buttons/overview
///
/// ** See code in examples/api/lib/material/icon_button/icon_button.2.dart **
/// {@end-tool}
```

## 11. Add Changelog and Version Update

Create a pending changelog file that includes the changelog entry and version bump.

Make a copy of the [`material_ui` `template.yaml`](https://github.com/flutter/packages/blob/main/packages/material_ui/pending_changelogs/template.yaml), then fill out the details. Use `version: minor` when the PR adds public API or new M3E component support.

Alternatively, use the Flutter Packages Tool. Follow the [configuration instructions](https://github.com/flutter/packages/tree/main/script/tool#flutter-plugin-tools), then run this from the `material_ui` package directory:

```shell
fpt update-release-info \
  --current-package \
  --version=minor \
  --changelog="Adds Material 3 Expressive support for <Component>."
```

Use `bugfix` or `next` instead of `minor` only when that better matches the change.

## 12. Run Verification

Run formatting:

```shell
dart run script/tool/bin/flutter_plugin_tools.dart format --packages material_ui
```

Run analysis:

```shell
dart run script/tool/bin/flutter_plugin_tools.dart analyze --packages material_ui
```

Run the relevant component tests:

```shell
flutter test packages/material_ui/test/<component>_test.dart
```

Run generator tests if generator code changed:

```shell
dart test packages/material_ui/tool/gen_defaults/test
```

## 13. PR Description Checklist

Include:

- Component migrated.
- New public APIs.
- New component theme opt-in.
- Follow-up PRs needed.

Example:

```md
## Description

Adds Material 3 Expressive support for `<Component>` behind an explicit component-level opt-in.

## Changes

- Adds `<Component>ThemeData.variant`.
- Adds new style APIs: `<new style APIs>`.
- Adds `<Component>TemplateM3E`.
- Adds generated defaults in `packages/material_ui/lib/src/generated/<component>_defaults_m3e.g.dart`.
- Adds tests for M3E defaults and opt-in behavior.

## Follow-ups

- Add or update the ThemeData M3E component list.
- Add an example demonstrating the M3E `<Component>`.
- Add follow-up PRs for any M3E behavior that cannot be included in this PR.
```
