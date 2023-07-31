[![Dart CI](https://github.com/dart-lang/glob/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/glob/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/glob.svg)](https://pub.dev/packages/glob)
[![package publisher](https://img.shields.io/pub/publisher/glob.svg)](https://pub.dev/packages/glob/publisher)

`glob` is a file and directory globbing library that supports both checking
whether a path matches a glob and listing all entities that match a glob.

A "glob" is a pattern designed specifically to match files and directories. Most
shells support globs natively.

## Usage

To construct a glob, just use `Glob()`. As with `RegExp`s, it's a good idea
to keep around a glob if you'll be using it more than once so that it doesn't
have to be compiled over and over. You can check whether a path matches the glob
using `Glob.matches()`:

```dart
import 'package:glob/glob.dart';

final dartFile = Glob("**.dart");

// Print all command-line arguments that are Dart files.
void main(List<String> arguments) {
  for (var argument in arguments) {
    if (dartFile.matches(argument)) print(argument);
  }
}
```

You can also list all files that match a glob using `Glob.list()` or
`Glob.listSync()`:

```dart
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

final dartFile = Glob("**.dart");

// Recursively list all Dart files in the current directory.
void main(List<String> arguments) {
  for (var entity in dartFile.listSync()) {
    print(entity.path);
  }
}
```

## Syntax

The glob syntax hews closely to the widely-known Bash glob syntax, with a few
exceptions that are outlined below.

In order to be as cross-platform and as close to the Bash syntax as possible,
all globs use POSIX path syntax, including using `/` as a directory separator
regardless of which platform they're on. This is true even for Windows roots;
for example, a glob matching all files in the C drive would be `C:/*`.

Globs are case-sensitive by default on Posix systems and browsers, and
case-insensitive by default on Windows.

### Match any characters in a filename: `*`

The `*` character matches zero or more of any character other than `/`. This
means that it can be used to match all files in a given directory that match a
pattern without also matching files in a subdirectory. For example, `lib/*.dart`
will match `lib/glob.dart` but not `lib/src/utils.dart`.

### Match any characters across directories: `**`

`**` is like `*`, but matches `/` as well. It's useful for matching files or
listing directories recursively. For example, `lib/**.dart` will match both
`lib/glob.dart` and `lib/src/utils.dart`.

If `**` appears at the beginning of a glob, it won't match absolute paths or
paths beginning with `../`. For example, `**.dart` won't match `/foo.dart`,
although `/**.dart` will. This is to ensure that listing a bunch of paths and
checking whether they match a glob produces the same results as listing that
glob. In the previous example, `/foo.dart` wouldn't be listed for `**.dart`, so
it shouldn't be matched by it either.

This is an extension to Bash glob syntax that's widely supported by other glob
implementations.

### Match any single character: `?`

The `?` character matches a single character other than `/`. Unlike `*`, it
won't match any more or fewer than one character. For example, `test?.dart` will
match `test1.dart` but not `test10.dart` or `test.dart`.

### Match a range of characters: `[...]`

The `[...]` construction matches one of several characters. It can contain
individual characters, such as `[abc]`, in which case it will match any of those
characters; it can contain ranges, such as `[a-zA-Z]`, in which case it will
match any characters that fall within the range; or it can contain a mix of
both. It will only ever match a single character. For example,
`test[a-zA-Z_].dart` will match `testx.dart`, `testA.dart`, and `test_.dart`,
but not `test-.dart`.

If it starts with `^` or `!`, the construction will instead match all characters
*not* mentioned. For example, `test[^a-z].dart` will match `test1.dart` but not
`testa.dart`.

This construction never matches `/`.

### Match one of several possibilities: `{...,...}`

The `{...,...}` construction matches one of several options, each of which is a
glob itself. For example, `lib/{*.dart,src/*}` matches `lib/glob.dart` and
`lib/src/data.txt`. It can contain any number of options greater than one, and
can even contain nested options.

This is an extension to Bash glob syntax, although it is supported by other
layers of Bash and is often used in conjunction with globs.

### Escaping a character: `\`

The `\` character can be used in any context to escape a character that would
otherwise be semantically meaningful. For example, `\*.dart` matches `*.dart`
but not `test.dart`.

### Syntax errors

Because they're used as part of the shell, almost all strings are valid Bash
globs. This implementation is more picky, and performs some validation to ensure
that globs are meaningful. For instance, unclosed `{` and `[` are disallowed.

### Reserved syntax: `(...)`

Parentheses are reserved in case this package adds support for Bash extended
globbing in the future. For the time being, using them will throw an error
unless they're escaped.
