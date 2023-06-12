// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class Enum1Adapter extends TypeAdapter<Enum1> {
  @override
  final int typeId = 3;

  @override
  Enum1 read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Enum1.emumValue1;
      case 1:
        return Enum1.emumValue2;
      case 2:
        return Enum1.emumValue3;
      default:
        return Enum1.emumValue2;
    }
  }

  @override
  void write(BinaryWriter writer, Enum1 obj) {
    switch (obj) {
      case Enum1.emumValue1:
        writer.writeByte(0);
        break;
      case Enum1.emumValue2:
        writer.writeByte(1);
        break;
      case Enum1.emumValue3:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enum1Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class Class1Adapter extends TypeAdapter<Class1> {
  @override
  final int typeId = 1;

  @override
  Class1 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Class1(
      fields[0] == null
          ? const Class2(4, 'param', {
              5: {
                'magic': [
                  const Class1(const Class2(5, 'sad')),
                  const Class1(const Class2(5, 'sad'), Enum1.emumValue1)
                ]
              },
              67: {
                'hold': [const Class1(const Class2(42, 'meaning of life'))]
              }
            })
          : fields[0] as Class2,
    );
  }

  @override
  void write(BinaryWriter writer, Class1 obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.nested);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Class1Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class Class2Adapter extends TypeAdapter<Class2> {
  @override
  final int typeId = 2;

  @override
  Class2 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Class2(
      fields[0] == null ? 0 : fields[0] as int,
      fields[1] as String,
      (fields[6] as Map?)?.map((dynamic k, dynamic v) => MapEntry(
          k as int,
          (v as Map).map((dynamic k, dynamic v) =>
              MapEntry(k as String, (v as List).cast<Class1>())))),
    );
  }

  @override
  void write(BinaryWriter writer, Class2 obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.param1)
      ..writeByte(1)
      ..write(obj.param2)
      ..writeByte(6)
      ..write(obj.what);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Class2Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmptyClassAdapter extends TypeAdapter<EmptyClass> {
  @override
  final int typeId = 4;

  @override
  EmptyClass read(BinaryReader reader) {
    return EmptyClass();
  }

  @override
  void write(BinaryWriter writer, EmptyClass obj) {
    writer..writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmptyClassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
