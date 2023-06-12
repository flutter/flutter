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
class MediaPropertySet extends IInspectable implements IMap<Guid, Object?> {
  MediaPropertySet() : super(ActivateClass(_className));
  MediaPropertySet.fromRawPointer(super.ptr);

  static const _className = 'Windows.Media.MediaProperties.MediaPropertySet';

  late final _iMap = IMap<Guid, Object?>.fromRawPointer(
      toInterface(IID_IMap_Guid_Object),
      iterableIid: '{f3b20528-e3b3-5331-b2d0-0c2623aee785}');

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<Guid, Object?>> first() => _iMap.first();

  @override
  Map<Guid, Object?> getView() => _iMap.getView();

  @override
  bool hasKey(Guid value) => _iMap.hasKey(value);

  @override
  bool insert(Guid key, Object? value) => _iMap.insert(key, value);

  @override
  Object? lookup(Guid key) => _iMap.lookup(key);

  @override
  void remove(Guid key) => _iMap.remove(key);

  @override
  int get size => _iMap.size;

  @override
  Map<Guid, Object?> toMap() => _iMap.toMap();
}
