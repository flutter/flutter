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

/// A reference to a directory (or _folder_) on the file system.
///
/// A Directory instance is an object holding a [path] on which operations can
/// be performed. The path to the directory can be [absolute] or relative.
/// You can get the parent directory using the getter [parent],
/// a property inherited from [FileSystemEntity].
///
/// In addition to being used as an instance to access the file system,
/// Directory has a number of static properties, such as [systemTemp],
/// which gets the system's temporary directory, and the getter and setter
/// [current], which you can use to access or change the current directory.
///
/// Create a new Directory object with a pathname to access the specified
/// directory on the file system from your program.
///
///     var myDir = new Directory('myDir');
///
/// Most methods in this class occur in synchronous and asynchronous pairs,
/// for example, [create] and [createSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// ## Create a directory
///
/// The following code sample creates a directory using the [create] method.
/// By setting the `recursive` parameter to true, you can create the
/// named directory and all its necessary parent directories,
/// if they do not already exist.
///
///     import 'dart:io';
///
///     void main() {
///       // Creates dir/ and dir/subdir/.
///       new Directory('dir/subdir').create(recursive: true)
///         // The created directory is returned as a Future.
///         .then((Directory directory) {
///           print(directory.path);
///       });
///     }
///
/// ## List a directory
///
/// Use the [list] or [listSync] methods to get the files and directories
/// contained by a directory.
/// Set `recursive` to true to recursively list all subdirectories.
/// Set `followLinks` to true to follow symbolic links.
/// The list method returns a [Stream] that provides FileSystemEntity
/// objects. Use the listen callback function to process each object
/// as it become available.
///
///     import 'dart:io';
///
///     void main() {
///       // Get the system temp directory.
///       var systemTempDir = Directory.systemTemp;
///
///       // List directory contents, recursing into sub-directories,
///       // but not following symbolic links.
///       systemTempDir.list(recursive: true, followLinks: false)
///         .listen((FileSystemEntity entity) {
///           print(entity.path);
///         });
///     }
///
/// ## The use of Futures
///
/// I/O operations can block a program for some period of time while it waits for
/// the operation to complete. To avoid this, all
/// methods involving I/O have an asynchronous variant which returns a [Future].
/// This future completes when the I/O operation finishes. While the I/O
/// operation is in progress, the Dart program is not blocked,
/// and can perform other operations.
///
/// For example,
/// the [exists] method, which determines whether the directory exists,
/// returns a boolean value using a Future.
/// Use `then` to register a callback function, which is called when
/// the value is ready.
///
///     import 'dart:io';
///
///     main() {
///       final myDir = new Directory('dir');
///       myDir.exists().then((isThere) {
///         isThere ? print('exists') : print('non-existent');
///       });
///     }
///
///
/// In addition to exists, the [stat], [rename], and
/// other methods, return Futures.
///
/// ## Other resources
///
/// * [Dart by Example](https://www.dartlang.org/dart-by-example/#files-directories-and-symlinks)
///   provides additional task-oriented code samples that show how to use
///   various API from the Directory class and the related [File] class.
///
/// * [I/O for Command-Line
///   Apps](https://www.dartlang.org/docs/dart-up-and-running/ch03.html#dartio---io-for-command-line-apps)
///   a section from _A Tour of the Dart Libraries_ covers files and directories.
///
/// * [Write Command-Line Apps](https://www.dartlang.org/docs/tutorials/cmdline/),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
@pragma('vm:entry-point')
abstract class Directory implements FileSystemEntity {
  /// Creates a directory object pointing to the current working
  /// directory.
  static Directory get current {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.getCurrentDirectory();
  }

  /// Sets the current working directory of the Dart process including
  /// all running isolates. The new value set can be either a [Directory]
  /// or a [String].
  ///
  /// The new value is passed to the OS's system call unchanged, so a
  /// relative path passed as the new working directory will be
  /// resolved by the OS.
  ///
  /// Note that setting the current working directory is a synchronous
  /// operation and that it changes the working directory of *all*
  /// isolates.
  ///
  /// Use this with care - especially when working with asynchronous
  /// operations and multiple isolates. Changing the working directory,
  /// while asynchronous operations are pending or when other isolates
  /// are working with the file system, can lead to unexpected results.
  static set current(path) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    overrides.setCurrentDirectory(path);
  }

  /// Gets the system temp directory.
  ///
  /// Gets the directory provided by the operating system for creating
  /// temporary files and directories in.
  /// The location of the system temp directory is platform-dependent,
  /// and may be set by an environment variable.
  static Directory get systemTemp {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.getSystemTempDirectory();
  }

  /// Creates a [Directory] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  @pragma('vm:entry-point')
  factory Directory(String path) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.createDirectory(path);
  }

  @pragma('vm:entry-point')
  factory Directory.fromRawPath(Uint8List path) {
    return Directory(utf8.decode(path));
  }

  /// Create a Directory object from a URI.
  ///
  /// If [uri] cannot reference a directory this throws [UnsupportedError].
  factory Directory.fromUri(Uri uri) => Directory(uri.toFilePath());

  /// Returns a [Directory] instance whose path is the absolute path to [this].
  ///
  /// The absolute path is computed by prefixing
  /// a relative path with the current working directory, and returning
  /// an absolute path unchanged.
  @override
  Directory get absolute;

  /// Gets the path of this directory.
  @override
  String get path;

  /// Returns a [Uri] representing the directory's location.
  ///
  /// The returned URI's scheme is always "file" if the entity's [path] is
  /// absolute, otherwise the scheme will be empty.
  /// The returned URI's path always ends in a slash ('/').
  @override
  Uri get uri;

  /// Creates the directory with this name.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// Returns a [:Future<Directory>:] that completes with this
  /// directory once it has been created. If the directory cannot be
  /// created the future completes with an exception.
  Future<Directory> create({bool recursive = false});

  /// Synchronously creates the directory with this name.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// If the directory cannot be created an exception is thrown.
  void createSync({bool recursive = false});

  /// Creates a temporary directory in this directory. Additional random
  /// characters are appended to [prefix] to produce a unique directory
  /// name. If [prefix] is missing or null, the empty string is used
  /// for [prefix].
  ///
  /// Returns a [:Future<Directory>:] that completes with the newly
  /// created temporary directory.
  Future<Directory> createTemp([String? prefix]);

  /// Synchronously creates a temporary directory in this directory.
  /// Additional random characters are appended to [prefix] to produce
  /// a unique directory name. If [prefix] is missing or null, the empty
  /// string is used for [prefix].
  ///
  /// Returns the newly created temporary directory.
  Directory createTempSync([String? prefix]);

  /// Lists the sub-directories and files of this [Directory].
  /// Optionally recurses into sub-directories.
  ///
  /// If [followLinks] is false, then any symbolic links found
  /// are reported as [Link] objects, rather than as directories or files,
  /// and are not recursed into.
  ///
  /// If [followLinks] is true, then working links are reported as
  /// directories or files, depending on
  /// their type, and links to directories are recursed into.
  /// Broken links are reported as [Link] objects.
  /// If a symbolic link makes a loop in the file system, then a recursive
  /// listing will not follow a link twice in the
  /// same recursive descent, but will report it as a [Link]
  /// the second time it is seen.
  ///
  /// The result is a stream of [FileSystemEntity] objects
  /// for the directories, files, and links.
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true});

  /// Lists the sub-directories and files of this [Directory].
  /// Optionally recurses into sub-directories.
  ///
  /// If [followLinks] is false, then any symbolic links found
  /// are reported as [Link] objects, rather than as directories or files,
  /// and are not recursed into.
  ///
  /// If [followLinks] is true, then working links are reported as
  /// directories or files, depending on
  /// their type, and links to directories are recursed into.
  /// Broken links are reported as [Link] objects.
  /// If a link makes a loop in the file system, then a recursive
  /// listing will not follow a link twice in the
  /// same recursive descent, but will report it as a [Link]
  /// the second time it is seen.
  ///
  /// Returns a [List] containing [FileSystemEntity] objects for the
  /// directories, files, and links.
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true});

  /// Renames this directory. Returns a [:Future<Directory>:] that completes
  /// with a [Directory] instance for the renamed directory.
  ///
  /// If newPath identifies an existing directory, that directory is
  /// replaced. If newPath identifies an existing file, the operation
  /// fails and the future completes with an exception.
  @override
  Future<Directory> rename(String newPath);

  /// Synchronously renames this directory. Returns a [Directory]
  /// instance for the renamed directory.
  ///
  /// If newPath identifies an existing directory, that directory is
  /// replaced. If newPath identifies an existing file the operation
  /// fails and an exception is thrown.
  @override
  Directory renameSync(String newPath);

  @override
  Future<String> resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync();

  /// Returns a human readable string for this Directory instance.
  @override
  String toString();
}
