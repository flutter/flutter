// mediapropertyset.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../guid.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/collections/iiterable.dart';
import '../../foundation/collections/iiterator.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import '../../foundation/collections/imap.dart';
import '../../foundation/collections/imapview.dart';
import '../../internal/hstring_array.dart';

/// Represents a set of media properties.
///
/// {@category Class}
/// {@category winrt}
class MediaPropertySet extends IInspectable
    implements IMap<Guid, Object?>, IIterable<IKeyValuePair<Guid, Object?>> {
  MediaPropertySet() : super(ActivateClass(_className));
  MediaPropertySet.fromRawPointer(super.ptr);

  static const _className = 'Windows.Media.MediaProperties.MediaPropertySet';

  // IMap<Guid, Object?> methods
  late final _iMap = IMap<Guid, Object?>.fromRawPointer(
      toInterface('{5ee3189c-7dbf-5998-ad07-5414fb82567c}'),
      iterableIid: '{f3b20528-e3b3-5331-b2d0-0c2623aee785}');

  @override
  Object? lookup(Guid key) => _iMap.lookup(key);

  @override
  int get size => _iMap.size;

  @override
  bool hasKey(Guid key) => _iMap.hasKey(key);

  @override
  Map<Guid, Object?> getView() => _iMap.getView();

  @override
  bool insert(Guid key, Object? value) => _iMap.insert(key, value);

  @override
  void remove(Guid key) => _iMap.remove(key);

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<Guid, Object?>> first() => _iMap.first();

  @override
  Map<Guid, Object?> toMap() => _iMap.toMap();
}
