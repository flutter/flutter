// fileopenpicker.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/collections/ivector.dart';
import '../../foundation/collections/ivectorview.dart';
import '../../foundation/collections/valueset.dart';
import '../../foundation/iasyncoperation.dart';
import '../../internal/hstring_array.dart';
import '../../system/user.dart';
import '../storagefile.dart';
import 'enums.g.dart';
import 'ifileopenpicker.dart';
import 'ifileopenpicker3.dart';
import 'ifileopenpickerstatics2.dart';

/// Represents a UI element that lets the user choose and open files. In a
/// desktop app, before using an instance of this class in a way that
/// displays UI, you'll need to associate the object with its owner's window
/// handle.
///
/// {@category Class}
/// {@category winrt}
class FileOpenPicker extends IInspectable
    implements IFileOpenPicker, IFileOpenPicker3 {
  FileOpenPicker() : super(ActivateClass(_className));
  FileOpenPicker.fromRawPointer(super.ptr);

  static const _className = 'Windows.Storage.Pickers.FileOpenPicker';

  // IFileOpenPickerStatics2 methods
  static FileOpenPicker? createForUser(User? user) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IFileOpenPickerStatics2);
    final object = IFileOpenPickerStatics2.fromRawPointer(activationFactoryPtr);

    try {
      return object.createForUser(user);
    } finally {
      object.release();
    }
  }

  // IFileOpenPicker methods
  late final _iFileOpenPicker = IFileOpenPicker.from(this);

  @override
  PickerViewMode get viewMode => _iFileOpenPicker.viewMode;

  @override
  set viewMode(PickerViewMode value) => _iFileOpenPicker.viewMode = value;

  @override
  String get settingsIdentifier => _iFileOpenPicker.settingsIdentifier;

  @override
  set settingsIdentifier(String value) =>
      _iFileOpenPicker.settingsIdentifier = value;

  @override
  PickerLocationId get suggestedStartLocation =>
      _iFileOpenPicker.suggestedStartLocation;

  @override
  set suggestedStartLocation(PickerLocationId value) =>
      _iFileOpenPicker.suggestedStartLocation = value;

  @override
  String get commitButtonText => _iFileOpenPicker.commitButtonText;

  @override
  set commitButtonText(String value) =>
      _iFileOpenPicker.commitButtonText = value;

  @override
  IVector<String> get fileTypeFilter => _iFileOpenPicker.fileTypeFilter;

  @override
  Future<StorageFile?> pickSingleFileAsync() =>
      _iFileOpenPicker.pickSingleFileAsync();

  @override
  Future<List<StorageFile>> pickMultipleFilesAsync() =>
      _iFileOpenPicker.pickMultipleFilesAsync();

  // IFileOpenPicker3 methods
  late final _iFileOpenPicker3 = IFileOpenPicker3.from(this);

  @override
  User? get user => _iFileOpenPicker3.user;
}
