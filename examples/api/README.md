# API Example Code

This directory contains the API sample code that is referenced from the
API documentation in each class.

They can be run individually by just specifying the path to the example on the
command line (or in the run configuration of an IDE).

For example, to run, in Chrome, the first example from the `Curve2D` class, you
would run it like so, from this [api](.) directory:

```
% flutter run -d chrome lib/animation/curves/curve2_d.0.dart
```

These same examples are available on the API docs site. For instance, the
example above is available on [this
page](https://api.flutter.dev/flutter/animation/Curve2D-class.html#animation.Curve2D.1).
Most of them are available as interactive examples in Dartpad, but some just
don't make sense on the web, and so are available as standalone examples that
can be run here.

## Naming

The naming scheme for the files is similar to the hierarchy under
[packages/flutter/lib/src](../../packages/flutter/lib/src), except that the
files are represented as directories, and each sample in each file as a separate
file in that directory. So, for the example above, the examples are from the
[packages/flutter/lib/src/animation/curves.dart](../../packages/flutter/lib/src/animation/curves.dart)
file, the `Curve2D` class, and the first sample (hence the index "0") for that
symbol resides in the
[lib/animation/curves/curve2_d.0.dart](lib/animation/curves/curve2_d.0.dart)
file.

## Authoring

When authoring these examples, place a block like so in the Dartdoc
documentation for the symbol you would like to attach it to. Here's what it
might look like if you wanted to add a new example to the `Curve2D` class. First
add the stub to the symbol documentation:

```dart
/// {@tool dartpad --template=material_scaffold}
/// Write a description of the example here. This description will appear in the
/// API web documentation to introduce the example.
///
/// ```dart
/// // These are the sections you want to fill out in the template.
/// // They will be transferred to the example file when you extract it.
/// ```
/// {@end-tool}
```

Then install the `extract_sample` command with:

```
% pub global activate snippets
```

And run the `extract_sample` command from the Flutter repo dir:

```
$ pub global run extract_sample packages/flutter/lib/src/animation/curves.dart
```

This will create a new file in the `examples/api` directory, in this case it
would create `examples/api/lib/animation/curves/curve2_d.1.dart`
