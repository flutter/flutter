// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../io_impl_js.dart';

/// The mode for opening a file for reading and writing to the
/// end of it. The file is created if it does not already exist.
@Deprecated('Use FileMode.append instead')
const APPEND = FileMode.append;

/// The mode for opening a file only for reading.
@Deprecated('Use FileMode.read instead')
const READ = FileMode.read;

/// The mode for opening a file for reading and writing. The file is
/// overwritten if it already exists. The file is created if it does not
/// already exist.
@Deprecated('Use FileMode.write instead')
const WRITE = FileMode.write;

/// Mode for opening a file for writing *only*. The file is
/// overwritten if it already exists. The file is created if it does not
/// already exist.
@Deprecated('Use FileMode.writeOnly instead')
const WRITE_ONLY = FileMode.writeOnly;

/// Mode for opening a file for writing *only* to the
/// end of it. The file is created if it does not already exist.
@Deprecated('Use FileMode.writeOnlyAppend instead')
const WRITE_ONLY_APPEND = FileMode.writeOnlyAppend;

/// A reference to a file on the file system.
///
/// A File instance is an object that holds a [path] on which operations can
/// be performed.
/// You can get the parent directory of the file using the getter [parent],
/// a property inherited from [FileSystemEntity].
///
/// Create a new File object with a pathname to access the specified file on the
/// file system from your program.
///
///     var myFile = new File('file.txt');
///
/// The File class contains methods for manipulating files and their contents.
/// Using methods in this class, you can open and close files, read to and write
/// from them, create and delete them, and check for their existence.
///
/// When reading or writing a file, you can use streams (with [openRead]),
/// random access operations (with [open]),
/// or convenience methods such as [readAsString],
///
/// Most methods in this class occur in synchronous and asynchronous pairs,
/// for example, [readAsString] and [readAsStringSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// ## If path is a link
///
/// If [path] is a symbolic link, rather than a file,
/// then the methods of File operate on the ultimate target of the
/// link, except for [delete] and [deleteSync], which operate on
/// the link.
///
/// ## Read from a file
///
/// The following code sample reads the entire contents from a file as a string
/// using the asynchronous [readAsString] method:
///
///     import 'dart:async';
///     import 'dart:io';
///
///     void main() {
///       new File('file.txt').readAsString().then((String contents) {
///         print(contents);
///       });
///     }
///
/// A more flexible and useful way to read a file is with a [Stream].
/// Open the file with [openRead], which returns a stream that
/// provides the data in the file as chunks of bytes.
/// Listen to the stream for data and process as needed.
/// You can use various transformers in succession to manipulate the
/// data into the required format or to prepare it for output.
///
/// You might want to use a stream to read large files,
/// to manipulate the data with transformers,
/// or for compatibility with another API, such as [WebSocket]s.
///
///     import 'dart:io';
///     import 'dart:convert';
///     import 'dart:async';
///
///     main() {
///       final file = new File('file.txt');
///       Stream<List<int>> inputStream = file.openRead();
///
///       inputStream
///         .transform(utf8.decoder)       // Decode bytes to UTF-8.
///         .transform(new LineSplitter()) // Convert stream to individual lines.
///         .listen((String line) {        // Process results.
///             print('$line: ${line.length} bytes');
///           },
///           onDone: () { print('File is now closed.'); },
///           onError: (e) { print(e.toString()); });
///     }
///
/// ## Write to a file
///
/// To write a string to a file, use the [writeAsString] method:
///
///     import 'dart:io';
///
///     void main() {
///       final filename = 'file.txt';
///       new File(filename).writeAsString('some content')
///         .then((File file) {
///           // Do something with the file.
///         });
///     }
///
/// You can also write to a file using a [Stream]. Open the file with
/// [openWrite], which returns an [IOSink] to which you can write data.
/// Be sure to close the sink with the [IOSink.close] method.
///
///     import 'dart:io';
///
///     void main() {
///       var file = new File('file.txt');
///       var sink = file.openWrite();
///       sink.write('FILE ACCESSED ${new DateTime.now()}\n');
///
///       // Close the IOSink to free system resources.
///       sink.close();
///     }
///
/// ## The use of Futures
///
/// To avoid unintentional blocking of the program,
/// several methods use a [Future] to return a value. For example,
/// the [length] method, which gets the length of a file, returns a Future.
/// Use `then` to register a callback function, which is called when
/// the value is ready.
///
///     import 'dart:io';
///
///     main() {
///       final file = new File('file.txt');
///
///       file.length().then((len) {
///         print(len);
///       });
///     }
///
/// In addition to length, the [exists], [lastModified], [stat], and
/// other methods, return Futures.
///
/// ## Other resources
///
/// * The [Files and directories](https://dart.dev/guides/libraries/library-tour#files-and-directories)
///   section of the library tour.
///
/// * [Write Command-Line Apps](https://dart.dev/tutorials/server/cmdline),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
@pragma('vm:entry-point')
abstract class File implements FileSystemEntity {
  /// Creates a [File] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  @pragma('vm:entry-point')
  factory File(String path) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.createFile(path);
  }

  /// Creates a File object from a raw path, that is, a sequence of bytes
  /// as represented by the OS.
  @pragma('vm:entry-point')
  factory File.fromRawPath(Uint8List rawPath) {
    return File(utf8.decode(rawPath));
  }

  /// Create a File object from a URI.
  ///
  /// If [uri] cannot reference a file this throws [UnsupportedError].
  factory File.fromUri(Uri uri) => File(uri.toFilePath());

  /// Returns a [File] instance whose path is the absolute path to [this].
  ///
  /// The absolute path is computed by prefixing
  /// a relative path with the current working directory, and returning
  /// an absolute path unchanged.
  @override
  File get absolute;

  /// Get the path of the file.
  @override
  String get path;

  /// Copy this file. Returns a `Future<File>` that completes
  /// with a [File] instance for the copied file.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// replaced. If [newPath] identifies an existing directory, the
  /// operation fails and the future completes with an exception.
  Future<File> copy(String newPath);

  /// Synchronously copy this file. Returns a [File]
  /// instance for the copied file.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// replaced. If [newPath] identifies an existing directory the
  /// operation fails and an exception is thrown.
  File copySync(String newPath);

  /// Create the file. Returns a `Future<File>` that completes with
  /// the file when it has been created.
  ///
  /// If [recursive] is false, the default, the file is created only if
  /// all directories in the path exist. If [recursive] is true, all
  /// non-existing path components are created.
  ///
  /// Existing files are left untouched by [create]. Calling [create] on an
  /// existing file might fail if there are restrictive permissions on
  /// the file.
  ///
  /// Completes the future with a [FileSystemException] if the operation fails.
  Future<File> create({bool recursive = false});

  /// Synchronously create the file. Existing files are left untouched
  /// by [createSync]. Calling [createSync] on an existing file might fail
  /// if there are restrictive permissions on the file.
  ///
  /// If [recursive] is false, the default, the file is created
  /// only if all directories in the path exist.
  /// If [recursive] is true, all non-existing path components are created.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void createSync({bool recursive = false});

  /// Get the last-accessed time of the file.
  ///
  /// Returns a `Future<DateTime>` that completes with the date and time when the
  /// file was last accessed, if the information is available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Future<DateTime> lastAccessed();

  /// Get the last-accessed time of the file.
  ///
  /// Returns the date and time when the file was last accessed,
  /// if the information is available. Blocks until the information can be returned
  /// or it is determined that the information is not available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  DateTime lastAccessedSync();

  /// Get the last-modified time of the file.
  ///
  /// Returns a `Future<DateTime>` that completes with the date and time when the
  /// file was last modified, if the information is available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Future<DateTime> lastModified();

  /// Get the last-modified time of the file.
  ///
  /// Returns the date and time when the file was last modified,
  /// if the information is available. Blocks until the information can be returned
  /// or it is determined that the information is not available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  DateTime lastModifiedSync();

  /// Get the length of the file. Returns a `Future<int>` that
  /// completes with the length in bytes.
  Future<int> length();

  /// Synchronously get the length of the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int lengthSync();

  /// Open the file for random access operations. Returns a
  /// `Future<RandomAccessFile>` that completes with the opened
  /// random access file. [RandomAccessFile]s must be closed using the
  /// [RandomAccessFile.close] method.
  ///
  /// Files can be opened in three modes:
  ///
  /// [FileMode.read]: open the file for reading.
  ///
  /// [FileMode.write]: open the file for both reading and writing and
  /// truncate the file to length zero. If the file does not exist the
  /// file is created.
  ///
  /// [FileMode.append]: same as [FileMode.write] except that the file is
  /// not truncated.
  Future<RandomAccessFile> open({FileMode mode = FileMode.read});

  /// Create a new independent [Stream] for the contents of this file.
  ///
  /// If [start] is present, the file will be read from byte-offset [start].
  /// Otherwise from the beginning (index 0).
  ///
  /// If [end] is present, only up to byte-index [end] will be read. Otherwise,
  /// until end of file.
  ///
  /// In order to make sure that system resources are freed, the stream
  /// must be read to completion or the subscription on the stream must
  /// be cancelled.
  Stream<List<int>> openRead([int? start, int? end]);

  /// Synchronously open the file for random access operations. The
  /// result is a [RandomAccessFile] on which random access operations
  /// can be performed. Opened [RandomAccessFile]s must be closed using
  /// the [RandomAccessFile.close] method.
  ///
  /// See [open] for information on the [mode] argument.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  RandomAccessFile openSync({FileMode mode = FileMode.read});

  /// Creates a new independent [IOSink] for the file. The
  /// [IOSink] must be closed when no longer used, to free
  /// system resources.
  ///
  /// An [IOSink] for a file can be opened in two modes:
  ///
  /// * [FileMode.write]: truncates the file to length zero.
  /// * [FileMode.append]: sets the initial write position to the end
  ///   of the file.
  ///
  ///  When writing strings through the returned [IOSink] the encoding
  ///  specified using [encoding] will be used. The returned [IOSink]
  ///  has an `encoding` property which can be changed after the
  ///  [IOSink] has been created.
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8});

  /// Read the entire file contents as a list of bytes. Returns a
  /// `Future<Uint8List>` that completes with the list of bytes that
  /// is the contents of the file.
  Future<Uint8List> readAsBytes();

  /// Synchronously read the entire file contents as a list of bytes.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Uint8List readAsBytesSync();

  /// Read the entire file contents as lines of text using the given
  /// [Encoding].
  ///
  /// Returns a `Future<List<String>>` that completes with the lines
  /// once the file contents has been read.
  Future<List<String>> readAsLines({Encoding encoding = utf8});

  /// Synchronously read the entire file contents as lines of text
  /// using the given [Encoding].
  ///
  /// Throws a [FileSystemException] if the operation fails.
  List<String> readAsLinesSync({Encoding encoding = utf8});

  /// Read the entire file contents as a string using the given
  /// [Encoding].
  ///
  /// Returns a `Future<String>` that completes with the string once
  /// the file contents has been read.
  Future<String> readAsString({Encoding encoding = utf8});

  /// Synchronously read the entire file contents as a string using the
  /// given [Encoding].
  ///
  /// Throws a [FileSystemException] if the operation fails.
  String readAsStringSync({Encoding encoding = utf8});

  /// Renames this file. Returns a `Future<File>` that completes
  /// with a [File] instance for the renamed file.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// replaced. If [newPath] identifies an existing directory, the
  /// operation fails and the future completes with an exception.
  @override
  Future<File> rename(String newPath);

  /// Synchronously renames this file. Returns a [File]
  /// instance for the renamed file.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// replaced. If [newPath] identifies an existing directory the
  /// operation fails and an exception is thrown.
  @override
  File renameSync(String newPath);

  /// Modifies the time the file was last accessed.
  ///
  /// Returns a [Future] that completes once the operation has completed.
  ///
  /// Throws a [FileSystemException] if the time cannot be set.
  Future setLastAccessed(DateTime time);

  /// Synchronously modifies the time the file was last accessed.
  ///
  /// Throws a [FileSystemException] if the time cannot be set.
  void setLastAccessedSync(DateTime time);

  /// Modifies the time the file was last modified.
  ///
  /// Returns a [Future] that completes once the operation has completed.
  ///
  /// Throws a [FileSystemException] if the time cannot be set.
  Future setLastModified(DateTime time);

  /// Synchronously modifies the time the file was last modified.
  ///
  /// If the attributes cannot be set, throws a [FileSystemException].
  void setLastModifiedSync(DateTime time);

  /// Write a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it, and closes the file.
  /// Returns a `Future<File>` that completes with this [File] object once
  /// the entire operation has completed.
  ///
  /// By default [writeAsBytes] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false});

  /// Synchronously write a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it and closes the file.
  ///
  /// By default [writeAsBytesSync] creates the file for writing and truncates
  /// the file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the [flush] argument is set to `true` data written will be
  /// flushed to the file system before returning.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false});

  /// Write a string to a file.
  ///
  /// Opens the file, writes the string in the given encoding, and closes the
  /// file. Returns a `Future<File>` that completes with this [File] object
  /// once the entire operation has completed.
  ///
  /// By default [writeAsString] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  ///
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false});

  /// Synchronously write a string to a file.
  ///
  /// Opens the file, writes the string in the given encoding, and closes the
  /// file.
  ///
  /// By default [writeAsStringSync] creates the file for writing and
  /// truncates the file if it already exists. In order to append the bytes
  /// to an existing file, pass [FileMode.append] as the optional mode
  /// parameter.
  ///
  /// If the [flush] argument is set to `true` data written will be
  /// flushed to the file system before returning.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeAsStringSync(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false});
}

/// Type of lock when requesting a lock on a file.
class FileLock {
  /// Shared file lock.
  static const shared = FileLock._internal(1);
  @Deprecated('Use shared instead')
  static const SHARED = shared;

  /// Exclusive file lock.
  static const exclusive = FileLock._internal(2);
  @Deprecated('Use exclusive instead')
  static const EXCLUSIVE = exclusive;

  /// Blocking shared file lock.
  static const blockingShared = FileLock._internal(3);
  @Deprecated('Use blockingShared instead')
  static const BLOCKING_SHARED = blockingShared;

  /// Blocking exclusive file lock.
  static const blockingExclusive = FileLock._internal(4);
  @Deprecated('Use blockingExclusive instead')
  static const BLOCKING_EXCLUSIVE = blockingExclusive;

  final int _type;

  const FileLock._internal(this._type);

  @override
  int get hashCode => _type;
}

/// The modes in which a File can be opened.
class FileMode {
  /// The mode for opening a file only for reading.
  static const read = FileMode._internal(0);
  @Deprecated('Use read instead')
  static const READ = read;

  /// Mode for opening a file for reading and writing. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const write = FileMode._internal(1);
  @Deprecated('Use write instead')
  static const WRITE = write;

  /// Mode for opening a file for reading and writing to the
  /// end of it. The file is created if it does not already exist.
  static const append = FileMode._internal(2);
  @Deprecated('Use append instead')
  static const APPEND = append;

  /// Mode for opening a file for writing *only*. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const writeOnly = FileMode._internal(3);
  @Deprecated('Use writeOnly instead')
  static const WRITE_ONLY = writeOnly;

  /// Mode for opening a file for writing *only* to the
  /// end of it. The file is created if it does not already exist.
  static const writeOnlyAppend = FileMode._internal(4);
  @Deprecated('Use writeOnlyAppend instead')
  static const WRITE_ONLY_APPEND = writeOnlyAppend;

  final int _mode;

  const FileMode._internal(this._mode);

  @override
  int get hashCode => _mode;
}

/// Exception thrown when a file operation fails.
@pragma('vm:entry-point')
class FileSystemException implements IOException {
  /// Message describing the error. This does not include any detailed
  /// information form the underlying OS error. Check [osError] for
  /// that information.
  final String message;

  /// The file system path on which the error occurred. Can be `null`
  /// if the exception does not relate directly to a file system path.
  final String? path;

  /// The underlying OS error. Can be `null` if the exception is not
  /// raised due to an OS error.
  final OSError? osError;

  /// Creates a new FileSystemException with an optional error message
  /// [message], optional file system path [path] and optional OS error
  /// [osError].
  @pragma('vm:entry-point')
  const FileSystemException([this.message = '', this.path = '', this.osError]);

  @override
  String toString() {
    var sb = StringBuffer();
    sb.write('FileSystemException');
    if (message.isNotEmpty) {
      sb.write(': $message');
      if (path != null) {
        sb.write(", path = '$path'");
      }
      if (osError != null) {
        sb.write(' ($osError)');
      }
    } else if (osError != null) {
      sb.write(': $osError');
      if (path != null) {
        sb.write(", path = '$path'");
      }
    } else if (path != null) {
      sb.write(': $path');
    }
    return sb.toString();
  }
}

/// `RandomAccessFile` provides random access to the data in a
/// file.
///
/// `RandomAccessFile` objects are obtained by calling the
/// `open` method on a [File] object.
///
/// A `RandomAccessFile` have both asynchronous and synchronous
/// methods. The asynchronous methods all return a `Future`
/// whereas the synchronous methods will return the result directly,
/// and block the current isolate until the result is ready.
///
/// At most one asynchronous method can be pending on a given `RandomAccessFile`
/// instance at the time. If an asynchronous method is called when one is
/// already in progress a [FileSystemException] is thrown.
///
/// If an asynchronous method is pending it is also not possible to call any
/// synchronous methods. This will also throw a [FileSystemException].
abstract class RandomAccessFile {
  /// Gets the path of the file underlying this RandomAccessFile.
  String get path;

  /// Closes the file. Returns a `Future` that
  /// completes when it has been closed.
  Future<void> close();

  /// Synchronously closes the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void closeSync();

  /// Flushes the contents of the file to disk. Returns a
  /// `Future<RandomAccessFile>` that completes with this
  /// RandomAccessFile when the flush operation completes.
  Future<RandomAccessFile> flush();

  /// Synchronously flushes the contents of the file to disk.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void flushSync();

  /// Gets the length of the file. Returns a `Future<int>` that
  /// completes with the length in bytes.
  Future<int> length();

  /// Synchronously gets the length of the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int lengthSync();

  /// Locks the file or part of the file.
  ///
  /// By default an exclusive lock will be obtained, but that can be overridden
  /// by the [mode] argument.
  ///
  /// Locks the byte range from [start] to [end] of the file, with the
  /// byte at position `end` not included. If no arguments are
  /// specified, the full file is locked, If only `start` is specified
  /// the file is locked from byte position `start` to the end of the
  /// file, no matter how large it grows. It is possible to specify an
  /// explicit value of `end` which is past the current length of the file.
  ///
  /// To obtain an exclusive lock on a file it must be opened for writing.
  ///
  /// If [mode] is [FileLock.exclusive] or [FileLock.shared], an error is
  /// signaled if the lock cannot be obtained. If [mode] is
  /// [FileLock.blockingExclusive] or [FileLock.blockingShared], the
  /// returned [Future] is resolved only when the lock has been obtained.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// On Linux and OS X this uses advisory locks, which have the
  /// surprising semantics that all locks associated with a given file
  /// are removed when *any* file descriptor for that file is closed by
  /// the process. Note that this does not actually lock the file for
  /// access. Also note that advisory locks are on a process
  /// level. This means that several isolates in the same process can
  /// obtain an exclusive lock on the same file.
  ///
  /// On Windows the regions used for lock and unlock needs to match. If that
  /// is not the case unlocking will result in the OS error "The segment is
  /// already unlocked".
  Future<RandomAccessFile> lock(
      [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]);

  /// Synchronously locks the file or part of the file.
  ///
  /// By default an exclusive lock will be obtained, but that can be overridden
  /// by the [mode] argument.
  ///
  /// Locks the byte range from [start] to [end] of the file ,with the
  /// byte at position `end` not included. If no arguments are
  /// specified, the full file is locked, If only `start` is specified
  /// the file is locked from byte position `start` to the end of the
  /// file, no matter how large it grows. It is possible to specify an
  /// explicit value of `end` which is past the current length of the file.
  ///
  /// To obtain an exclusive lock on a file it must be opened for writing.
  ///
  /// If [mode] is [FileLock.exclusive] or [FileLock.shared], an exception is
  /// thrown if the lock cannot be obtained. If [mode] is
  /// [FileLock.blockingExclusive] or [FileLock.blockingShared], the
  /// call returns only after the lock has been obtained.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// On Linux and OS X this uses advisory locks, which have the
  /// surprising semantics that all locks associated with a given file
  /// are removed when *any* file descriptor for that file is closed by
  /// the process. Note that this does not actually lock the file for
  /// access. Also note that advisory locks are on a process
  /// level. This means that several isolates in the same process can
  /// obtain an exclusive lock on the same file.
  ///
  /// On Windows the regions used for lock and unlock needs to match. If that
  /// is not the case unlocking will result in the OS error "The segment is
  /// already unlocked".
  ///
  void lockSync(
      [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]);

  /// Gets the current byte position in the file. Returns a
  /// `Future<int>` that completes with the position.
  Future<int> position();

  /// Synchronously gets the current byte position in the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int positionSync();

  /// Reads [bytes] bytes from a file and returns the result as a list of bytes.
  Future<Uint8List> read(int bytes);

  /// Reads a byte from the file. Returns a `Future<int>` that
  /// completes with the byte, or with -1 if end-of-file has been reached.
  Future<int> readByte();

  /// Synchronously reads a single byte from the file. If end-of-file
  /// has been reached -1 is returned.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int readByteSync();

  /// Reads into an existing [List<int>] from the file. If [start] is present,
  /// the bytes will be filled into [buffer] from at index [start], otherwise
  /// index 0. If [end] is present, the [end] - [start] bytes will be read into
  /// [buffer], otherwise up to [buffer.length]. If [end] == [start] nothing
  /// happens.
  ///
  /// Returns a `Future<int>` that completes with the number of bytes read.
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]);

  /// Synchronously reads into an existing [List<int>] from the file and returns
  /// the number of bytes read.
  ///
  /// If [start] is present, the bytes will be filled into [buffer] from at
  /// index [start], otherwise index 0.  If [end] is present, the
  /// [end] - [start] bytes will be read into [buffer], otherwise up to
  /// [buffer.length]. If [end] == [start] nothing happens.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int readIntoSync(List<int> buffer, [int start = 0, int? end]);

  /// Synchronously reads a maximum of [bytes] bytes from a file and
  /// returns the result in a list of bytes.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Uint8List readSync(int bytes);

  /// Sets the byte position in the file. Returns a
  /// `Future<RandomAccessFile>` that completes with this
  /// RandomAccessFile when the position has been set.
  Future<RandomAccessFile> setPosition(int position);

  /// Synchronously sets the byte position in the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void setPositionSync(int position);

  /// Returns a human-readable string for this RandomAccessFile instance.
  @override
  String toString();

  /// Truncates (or extends) the file to [length] bytes. Returns a
  /// `Future<RandomAccessFile>` that completes with this
  /// RandomAccessFile when the truncation has been performed.
  Future<RandomAccessFile> truncate(int length);

  /// Synchronously truncates (or extends) the file to [length] bytes.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void truncateSync(int length);

  /// Unlocks the file or part of the file.
  ///
  /// Unlocks the byte range from [start] to [end] of the file, with
  /// the byte at position `end` not included. If no arguments are
  /// specified, the full file is unlocked, If only `start` is
  /// specified the file is unlocked from byte position `start` to the
  /// end of the file.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// See [lock] for more details.
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]);

  /// Synchronously unlocks the file or part of the file.
  ///
  /// Unlocks the byte range from [start] to [end] of the file, with
  /// the byte at position `end` not included. If no arguments are
  /// specified, the full file is unlocked, If only `start` is
  /// specified the file is unlocked from byte position `start` to the
  /// end of the file.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// See [lockSync] for more details.
  void unlockSync([int start = 0, int end = -1]);

  /// Writes a single byte to the file. Returns a
  /// `Future<RandomAccessFile>` that completes with this
  /// RandomAccessFile when the write completes.
  Future<RandomAccessFile> writeByte(int value);

  /// Synchronously writes a single byte to the file. Returns 1 on success.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int writeByteSync(int value);

  /// Writes from a [List<int>] to the file. It will read the buffer from index
  /// [start] to index [end]. If [start] is omitted, it'll start from index 0.
  /// If [end] is omitted, it will write to end of [buffer].
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// [RandomAccessFile] when the write completes.
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int? end]);

  /// Synchronously writes from a [List<int>] to the file. It will read the
  /// buffer from index [start] to index [end]. If [start] is omitted, it'll
  /// start from index 0. If [end] is omitted, it will write to the end of
  /// [buffer].
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeFromSync(List<int> buffer, [int start = 0, int? end]);

  /// Writes a string to the file using the given [Encoding]. Returns a
  /// `Future<RandomAccessFile>` that completes with this
  /// RandomAccessFile when the write completes.
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding = utf8});

  /// Synchronously writes a single string to the file using the given
  /// [Encoding].
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeStringSync(String string, {Encoding encoding = utf8});
}
