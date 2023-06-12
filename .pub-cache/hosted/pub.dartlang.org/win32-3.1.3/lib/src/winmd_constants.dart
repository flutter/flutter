// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Enums and constants used for Windows Metadata

// ignore_for_file: constant_identifier_names

/// @nodoc
const CLSID_CorMetaDataDispenser = '{E5CB7A31-7512-11D2-89CE-0080C792E5D8}';

/// Contains flag values that control metadata behavior upon opening manifest
/// files.
///
/// {@category Enum}
class CorOpenFlags {
  /// Indicates that the file should be opened for reading only.
  static const ofRead = 0x00000000;

  /// Indicates that the file should be opened for writing.
  static const ofWrite = 0x00000001;

  /// A mask for reading and writing.
  static const ofReadWriteMask = 0x00000001;

  /// Indicates that the file should be read into memory. Metadata should
  /// maintain its own copy.
  static const ofCopyMemory = 0x00000002;

  /// Obsolete. This flag is ignored.
  static const ofCacheImage = 0x00000004;

  /// Obsolete. This flag is ignored.
  static const ofManifestMetadata = 0x00000008;

  /// Indicates that the file should be opened for reading, and that a call to
  /// QueryInterface for an IMetaDataEmit cannot be made.
  static const ofReadOnly = 0x00000010;

  /// Indicates that the memory was allocated using a call to CoTaskMemAlloc and
  /// will be freed by the metadata.
  static const ofTakeOwnership = 0x00000020;

  /// Obsolete. This flag is ignored.
  static const ofNoTypeLib = 0x00000080;

  /// Indicates that automatic transforms of .winmd files should be disabled. In
  /// other words, the projection of a Windows Runtime type to a .NET Framework
  /// type should be disabled.
  static const ofNoTransform = 0x00001000;

  /// Reserved for internal use.
  static const ofReserved1 = 0x00000100;

  /// Reserved for internal use.
  static const ofReserved2 = 0x00000200;

  /// Reserved for internal use.
  static const ofReserved = 0xffffff40;
}
