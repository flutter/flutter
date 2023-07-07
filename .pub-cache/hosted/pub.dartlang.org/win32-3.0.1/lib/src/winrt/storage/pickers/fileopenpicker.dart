// fileopenpicker.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../../winrt/internal/hstring_array.dart';

import '../../../winrt/storage/pickers/ifileopenpicker.dart';
import '../../../winrt/storage/pickers/ifileopenpicker3.dart';
import 'ifileopenpickerstatics2.dart';
import '../../../winrt/foundation/collections/valueset.dart';
import '../../../winrt/foundation/iasyncoperation.dart';
import '../../../winrt/storage/storagefile.dart';
import '../../../winrt/storage/pickers/enums.g.dart';
import '../../../winrt/foundation/collections/ivector.dart';
import '../../../winrt/foundation/collections/ivectorview.dart';
import '../../../winrt/system/user.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class FileOpenPicker extends IInspectable
    implements IFileOpenPicker, IFileOpenPicker3 {
  FileOpenPicker({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  FileOpenPicker.fromRawPointer(super.ptr);

  static const _className = 'Windows.Storage.Pickers.FileOpenPicker';

  // IFileOpenPickerStatics2 methods
  static Pointer<COMObject> createForUser(Pointer<COMObject> user) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IFileOpenPickerStatics2);

    try {
      return IFileOpenPickerStatics2.fromRawPointer(activationFactory)
          .createForUser(user);
    } finally {
      free(activationFactory);
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
  Pointer<COMObject> pickSingleFileAsync() =>
      _iFileOpenPicker.pickSingleFileAsync();

  @override
  Pointer<COMObject> pickMultipleFilesAsync() =>
      _iFileOpenPicker.pickMultipleFilesAsync();
  // IFileOpenPicker3 methods
  late final _iFileOpenPicker3 = IFileOpenPicker3.from(this);

  @override
  Pointer<COMObject> get user => _iFileOpenPicker3.user;
}
