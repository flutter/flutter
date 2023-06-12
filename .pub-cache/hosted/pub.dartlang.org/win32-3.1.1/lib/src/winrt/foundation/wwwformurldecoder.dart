// wwwformurldecoder.dart

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../com/iinspectable.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_constants.dart';
import '../../winrt_helpers.dart';
import '../internal/hstring_array.dart';
import 'collections/iiterator.dart';
import 'collections/ivectorview.dart';
import 'iwwwformurldecoderentry.dart';
import 'iwwwformurldecoderruntimeclass.dart';
import 'iwwwformurldecoderruntimeclassfactory.dart';

/// {@category Class}
/// {@category winrt}
class WwwFormUrlDecoder extends IInspectable
    implements
        IWwwFormUrlDecoderRuntimeClass,
        IVectorView<IWwwFormUrlDecoderEntry> {
  WwwFormUrlDecoder.fromRawPointer(super.ptr);

  static const _className = 'Windows.Foundation.WwwFormUrlDecoder';

  // IWwwFormUrlDecoderRuntimeClassFactory methods
  static WwwFormUrlDecoder createWwwFormUrlDecoder(String query) {
    final activationFactory = CreateActivationFactory(
        _className, IID_IWwwFormUrlDecoderRuntimeClassFactory);

    try {
      return IWwwFormUrlDecoderRuntimeClassFactory.fromRawPointer(
              activationFactory)
          .createWwwFormUrlDecoder(query);
    } finally {
      free(activationFactory);
    }
  }

  // IWwwFormUrlDecoderRuntimeClass methods
  late final _iWwwFormUrlDecoderRuntimeClass =
      IWwwFormUrlDecoderRuntimeClass.from(this);

  @override
  String getFirstValueByName(String name) =>
      _iWwwFormUrlDecoderRuntimeClass.getFirstValueByName(name);

  // IVectorView<IWwwFormUrlDecoderEntry> methods
  late final _iVectorView = IVectorView.fromRawPointer(
      toInterface(IID_IVectorView_IWwwFormUrlDecoderEntry),
      creator: IWwwFormUrlDecoderEntry.fromRawPointer);

  @override
  IIterator<IWwwFormUrlDecoderEntry> first() => _iVectorView.first();

  @override
  IWwwFormUrlDecoderEntry getAt(int index) => _iVectorView.getAt(index);

  @override
  int getMany(int startIndex, int capacity, Pointer<NativeType> value) =>
      _iVectorView.getMany(startIndex, capacity, value);

  @override
  bool indexOf(IWwwFormUrlDecoderEntry value, Pointer<Uint32> index) =>
      _iVectorView.indexOf(value, index);

  @override
  int get size => _iVectorView.size;

  @override
  List<IWwwFormUrlDecoderEntry> toList() => _iVectorView.toList();
}
