// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/public/js/buffer", function() {

  var kHostIsLittleEndian = (function () {
    var endianArrayBuffer = new ArrayBuffer(2);
    var endianUint8Array = new Uint8Array(endianArrayBuffer);
    var endianUint16Array = new Uint16Array(endianArrayBuffer);
    endianUint16Array[0] = 1;
    return endianUint8Array[0] == 1;
  })();

  var kHighWordMultiplier = 0x100000000;

  function Buffer(sizeOrArrayBuffer) {
    if (sizeOrArrayBuffer instanceof ArrayBuffer)
      this.arrayBuffer = sizeOrArrayBuffer;
    else
      this.arrayBuffer = new ArrayBuffer(sizeOrArrayBuffer);

    this.dataView = new DataView(this.arrayBuffer);
    this.next = 0;
  }

  Object.defineProperty(Buffer.prototype, "byteLength", {
    get: function() { return this.arrayBuffer.byteLength; }
  });

  Buffer.prototype.alloc = function(size) {
    var pointer = this.next;
    this.next += size;
    if (this.next > this.byteLength) {
      var newSize = (1.5 * (this.byteLength + size)) | 0;
      this.grow(newSize);
    }
    return pointer;
  };

  function copyArrayBuffer(dstArrayBuffer, srcArrayBuffer) {
    (new Uint8Array(dstArrayBuffer)).set(new Uint8Array(srcArrayBuffer));
  }

  Buffer.prototype.grow = function(size) {
    var newArrayBuffer = new ArrayBuffer(size);
    copyArrayBuffer(newArrayBuffer, this.arrayBuffer);
    this.arrayBuffer = newArrayBuffer;
    this.dataView = new DataView(this.arrayBuffer);
  };

  Buffer.prototype.trim = function() {
    this.arrayBuffer = this.arrayBuffer.slice(0, this.next);
    this.dataView = new DataView(this.arrayBuffer);
  };

  Buffer.prototype.getUint8 = function(offset) {
    return this.dataView.getUint8(offset);
  }
  Buffer.prototype.getUint16 = function(offset) {
    return this.dataView.getUint16(offset, kHostIsLittleEndian);
  }
  Buffer.prototype.getUint32 = function(offset) {
    return this.dataView.getUint32(offset, kHostIsLittleEndian);
  }
  Buffer.prototype.getUint64 = function(offset) {
    var lo, hi;
    if (kHostIsLittleEndian) {
      lo = this.dataView.getUint32(offset, kHostIsLittleEndian);
      hi = this.dataView.getUint32(offset + 4, kHostIsLittleEndian);
    } else {
      hi = this.dataView.getUint32(offset, kHostIsLittleEndian);
      lo = this.dataView.getUint32(offset + 4, kHostIsLittleEndian);
    }
    return lo + hi * kHighWordMultiplier;
  }

  Buffer.prototype.getInt8 = function(offset) {
    return this.dataView.getInt8(offset);
  }
  Buffer.prototype.getInt16 = function(offset) {
    return this.dataView.getInt16(offset, kHostIsLittleEndian);
  }
  Buffer.prototype.getInt32 = function(offset) {
    return this.dataView.getInt32(offset, kHostIsLittleEndian);
  }
  Buffer.prototype.getInt64 = function(offset) {
    var lo, hi;
    if (kHostIsLittleEndian) {
      lo = this.dataView.getUint32(offset, kHostIsLittleEndian);
      hi = this.dataView.getInt32(offset + 4, kHostIsLittleEndian);
    } else {
      hi = this.dataView.getInt32(offset, kHostIsLittleEndian);
      lo = this.dataView.getUint32(offset + 4, kHostIsLittleEndian);
    }
    return lo + hi * kHighWordMultiplier;
  }

  Buffer.prototype.getFloat32 = function(offset) {
    return this.dataView.getFloat32(offset, kHostIsLittleEndian);
  }
  Buffer.prototype.getFloat64 = function(offset) {
    return this.dataView.getFloat64(offset, kHostIsLittleEndian);
  }

  Buffer.prototype.setUint8 = function(offset, value) {
    this.dataView.setUint8(offset, value);
  }
  Buffer.prototype.setUint16 = function(offset, value) {
    this.dataView.setUint16(offset, value, kHostIsLittleEndian);
  }
  Buffer.prototype.setUint32 = function(offset, value) {
    this.dataView.setUint32(offset, value, kHostIsLittleEndian);
  }
  Buffer.prototype.setUint64 = function(offset, value) {
    var hi = (value / kHighWordMultiplier) | 0;
    if (kHostIsLittleEndian) {
      this.dataView.setInt32(offset, value, kHostIsLittleEndian);
      this.dataView.setInt32(offset + 4, hi, kHostIsLittleEndian);
    } else {
      this.dataView.setInt32(offset, hi, kHostIsLittleEndian);
      this.dataView.setInt32(offset + 4, value, kHostIsLittleEndian);
    }
  }

  Buffer.prototype.setInt8 = function(offset, value) {
    this.dataView.setInt8(offset, value);
  }
  Buffer.prototype.setInt16 = function(offset, value) {
    this.dataView.setInt16(offset, value, kHostIsLittleEndian);
  }
  Buffer.prototype.setInt32 = function(offset, value) {
    this.dataView.setInt32(offset, value, kHostIsLittleEndian);
  }
  Buffer.prototype.setInt64 = function(offset, value) {
    var hi = Math.floor(value / kHighWordMultiplier);
    if (kHostIsLittleEndian) {
      this.dataView.setInt32(offset, value, kHostIsLittleEndian);
      this.dataView.setInt32(offset + 4, hi, kHostIsLittleEndian);
    } else {
      this.dataView.setInt32(offset, hi, kHostIsLittleEndian);
      this.dataView.setInt32(offset + 4, value, kHostIsLittleEndian);
    }
  }

  Buffer.prototype.setFloat32 = function(offset, value) {
    this.dataView.setFloat32(offset, value, kHostIsLittleEndian);
  }
  Buffer.prototype.setFloat64 = function(offset, value) {
    this.dataView.setFloat64(offset, value, kHostIsLittleEndian);
  }

  var exports = {};
  exports.Buffer = Buffer;
  return exports;
});
