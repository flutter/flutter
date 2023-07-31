// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../vm_service.dart';

class _ReadStream {
  final List<ByteData> _chunks;
  int _chunkIndex = 0;
  int _byteIndex = 0;

  _ReadStream(this._chunks);

  bool get atEnd => ((_byteIndex >= _chunks[_chunkIndex].lengthInBytes) &&
      (_chunkIndex + 1 >= _chunks.length));

  int readByte() {
    while (_byteIndex >= _chunks[_chunkIndex].lengthInBytes) {
      _chunkIndex++;
      _byteIndex = 0;
    }
    return _chunks[_chunkIndex].getUint8(_byteIndex++);
  }

  /// Read one ULEB128 number.
  int readUnsigned() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = readByte();
      result |= (part & 0x7F) << shift;
      if ((part & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return result;
  }

  /// Read one SLEB128 number.
  int readSigned() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = readByte();
      result |= (part & 0x7F) << shift;
      shift += 7;
      if ((part & 0x80) == 0) {
        if ((part & 0x40) != 0) {
          result |= (-1 << shift);
        }
        break;
      }
    }
    return result;
  }

  double readFloat64() {
    final bytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = readByte();
    }
    return Float64List.view(bytes.buffer)[0];
  }

  String readUtf8() {
    int len = readUnsigned();
    final bytes = Uint8List(len);
    for (int i = 0; i < len; i++) {
      bytes[i] = readByte();
    }
    return Utf8Codec(allowMalformed: true).decode(bytes);
  }

  String readLatin1() {
    int len = readUnsigned();
    final codeUnits = Uint8List(len);
    for (int i = 0; i < len; i++) {
      codeUnits[i] = readByte();
    }
    return String.fromCharCodes(codeUnits);
  }

  String readUtf16() {
    int len = readUnsigned();
    final codeUnits = Uint16List(len);
    for (int i = 0; i < len; i++) {
      codeUnits[i] = readByte() | (readByte() << 8);
    }
    return String.fromCharCodes(codeUnits);
  }
}

/// A representation of a field captured in a memory snapshot.
class HeapSnapshotField {
  /// An index into [HeapSnapshotObject.references].
  int get index => _index;

  /// The name of the field.
  String get name => _name;

  int _index = -1;
  String _name = '';

  HeapSnapshotField._read(_ReadStream reader) {
    // flags (reserved)
    reader.readUnsigned();

    _index = reader.readUnsigned();
    _name = reader.readUtf8();

    // reserved
    reader.readUtf8();
  }
}

/// A representation of a class type captured in a memory snapshot.
class HeapSnapshotClass {
  /// The class ID representing this type.
  int get classId => _classId;

  /// The simple (not qualified) name of the class.
  String get name => _name;

  /// The name of the class's library.
  String get libraryName => _libraryName;

  /// The [Uri] of the class's library.
  Uri get libraryUri => _libraryUri;

  /// The list of fields in the class.
  List<HeapSnapshotField> get fields => _fields;

  final int _classId;
  String _name = '';
  String _libraryName = '';
  late final Uri _libraryUri;
  final List<HeapSnapshotField> _fields = <HeapSnapshotField>[];

  HeapSnapshotClass._read(this._classId, _ReadStream reader) {
    // flags (reserved).
    reader.readUnsigned();

    _name = reader.readUtf8();
    _libraryName = reader.readUtf8();
    _libraryUri = Uri.parse(reader.readUtf8());

    // reserved
    reader.readUtf8();

    _populateFields(reader);
  }

  HeapSnapshotClass._root()
      : _classId = 0,
        _name = 'Root',
        _libraryName = '',
        _libraryUri = Uri();

  HeapSnapshotClass._sentinel()
      : _classId = 0,
        _name = 'Sentinel',
        _libraryName = '',
        _libraryUri = Uri();

  void _populateFields(_ReadStream reader) {
    final fieldCount = reader.readUnsigned();
    for (int i = 0; i < fieldCount; ++i) {
      _fields.add(HeapSnapshotField._read(reader));
    }
  }
}

/// A representation of an object instance captured in a memory snapshot.
class HeapSnapshotObject {
  /// The class ID representing the type of this object.
  int get classId => _classId;

  /// The class representing the type of this object.
  HeapSnapshotClass get klass {
    if (_classId <= 0) {
      return HeapSnapshotClass._sentinel();
    }
    return _graph._classes[_classId];
  }

  /// The space used by this object in bytes.
  int get shallowSize => _shallowSize;

  /// Data associated with this object.
  dynamic get data => _data;

  /// A list of indices into [HeapSnapshotGraph.objects].
  List<int> get references => _references;

  /// The identity hash code of this object.
  ///
  /// If `identityHashCode` is 0, either the snapshot did not contain the list
  /// of identity hash codes or this object cannot be compared across
  /// snapshots.
  int get identityHashCode => _identityHashCode;

  Iterable<HeapSnapshotObject> get successors sync* {
    final startSuccessorIndex = _graph._firstSuccessors[_oid];
    final limitSuccessorIndex = _graph._firstSuccessors[_oid + 1];

    for (int nextSuccessorIndex = startSuccessorIndex;
        nextSuccessorIndex < limitSuccessorIndex;
        ++nextSuccessorIndex) {
      final successorId = _graph._successors[nextSuccessorIndex];
      yield _graph.objects[successorId];
    }
  }

  final HeapSnapshotGraph _graph;
  final int _oid;
  int _classId = 0;
  int _shallowSize = -1;
  int _identityHashCode = 0;
  late final dynamic _data;
  final List<int> _references = <int>[];

  HeapSnapshotObject._sentinel(this._graph)
      : _oid = 0,
        _data = HeapSnapshotObjectNoData() {
    _graph._firstSuccessors[_oid] = _graph._eid;
  }

  HeapSnapshotObject._read(this._graph, this._oid, _ReadStream reader) {
    _classId = reader.readUnsigned();
    _shallowSize = reader.readUnsigned();
    _data = _getNonReferenceData(reader);
    _graph._firstSuccessors[_oid] = _graph._eid;
    _populateReferences(reader);
  }

  void _populateReferences(_ReadStream reader) {
    final referencesCount = reader.readUnsigned();
    for (int i = 0; i < referencesCount; ++i) {
      int childOid = reader.readUnsigned();
      _references.add(childOid);
      _graph._successors[_graph._eid] = childOid;
      _graph._eid++;
    }
  }
}

/// A representation of an external property captured in a memory snapshot.
class HeapSnapshotExternalProperty {
  /// An index into [HeapSnapshotGraph.objects].
  final int object;

  /// The amount of external memory used.
  final int externalSize;

  /// The name of the external property.
  final String name;

  HeapSnapshotExternalProperty._read(_ReadStream reader)
      : object = reader.readUnsigned(),
        externalSize = reader.readUnsigned(),
        name = reader.readUtf8();
}

/// A graph representation of a heap snapshot.
class HeapSnapshotGraph {
  /// The name of the isolate represented by this heap snapshot.
  String get name => _name;

  int get flags => _flags;

  /// The sum of shallow sizes of all objects in this graph in bytes.
  int get shallowSize => _shallowSize;

  /// The amount of memory reserved for this heap in bytes.
  ///
  /// At least as large as [shallowSize].
  int get capacity => _capacity;

  /// The sum of sizes of all external properties in this graph in bytes.
  int get externalSize => _externalSize;

  /// The list of classes found in this snapshot.
  List<HeapSnapshotClass> get classes => _classes;

  /// At least as big as the sum of all [HeapSnapshotObject.referenceCount].
  int get referenceCount => _referenceCount;

  /// The list of objects found in this snapshot.
  List<HeapSnapshotObject> get objects => _objects;

  /// The list of external properties found in this snapshot.
  List<HeapSnapshotExternalProperty> get externalProperties =>
      _externalProperties;

  String _name = '';
  int _flags = -1;
  int _shallowSize = -1;
  int _capacity = -1;
  int _externalSize = -1;
  final List<HeapSnapshotClass> _classes = <HeapSnapshotClass>[];
  int _referenceCount = -1;
  final List<HeapSnapshotObject> _objects = <HeapSnapshotObject>[];
  final List<HeapSnapshotExternalProperty> _externalProperties =
      <HeapSnapshotExternalProperty>[];

  late Uint32List _firstSuccessors;
  late Uint32List _successors;
  int _eid = 0;

  /// Requests a heap snapshot for a given isolate and builds a
  /// [HeapSnapshotGraph].
  ///
  /// Note: this method calls [VmService.streamListen] and
  /// [VmService.streamCancel] on [EventStreams.kHeapSnapshot].
  static Future<HeapSnapshotGraph> getSnapshot(
      VmService service, IsolateRef isolate) async {
    await service.streamListen(EventStreams.kHeapSnapshot);

    final completer = Completer<HeapSnapshotGraph>();
    final chunks = <ByteData>[];
    late StreamSubscription streamSubscription;
    streamSubscription = service.onHeapSnapshotEvent.listen((e) async {
      chunks.add(e.data!);
      if (e.last!) {
        await service.streamCancel(EventStreams.kHeapSnapshot);
        await streamSubscription.cancel();
        completer.complete(HeapSnapshotGraph.fromChunks(chunks));
      }
    });

    await service.requestHeapSnapshot(isolate.id!);
    return completer.future;
  }

  /// Populates the [HeapSnapshotGraph] by parsing the events from the
  /// `HeapSnapshot` stream.
  HeapSnapshotGraph.fromChunks(List<ByteData> chunks) {
    final reader = _ReadStream(chunks);

    // Skip magic header
    for (int i = 0; i < 8; ++i) {
      reader.readByte();
    }

    _flags = reader.readUnsigned();
    _name = reader.readUtf8();
    _shallowSize = reader.readUnsigned();
    _capacity = reader.readUnsigned();
    _externalSize = reader.readUnsigned();
    _populateClasses(reader);
    _populateObjects(reader);
    _populateExternalProperties(reader);
    _populateIdentityHashCodes(reader);
  }

  void _populateClasses(_ReadStream reader) {
    final classCount = reader.readUnsigned();
    _classes.add(HeapSnapshotClass._root());
    for (int i = 1; i <= classCount; ++i) {
      final klass = HeapSnapshotClass._read(i, reader);
      _classes.add(klass);
    }
  }

  void _populateObjects(_ReadStream reader) {
    _referenceCount = reader.readUnsigned();
    final objectCount = reader.readUnsigned();
    _firstSuccessors = _newUint32Array(objectCount + 2);
    _successors = _newUint32Array(_referenceCount);

    _objects.add(HeapSnapshotObject._sentinel(this));
    for (int i = 1; i <= objectCount; ++i) {
      _objects.add(HeapSnapshotObject._read(this, i, reader));
    }
    _firstSuccessors[objectCount + 1] = _eid;
  }

  void _populateExternalProperties(_ReadStream reader) {
    final propertiesCount = reader.readUnsigned();
    for (int i = 0; i < propertiesCount; ++i) {
      _externalProperties.add(HeapSnapshotExternalProperty._read(reader));
    }
  }

  void _populateIdentityHashCodes(_ReadStream reader) {
    if (reader.atEnd) {
      // Older VMs don't include identity hash codes.
      return;
    }
    final objectCount = _objects.length;
    for (int i = 1; i < objectCount; ++i) {
      _objects[i]._identityHashCode = reader.readUnsigned();
    }
  }

  Uint32List _newUint32Array(int size) {
    try {
      return Uint32List(size);
    } on ArgumentError {
      // JS throws a misleading invalid argument error. Convert to a more
      // user-friendly message.
      throw Exception(
        'OutOfMemoryError: Not enough memory available to analyze the snapshot.',
      );
    }
  }
}

const _kNoData = 0;
const _kNullData = 1;
const _kBoolData = 2;
const _kIntData = 3;
const _kDoubleData = 4;
const _kLatin1Data = 5;
const _kUtf16Data = 6;
const _kLengthData = 7;
const _kNameData = 8;

dynamic _getNonReferenceData(_ReadStream reader) {
  final tag = reader.readUnsigned();
  switch (tag) {
    case _kNoData:
      return const HeapSnapshotObjectNoData();
    case _kNullData:
      return const HeapSnapshotObjectNullData();
    case _kBoolData:
      return (reader.readByte() == 1);
    case _kIntData:
      return reader.readUnsigned();
    case _kDoubleData:
      return reader.readFloat64();
    case _kLatin1Data:
      final len = reader.readUnsigned();
      final str = reader.readLatin1();
      return (str.length < len) ? '$str...' : str;
    case _kUtf16Data:
      final len = reader.readUnsigned();
      final str = reader.readUtf16();
      return (str.length < len) ? '$str...' : str;
    case _kLengthData:
      return HeapSnapshotObjectLengthData(reader.readUnsigned());
    case _kNameData:
      return reader.readUtf8();
    default:
      throw 'Invalid tag: $tag';
  }
}

/// Represents that no data is associated with an object.
class HeapSnapshotObjectNoData {
  const HeapSnapshotObjectNoData();
}

/// Represents that the data associated with an object is null.
class HeapSnapshotObjectNullData {
  const HeapSnapshotObjectNullData();
}

/// Represents the length of an object.
class HeapSnapshotObjectLengthData {
  final int length;
  HeapSnapshotObjectLengthData(this.length);
}
