import 'package:hive/hive.dart';

/// Not part of public API
class Frame {
  /// Not part of public API
  final dynamic key;

  /// Not part of public API
  final dynamic value;

  /// Not part of public API
  final bool deleted;

  /// Not part of public API
  final bool lazy;

  /// Not part of public API
  int? length;

  /// Not part of public API
  int offset = -1;

  /// Not part of public API
  Frame(this.key, this.value, {this.length, this.offset = -1})
      : lazy = false,
        deleted = false {
    assert(assertKey(key));
  }

  /// Not part of public API
  Frame.deleted(this.key, {this.length})
      : value = null,
        lazy = false,
        deleted = true,
        offset = -1 {
    assert(assertKey(key));
  }

  /// Not part of public API
  Frame.lazy(this.key, {this.length, this.offset = -1})
      : value = null,
        lazy = true,
        deleted = false {
    assert(assertKey(key));
  }

  /// Not part of public API
  static bool assertKey(dynamic key) {
    if (key is int) {
      if (key < 0 || key > 0xFFFFFFFF) {
        throw HiveError('Integer keys need to be in the range 0 - 0xFFFFFFFF');
      }
    } else if (key is String) {
      if (key.length > 0xFF) {
        throw HiveError('String keys need to be a max length of 255');
      }
    } else {
      throw HiveError('Keys need to be Strings or integers');
    }

    return true;
  }

  /// Not part of public API
  Frame toLazy() {
    if (deleted) return this;
    return Frame.lazy(
      key,
      length: length,
      offset: offset,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is Frame) {
      return key == other.key &&
          value == other.value &&
          length == other.length &&
          deleted == other.deleted;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    if (deleted) {
      return 'Frame.deleted(key: $key, length: $length)';
    } else if (lazy) {
      return 'Frame.lazy(key: $key, length: $length, offset: $offset)';
    } else {
      return 'Frame(key: $key, value: $value, '
          'length: $length, offset: $offset)';
    }
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      key.hashCode ^
      value.hashCode ^
      length.hashCode ^
      deleted.hashCode;
}

/// Possible Key types
class FrameKeyType {
  /// Integer key
  static const uintT = 0;

  /// String key
  static const utf8StringT = 1;
}

/// Possible value types
class FrameValueType {
  /// null
  static const nullT = 0;

  /// int
  static const intT = 1;

  /// double
  static const doubleT = 2;

  /// bool
  static const boolT = 3;

  /// String
  static const stringT = 4;

  /// Uint8List
  static const byteListT = 5;

  /// List<int>
  static const intListT = 6;

  /// List<double>
  static const doubleListT = 7;

  /// List<bool>
  static const boolListT = 8;

  /// List<String>
  static const stringListT = 9;

  /// List<dynamic>
  static const listT = 10;

  /// Map<dynamic, dynamic>
  static const mapT = 11;

  /// List<HiveObject>
  static const hiveListT = 12;
}
