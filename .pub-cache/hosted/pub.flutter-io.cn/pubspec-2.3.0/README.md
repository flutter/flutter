# pubspec

A library for manipulating [pubspec](https://www.dartlang.org/tools/pub/pubspec.html) files.

## Usage

A simple usage example:

    import 'package:pubspec/pubspec.dart';

    main() async {
      // load it
      var pubSpec = await PubSpec.load(myDirectory);

      // change the dependencies to a single path dependency on project 'foo'
      var newPubSpec = pubSpec.copy(dependencies: { 'foo': PathReference('../foo') });

      // save it
      await newPubSpec.save(myDirectory);
    }


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/j4qfrost/pubspec/issues
