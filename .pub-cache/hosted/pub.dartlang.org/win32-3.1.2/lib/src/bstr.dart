// A wrapper for BSTR string types.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'win32/oleaut32.g.dart';

/// A string data type that is commonly used by OLE Automation, as well as some
/// COM methods.
///
/// `BSTR` types differ from `Pointer<Utf16>` in that they include a four byte
/// prefix stored immediately prior to the string itself that represents its
/// length in bytes. The pointer points to the first character of the data
/// string, not to the length prefix.
///
/// `BSTR`s should never be created using Dart's memory allocation functions.
/// For instance, the following code is incorrect, since it does not allocate
/// and store the length prefix.
///
/// ```dart
/// final bstr = 'I am a happy BSTR'.toNativeUtf16();
/// ```
///
/// This class wraps the COM memory allocation functions so that `BSTR` types
/// can be created without concern. Instead of the above code, you can write:
///
/// ```dart
/// final bstr = BSTR.fromString('I am a happy BSTR');
/// ```
///
/// A debugger that examines the four bytes prior to this location will see a
/// 32-bit int containing the value 34, representing the length of the string in
/// Utf-16.
///
/// Dart does not garbage collect `BSTR` objects; instead, you are responsible
/// for freeing the memory allocated for a `BSTR` when it is no longer used. To
/// release its memory, you can call an object's [free] method.
class BSTR {
  /// A pointer to the start of the string itself.
  ///
  /// The string is null terminated with a two-byte value (0x0000).
  final Pointer<Utf16> ptr;

  const BSTR._(this.ptr);

  /// Create a BSTR from a given Dart string.
  ///
  /// This allocates native memory for the BSTR; it can be released with [free].
  factory BSTR.fromString(String str) {
    final pStr = str.toNativeUtf16();
    final pbstr = SysAllocString(pStr);
    calloc.free(pStr);
    return BSTR._(pbstr);
  }

  /// Returns the length in characters.
  int get length => SysStringLen(ptr);

  /// Returns the length in bytes.
  int get byteLength => SysStringByteLen(ptr);

  /// Releases the native memory allocated to the BSTR.
  void free() => SysFreeString(ptr);

  /// Concatenate two BSTR objects and returns a newly-allocated object with
  /// the results.
  BSTR operator +(BSTR other) {
    final pbstrResult = calloc<Pointer<Utf16>>();
    VarBstrCat(ptr, other.ptr, pbstrResult.cast());
    final result = BSTR._(pbstrResult.value);
    calloc.free(pbstrResult);
    return result;
  }

  /// Allocates a new string that is a copy of the existing string.
  BSTR clone() => BSTR._(SysAllocString(ptr));

  /// Returns the contents of the BSTR as a regular Dart string.
  @override
  String toString() => ptr.toDartString();
}
