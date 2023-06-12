import 'package:flutter_launcher_icons/utils.dart';

class InvalidAndroidIconNameException implements Exception {
  const InvalidAndroidIconNameException([this.message]);
  final String? message;

  @override
  String toString() {
    return generateError(this, message);
  }
}

class InvalidConfigException implements Exception {
  const InvalidConfigException([this.message]);
  final String? message;

  @override
  String toString() {
    return generateError(this, message);
  }
}

class NoConfigFoundException implements Exception {
  const NoConfigFoundException([this.message]);
  final String? message;

  @override
  String toString() {
    return generateError(this, message);
  }
}

class NoDecoderForImageFormatException implements Exception {
  const NoDecoderForImageFormatException([this.message]);
  final String? message;

  @override
  String toString() {
    return generateError(this, message);
  }
}

/// A exception to throw when given [fileName] is not found
class FileNotFoundException implements Exception {
  /// Creates a instance of [FileNotFoundException].
  const FileNotFoundException(this.fileName);

  /// Name of the file
  final String fileName;

  @override
  String toString() {
    return generateError(this, '$fileName file not found');
  }
}
