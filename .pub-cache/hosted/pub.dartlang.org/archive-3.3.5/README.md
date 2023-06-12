# archive
[![Dart CI](https://github.com/brendan-duncan/archive/actions/workflows/build.yaml/badge.svg)](https://github.com/brendan-duncan/archive/actions/workflows/build.yaml)
[![pub package](https://img.shields.io/pub/v/archive.svg)](https://pub.dev/packages/archive)

## Overview

A Dart library to encode and decode various archive and compression formats.

The archive library currently supports the following decoders:

- Zip (Archive)
- Tar (Archive)
- ZLib [Inflate decompression]
- GZip [Inflate decompression]
- BZip2 [decompression]
- XZ [decompression]

And the following encoders:

- Zip (Archive)
- Tar (Archive)
- ZLib [Deflate compression]
- GZip [Deflate compression]
- BZip2 [compression]

---

## Usage

There are two versions of the Archive library:

**package:archive/archive.dart**
* Can be used for web applications since it has no dependency on 'dart:io'.

**package:archive/archive_io.dart**
  * For Flutter and server applications, with direct file access to
    reduce memory usage. All classes and functions of `archive.dart`
    are included in `archive_io.dart`.

### archive_io

The archive_io library contains classes and functions for accessing the file system. 
These classes and functions can significantly reduce memory usage for decoding archives
directly to disk.

#### Using InputFileStream and OutputFileStream to reduce memory usage:
```dart
import 'package:archive/archive_io.dart';
// ...
  // Use an InputFileStream to access the zip file without storing it in memory.
  final inputStream = InputFileStream('test.zip');
  // Decode the zip from the InputFileStream. The archive will have the contents of the
  // zip, without having stored the data in memory. 
  final archive = ZipDecoder().decodeBuffer(inputStream);
  // For all of the entries in the archive
  for (var file in archive.files) {
    // If it's a file and not a directory 
    if (file.isFile) {
      // Write the file content to a directory called 'out'.
      // In practice, you should make sure file.name doesn't include '..' paths
      // that would put it outside of the extraction directory.
      // An OutputFileStream will write the data to disk.
      final outputStream = OutputFileStream('out/${file.name}');
      // The writeContent method will decompress the file content directly to disk without
      // storing the decompressed data in memory. 
      file.writeContent(outputStream);
      // Make sure to close the output stream so the File is closed.
      outputStream.close();
    }
  }
```
#### extractFileToDisk
`extractFileToDisk` is a convenience function to extract the contents of
an archive file directory to an output directory.
The type of archive it is will be determined by the file extension.
```dart
import 'package:archive/archive_io.dart';
// ...
extractFileToDisk('test.zip', 'out');
```
#### extractArchiveToDisk
`extractArchiveToDisk` is a convenience function to write the contents of an Archive
to an output directory.
```dart
import 'package:archive/archive_io.dart';
// ...
// Use an InputFileStream to access the zip file without storing it in memory.
final inputStream = InputFileStream('test.zip');
// Decode the zip from the InputFileStream. The archive will have the contents of the
// zip, without having stored the data in memory. 
final archive = ZipDecoder().decodeBuffer(inputStream);
extractArchiveToDisk(archive, 'out');
```
