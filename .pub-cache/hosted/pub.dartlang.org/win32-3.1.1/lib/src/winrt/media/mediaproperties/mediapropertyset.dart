// mediapropertyset.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import '../../../com/iinspectable.dart';
import '../../../guid.dart';
import '../../../winrt_constants.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/collections/iiterator.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import '../../foundation/collections/imap.dart';

/// @nodoc
const IID_MediaPropertySet = '{D0204E8D-5F1D-4F95-A6E2-BE7B29830342}';

/// Represents a set of media properties.
///
/// {@category Class}
/// {@category winrt}
class MediaPropertySet extends IInspectable implements IMap<GUID, Object?> {
  MediaPropertySet() : super(ActivateClass(_className));
  MediaPropertySet.fromRawPointer(super.ptr);

  static const _className = 'Windows.Media.MediaProperties.MediaPropertySet';

  late final _iMap =
      IMap<GUID, Object?>.fromRawPointer(toInterface(IID_IMap_GUID_Object));

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<GUID, Object?>> first() => _iMap.first();

  @override
  Map<GUID, Object?> getView() => _iMap.getView();

  @override
  bool hasKey(GUID value) => _iMap.hasKey(value);

  @override
  bool insert(GUID key, Object? value) => _iMap.insert(key, value);

  @override
  Object? lookup(GUID key) => _iMap.lookup(key);

  @override
  void remove(GUID key) => _iMap.remove(key);

  @override
  int get size => _iMap.size;

  @override
  Map<GUID, Object?> toMap() => _iMap.toMap();
}
