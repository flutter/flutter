// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * Defines functions for translating between JavaScript strings and UTF8 strings
 * stored in ArrayBuffers. There is much room for optimization in this code if
 * it proves necessary.
 */
define("mojo/public/js/unicode", function() {
  /**
   * Decodes the UTF8 string from the given buffer.
   * @param {ArrayBufferView} buffer The buffer containing UTF8 string data.
   * @return {string} The corresponding JavaScript string.
   */
  function decodeUtf8String(buffer) {
    return decodeURIComponent(escape(String.fromCharCode.apply(null, buffer)));
  }

  /**
   * Encodes the given JavaScript string into UTF8.
   * @param {string} str The string to encode.
   * @param {ArrayBufferView} outputBuffer The buffer to contain the result.
   * Should be pre-allocated to hold enough space. Use |utf8Length| to determine
   * how much space is required.
   * @return {number} The number of bytes written to |outputBuffer|.
   */
  function encodeUtf8String(str, outputBuffer) {
    var utf8String = unescape(encodeURIComponent(str));
    if (outputBuffer.length < utf8String.length)
      throw new Error("Buffer too small for encodeUtf8String");
    for (var i = 0; i < outputBuffer.length && i < utf8String.length; i++)
      outputBuffer[i] = utf8String.charCodeAt(i);
    return i;
  }

  /**
   * Returns the number of bytes that a UTF8 encoding of the JavaScript string
   * |str| would occupy.
   */
  function utf8Length(str) {
    var utf8String = unescape(encodeURIComponent(str));
    return utf8String.length;
  }

  var exports = {};
  exports.decodeUtf8String = decodeUtf8String;
  exports.encodeUtf8String = encodeUtf8String;
  exports.utf8Length = utf8Length;
  return exports;
});
