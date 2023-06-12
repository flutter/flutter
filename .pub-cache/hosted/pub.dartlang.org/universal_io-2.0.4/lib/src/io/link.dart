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
import 'dart:typed_data';

import '../io_impl_js.dart';

/// [Link] objects are references to filesystem links.
///
abstract class Link implements FileSystemEntity {
  /// Creates a Link object.
  factory Link(String path) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.createLink(path);
  }

  factory Link.fromRawPath(Uint8List rawPath) {
    throw UnimplementedError();
  }

  /// Creates a [Link] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  factory Link.fromUri(Uri uri) => Link(uri.toFilePath());

  /// Returns a [Link] instance whose path is the absolute path to [this].
  ///
  /// The absolute path is computed by prefixing
  /// a relative path with the current working directory, and returning
  /// an absolute path unchanged.
  @override
  Link get absolute;

  /// Creates a symbolic link. Returns a [:Future<Link>:] that completes with
  /// the link when it has been created. If the link exists,
  /// the future will complete with an error.
  ///
  /// If [recursive] is false, the default, the link is created
  /// only if all directories in its path exist.
  /// If [recursive] is true, all non-existing path
  /// components are created. The directories in the path of [target] are
  /// not affected, unless they are also in [path].
  ///
  /// On the Windows platform, this call will create a true symbolic link
  /// instead of a Junction. In order to create a symbolic link on Windows, Dart
  /// must be run in Administrator mode or the system must have Developer Mode
  /// enabled, otherwise a [FileSystemException] will be raised with
  /// `ERROR_PRIVILEGE_NOT_HELD` set as the errno when this call is made.
  ///
  /// On other platforms, the posix symlink() call is used to make a symbolic
  /// link containing the string [target].  If [target] is a relative path,
  /// it will be interpreted relative to the directory containing the link.
  Future<Link> create(String target, {bool recursive = false});

  /// Synchronously create the link. Calling [createSync] on an existing link
  /// will throw an exception.
  ///
  /// If [recursive] is false, the default, the link is created only if all
  /// directories in its path exist. If [recursive] is true, all
  /// non-existing path components are created. The directories in
  /// the path of [target] are not affected, unless they are also in [path].
  ///
  /// On the Windows platform, this call will create a true symbolic link
  /// instead of a Junction. In order to create a symbolic link on Windows, Dart
  /// must be run in Administrator mode or the system must have Developer Mode
  /// enabled, otherwise a [FileSystemException] will be raised with
  /// `ERROR_PRIVILEGE_NOT_HELD` set as the errno when this call is made.
  ///
  /// On other platforms, the posix symlink() call is used to make a symbolic
  /// link containing the string [target].  If [target] is a relative path,
  /// it will be interpreted relative to the directory containing the link.
  void createSync(String target, {bool recursive = false});

  /// Renames this link. Returns a `Future<Link>` that completes
  /// with a [Link] instance for the renamed link.
  ///
  /// If [newPath] identifies an existing link, that link is
  /// replaced. If [newPath] identifies an existing file or directory,
  /// the operation fails and the future completes with an exception.
  @override
  Future<Link> rename(String newPath);

  /// Synchronously renames this link. Returns a [Link]
  /// instance for the renamed link.
  ///
  /// If [newPath] identifies an existing link, that link is
  /// replaced. If [newPath] identifies an existing file or directory
  /// the operation fails and an exception is thrown.
  @override
  Link renameSync(String newPath);

  @override
  Future<String> resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync();

  /// Gets the target of the link. Returns a future that completes with
  /// the path to the target.
  ///
  /// If the returned target is a relative path, it is relative to the
  /// directory containing the link.
  ///
  /// If the link does not exist, or is not a link, the future completes with
  /// a FileSystemException.
  Future<String> target();

  /// Synchronously gets the target of the link. Returns the path to the target.
  ///
  /// If the returned target is a relative path, it is relative to the
  /// directory containing the link.
  ///
  /// If the link does not exist, or is not a link, throws a FileSystemException.
  String targetSync();

  /// Updates the link. Returns a [:Future<Link>:] that completes with the
  /// link when it has been updated.  Calling [update] on a non-existing link
  /// will complete its returned future with an exception.
  Future<Link> update(String target);

  /// Synchronously updates the link. Calling [updateSync] on a non-existing link
  /// will throw an exception.
  void updateSync(String target);
}
