// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_js_helper' show JS;
import 'dart:_string';
import 'dart:_typed_data';
import 'dart:_wasm';
import 'dart:typed_data';

@patch
@pragma('wasm:prefer-inline')
JSStringImpl jsStringFromDartString(String s) {
  if (s is OneByteString) {
    return JSStringImpl(JS<WasmExternRef>(r'''
      (s, length) => {
        if (length == 0) return '';

        const read = dartInstance.exports.$stringRead1;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      }
      ''', jsObjectFromDartObject(s), s.length.toWasmI32()));
  }
  if (s is TwoByteString) {
    return JSStringImpl(JS<WasmExternRef>(r'''
    (s, length) => {
      if (length == 0) return '';

      const read = dartInstance.exports.$stringRead2;
      let result = '';
      let index = 0;
      const chunkLength = Math.min(length - index, 500);
      let array = new Array(chunkLength);
      while (index < length) {
        const newChunkLength = Math.min(length - index, 500);
        for (let i = 0; i < newChunkLength; i++) {
          array[i] = read(s, index++);
        }
        if (newChunkLength < chunkLength) {
          array = array.slice(0, newChunkLength);
        }
        result += String.fromCharCode(...array);
      }
      return result;
    }
    ''', jsObjectFromDartObject(s), s.length.toWasmI32()));
  }

  return unsafeCast<JSStringImpl>(s);
}

@patch
@pragma('wasm:prefer-inline')
String jsStringToDartString(JSStringImpl s) {
  final length = s.length;
  if (length == 0) return '';

  return JS<String>(r'''
    (s) => {
      let length = s.length;
      let range = 0;
      for (let i = 0; i < length; i++) {
        range |= s.codePointAt(i);
      }
      const exports = dartInstance.exports;
      if (range < 256) {
        if (length <= 10) {
          if (length == 1) {
            return exports.$stringAllocate1_1(s.codePointAt(0));
          }
          if (length == 2) {
            return exports.$stringAllocate1_2(s.codePointAt(0), s.codePointAt(1));
          }
          if (length == 3) {
            return exports.$stringAllocate1_3(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2));
          }
          if (length == 4) {
            return exports.$stringAllocate1_4(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3));
          }
          if (length == 5) {
            return exports.$stringAllocate1_5(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4));
          }
          if (length == 6) {
            return exports.$stringAllocate1_6(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5));
          }
          if (length == 7) {
            return exports.$stringAllocate1_7(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6));
          }
          if (length == 8) {
            return exports.$stringAllocate1_8(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7));
          }
          if (length == 9) {
            return exports.$stringAllocate1_9(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8));
          }
          if (length == 10) {
            return exports.$stringAllocate1_10(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8), s.codePointAt(9));
          }
        }
        const dartString = exports.$stringAllocate1(length);
        const write = exports.$stringWrite1;
        for (let i = 0; i < length; i++) {
          write(dartString, i, s.codePointAt(i));
        }
        return dartString;
      } else {
        const dartString = exports.$stringAllocate2(length);
        const write = exports.$stringWrite2;
        for (let i = 0; i < length; i++) {
          write(dartString, i, s.charCodeAt(i));
        }
        return dartString;
      }
    }
    ''', s.toExternRef);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef? jsUint8ArrayFromDartUint8List(Uint8List l) =>
    JS<WasmExternRef?>("""(data, length) => {
          const jsBytes = new Uint8Array(length);
          const getByte = dartInstance.exports.\$uint8ListGet;
          for (let i = 0; i < length; i++) {
            jsBytes[i] = getByte(data, i);
          }
          return jsBytes;
        }""", l, l.length.toWasmI32());

@pragma("wasm:export", "\$stringAllocate1")
OneByteString _stringAllocate1(WasmI32 length) {
  return OneByteString.withLength(length.toIntSigned());
}

@pragma("wasm:export", "\$stringAllocate1_1")
OneByteString _stringAllocate1_1(WasmI32 a0) {
  final result = OneByteString.withLength(1);
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_2")
OneByteString _stringAllocate1_2(WasmI32 a0, WasmI32 a1) {
  final result = OneByteString.withLength(2);
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_3")
OneByteString _stringAllocate1_3(WasmI32 a0, WasmI32 a1, WasmI32 a2) {
  final result = OneByteString.withLength(3);
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_4")
OneByteString _stringAllocate1_4(
    WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3) {
  final result = OneByteString.withLength(4);
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_5")
OneByteString _stringAllocate1_5(
    WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3, WasmI32 a4) {
  final result = OneByteString.withLength(5);
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_6")
OneByteString _stringAllocate1_6(
    WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3, WasmI32 a4, WasmI32 a5) {
  final result = OneByteString.withLength(6);
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_7")
OneByteString _stringAllocate1_7(WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3,
    WasmI32 a4, WasmI32 a5, WasmI32 a6) {
  final result = OneByteString.withLength(7);
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_8")
OneByteString _stringAllocate1_8(WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3,
    WasmI32 a4, WasmI32 a5, WasmI32 a6, WasmI32 a7) {
  final result = OneByteString.withLength(8);
  result.setUnchecked(7, a7.toIntSigned());
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_9")
OneByteString _stringAllocate1_9(WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3,
    WasmI32 a4, WasmI32 a5, WasmI32 a6, WasmI32 a7, WasmI32 a8) {
  final result = OneByteString.withLength(9);
  result.setUnchecked(8, a8.toIntSigned());
  result.setUnchecked(7, a7.toIntSigned());
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_10")
OneByteString _stringAllocate1_10(
    WasmI32 a0,
    WasmI32 a1,
    WasmI32 a2,
    WasmI32 a3,
    WasmI32 a4,
    WasmI32 a5,
    WasmI32 a6,
    WasmI32 a7,
    WasmI32 a8,
    WasmI32 a9) {
  final result = OneByteString.withLength(10);
  result.setUnchecked(9, a9.toIntSigned());
  result.setUnchecked(8, a8.toIntSigned());
  result.setUnchecked(7, a7.toIntSigned());
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringRead1")
WasmI32 _stringRead1(OneByteString string, WasmI32 index) {
  return string.codeUnitAtUnchecked(index.toIntSigned()).toWasmI32();
}

@pragma("wasm:export", "\$stringWrite1")
void _stringWrite1(OneByteString string, WasmI32 index, WasmI32 codePoint) {
  string.setUnchecked(index.toIntSigned(), codePoint.toIntSigned());
}

@pragma("wasm:export", "\$stringAllocate2")
TwoByteString _stringAllocate2(WasmI32 length) {
  return TwoByteString.withLength(length.toIntSigned());
}

@pragma("wasm:export", "\$stringRead2")
WasmI32 _stringRead2(TwoByteString string, WasmI32 index) {
  return string.codeUnitAtUnchecked(index.toIntSigned()).toWasmI32();
}

@pragma("wasm:export", "\$stringWrite2")
void _stringWrite2(TwoByteString string, WasmI32 index, WasmI32 codePoint) {
  string.setUnchecked(index.toIntSigned(), codePoint.toIntSigned());
}

@pragma("wasm:export", "\$uint8ListGet")
WasmI32 _uint8ListGet(Uint8List bytes, WasmI32 index) {
  if (bytes is U8List) {
    return bytes[index.toIntSigned()].toWasmI32();
  }
  return bytes[index.toIntSigned()].toWasmI32();
}
