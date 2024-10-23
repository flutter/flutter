# API MultiWindow Examples

This directory contains examples of the current API built on top of
multi-window support. Only some widgets support multi-window out-of-the-box,
so the number of examples is sparser than what is found in `examples/api`.

At the moment, only Windows examples are supported as that is the only platform
which supports a multi-window runner.

The examples can be run individually by just specifying the path to the example
on the command line (or in the run configuration of an IDE).

For example (no pun intended!), to run the first example from the `Curve2D`
class in Chrome, you would run it like so from the [api](.) directory:

```
% flutter run lib/material/menu_anchor/menu_anchor.0.dart
```

## Naming

> `lib/library/file/class_name.n.dart`
>
> `lib/library/file/class_name.member_name.n.dart`

The naming scheme for the files is similar to the hierarchy under
[packages/flutter/lib/src](../../packages/flutter/lib/src), except that the
files are represented as directories (without the `.dart` suffix), and each
sample in the file is a separate file in that directory. So, for the example
above, where the examples are from the
[packages/flutter/lib/src/animation/curves.dart](../../packages/flutter/lib/src/animation/curves.dart)
file, the `Curve2D` class, the first sample (hence the index "0") for that
symbol resides in the file named
[lib/animation/curves/curve2_d.0.dart](lib/animation/curves/curve2_d.0.dart).

Symbol names are converted from "CamelCase" to "snake_case". Dots are left
between symbol names, so the first example for symbol
`InputDecoration.prefixIconConstraints` would be converted to
`input_decoration.prefix_icon_constraints.0.dart`.

If the same example is linked to from multiple symbols, the source will be in
the canonical location for one of the symbols, and the link in the API docs
block for the other symbols will point to the first symbol's example location.
