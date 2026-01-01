// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_boxed_int';
import 'dart:_error_utils';
import 'dart:_internal' show EfficientLengthIterable, patch, unsafeCast;
import 'dart:_js_helper' as js;
import 'dart:_typed_data';
import 'dart:_js_types';
import 'dart:_list';
import 'dart:_string';
import 'dart:_wasm';
import 'dart:js_interop';
import 'dart:typed_data';

@pragma('wasm:initialize-at-startup')
const int _stringFromCharCodesSize = 512;
final _stringFromCharCodes = WasmArray<WasmI16>(_stringFromCharCodesSize);

@patch
class String {
  @patch
  factory String.fromCharCodes(
    Iterable<int> charCodes, [
    int start = 0,
    int? end,
  ]) {
    RangeError.checkNotNegative(start, "start");
    if (end != null && end < start) {
      throw RangeError.range(end, start, null, "end");
    }
    if (charCodes is U8List) {
      return _fromU8ListCharCodes(charCodes, start, end);
    }
    if (charCodes is Uint8List) {
      return _fromUint8ListCharCodes(charCodes, start, end);
    }
    if (charCodes is U16List) {
      return _fromU16ListCharCodes(charCodes, start, end);
    }
    if (charCodes is WasmListBase) {
      final result = _fromWasmListBaseCharCodes(
        unsafeCast<WasmListBase<int>>(charCodes),
        start,
        end,
      );
      if (result != null) return result;
    }
    return _fromIterableCharCodes(charCodes, start, end);
  }

  static String _fromU8ListCharCodes(
    U8List charCodes,
    int start,
    int? optionalEnd,
  ) {
    final length = charCodes.length;
    int end = optionalEnd != null
        ? (optionalEnd < length ? optionalEnd : length)
        : length;
    if (end <= start) return '';
    final count = end - start;

    final int offset = charCodes.offsetInElements;
    start += offset;
    end += offset;

    final src = charCodes.data;
    final dst = count < _stringFromCharCodesSize
        ? _stringFromCharCodes
        : WasmArray<WasmI16>(count);
    for (int i = 0; i < count; ++i) {
      dst.write(i, src.readUnsigned(start + i));
    }
    return JSStringImpl.fromRefUnchecked(
      jsStringFromCharCodeArray(dst, 0.toWasmI32(), count.toWasmI32()),
    );
  }

  static String _fromUint8ListCharCodes(
    Uint8List charCodes,
    int start,
    int? optionalEnd,
  ) {
    final length = charCodes.length;
    final int end = optionalEnd != null
        ? (optionalEnd < length ? optionalEnd : length)
        : length;
    if (end <= start) return '';
    final count = end - start;

    final dst = count < _stringFromCharCodesSize
        ? _stringFromCharCodes
        : WasmArray<WasmI16>(count);
    for (int i = 0; i < count; ++i) {
      dst.write(i, charCodes[start + i]);
    }
    return JSStringImpl.fromRefUnchecked(
      jsStringFromCharCodeArray(dst, 0.toWasmI32(), count.toWasmI32()),
    );
  }

  static String _fromU16ListCharCodes(
    U16List charCodes,
    int start,
    int? optionalEnd,
  ) {
    final length = charCodes.length;
    int end = optionalEnd != null
        ? (optionalEnd < length ? optionalEnd : length)
        : length;
    if (end <= start) return '';
    final count = end - start;

    final int offset = charCodes.offsetInElements;
    start += offset;
    end += offset;

    final data = charCodes.data;
    return JSStringImpl.fromRefUnchecked(
      jsStringFromCharCodeArray(data, start.toWasmI32(), end.toWasmI32()),
    );
  }

  static String? _fromWasmListBaseCharCodes(
    WasmListBase<int> charCodes,
    int start,
    int? optionalEnd,
  ) {
    final length = charCodes.length;
    final int end = optionalEnd != null
        ? (optionalEnd < length ? optionalEnd : length)
        : length;
    if (end <= start) return '';
    final count = end - start;

    final src = charCodes.data;
    final dst = count < _stringFromCharCodesSize
        ? _stringFromCharCodes
        : WasmArray<WasmI16>(count);
    for (int i = 0; i < count; ++i) {
      final charCode = unsafeCast<BoxedInt>(src[start + i]);
      if (charCode.gtU(0xffff)) {
        return null; // fall back to general case.
      }
      dst.write(i, charCode);
    }
    return JSStringImpl.fromRefUnchecked(
      jsStringFromCharCodeArray(dst, 0.toWasmI32(), count.toWasmI32()),
    );
  }

  static String _fromIterableCharCodes(
    Iterable<int> charCodes,
    int start,
    int? end,
  ) {
    RangeError.checkNotNegative(start, "start");
    if (end != null) {
      if (end < start) {
        throw RangeError.range(end, start, null, "end");
      }
      if (end == start) return "";
    }

    final length = charCodes.length;

    // Skip until `start`.
    final it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      it.moveNext();
    }

    // The part of the iterable converted to string is collected in a JS typed
    // array, to be able to effciently get subarrays, to pass to
    // `String.fromCharCode.apply`.
    final charCodesLength = (end ?? length) - start;
    if (charCodesLength <= 0) return "";
    final typedArrayLength = charCodesLength * 2;
    final WasmArray<WasmI16> list = WasmArray(typedArrayLength);
    int index = 0; // index in `list`.
    end ??= start + charCodesLength;
    for (int i = start; i < end; i++) {
      if (!it.moveNext()) {
        break;
      }
      final charCode = it.current;
      if (charCode.leU(0xffff)) {
        list.write(index++, charCode);
      } else if (charCode.leU(0x10ffff)) {
        list.write(index++, 0xd800 + ((((charCode - 0x10000) >> 10) & 0x3ff)));
        list.write(index++, 0xdc00 + (charCode & 0x3ff));
      } else {
        throw RangeError.range(charCode, 0, 0x10ffff);
      }
    }

    return JSStringImpl.fromRefUnchecked(
      jsStringFromCharCodeArray(list, const WasmI32(0), WasmI32.fromInt(index)),
    );
  }

  @patch
  @pragma("wasm:prefer-inline")
  factory String.fromCharCode(int charCode) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(charCode, 0x10ffff);
    return JSStringImpl.fromCodePoint(charCode);
  }
}

extension _StringExt on String {
  int firstNonWhitespace() =>
      unsafeCast<JSStringImpl>(this).firstNonWhitespace();

  int lastNonWhitespace() => unsafeCast<JSStringImpl>(this).lastNonWhitespace();
}
