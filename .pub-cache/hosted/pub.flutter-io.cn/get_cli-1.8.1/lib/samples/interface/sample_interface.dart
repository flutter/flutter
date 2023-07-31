import 'dart:io';

import '../../functions/create/create_single_file.dart';

/// [Sample] is the Base class in which the files for each command
/// will be built.
abstract class Sample {
  String customContent = '';

  /// The path where the sample file will be added
  String path;

  /// If the file is found in the path, it can be ignored or
  /// overwritten. If overrite = false, the source file will not be changed.
  /// The default is [false].
  bool overwrite;

  /// Store the content that will be written to the file in a String or
  /// Future <String> in that variable. It is used to fill the file created
  /// by path.
  String get content;

  Sample(this.path, {this.overwrite = false});

  /// This function will create the file in [path] with the
  /// content of [content].
  File create({bool skipFormatter = false}) {
    return writeFile(
      path,
      customContent.isNotEmpty ? customContent : content,
      overwrite: overwrite,
      skipFormatter: skipFormatter,
      useRelativeImport: true,
    );
  }
}
