// iwwwformurldecoderruntimeclass.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';
import '../internal/hstring_array.dart';
import 'collections/iiterable.dart';
import 'collections/iiterator.dart';
import 'collections/ivectorview.dart';
import 'iwwwformurldecoderentry.dart';

/// @nodoc
const IID_IWwwFormUrlDecoderRuntimeClass =
    '{d45a0451-f225-4542-9296-0e1df5d254df}';

/// {@category Interface}
/// {@category winrt}
class IWwwFormUrlDecoderRuntimeClass extends IInspectable
    implements
        IIterable<IWwwFormUrlDecoderEntry>,
        IVectorView<IWwwFormUrlDecoderEntry> {
  // vtable begins at 6, is 1 entries long.
  IWwwFormUrlDecoderRuntimeClass.fromRawPointer(super.ptr);

  factory IWwwFormUrlDecoderRuntimeClass.from(IInspectable interface) =>
      IWwwFormUrlDecoderRuntimeClass.fromRawPointer(
          interface.toInterface(IID_IWwwFormUrlDecoderRuntimeClass));

  String getFirstValueByName(String name) {
    final retValuePtr = calloc<HSTRING>();
    final nameHstring = convertToHString(name);

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr name, Pointer<IntPtr>)>>>()
              .value
              .asFunction<int Function(Pointer, int name, Pointer<IntPtr>)>()(
          ptr.ref.lpVtbl, nameHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  // IVectorView<IWwwFormUrlDecoderEntry> methods
  late final _iVectorView = IVectorView<IWwwFormUrlDecoderEntry>.fromRawPointer(
      toInterface('{b1f00d3b-1f06-5117-93ea-2a0d79116701}'),
      creator: IWwwFormUrlDecoderEntry.fromRawPointer,
      iterableIid: '{876be83b-7218-5bfb-a169-83152ef7e146}');

  @override
  IWwwFormUrlDecoderEntry getAt(int index) => _iVectorView.getAt(index);

  @override
  int get size => _iVectorView.size;

  @override
  bool indexOf(IWwwFormUrlDecoderEntry value, Pointer<Uint32> index) =>
      _iVectorView.indexOf(value, index);

  @override
  int getMany(int startIndex, int valueSize, Pointer<NativeType> value) =>
      _iVectorView.getMany(startIndex, valueSize, value);

  @override
  IIterator<IWwwFormUrlDecoderEntry> first() => _iVectorView.first();

  @override
  List<IWwwFormUrlDecoderEntry> toList() => _iVectorView.toList();
}
