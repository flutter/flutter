// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'remote_instance.dart';

/// All serialization must be done in a serialization Zone, which tells it
/// whether we are the client or server.
///
/// In [SerializationMode.server], sets up a remote instance cache to use when
/// deserializing remote instances back to their original instance.
T withSerializationMode<T>(
  SerializationMode mode,
  T Function() fn, {
  Serializer Function()? serializerFactory,
  Deserializer Function(Object? data)? deserializerFactory,
}) =>
    runZoned(fn, zoneValues: {
      #serializationMode: mode,
      if (!mode.isClient) remoteInstanceZoneKey: <int, RemoteInstance>{}
    });

/// Serializable interface
abstract class Serializable {
  /// Serializes this object using [serializer].
  void serialize(Serializer serializer);
}

/// A push based object serialization interface.
abstract class Serializer {
  /// Serializes a [String].
  void addString(String value);

  /// Serializes a nullable [String].
  void addNullableString(String? value) =>
      value == null ? addNull() : addString(value);

  /// Serializes a [double].
  void addDouble(double value);

  /// Serializes a nullable [double].
  void addNullableDouble(double? value) =>
      value == null ? addNull() : addDouble(value);

  /// Serializes an [int].
  void addInt(int value);

  /// Serializes a nullable [int].
  void addNullableInt(int? value) => value == null ? addNull() : addInt(value);

  /// Serializes a [bool].
  void addBool(bool value);

  /// Serializes a nullable [bool].
  void addNullableBool(bool? value) =>
      value == null ? addNull() : addBool(value);

  /// Serializes a `null` literal.
  void addNull();

  /// Used to signal the start of an arbitrary length list of items.
  void startList();

  /// Used to signal the end of an arbitrary length list of items.
  void endList();

  /// Returns the resulting serialized object.
  Object get result;
}

/// A pull based object deserialization interface.
///
/// You must call [moveNext] before reading any items, and in order to advance
/// to the next item.
abstract class Deserializer {
  /// Checks if the current value is a null, returns `true` if so and `false`
  /// otherwise.
  bool checkNull();

  /// Reads the current value as a non-nullable [String].
  bool expectBool();

  /// Reads the current value as a nullable [bool].
  bool? expectNullableBool() => checkNull() ? null : expectBool();

  /// Reads the current value as a non-nullable [double].
  double expectDouble();

  /// Reads the current value as a nullable [double].
  double? expectNullableDouble() => checkNull() ? null : expectDouble();

  /// Reads the current value as a non-nullable [int].
  int expectInt();

  /// Reads the current value as a nullable [int].
  int? expectNullableInt() => checkNull() ? null : expectInt();

  /// Reads the current value as a non-nullable [String].
  String expectString();

  /// Reads the current value as a nullable [String].
  String? expectNullableString() => checkNull() ? null : expectString();

  /// Asserts that the current item is the start of a list.
  ///
  /// An example for how to read from a list is as follows:
  ///
  /// var json = JsonReader.fromString(source);
  /// I know it's a list of strings.
  ///
  /// ```
  ///   var result = <String>[];
  ///   deserializer.moveNext();
  ///   deserializer.expectList();
  ///   while (json.moveNext()) {
  ///     result.add(json.expectString());
  ///   }
  ///   // Can now read later items, but need to call `moveNext` again to move
  ///   // past the list.
  ///   deserializer.moveNext();
  ///   deserializer.expectBool();
  /// ```
  void expectList();

  /// Moves to the next item, returns `false` if there are no more items to
  /// read.
  ///
  /// If inside of a list, this returns `false` when the end of the list is
  /// reached, and moves back to the parent, but does not advance it, so another
  /// call to `moveNext` is needed. See example in the [expectList] docs.
  bool moveNext();
}

class JsonSerializer implements Serializer {
  /// The full result.
  final _result = <Object?>[];

  /// A path to the current list we are modifying.
  late List<List<Object?>> _path = [_result];

  /// Returns the result as an unmodifiable [Iterable].
  ///
  /// Asserts that all [List] entries have not been closed with [endList].
  @override
  Iterable<Object?> get result {
    assert(_path.length == 1);
    return _result;
  }

  @override
  void addBool(bool value) => _path.last.add(value);
  @override
  void addNullableBool(bool? value) => _path.last.add(value);

  @override
  void addDouble(double value) => _path.last.add(value);
  @override
  void addNullableDouble(double? value) => _path.last.add(value);

  @override
  void addInt(int value) => _path.last.add(value);
  @override
  void addNullableInt(int? value) => _path.last.add(value);

  @override
  void addString(String value) => _path.last.add(value);
  @override
  void addNullableString(String? value) => _path.last.add(value);

  @override
  void addNull() => _path.last.add(null);

  @override
  void startList() {
    List<Object?> sublist = [];
    _path.last.add(sublist);
    _path.add(sublist);
  }

  @override
  void endList() {
    _path.removeLast();
  }
}

class JsonDeserializer implements Deserializer {
  /// The root source list to read from.
  final Iterable<Object?> _source;

  /// The path to the current iterator we are reading from.
  late List<Iterator<Object?>> _path = [];

  /// Whether we have received our first [moveNext] call.
  bool _initialized = false;

  /// Initialize this deserializer from `_source`.
  JsonDeserializer(this._source);

  @override
  bool checkNull() => _expectValue<Object?>() == null;

  @override
  void expectList() => _path.add(_expectValue<Iterable<Object?>>().iterator);

  @override
  bool expectBool() => _expectValue();
  @override
  bool? expectNullableBool() => _expectValue();

  @override
  double expectDouble() => _expectValue();
  @override
  double? expectNullableDouble() => _expectValue();

  @override
  int expectInt() => _expectValue();
  @override
  int? expectNullableInt() => _expectValue();

  @override
  String expectString() => _expectValue();
  @override
  String? expectNullableString() => _expectValue();

  /// Reads the current value and casts it to [T].
  T _expectValue<T>() {
    if (!_initialized) {
      throw new StateError(
          'You must call `moveNext()` before reading any values.');
    }
    return _path.last.current as T;
  }

  @override
  bool moveNext() {
    if (!_initialized) {
      _path.add(_source.iterator);
      _initialized = true;
    }

    // Move the current iterable, if its at the end of its items remove it from
    // the current path and return false.
    if (!_path.last.moveNext()) {
      _path.removeLast();
      return false;
    }

    return true;
  }
}

class ByteDataSerializer extends Serializer {
  final BytesBuilder _builder = new BytesBuilder();

  // Re-usable 8 byte list and view for encoding doubles.
  final Uint8List _eightByteList = new Uint8List(8);
  late final ByteData _eightByteListData =
      new ByteData.sublistView(_eightByteList);

  @override
  void addBool(bool value) => _builder
      .addByte(value ? DataKind.boolTrue.index : DataKind.boolFalse.index);

  @override
  void addDouble(double value) {
    _eightByteListData.setFloat64(0, value);
    _builder
      ..addByte(DataKind.float64.index)
      ..add(_eightByteList);
  }

  @override
  void addNull() => _builder.addByte(DataKind.nil.index);

  @override
  void addInt(int value) {
    if (value >= 0x0) {
      assert(DataKind.values.length < 0xff);
      if (value <= 0xff - DataKind.values.length) {
        _builder..addByte(value + DataKind.values.length);
      } else if (value <= 0xff) {
        _builder
          ..addByte(DataKind.uint8.index)
          ..addByte(value);
      } else if (value <= 0xffff) {
        _builder
          ..addByte(DataKind.uint16.index)
          ..addByte(value >> 8)
          ..addByte(value);
      } else if (value <= 0xffffffff) {
        _builder
          ..addByte(DataKind.uint32.index)
          ..addByte(value >> 24)
          ..addByte(value >> 16)
          ..addByte(value >> 8)
          ..addByte(value);
      } else {
        _builder
          ..addByte(DataKind.uint64.index)
          ..addByte(value >> 56)
          ..addByte(value >> 48)
          ..addByte(value >> 40)
          ..addByte(value >> 32)
          ..addByte(value >> 24)
          ..addByte(value >> 16)
          ..addByte(value >> 8)
          ..addByte(value);
      }
    } else {
      if (value >= -0x80) {
        _builder
          ..addByte(DataKind.int8.index)
          ..addByte(value);
      } else if (value >= -0x8000) {
        _builder
          ..addByte(DataKind.int16.index)
          ..addByte(value >> 8)
          ..addByte(value);
      } else if (value >= -0x8000000) {
        _builder
          ..addByte(DataKind.int32.index)
          ..addByte(value >> 24)
          ..addByte(value >> 16)
          ..addByte(value >> 8)
          ..addByte(value);
      } else {
        _builder
          ..addByte(DataKind.int64.index)
          ..addByte(value >> 56)
          ..addByte(value >> 48)
          ..addByte(value >> 40)
          ..addByte(value >> 32)
          ..addByte(value >> 24)
          ..addByte(value >> 16)
          ..addByte(value >> 8)
          ..addByte(value);
      }
    }
  }

  @override
  void addString(String value) {
    for (int i = 0; i < value.length; i++) {
      if (value.codeUnitAt(i) > 0xff) {
        _addTwoByteString(value);
        return;
      }
    }
    _addOneByteString(value);
  }

  void _addOneByteString(String value) {
    _builder.addByte(DataKind.oneByteString.index);
    addInt(value.length);
    for (int i = 0; i < value.length; i++) {
      _builder.addByte(value.codeUnitAt(i));
    }
  }

  void _addTwoByteString(String value) {
    _builder.addByte(DataKind.twoByteString.index);
    addInt(value.length);
    for (int i = 0; i < value.length; i++) {
      int codeUnit = value.codeUnitAt(i);
      switch (Endian.host) {
        case Endian.little:
          _builder
            ..addByte(codeUnit)
            ..addByte(codeUnit >> 8);
          break;
        case Endian.big:
          _builder
            ..addByte(codeUnit >> 8)
            ..addByte(codeUnit);
          break;
      }
    }
  }

  @override
  void startList() => _builder.addByte(DataKind.startList.index);

  @override
  void endList() => _builder.addByte(DataKind.endList.index);

  /// Used to signal the start of an arbitrary length list of map entries.
  void startMap() => _builder.addByte(DataKind.startMap.index);

  /// Used to signal the end of an arbitrary length list of map entries.
  void endMap() => _builder.addByte(DataKind.endMap.index);

  /// Serializes a [Uint8List].
  void addUint8List(Uint8List value) {
    _builder.addByte(DataKind.uint8List.index);
    addInt(value.length);
    _builder.add(value);
  }

  /// Serializes an object with arbitrary structure. It supports `bool`,
  /// `int`, `String`, `null`, `Uint8List`, `List`, `Map`.
  void addAny(Object? value) {
    if (value == null) {
      addNull();
    } else if (value is bool) {
      addBool(value);
    } else if (value is int) {
      addInt(value);
    } else if (value is String) {
      addString(value);
    } else if (value is Uint8List) {
      addUint8List(value);
    } else if (value is List) {
      startList();
      value.forEach(addAny);
      endList();
    } else if (value is Map) {
      startMap();
      for (MapEntry<Object?, Object?> entry in value.entries) {
        addAny(entry.key);
        addAny(entry.value);
      }
      endMap();
    } else {
      throw new ArgumentError('(${value.runtimeType}) $value');
    }
  }

  @override
  Uint8List get result => _builder.takeBytes();
}

class ByteDataDeserializer extends Deserializer {
  final ByteData _bytes;
  int _byteOffset = 0;
  int? _byteOffsetIncrement = 0;

  ByteDataDeserializer(this._bytes);

  /// Reads the next [DataKind] and advances [_byteOffset].
  DataKind _readKind([int offset = 0]) {
    int value = _bytes.getUint8(_byteOffset + offset);
    if (value < DataKind.values.length) {
      return DataKind.values[value];
    } else {
      return DataKind.directEncodedUint8;
    }
  }

  @override
  bool checkNull() {
    _byteOffsetIncrement = 1;
    return _readKind() == DataKind.nil;
  }

  @override
  bool expectBool() {
    DataKind kind = _readKind();
    _byteOffsetIncrement = 1;
    if (kind == DataKind.boolTrue) {
      return true;
    } else if (kind == DataKind.boolFalse) {
      return false;
    } else {
      throw new StateError('Expected a bool but found a $kind');
    }
  }

  @override
  double expectDouble() {
    DataKind kind = _readKind();
    if (kind != DataKind.float64) {
      throw new StateError('Expected a double but found a $kind');
    }
    _byteOffsetIncrement = 9;
    return _bytes.getFloat64(_byteOffset + 1);
  }

  @override
  int expectInt() => _expectInt(0);

  int _expectInt(int offset) {
    DataKind kind = _readKind(offset);
    if (kind == DataKind.directEncodedUint8) {
      _byteOffsetIncrement = offset + 1;
      return _bytes.getUint8(_byteOffset + offset) - DataKind.values.length;
    }
    offset += 1;
    int result;
    switch (kind) {
      case DataKind.int8:
        result = _bytes.getInt8(_byteOffset + offset);
        _byteOffsetIncrement = 1 + offset;
        break;
      case DataKind.int16:
        result = _bytes.getInt16(_byteOffset + offset);
        _byteOffsetIncrement = 2 + offset;
        break;
      case DataKind.int32:
        result = _bytes.getInt32(_byteOffset + offset);
        _byteOffsetIncrement = 4 + offset;
        break;
      case DataKind.int64:
        result = _bytes.getInt64(_byteOffset + offset);
        _byteOffsetIncrement = 8 + offset;
        break;
      case DataKind.uint8:
        result = _bytes.getUint8(_byteOffset + offset);
        _byteOffsetIncrement = 1 + offset;
        break;
      case DataKind.uint16:
        result = _bytes.getUint16(_byteOffset + offset);
        _byteOffsetIncrement = 2 + offset;
        break;
      case DataKind.uint32:
        result = _bytes.getUint32(_byteOffset + offset);
        _byteOffsetIncrement = 4 + offset;
        break;
      case DataKind.uint64:
        result = _bytes.getUint64(_byteOffset + offset);
        _byteOffsetIncrement = 8 + offset;
        break;
      default:
        throw new StateError('Expected an int but found a $kind');
    }
    return result;
  }

  @override
  void expectList() {
    DataKind kind = _readKind();
    if (kind != DataKind.startList) {
      throw new StateError('Expected the start to a list but found a $kind');
    }
    _byteOffsetIncrement = 1;
  }

  /// Asserts that the current item is the start of a map.
  ///
  /// An example for how to read from a map is as follows:
  ///
  /// I know it's a map of ints to strings.
  ///
  /// ```
  ///   var result = <int, String>[];
  ///   deserializer.expectMap();
  ///   while (deserializer.moveNext()) {
  ///     var key = deserializer.expectInt();
  ///     deserializer.next();
  ///     var value = deserializer.expectString();
  ///     result[key] = value;
  ///   }
  ///   // We have already called `moveNext` to move past the map.
  ///   deserializer.expectBool();
  /// ```
  void expectMap() {
    DataKind kind = _readKind();
    if (kind != DataKind.startMap) {
      throw new StateError('Expected the start to a map but found a $kind');
    }
    _byteOffsetIncrement = 1;
  }

  @override
  String expectString() {
    DataKind kind = _readKind();
    int length = _expectInt(1);
    int offset = _byteOffsetIncrement! + _byteOffset;
    if (kind == DataKind.oneByteString) {
      _byteOffsetIncrement = _byteOffsetIncrement! + length;
      return new String.fromCharCodes(
          _bytes.buffer.asUint8List(offset, length));
    } else if (kind == DataKind.twoByteString) {
      length = length * 2;
      _byteOffsetIncrement = _byteOffsetIncrement! + length;
      Uint8List bytes =
          new Uint8List.fromList(_bytes.buffer.asUint8List(offset, length));
      return new String.fromCharCodes(bytes.buffer.asUint16List());
    } else {
      throw new StateError('Expected a string but found a $kind');
    }
  }

  /// Reads the current value as [Uint8List].
  Uint8List expectUint8List() {
    _byteOffsetIncrement = 1;
    moveNext();
    int length = expectInt();
    int offset = _byteOffset + _byteOffsetIncrement!;
    _byteOffsetIncrement = _byteOffsetIncrement! + length;
    return _bytes.buffer.asUint8List(offset, length);
  }

  /// Reads the current value as an object of arbitrary structure.
  Object? expectAny() {
    const Set<DataKind> boolKinds = {
      DataKind.boolFalse,
      DataKind.boolTrue,
    };

    const Set<DataKind> intKinds = {
      DataKind.directEncodedUint8,
      DataKind.int8,
      DataKind.int16,
      DataKind.int32,
      DataKind.int64,
      DataKind.uint8,
      DataKind.uint16,
      DataKind.uint32,
      DataKind.uint64,
    };

    const Set<DataKind> stringKinds = {
      DataKind.oneByteString,
      DataKind.twoByteString,
    };

    DataKind kind = _readKind();
    if (boolKinds.contains(kind)) {
      return expectBool();
    } else if (kind == DataKind.nil) {
      checkNull();
      return null;
    } else if (intKinds.contains(kind)) {
      return expectInt();
    } else if (stringKinds.contains(kind)) {
      return expectString();
    } else if (kind == DataKind.startList) {
      List<Object?> result = [];
      expectList();
      while (moveNext()) {
        Object? element = expectAny();
        result.add(element);
      }
      return result;
    } else if (kind == DataKind.startMap) {
      Map<Object?, Object?> result = {};
      expectMap();
      while (moveNext()) {
        Object? key = expectAny();
        moveNext();
        Object? value = expectAny();
        result[key] = value;
      }
      return result;
    } else if (kind == DataKind.uint8List) {
      return expectUint8List();
    } else {
      throw new StateError('Expected: $kind');
    }
  }

  @override
  bool moveNext() {
    int? increment = _byteOffsetIncrement;
    _byteOffsetIncrement = null;
    if (increment == null) {
      throw new StateError("Can't move until consuming the current element");
    }
    _byteOffset += increment;
    if (_byteOffset >= _bytes.lengthInBytes) {
      return false;
    } else if (_readKind() == DataKind.endList ||
        _readKind() == DataKind.endMap) {
      // You don't explicitly consume list/map end markers.
      _byteOffsetIncrement = 1;
      return false;
    } else {
      return true;
    }
  }
}

enum DataKind {
  nil,
  boolTrue,
  boolFalse,
  directEncodedUint8, // Encoded in the kind byte.
  startList,
  endList,
  startMap,
  endMap,
  int8,
  int16,
  int32,
  int64,
  uint8,
  uint16,
  uint32,
  uint64,
  float64,
  oneByteString,
  twoByteString,
  uint8List,
}

/// Must be set using `withSerializationMode` before doing any serialization or
/// deserialization.
SerializationMode get serializationMode {
  SerializationMode? mode =
      Zone.current[#serializationMode] as SerializationMode?;
  if (mode == null) {
    throw new StateError('No SerializationMode set, you must do all '
        'serialization inside a call to `withSerializationMode`.');
  }
  return mode;
}

/// Returns the current deserializer factory for the zone.
Deserializer Function(Object?) get deserializerFactory {
  switch (serializationMode) {
    case SerializationMode.byteDataClient:
    case SerializationMode.byteDataServer:
      return (Object? message) => new ByteDataDeserializer(
          new ByteData.sublistView(message as Uint8List));
    case SerializationMode.jsonClient:
    case SerializationMode.jsonServer:
      return (Object? message) =>
          new JsonDeserializer(message as Iterable<Object?>);
  }
}

/// Returns the current serializer factory for the zone.
Serializer Function() get serializerFactory {
  switch (serializationMode) {
    case SerializationMode.byteDataClient:
    case SerializationMode.byteDataServer:
      return () => new ByteDataSerializer();
    case SerializationMode.jsonClient:
    case SerializationMode.jsonServer:
      return () => new JsonSerializer();
  }
}

/// Some objects are serialized differently on the client side versus the server
/// side. This indicates the different modes, as well as the format used.
enum SerializationMode {
  byteDataClient,
  byteDataServer,
  jsonServer,
  jsonClient,
}

extension SerializationModeHelpers on SerializationMode {
  bool get isClient {
    switch (this) {
      case SerializationMode.byteDataClient:
      case SerializationMode.jsonClient:
        return true;
      case SerializationMode.byteDataServer:
      case SerializationMode.jsonServer:
        return false;
    }
  }

  /// A stable string to write in code.
  String get asCode {
    switch (this) {
      case SerializationMode.byteDataClient:
        return 'SerializationMode.byteDataClient';
      case SerializationMode.byteDataServer:
        return 'SerializationMode.byteDataServer';
      case SerializationMode.jsonClient:
        return 'SerializationMode.jsonClient';
      case SerializationMode.jsonServer:
        return 'SerializationMode.jsonServer';
    }
  }
}
