import 'dart:typed_data';
import '../../image.dart';
import '../internal/bit_operators.dart';

enum ExifValueType {
  None,
  Byte,
  Ascii,
  Short,
  Long,
  Rational,
  SByte,
  Undefined,
  SShort,
  SLong,
  SRational,
  Single,
  Double
}

const ExifValueTypeString = [
  'None',
  'Byte',
  'Ascii',
  'Short',
  'Long',
  'Rational',
  'SByte',
  'Undefined',
  'SShort',
  'SLong',
  'SRational',
  'Single',
  'Double'
];

const ExifValueTypeSize = [
  0,
  1,
  1,
  2,
  4,
  8,
  1,
  1,
  2,
  4,
  8,
  4,
  8
];

class Rational {
  int numerator;
  int denominator;
  Rational(this.numerator, this.denominator);

  void simplify() {
    final d = numerator.gcd(denominator);
    if (d != 0) {
      numerator ~/= d;
      denominator ~/= d;
    }
  }

  int toInt() => denominator == 0 ? 0 : numerator ~/ denominator;
  double toDouble() => denominator == 0 ? 0.0 : numerator / denominator;

  bool operator ==(Object other) =>
      other is Rational &&
      numerator == other.numerator && denominator == other.denominator;

  int get hashCode => Object.hash(numerator, denominator);

  String toString() => '$numerator/$denominator';
}

abstract class ExifValue {
  ExifValue clone();

  ExifValueType get type;
  int get length;

  int get dataSize => ExifValueTypeSize[type.index] * length;

  String get typeString => ExifValueTypeString[type.index];

  bool toBool([int index = 0]) => false;
  int toInt([int index = 0]) => 0;
  double toDouble([int index = 0]) => 0.0;
  Uint8List toData() => Uint8List(0);
  String toString() => "";
  Rational toRational([int index = 0]) => Rational(0, 1);

  bool operator ==(Object other) =>
      other is ExifValue &&
      type == other.type &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => 0;

  void write(OutputBuffer out);

  void setBool(bool v, [int index = 0]) {}
  void setInt(int v, [int index = 0]) {}
  void setDouble(double v, [int index = 0]) {}
  void setRational(int numerator, int denomitator, [int index = 0]) {}
  void setString(String v) {}
}

class ExifByteValue extends ExifValue {
  Uint8List value;

  ExifByteValue(int value)
      : value = Uint8List(1) {
    this.value[0] = value;
  }

  ExifByteValue.list(Uint8List value)
    : value = Uint8List.fromList(value);

  ExifByteValue.data(InputBuffer data, int count)
      : value = Uint8List.fromList(data.toUint8List());

  ExifValue clone() => ExifByteValue.list(value);
  ExifValueType get type => ExifValueType.Byte;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifByteValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  int toInt([int index = 0]) => value[index];
  void setInt(int v, [int index = 0]) { value[index] = v; }

  Uint8List toData() => value;

  void write(OutputBuffer out) {
    out.writeBytes(value);
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifAsciiValue extends ExifValue {
  String value;

  ExifAsciiValue(this.value);

  ExifAsciiValue.list(List<int> value)
      : value = String.fromCharCodes(value);

  ExifAsciiValue.data(InputBuffer data, int count)
      : value = count == 0 ? data.readString() : data.readString(count - 1);

  ExifAsciiValue.string(this.value);

  ExifValue clone() => ExifAsciiValue.string(value);
  ExifValueType get type => ExifValueType.Ascii;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifAsciiValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => value.hashCode;

  Uint8List toData() => Uint8List.fromList(value.codeUnits);

  void write(OutputBuffer out) {
    out.writeBytes(value.codeUnits);
  }

  String toString() => value;
  void setString(String v) { value = v; }
}

class ExifShortValue extends ExifValue {
  Uint16List value;

  ExifShortValue(int value)
      : value = Uint16List(1) {
    this.value[0] = value;
  }

  ExifShortValue.list(List<int> value)
      : value = Uint16List.fromList(value);

  ExifShortValue.data(InputBuffer data, int count)
      : value = Uint16List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readUint16();
    }
  }

  ExifValue clone() => ExifShortValue.list(value);
  ExifValueType get type => ExifValueType.Short;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifShortValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  int toInt([int index = 0]) => value[index];
  void setInt(int v, [int index = 0]) { value[index] = v; }

  void write(OutputBuffer out) {
    for (int i = 0, l = value.length; i < l; ++i) {
      out.writeUint16(value[i]);
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifLongValue extends ExifValue {
  Uint32List value;

  ExifLongValue(int value)
      : value = Uint32List(1) {
    this.value[0] = value;
  }

  ExifLongValue.list(List<int> value)
      : value = Uint32List.fromList(value);

  ExifLongValue.data(InputBuffer data, int count)
      : value = Uint32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readUint32();
    }
  }

  ExifValue clone() => ExifLongValue.list(value);
  ExifValueType get type => ExifValueType.Long;
  int get length => value.length;

    bool operator ==(Object other) =>
    other is ExifLongValue &&
        length == other.length &&
        hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  int toInt([int index = 0]) => value[index];
  void setInt(int v, [int index = 0]) { value[index] = v; }

  Uint8List toData() => Uint8List.view(value.buffer);

  void write(OutputBuffer out) {
    for (int i = 0, l = value.length; i < l; ++i) {
      out.writeUint32(value[i]);
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifRationalValue extends ExifValue {
  List<Rational> value;

  ExifRationalValue(int numerator, int denominator)
      : value = [Rational(numerator, denominator)];

  ExifRationalValue.from(Rational r)
      : value = [Rational(r.numerator, r.denominator)];

  ExifRationalValue.list(List<Rational> value)
      : value = List<Rational>.from(value);

  ExifRationalValue.data(InputBuffer data, int count)
    : value = List<Rational>.generate(count, (i) =>
        Rational(data.readUint32(), data.readUint32()));

  ExifValue clone() => ExifRationalValue.list(value);
  ExifValueType get type => ExifValueType.Rational;
  int get length => value.length;

  int toInt([int index = 0]) => value[index].toInt();
  double toDouble([int index = 0]) => value[index].toDouble();
  Rational toRational([int index = 0]) => value[index];

  bool operator ==(Object other) =>
      other is ExifRationalValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  void setRational(int numerator, int denomitator, [int index = 0]) {
    value[index].numerator = numerator;
    value[index].denominator = denomitator;
  }

  void write(OutputBuffer out) {
    for (var v in value) {
      out.writeUint32(v.numerator);
      out.writeUint32(v.denominator);
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifSByteValue extends ExifValue {
  Int8List value;

  ExifSByteValue(int value)
      : value = Int8List(1) {
    this.value[0] = value;
  }

  ExifSByteValue.list(List<int> value)
      : value = Int8List.fromList(value);

  ExifSByteValue.data(InputBuffer data, int count)
      : value = Int8List.fromList(Int8List.view(data.toUint8List().buffer));

  ExifValue clone() => ExifSByteValue.list(value);
  ExifValueType get type => ExifValueType.SByte;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifSByteValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  int toInt([int index = 0]) => value[index];
  void setInt(int v, [int index = 0]) { value[index] = v; }

  Uint8List toData() => Uint8List.view(value.buffer);

  void write(OutputBuffer out) {
    out.writeBytes(Uint8List.view(value.buffer));
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifSShortValue extends ExifValue {
  Int16List value;

  ExifSShortValue(int value)
      : value = Int16List(1) {
    this.value[0] = value;
  }

  ExifSShortValue.list(List<int> value)
      : value = Int16List.fromList(value);

  ExifSShortValue.data(InputBuffer data, int count)
      : value = Int16List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readInt16();
    }
  }

  ExifValue clone() => ExifSShortValue.list(value);
  ExifValueType get type => ExifValueType.SShort;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifSShortValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  int toInt([int index = 0]) => value[index];
  void setInt(int v, [int index = 0]) { value[index] = v; }

  Uint8List toData() => Uint8List.view(value.buffer);

  void write(OutputBuffer out) {
    final v = Int16List(1);
    final vb = Uint16List.view(v.buffer);
    for (int i = 0, l = value.length; i < l; ++i) {
      v[0] = value[i];
      out.writeUint16(vb[0]);
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifSLongValue extends ExifValue {
  Int32List value;

  ExifSLongValue(int value)
      : value = Int32List(1) {
    this.value[0] = value;
  }

  ExifSLongValue.list(List<int> value)
      : value = Int32List.fromList(value);

  ExifSLongValue.data(InputBuffer data, int count)
      : value = Int32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readInt32();
    }
  }

  ExifValue clone() => ExifSLongValue.list(value);
  ExifValueType get type => ExifValueType.SLong;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifSLongValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  int toInt([int index = 0]) => value[index];
  void setInt(int v, [int index = 0]) { value[index] = v; }

  Uint8List toData() => Uint8List.view(value.buffer);

  void write(OutputBuffer out) {
    for (int i = 0, l = value.length; i < l; ++i) {
      out.writeUint32(int32ToUint32(value[i]));
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifSRationalValue extends ExifValue {
  List<Rational> value;

  ExifSRationalValue(int numerator, int denominator)
      : value = [Rational(numerator, denominator)];

  ExifSRationalValue.from(Rational value)
      : value = [value];

  ExifSRationalValue.data(InputBuffer data, int count)
      : value = List<Rational>.generate(count, (i) =>
        Rational(data.readInt32(), data.readInt32()));

  ExifSRationalValue.list(List<Rational> value)
      : value = List<Rational>.from(value);

  ExifValue clone() => ExifSRationalValue.list(value);
  ExifValueType get type => ExifValueType.SRational;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifSRationalValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  int toInt([int index = 0]) => value[index].toInt();
  double toDouble([int index = 0]) => value[index].toDouble();

  void setRational(int numerator, int denomitator, [int index = 0]) {
    value[index].numerator = numerator;
    value[index].denominator = denomitator;
  }

  void write(OutputBuffer out) {
    for (var v in value) {
      out.writeUint32(int32ToUint32(v.numerator));
      out.writeUint32(int32ToUint32(v.denominator));
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifSingleValue extends ExifValue {
  Float32List value;

  ExifSingleValue(double value)
      : value = Float32List(1) {
    this.value[0] = value;
  }

  ExifSingleValue.list(List<double> value)
      : value = Float32List.fromList(value);

  ExifSingleValue.data(InputBuffer data, int count)
      : value = Float32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readFloat32();
    }
  }

  ExifValue clone() => ExifSingleValue.list(value);
  ExifValueType get type => ExifValueType.Single;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifSingleValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  Uint8List toData() => Uint8List.view(value.buffer);

  double toDouble([int index = 0]) => value[index];
  void setDouble(double v, [int index = 0]) { value[index] = v; }

  void write(OutputBuffer out) {
    for (int i = 0, l = value.length; i < l; ++i) {
      out.writeFloat32(value[i]);
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifDoubleValue extends ExifValue {
  Float64List value;

  ExifDoubleValue(double value)
      : value = Float64List(1) {
    this.value[0] = value;
  }

  ExifDoubleValue.list(List<double> value)
      : value = Float64List.fromList(value);

  ExifDoubleValue.data(InputBuffer data, int count)
      : value = Float64List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readFloat32();
    }
  }

  ExifValue clone() => ExifDoubleValue.list(value);
  ExifValueType get type => ExifValueType.Double;
  int get length => value.length;

  bool operator ==(Object other) =>
      other is ExifDoubleValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  double toDouble([int index = 0]) => value[index];
  void setDouble(double v, [int index = 0]) { value[index] = v; }

  Uint8List toData() => Uint8List.view(value.buffer);

  void write(OutputBuffer out) {
    for (int i = 0, l = value.length; i < l; ++i) {
      out.writeFloat64(value[i]);
    }
  }

  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifUndefinedValue extends ExifValue {
  Uint8List value;

  ExifUndefinedValue.list(List<int> value)
      : value = Uint8List.fromList(value);

  ExifUndefinedValue.data(InputBuffer data, int count)
      : value = Uint8List.fromList(data.toUint8List());

  ExifValue clone() => ExifUndefinedValue.list(value);
  ExifValueType get type => ExifValueType.Undefined;
  int get length => value.length;

  Uint8List toData() => value;

  bool operator ==(Object other) =>
      other is ExifUndefinedValue &&
      length == other.length &&
      hashCode == other.hashCode;

  int get hashCode => Object.hashAll(value);

  void write(OutputBuffer out) {
    out.writeBytes(value);
  }

  String toString() => '<data>';
}
