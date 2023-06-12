// guid.dart

// GUID (Globally Unique Identifier).

// Struct representing the GUID type. GUID is not represented in the Win32
// metadata, which instead points at the .NET System.Guid. So we have to project
// this manually.

// For reference, the MIT-licensed implementation used in .NET can be found here:
// https://github.com/dotnet/runtime/blob/main/src/libraries/System.Private.CoreLib/src/System/Guid.cs

// The GUID structure as used in Win32 is documented here:
// https://docs.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid

// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'win32/ole32.g.dart';

/// Represents an immutable GUID (globally unique identifier).
///
/// To pass a GUID to a Windows API, use the [toNativeGUID] method to create a
/// copy in unmanaged memory.
class Guid {
  // A GUID is a 128-bit unique value.
  final UnmodifiableUint8ListView bytes;

  const Guid(this.bytes) : assert(bytes.length == 16);

  /// Creates a Guid from four integer components.
  ///
  /// The first component should be a 32-bit value, the second and third
  /// components should be 16-bit values, and the fourth component should be a
  /// 64-bit value.
  factory Guid.fromComponents(int data1, int data2, int data3, int data4) {
    assert(data1 <= 0xFFFFFFFF);
    assert(data2 <= 0xFFFF);
    assert(data3 <= 0xFFFF);

    final guid = Uint8List(16);
    guid.buffer.asUint32List(0)[0] = data1;
    guid.buffer.asUint16List(4)[0] = data2;
    guid.buffer.asUint16List(6)[0] = data3;
    guid.buffer.asUint64List(8)[0] = data4;

    return Guid(UnmodifiableUint8ListView(guid));
  }

  /// Creates a 'nil' GUID (i.e. {00000000-0000-0000-0000-000000000000})
  factory Guid.zero() => Guid(UnmodifiableUint8ListView(Uint8List(16)));

  /// Creates a new GUID.
  factory Guid.generate() {
    final pGuid = calloc<GUID>();
    try {
      CoCreateGuid(pGuid);
      return pGuid.toDartGuid();
    } finally {
      calloc.free(pGuid);
    }
  }

  /// Creates a new GUID from a string.
  ///
  /// The string must be of the form `{dddddddd-dddd-dddd-dddd-dddddddddddd}`.
  /// where d is a hex digit.
  factory Guid.parse(String guid) {
    // This is a debug assert, becuase it's probably computationally expensive,
    // and int.parse will throw a FormatException anyway if it can't parse the
    // values.
    assert(RegExp(r'\{[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}}')
        .hasMatch(guid));

    if (guid.length != 38) {
      throw FormatException('GUID is not the correct length', guid);
    }

    // Note that the order of bytes in the returned byte array is different from
    // the string representation of a GUID value. The order of the beginning
    // four-byte group and the next two two-byte groups are reversed; the order
    // of the final two-byte group and the closing six-byte group are the same.
    //
    // The following zero-indexed list provides the offset for each 8-bit hex
    // value in the string representation.
    const offsets = [
      7, 5, 3, 1, 12, 10, 17, 15, //
      20, 22, 25, 27, 29, 31, 33, 35
    ];

    final guidAsBytes = offsets
        .map((idx) => int.parse(guid.substring(idx, idx + 2), radix: 16))
        .toList(growable: false);

    return Guid(UnmodifiableUint8ListView(Uint8List.fromList(guidAsBytes)));
  }

  /// Copy the GUID to unmanaged memory and return a pointer to the memory
  /// location.
  ///
  /// It is the caller's responsibility to free the memory at the pointer
  /// location, for example by calling [calloc.free].
  Pointer<GUID> toNativeGUID({Allocator allocator = malloc}) {
    final pGUID = allocator<Uint8>(16);

    for (var i = 0; i < 16; i++) {
      pGUID[i] = bytes[i];
    }
    return pGUID.cast<GUID>();
  }

  @override
  String toString() {
    // Note that the order of bytes in the returned string is different from the
    // internal byte representation of a GUID value. The order of the beginning
    // four-byte group and the next two two-byte groups are reversed; the order
    // of the final two-byte group and the closing six-byte group are the same.
    //
    // The following zero-indexed list provides the offset for each 8-bit hex
    // value within the 16-byte array.
    const offsets = [3, 2, 1, 0, 5, 4, 7, 6, 8, 9, 10, 11, 12, 13, 14, 15];

    final guidAsHexValues =
        offsets.map((idx) => bytes[idx].toRadixString(16).padLeft(2, '0'));

    final formattedString = guidAsHexValues.join('');
    final part1 = formattedString.substring(0, 8);
    final part2 = formattedString.substring(8, 12);
    final part3 = formattedString.substring(12, 16);
    final part4 = formattedString.substring(16, 20);
    final part5 = formattedString.substring(20);

    return '{$part1-$part2-$part3-$part4-$part5}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Guid) return false;

    for (var i = 0; i < 16; i++) {
      if (this.bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  // toString()'s hashCode is used instead of bytes' because the bytes' hashCode
  // does not work while using Guid as a key in maps.
  @override
  int get hashCode => toString().hashCode;
}

// typedef struct _GUID {
//     unsigned long  Data1;
//     unsigned short Data2;
//     unsigned short Data3;
//     unsigned char  Data4[ 8 ];
// } GUID;

/// Represents a native globally unique identifier (GUID).
///
/// {@category Struct}
@Packed(4)
class GUID extends Struct {
  @Uint32()
  external int Data1;
  @Uint16()
  external int Data2;
  @Uint16()
  external int Data3;
  @Uint64()
  external int Data4;

  /// Print GUID in common {fdd39ad0-238f-46af-adb4-6c85480369c7} format
  @override
  String toString() =>
      Guid.fromComponents(Data1, Data2, Data3, Data4).toString();

  /// Create GUID from common {FDD39AD0-238F-46AF-ADB4-6C85480369C7} format
  void setGUID(String guidString) {
    final byteBuffer = Guid.parse(guidString).bytes.buffer;
    Data1 = byteBuffer.asUint32List(0).first;
    Data2 = byteBuffer.asUint16List(4).first;
    Data3 = byteBuffer.asUint16List(6).first;
    Data4 = byteBuffer.asUint64List(8).first;
  }
}

extension PointerGUIDExtension on Pointer<GUID> {
  /// Converts this native GUID to a Dart [Guid].
  Guid toDartGuid() =>
      Guid.fromComponents(ref.Data1, ref.Data2, ref.Data3, ref.Data4);
}

Pointer<GUID> GUIDFromString(String guid, {Allocator allocator = calloc}) =>
    Guid.parse(guid).toNativeGUID(allocator: allocator);
