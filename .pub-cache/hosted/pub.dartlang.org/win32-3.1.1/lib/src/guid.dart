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

import 'package:ffi/ffi.dart';

// typedef struct _GUID {
//     unsigned long  Data1;
//     unsigned short Data2;
//     unsigned short Data3;
//     unsigned char  Data4[ 8 ];
// } GUID;

/// Represents a globally unique identifier (GUID).
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

  /// Print GUID in common {FDD39AD0-238F-46AF-ADB4-6C85480369C7} format
  @override
  String toString() {
    final comp1 = (Data4 & 0xFF).toRadixString(16).padLeft(2, '0') +
        ((Data4 & 0xFF00) >> 8).toRadixString(16).padLeft(2, '0');

    // This is hacky as all get-out :)
    final comp2 = ((Data4 & 0xFF0000) >> 16).toRadixString(16).padLeft(2, '0') +
        ((Data4 & 0xFF000000) >> 24).toRadixString(16).padLeft(2, '0') +
        ((Data4 & 0xFF00000000) >> 32).toRadixString(16).padLeft(2, '0') +
        ((Data4 & 0xFF0000000000) >> 40).toRadixString(16).padLeft(2, '0') +
        ((Data4 & 0xFF000000000000) >> 48).toRadixString(16).padLeft(2, '0') +
        (BigInt.from(Data4 & 0xFF00000000000000).toUnsigned(64) >> 56)
            .toRadixString(16)
            .padLeft(2, '0');

    return '{${Data1.toRadixString(16).padLeft(8, '0').toUpperCase()}-'
        '${Data2.toRadixString(16).padLeft(4, '0').toUpperCase()}-'
        '${Data3.toRadixString(16).padLeft(4, '0').toUpperCase()}-'
        '${comp1.toUpperCase()}-'
        '${comp2.toUpperCase()}}';
  }

  /// Create GUID from common {FDD39AD0-238F-46AF-ADB4-6C85480369C7} format
  void setGUID(String guidString) {
    assert(guidString.length == 38);
    Data1 = int.parse(guidString.substring(1, 9), radix: 16);
    Data2 = int.parse(guidString.substring(10, 14), radix: 16);
    Data3 = int.parse(guidString.substring(15, 19), radix: 16);

    // Final component is pushed on the stack in reverse order per x64
    // calling convention.
    final rawString = guidString.substring(35, 37) +
        guidString.substring(33, 35) +
        guidString.substring(31, 33) +
        guidString.substring(29, 31) +
        guidString.substring(27, 29) +
        guidString.substring(25, 27) +
        guidString.substring(22, 24) +
        guidString.substring(20, 22);

    // We need to split this to avoid overflowing a signed int.parse()
    Data4 = (int.parse(rawString.substring(0, 4), radix: 16) << 48) +
        int.parse(rawString.substring(4, 16), radix: 16);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GUID &&
        other.Data1 == Data1 &&
        other.Data2 == Data2 &&
        other.Data3 == Data3 &&
        other.Data4 == Data4;
  }

  @override
  int get hashCode =>
      Data1.hashCode ^ Data2.hashCode ^ Data3.hashCode ^ Data4.hashCode;
}

Pointer<GUID> GUIDFromString(String guid, {Allocator allocator = calloc}) =>
    allocator<GUID>()..ref.setGUID(guid);
