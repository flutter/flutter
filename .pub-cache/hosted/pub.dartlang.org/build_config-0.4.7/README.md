# Customizing builds

Customizing the build behavior of a package is done  by creating a `build.yaml`
file, which describes your configuration.

The full format is described in the
[docs/build_yaml_format.md](https://github.com/dart-lang/build/blob/master/docs/build_yaml_format.md)
file, while this documentation is more focused on specific usage scenarios of
the file.

## Dividing a package into Build targets

When a `Builder` should be applied to a subset of files in a package the package
can be broken up into multiple 'targets'. Targets are configured in the
`targets` section of the `build.yaml`. The key for each target makes up the name
for that target. Targets can be referred to in
`'$definingPackageName:$targetname'`. When the target name matches the package
name it can also be referred to as just the package name. One target in every
package _must_ use the package name so that consumers will use it by default.
In the `build.yaml` file this target can be defined with the key `$default` or
with the name of the package.

Each target may also contain the following keys:

- **sources**: List of Strings or Map, Optional. The set of files within the
  package which make up this target. Files are specified using glob syntax. If a
  List of Strings is used they are considered the 'include' globs. If a Map is
  used can only have the keys `include` and `exclude`. Any file which matches
  any glob in `include` and no globs in `exclude` is considered a source of the
  target. When `include` is omitted every file is considered a match.
- **dependencies**: List of Strings, Optional. The targets that this target
  depends on. Strings in the format `'$packageName:$targetName'` to depend on a
  target within a package or `$packageName` to depend on a package's default
  target. By default this is all of the package names this package depends on
  (from the `pubspec.yaml`).
- **builders**: Map, Optional. See "configuring builders" below.

## Configuring `Builder`s applied to your package
Each target can specify a `builders` key which configures the builders which are
applied to that target. The value is a Map from builder to configuration for
that builder. The key is in the format `'$packageName:$builderName'`. The
configuration may have the following keys:

- **enabled**: Boolean, Optional: Whether to apply the builder to this target.
  Omit this key if you want the default behavior based on the builder's
  `auto_apply` configuration. Builders which are manually applied
  (`auto_apply: none`) are only ever used when there is a target specifying the
  builder with `enabled: True`.
- **generate_for**: List of String or Map, Optional:. The subset of files within
  the target's `sources` which should have this Builder applied. See `sources`
  configuration above for how to configure this.
- **options**: Map, Optional: A free-form map which will be passed to the
  `Builder` as a `BuilderOptions` when it is constructed. Usage varies depending
  on the particular builder. Values in this map will override the default
  provided by builder authors. Values may also be overridden based on the build
  mode with `dev_options` or `release_options`.
- **dev_options**: Map, Optional: A free-form map which will be passed to the
  `Builder` as a `BuilderOptions` when it is constructed. Usage varies depending
  on the particular builder. The values in this map override Builder defaults or
  non mode-specific options per-key when the build is done in dev mode.
- **release_options**: Map, Optional: A free-form map which will be passed to
  the `Builder` as a `BuilderOptions` when it is constructed. Usage varies
  depending on the particular builder. The values in this map override Builder
  defaults or non mode-specific options when the build is done in release mode.

## Configuring `Builder`s globally
Target level builder options can be overridden globally across all packages with
the `global_options` section. These options are applied _after_ all Builder
defaults and target level configuration, and _before_ `--define` command line
arguments.

- **options**: Map, Optional: A free-form map which will be passed to the
  `Builder` as a `BuilderOptions` when it is constructed. Usage varies depending
  on the particular builder. Values in this map will override the default
  provided by builder authors or at the target level. Values may also be
  overridden based on the build mode with `dev_options` or `release_options`.
- **dev_options**: Map, Optional: A free-form map which will be passed to the
  `Builder` as a `BuilderOptions` when it is constructed. Usage varies depending
  on the particular builder. The values in this map override all other values
  per-key when the build is done in dev mode.
- **release_options**: Map, Optional: A free-form map which will be passed to
  the `Builder` as a `BuilderOptions` when it is constructed. Usage varies
  depending on the particular builder. The values in this map override all other
  values per-key when the build is done in release mode.

## Defining `Builder`s to apply to dependents

If users of your package need to apply some code generation to their package,
then you can define `Builder`s and have those applied to packages with a
dependency on yours.

The key for a Builder will be normalized so that consumers of the builder can
refer to it in `'$definingPackageName:$builderName'` format. If the builder name
matches the package name it can also be referred to with just the package name.

Exposed `Builder`s are configured in the `builders` section of the `build.yaml`.
This is a map of builder names to configuration. Each builder config may contain
the following keys:

- **import**: Required. The import uri that should be used to import the library
  containing the `Builder` class. This should always be a `package:` uri.
- **builder_factories**: A `List<String>` which contains the names of the
  top-level methods in the imported library which are a function fitting the
  typedef `Builder factoryName(BuilderOptions options)`.
- **build_extensions**: Required. A map from input extension to the list of
  output extensions that may be created for that input. This must match the
  merged `buildExtensions` maps from each `Builder` in `builder_factories`.
- **auto_apply**: Optional. The packages which should have this builder
  automatically to applied. Defaults to `'none'` The possibilities are:
  - `"none"`: Never apply this Builder unless it is manually configured
  - `"dependents"`: Apply this Builder to the package with a direct dependency
    on the package exposing the builder.
  - `"all_packages"`: Apply this Builder to all packages in the transitive
    dependency graph.
  - `"root_package"`: Apply this Builder only to the top-level package.
- **required_inputs**: Optional, see [adjusting builder ordering][]
- **runs_before**: Optional, see [adjusting builder ordering][]
- **applies_builders**: Optional, list of Builder keys. Specifies that other
  builders should be run on any target which will run this Builder.
- **is_optional**: Optional, boolean. Specifies whether a Builder can be run
  lazily, such that it won't execute until one of it's outputs is requested by a
  later Builder. This option should be rare. Defaults to `False`.
- **build_to**: Optional. The location that generated assets should be output
  to. The possibilities are:
  - `"source"`: Outputs go to the source tree next to their primary inputs.
  - `"cache"`: Outputs go to a hidden build cache and won't be published.
  The default is "cache". If a Builder specifies that it outputs to "source" it
  will never run on any package other than the root - but does not necessarily
  need to use the "root_package" value for "auto_apply". If it would otherwise
  run on a non-root package it will be filtered out.
- **defaults**: Optional: Default values to apply when a user does not specify
  the corresponding key in their `builders` section. May contain the following
  keys:
  - **generate_for**: A list of globs that this Builder should run on as a
    subset of the corresponding target, or a map with `include` and `exclude`
    lists of globs.
  - **options**: Arbitrary yaml map, provided as the `config` map in
    `BuilderOptions` to the `BuilderFactory` for this builder. Individual keys
    will be overridden by configuration provided in either `dev_options` or
    `release_options` based on the build mode, and then overridden by any user
    specified configuration.
  - **dev_options**: Arbitrary yaml map. Values will replace the defaults from
    `options` when the build is done in dev mode (the default mode).
  - **release_options**: Arbitrary yaml map. Values will replace the defaults
    from `options` when the build is done in release mode (with `--release`).

Example `builders` config:

```yaml
builders:
  my_builder:
    import: "package:my_package/builder.dart"
    builder_factories: ["myBuilder"]
    build_extensions: {".dart": [".my_package.dart"]}
    auto_apply: dependents
    defaults:
      release_options:
        some_key: "Some value the users will want in release mode"
```

## Defining `PostProcessBuilder`s

`PostProcessBuilder`s are configured similarly to normal `Builder`s, but they
have some different/missing options.

These builders can not be auto-applied on their own, and must always build to
cache because their outputs are not declared ahead of time. To apply them a
user will need to explicitly enable them on a target, or a `Builder` definition
can add them to `apply_builders`.

Exposed `PostProcessBuilder`s are configured in the `post_process_builders`
section of the  `build.yaml`. This is a map of builder names to configuration.
Each post process builder config may contain the following keys:

- **import**: Required. The import uri that should be used to import the library
  containing the `Builder` class. This should always be a `package:` uri.
- **builder_factory**: A `String` which contains the name of the top-level
  method in the imported library which is a function fitting the
  typedef `PostProcessBuilder factoryName(BuilderOptions options)`.
- **input_extensions**: Required. A list of input extensions that will be
  processed. This must match the `inputExtensions` from the `PostProcessBuilder`
  returned by the `builder_factory`.
- **defaults**: Optional: Default values to apply when a user does not specify
  the corresponding key in their `builders` section. May contain the following
  keys:
  - **generate_for**: A list of globs that this Builder should run on as a
    subset of the corresponding target, or a map with `include` and `exclude`
    lists of globs.

Example config with a normal `builder` which auto-applies a
`post_process_builder`:

```yaml
builders:
  # The regular builder config, creates `.tar.gz` files.
  regular_builder:
    import: "package:my_package/builder.dart"
    builder_factories: ["myBuilder"]
    build_extensions: {".dart": [".tar.gz"]}
    auto_apply: dependents
    apply_builders: [":archive_extract_builder"]
post_process_builders:
  # The post process builder config, extracts `.tar.gz` files.
  extract_archive_builder:
    import: "package:my_package/extract_archive_builder.dart"
    builder_factory: "myExtractArchiveBuilder"
    input_extensions: [".tar.gz"]
```

[adjusting builder ordering]: #adjusting-builder-ordering

### Adjusting Builder Ordering

Both `required_inputs` and `runs_before` can be used to tweak the order that
Builders run in on a given target. These work by indicating a given builder is a
_dependency_ of another. The resulting dependency graph must not have cycles and
these options should be used rarely.

- **required_inputs**: Optional, list of extensions, defaults to empty list. If
  a Builder must see every input with one or more file extensions they can be
  specified here and it will be guaranteed to run after any Builder which might
  produce an output of that type. For instance a compiler must run after any
  Builder which can produce `.dart` outputs or those libraries can't be
  compiled. A Builder may not specify that it requires an output that it also
  produces since this would be a self-cycle.
- **runs_before**: Optional, list of Builder keys. If a Builder is producing
  outputs which are intended to be inputs to other Builders they may be
  specified here. This guarantees that the specified Builders will be ordered
  later than this one. This will not cause Builders to be applied if they would
  not otherwise run, it only affects ordering. If a builder emits files that
  should always be the input to another specific builder, use both `runs_before`
  and `applies_builder` to configure both ordering and ensure that steps are not
  skipped.

# Publishing `build.yaml` files

`build.yaml` configuration should be published to pub with the package and
checked in to source control. Whenever a package is published with a
`build.yaml` it should mark a `dependency` on `build_config` to ensure that
the package consuming the config has a compatible version. Breaking version
changes which do not impact the configuration file format will be clearly marked
in the changelog.
