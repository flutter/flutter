Tutorial examples
=================

These programs were used during the development of the code fragments
used in the tutorials.

They are not officially a part of the tutorials, and are only provided
on an as-is basis.

## Running the examples

Run "dart pub get" in the parent directory, and then run the example Dart
Dart programs. For example:

```sh
dart aes-cbc-direct.dart
dart digest-direct.dart "foobar"
dart rsa-demo.dart
```

All of these example programs accept the "-h" or "--help" option.

## Checking the text in the tutorials

Fragments of the Dart code are copied into the MarkDown tutorial files
in the parent directory.

The fragments between comment lines containing "BEGIN EXAMPLE" and
"END EXAMPLE" should appear literally the same in the MarkDown file.
Other fragments have been modified to make them more readable in the
tutorial and more functional in the example code.
