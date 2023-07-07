// Copyright (C) 2020 Potix Corporation. All Rights Reserved
// History: 2020/12/18 4:44 PM
// Author: jumperchen<jumperchen@potix.com>

import 'dart:typed_data';

bool isBinary(obj) {
  return (obj != null && obj is ByteBuffer) || obj is Uint8List;
}

bool hasBinary(obj, [bool toJSON = false]) {
  if (obj == null || (obj is! Map && obj is! List)) {
    return false;
  }
  if (obj is List && obj is! ByteBuffer && obj is! Uint8List) {
    for (var i = 0, l = obj.length; i < l; i++) {
      if (hasBinary(obj[i])) {
        return true;
      }
    }
    return false;
  }
  if (isBinary(obj)) {
    return true;
  }

  if (obj['toJSON'] != null && obj['toJSON'] is Function && toJSON == false) {
    return hasBinary(obj.toJSON(), true);
  }
  if (obj is Map) {
    for (var entry in obj.entries) {
      if (hasBinary(entry.value)) {
        return true;
      }
    }
  } else if (obj is List) {
    for (var value in obj) {
      if (hasBinary(value)) {
        return true;
      }
    }
  }
  return false;
}
