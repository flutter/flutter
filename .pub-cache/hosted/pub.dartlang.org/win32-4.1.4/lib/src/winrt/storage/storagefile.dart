// storagefile.dart

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../winrt_helpers.dart';
import 'enums.g.dart';
import 'fileproperties/basicproperties.dart';
import 'istoragefile.dart';
import 'istoragefilestatics.dart';
import 'istorageitem.dart';

/// Represents a file. Provides information about the file and its content, and
/// ways to manipulate them.
///
/// {@category Class}
/// {@category winrt}
class StorageFile extends IInspectable implements IStorageFile, IStorageItem {
  StorageFile() : super(ActivateClass(_className));
  StorageFile.fromRawPointer(super.ptr);

  static const _className = 'Windows.Storage.StorageFile';

  // IStorageFileStatics methods
  static Future<StorageFile?> getFileFromPathAsync(String path) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IStorageFileStatics);
    final object = IStorageFileStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getFileFromPathAsync(path);
    } finally {
      object.release();
    }
  }

  static Future<StorageFile?> getFileFromApplicationUriAsync(Uri uri) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IStorageFileStatics);
    final object = IStorageFileStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getFileFromApplicationUriAsync(uri);
    } finally {
      object.release();
    }
  }

  // IStorageFile methods
  late final _iStorageFile = IStorageFile.from(this);

  @override
  FileAttributes get attributes => _iStorageFile.attributes;

  @override
  String get contentType => _iStorageFile.contentType;

  @override
  Future<void> copyAndReplaceAsync(IStorageFile fileToReplace) =>
      _iStorageFile.copyAndReplaceAsync(fileToReplace);

  @override
  DateTime get dateCreated => _iStorageFile.dateCreated;

  @override
  Future<void> deleteAsync(StorageDeleteOption option) =>
      _iStorageFile.deleteAsync(option);

  @override
  Future<void> deleteAsyncOverloadDefaultOptions() =>
      _iStorageFile.deleteAsyncOverloadDefaultOptions();

  @override
  String get fileType => _iStorageFile.fileType;

  @override
  Future<BasicProperties?> getBasicPropertiesAsync() =>
      _iStorageFile.getBasicPropertiesAsync();

  @override
  bool isOfType(StorageItemTypes type) => _iStorageFile.isOfType(type);

  @override
  Future<void> moveAndReplaceAsync(IStorageFile fileToReplace) =>
      _iStorageFile.moveAndReplaceAsync(fileToReplace);

  @override
  String get name => _iStorageFile.name;

  @override
  String get path => _iStorageFile.path;

  @override
  Future<void> renameAsync(String desiredName, NameCollisionOption option) =>
      _iStorageFile.renameAsync(desiredName, option);

  @override
  Future<void> renameAsyncOverloadDefaultOptions(String desiredName) =>
      _iStorageFile.renameAsyncOverloadDefaultOptions(desiredName);
}
