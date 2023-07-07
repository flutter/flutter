// istorageitemextraproperties.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
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
import '../../foundation/collections/iiterable.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import '../../foundation/collections/imap.dart';
import '../../foundation/iasyncaction.dart';
import '../../foundation/iasyncoperation.dart';
import '../../internal/async_helpers.dart';
import '../../internal/hstring_array.dart';

/// @nodoc
const IID_IStorageItemExtraProperties =
    '{c54361b2-54cd-432b-bdbc-4b19c4b470d7}';

/// {@category Interface}
/// {@category winrt}
class IStorageItemExtraProperties extends IInspectable {
  // vtable begins at 6, is 3 entries long.
  IStorageItemExtraProperties.fromRawPointer(super.ptr);

  factory IStorageItemExtraProperties.from(IInspectable interface) =>
      IStorageItemExtraProperties.fromRawPointer(
          interface.toInterface(IID_IStorageItemExtraProperties));

  Future<IMap<String, Object?>> retrievePropertiesAsync(
      IIterable<String>? propertiesToRetrieve) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<IMap<String, Object?>>();

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer,
                            Pointer<COMObject> propertiesToRetrieve,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<COMObject> propertiesToRetrieve,
                    Pointer<COMObject>)>()(
        ptr.ref.lpVtbl,
        propertiesToRetrieve == null
            ? nullptr
            : propertiesToRetrieve.ptr.cast<Pointer<COMObject>>().value,
        retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncOperation =
        IAsyncOperation<IMap<String, Object?>>.fromRawPointer(retValuePtr,
            creator: (Pointer<COMObject> ptr) => IMap.fromRawPointer(ptr,
                iterableIid: '{fe2f3d47-5d47-5499-8374-430c7cda0204}'));
    completeAsyncOperation(
        asyncOperation, completer, asyncOperation.getResults);

    return completer.future;
  }

  Future<void> savePropertiesAsync(
      IIterable<IKeyValuePair<String, Object?>>? propertiesToSave) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<void>();

    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer,
                            Pointer<COMObject> propertiesToSave,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<COMObject> propertiesToSave,
                    Pointer<COMObject>)>()(
        ptr.ref.lpVtbl,
        propertiesToSave == null
            ? nullptr
            : propertiesToSave.ptr.cast<Pointer<COMObject>>().value,
        retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncAction = IAsyncAction.fromRawPointer(retValuePtr);
    completeAsyncAction(asyncAction, completer);

    return completer.future;
  }

  Future<void> savePropertiesAsyncOverloadDefault() {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<void>();

    final hr = ptr.ref.vtable
            .elementAt(8)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncAction = IAsyncAction.fromRawPointer(retValuePtr);
    completeAsyncAction(asyncAction, completer);

    return completer.future;
  }
}
