## ReCase ##

Changes the case of the input text to the desire case convention.

    import 'package:recase/recase.dart';

    void main() {
      ReCase rc = new ReCase('Just_someSample-text');

      print(rc.camelCase); // Prints 'justSomeSampleText'
      print(rc.constantCase); // Prints 'JUST_SOME_SAMPLE_TEXT'
    }

String extensions are also available.

    import 'package:recase/recase.dart';

    void main() {
      String sample = 'Just_someSample-text';

      print(sample.camelCase); // Prints 'justSomeSampleText'
      print(sample.constantCase); // Prints 'JUST_SOME_SAMPLE_TEXT'
    }
_This feature is available in version 3.0.0, and requires at least Dart 2.6_


Supports:
* snake_case
* dot.case
* path/case
* param-case
* PascalCase
* Header-Case
* Title Case
* camelCase
* Sentence case
* CONSTANT_CASE
