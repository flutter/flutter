# Flavor-specific configuration assets

An individual application configuration file can declare `bundle_path` together
with `flavors` to keep a fixed runtime asset key while selecting a source file
for each flavor:

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

With `--flavor dev`, the first file is included at `assets/branch-config.json`.
With `--flavor prod`, the second file uses the same key. With no matching flavor,
neither file is included. Source files remain unchanged and are tracked as build
inputs. Omitting `bundle_path` preserves existing asset behavior.

Dart reads the selected file with
`rootBundle.loadString('assets/branch-config.json')`. Native plugins can use the
same key with Android's `getLookupKeyForAsset` or iOS's `lookupKeyForAsset`, then
read the returned path through the platform's asset API. This mapping applies
inside the Flutter asset bundle, not to top-level platform resources.

Both paths must name relative files using forward slashes, without empty, `.`
or `..` segments. The source file must exist. Two selected assets cannot occupy
the same destination, and a destination cannot be both a file and a directory.
Generated Flutter asset paths are reserved. An unconditional asset at the same
key is a conflict, rather than a fallback.

This field is limited to flavor-specific application files. It does not support
directory declarations, image resolution variants, package asset paths or
dependency declarations, shaders, deferred components, platform filters, or
asset transformers. In particular, platform-specific mappings cannot cause
collisions when running tests or change the key between target platforms.
Existing flavor availability on each build target remains unchanged.

Third-party asset generators need to support `bundle_path` before generating
lookup keys for these declarations. This field still extends the pubspec asset
schema; a reduced scope does not eliminate that ecosystem compatibility work.
