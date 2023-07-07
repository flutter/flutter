import 'dart:typed_data';

import '../util/bit_utils.dart';
import '../util/input_buffer.dart';
import '../util/output_buffer.dart';
import '../util/rational.dart';

enum IfdValueType {
  none,
  byte,
  ascii,
  short,
  long,
  rational,
  sByte,
  undefined,
  sShort,
  sLong,
  sRational,
  single,
  double
}

const ifdValueTypeSize = [0, 1, 1, 2, 4, 8, 1, 1, 2, 4, 8, 4, 8];

abstract class IfdValue {
  IfdValue clone();

  IfdValueType get type;

  int get length;

  int get dataSize => ifdValueTypeSize[type.index] * length;

  String get typeString => type.name;

  bool toBool([int index = 0]) => false;

  int toInt([int index = 0]) => 0;

  double toDouble([int index = 0]) => 0.0;

  Uint8List toData() => Uint8List(0);

  @override
  String toString() => "";

  Rational toRational([int index = 0]) => Rational(0, 1);

  @override
  bool operator ==(Object other) =>
      other is IfdValue &&
      type == other.type &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => 0;

  void write(OutputBuffer out);

  void setBool(bool v, [int index = 0]) {}

  void setInt(int v, [int index = 0]) {}

  void setDouble(double v, [int index = 0]) {}

  void setRational(int numerator, int denomitator, [int index = 0]) {}

  void setString(String v) {}
}

class IfdByteValue extends IfdValue {
  Uint8List value;

  IfdByteValue(int value) : value = Uint8List(1) {
    this.value[0] = value;
  }

  IfdByteValue.list(Uint8List value) : value = Uint8List.fromList(value);

  IfdByteValue.data(InputBuffer data, int count)
      : value = Uint8List.fromList(data.readBytes(count).toUint8List());

  @override
  IfdValue clone() => IfdByteValue.list(value);

  @override
  IfdValueType get type => IfdValueType.byte;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdByteValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) {
    value[index] = v;
  }

  @override
  Uint8List toData() => value;

  @override
  void write(OutputBuffer out) {
    out.writeBytes(value);
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueAscii extends IfdValue {
  String value;

  IfdValueAscii(this.value);

  IfdValueAscii.list(List<int> value) : value = String.fromCharCodes(value);

  IfdValueAscii.data(InputBuffer data, int count)
      // The final byte is a null terminator
      : value = count == 0 ? '' : data.readString(count - 1);

  IfdValueAscii.string(this.value);

  @override
  IfdValue clone() => IfdValueAscii.string(value);

  @override
  IfdValueType get type => IfdValueType.ascii;

  @override
  int get length => value.codeUnits.length + 1;

  @override
  bool operator ==(Object other) =>
      other is IfdValueAscii &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => value.hashCode;

  @override
  Uint8List toData() => Uint8List.fromList(value.codeUnits);

  @override
  void write(OutputBuffer out) {
    final bytes = value.codeUnits;
    out
      ..writeBytes(bytes)
      ..writeByte(0);
  }

  @override
  String toString() => value;

  @override
  void setString(String v) {
    value = v;
  }
}

class IfdValueShort extends IfdValue {
  Uint16List value;

  IfdValueShort(int value) : value = Uint16List(1) {
    this.value[0] = value;
  }

  IfdValueShort.list(List<int> value) : value = Uint16List.fromList(value);

  IfdValueShort.data(InputBuffer data, int count) : value = Uint16List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readUint16();
    }
  }

  @override
  IfdValue clone() => IfdValueShort.list(value);

  @override
  IfdValueType get type => IfdValueType.short;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueShort &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) {
    value[index] = v;
  }

  @override
  Uint8List toData() => value.buffer.asUint8List();

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeUint16(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueLong extends IfdValue {
  Uint32List value;

  IfdValueLong(int value) : value = Uint32List(1) {
    this.value[0] = value;
  }

  IfdValueLong.list(List<int> value) : value = Uint32List.fromList(value);

  IfdValueLong.data(InputBuffer data, int count) : value = Uint32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readUint32();
    }
  }

  @override
  IfdValue clone() => IfdValueLong.list(value);

  @override
  IfdValueType get type => IfdValueType.long;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueLong &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];
  @override
  void setInt(int v, [int index = 0]) {
    value[index] = v;
  }

  @override
  Uint8List toData() => value.buffer.asUint8List();

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (int i = 0; i < l; ++i) {
      out.writeUint32(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueRational extends IfdValue {
  List<Rational> value;

  IfdValueRational(int numerator, int denominator)
      : value = [Rational(numerator, denominator)];

  IfdValueRational.from(Rational r)
      : value = [Rational(r.numerator, r.denominator)];

  IfdValueRational.list(List<Rational> value)
      : value = List<Rational>.from(value);

  IfdValueRational.data(InputBuffer data, int count)
      : value = List<Rational>.generate(
            count, (i) => Rational(data.readUint32(), data.readUint32()));

  @override
  IfdValue clone() => IfdValueRational.list(value);

  @override
  IfdValueType get type => IfdValueType.rational;

  @override
  int get length => value.length;

  @override
  int toInt([int index = 0]) => value[index].toInt();

  @override
  double toDouble([int index = 0]) => value[index].toDouble();

  @override
  Rational toRational([int index = 0]) => value[index];

  @override
  bool operator ==(Object other) =>
      other is IfdValueRational &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  void setRational(int numerator, int denomitator, [int index = 0]) {
    value[index].numerator = numerator;
    value[index].denominator = denomitator;
  }

  @override
  void write(OutputBuffer out) {
    for (var v in value) {
      out
        ..writeUint32(v.numerator)
        ..writeUint32(v.denominator);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueSByte extends IfdValue {
  Int8List value;

  IfdValueSByte(int value) : value = Int8List(1) {
    this.value[0] = value;
  }

  IfdValueSByte.list(List<int> value) : value = Int8List.fromList(value);

  IfdValueSByte.data(InputBuffer data, int count)
      : value = Int8List.fromList(
            Int8List.view(data.toUint8List().buffer, 0, count));

  @override
  IfdValue clone() => IfdValueSByte.list(value);

  @override
  IfdValueType get type => IfdValueType.sByte;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueSByte &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) {
    value[index] = v;
  }

  @override
  Uint8List toData() => value.buffer.asUint8List();

  @override
  void write(OutputBuffer out) {
    out.writeBytes(Uint8List.view(value.buffer));
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueSShort extends IfdValue {
  Int16List value;

  IfdValueSShort(int value) : value = Int16List(1) {
    this.value[0] = value;
  }

  IfdValueSShort.list(List<int> value) : value = Int16List.fromList(value);

  IfdValueSShort.data(InputBuffer data, int count) : value = Int16List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readInt16();
    }
  }

  @override
  IfdValue clone() => IfdValueSShort.list(value);

  @override
  IfdValueType get type => IfdValueType.sShort;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueSShort &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) {
    value[index] = v;
  }

  @override
  Uint8List toData() => value.buffer.asUint8List();

  @override
  void write(OutputBuffer out) {
    final v = Int16List(1);
    final vb = Uint16List.view(v.buffer);
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      v[0] = value[i];
      out.writeUint16(vb[0]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueSLong extends IfdValue {
  Int32List value;

  IfdValueSLong(int value) : value = Int32List(1) {
    this.value[0] = value;
  }

  IfdValueSLong.list(List<int> value) : value = Int32List.fromList(value);

  IfdValueSLong.data(InputBuffer data, int count) : value = Int32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readInt32();
    }
  }

  @override
  IfdValue clone() => IfdValueSLong.list(value);

  @override
  IfdValueType get type => IfdValueType.sLong;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueSLong &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) {
    value[index] = v;
  }

  @override
  Uint8List toData() => value.buffer.asUint8List();

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeUint32(int32ToUint32(value[i]));
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueSRational extends IfdValue {
  List<Rational> value;

  IfdValueSRational(int numerator, int denominator)
      : value = [Rational(numerator, denominator)];

  IfdValueSRational.from(Rational value) : value = [value];

  IfdValueSRational.data(InputBuffer data, int count)
      : value = List<Rational>.generate(
            count, (i) => Rational(data.readInt32(), data.readInt32()));

  IfdValueSRational.list(List<Rational> value)
      : value = List<Rational>.from(value);

  @override
  IfdValue clone() => IfdValueSRational.list(value);

  @override
  IfdValueType get type => IfdValueType.sRational;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueSRational &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index].toInt();

  @override
  double toDouble([int index = 0]) => value[index].toDouble();

  @override
  void setRational(int numerator, int denomitator, [int index = 0]) {
    value[index].numerator = numerator;
    value[index].denominator = denomitator;
  }

  @override
  void write(OutputBuffer out) {
    for (var v in value) {
      out
        ..writeUint32(int32ToUint32(v.numerator))
        ..writeUint32(int32ToUint32(v.denominator));
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueSingle extends IfdValue {
  Float32List value;

  IfdValueSingle(double value) : value = Float32List(1) {
    this.value[0] = value;
  }

  IfdValueSingle.list(List<double> value) : value = Float32List.fromList(value);

  IfdValueSingle.data(InputBuffer data, int count)
      : value = Float32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readFloat32();
    }
  }

  @override
  IfdValue clone() => IfdValueSingle.list(value);

  @override
  IfdValueType get type => IfdValueType.single;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueSingle &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  Uint8List toData() => value.buffer.asUint8List();

  @override
  double toDouble([int index = 0]) => value[index];

  @override
  void setDouble(double v, [int index = 0]) {
    value[index] = v;
  }

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeFloat32(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueDouble extends IfdValue {
  Float64List value;

  IfdValueDouble(double value) : value = Float64List(1) {
    this.value[0] = value;
  }

  IfdValueDouble.list(List<double> value) : value = Float64List.fromList(value);

  IfdValueDouble.data(InputBuffer data, int count)
      : value = Float64List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readFloat32();
    }
  }

  @override
  IfdValue clone() => IfdValueDouble.list(value);

  @override
  IfdValueType get type => IfdValueType.double;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdValueDouble &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  double toDouble([int index = 0]) => value[index];

  @override
  void setDouble(double v, [int index = 0]) {
    value[index] = v;
  }

  @override
  Uint8List toData() => value.buffer.asUint8List();

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeFloat64(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdValueUndefined extends IfdValue {
  Uint8List value;

  IfdValueUndefined.list(List<int> value) : value = Uint8List.fromList(value);

  IfdValueUndefined.data(InputBuffer data, int count)
      : value = Uint8List.fromList(data.readBytes(count).toUint8List());

  @override
  IfdValue clone() => IfdValueUndefined.list(value);

  @override
  IfdValueType get type => IfdValueType.undefined;

  @override
  int get length => value.length;

  @override
  Uint8List toData() => value;

  @override
  bool operator ==(Object other) =>
      other is IfdValueUndefined &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  void write(OutputBuffer out) {
    out.writeBytes(value);
  }

  @override
  String toString() => '<data>';
}
