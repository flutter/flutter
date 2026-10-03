# Asset bundle paths

An asset declaration can use `bundle_path` to choose its location and runtime
lookup key inside the Flutter asset bundle. `path` still identifies the source
relative to `pubspec.yaml`. When `bundle_path` is omitted, the existing asset
path behavior is unchanged.

For example, a plugin that always reads `assets/branch-config.json` can receive
a different configuration for each build flavor:

```yaml
flutter:
  assets:
    - path: configs/dev/branch-config.json
      flavors: [dev]
      bundle_path: assets/branch-config.json
    - path: configs/prod/branch-config.json
      flavors: [prod]
      bundle_path: assets/branch-config.json
```

A build with `--flavor dev` includes the development file at
`assets/branch-config.json`. A build with `--flavor prod` includes the production
file at the same location. Existing flavor selection rules apply, including
omitting flavor-restricted entries when no matching flavor is selected. The
source files are not copied over each other or modified.

Dart code uses the bundle path:

```dart
final String config = await rootBundle.loadString('assets/branch-config.json');
```

Native code uses that same key with Android's `getLookupKeyForAsset` or iOS's
`lookupKeyForAsset`, then opens the returned path with the platform's asset or
bundle API. No plugin changes are needed when the plugin already uses those
APIs with this key. This does not place files in Android's top-level `assets/`
directory or iOS's top-level application bundle.

## Other asset features

- Directory declarations must end both `path` and `bundle_path` with `/`. The
  bundle path replaces the directory prefix. Directory traversal remains
  non-recursive, apart from the existing image resolution variant discovery.
- Image variants follow the rewritten path and filename. For example,
  `source/logo.png` mapped to `images/brand.png` also maps
  `source/2.0x/logo.png` to `images/2.0x/brand.png`. A missing base image remains
  supported when resolution variants exist.
- Assets declared by dependencies retain the `packages/<package>/` prefix.
  An application can also map an explicit `packages/<package>/...` source.
- Platform filtering, asset transformers, shaders, and deferred-component
  asset declarations retain their existing behavior. Transformers and shader
  compilation read the source file and write to the mapped destination.
- Dependency files track source files. Editing the selected source or changing
  the flavor causes subsequent builds to use the selected contents. Directory
  mappings retain the existing wildcard rebuild behavior.
- Asset manifests expose the rewritten keys. Existing URI escaping applies to
  special characters in bundle filenames.

## Validation and limits

`bundle_path` must be a non-empty relative path using forward slashes. Absolute
paths, drive prefixes, backslashes, control characters, empty path segments,
and `.` or `..` segments are rejected. File declarations cannot target a
directory, and directory declarations cannot target a file.

Flutter checks destination conflicts after flavor and platform filtering,
including image variants, package assets, hook assets, fonts, and deferred
components. Two selected sources cannot write the same destination, and a file
cannot also be used as a directory. Existing duplicate declarations of the same
source with the same processing configuration remain allowed. Generated Flutter
asset names cannot be used as mapped destinations.

This field does not introduce fallback precedence between declarations. An
unconditional asset and a matching flavor-specific asset at the same destination
conflict. Flavor support is unchanged for each build target. Third-party asset
code generators must support this field before they can generate the rewritten
keys; build hooks remain available for configurations that need custom logic.
