// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Support for parsing binary sequences encoded as readable strings
// or ".data" files. The input format is described here:
// mojo/public/cpp/bindings/tests/validation_test_input_parser.h

define([
    "mojo/public/js/buffer"
  ], function(buffer) {

  // Files and Lines represent the raw text from an input string
  // or ".data" file.

  function InputError(message, line) {
    this.message = message;
    this.line = line;
  }

  InputError.prototype.toString = function() {
    var s = 'Error: ' + this.message;
    if (this.line)
      s += ', at line ' +
           (this.line.number + 1) + ': "' + this.line.contents + '"';
    return s;
  }

  function File(contents) {
    this.contents = contents;
    this.index = 0;
    this.lineNumber = 0;
  }

  File.prototype.endReached = function() {
    return this.index >= this.contents.length;
  }

  File.prototype.nextLine = function() {
    if (this.endReached())
      return null;
    var start = this.index;
    var end = this.contents.indexOf('\n', start);
    if (end == -1)
      end = this.contents.length;
    this.index = end + 1;
    return new Line(this.contents.substring(start, end), this.lineNumber++);
  }

  function Line(contents, number) {
    var i = contents.indexOf('//');
    var s = (i == -1) ? contents.trim() : contents.substring(0, i).trim();
    this.contents = contents;
    this.items = (s.length > 0) ? s.split(/\s+/) : [];
    this.index = 0;
    this.number = number;
  }

  Line.prototype.endReached = function() {
    return this.index >= this.items.length;
  }

  var ITEM_TYPE_SIZES = {
    u1: 1, u2: 2, u4: 4, u8: 8, s1: 1, s2: 2, s4: 4, s8: 8, b: 1, f: 4, d: 8,
    dist4: 4, dist8: 8, anchr: 0, handles: 0
  };

  function isValidItemType(type) {
    return ITEM_TYPE_SIZES[type] !== undefined;
  }

  Line.prototype.nextItem = function() {
    if (this.endReached())
      return null;

    var itemString = this.items[this.index++];
    var type = 'u1';
    var value = itemString;

    if (itemString.charAt(0) == '[') {
      var i = itemString.indexOf(']');
      if (i != -1 && i + 1 < itemString.length) {
        type = itemString.substring(1, i);
        value = itemString.substring(i + 1);
      } else {
        throw new InputError('invalid item', this);
      }
    }
    if (!isValidItemType(type))
      throw new InputError('invalid item type', this);

    return new Item(this, type, value);
  }

  // The text for each whitespace delimited binary data "item" is represented
  // by an Item.

  function Item(line, type, value) {
    this.line = line;
    this.type = type;
    this.value = value;
    this.size = ITEM_TYPE_SIZES[type];
  }

  Item.prototype.isFloat = function() {
    return this.type == 'f' || this.type == 'd';
  }

  Item.prototype.isInteger = function() {
    return ['u1', 'u2', 'u4', 'u8',
            's1', 's2', 's4', 's8'].indexOf(this.type) != -1;
  }

  Item.prototype.isNumber = function() {
    return this.isFloat() || this.isInteger();
  }

  Item.prototype.isByte = function() {
    return this.type == 'b';
  }

  Item.prototype.isDistance = function() {
    return this.type == 'dist4' || this.type == 'dist8';
  }

  Item.prototype.isAnchor = function() {
    return this.type == 'anchr';
  }

  Item.prototype.isHandles = function() {
    return this.type == 'handles';
  }

  // A TestMessage represents the complete binary message loaded from an input
  // string or ".data" file. The parseTestMessage() function below constructs
  // a TestMessage from a File.

  function TestMessage(byteLength) {
    this.index = 0;
    this.buffer = new buffer.Buffer(byteLength);
    this.distances = {};
    this.handleCount = 0;
  }

  function checkItemNumberValue(item, n, min, max) {
    if (n < min || n > max)
      throw new InputError('invalid item value', item.line);
  }

  TestMessage.prototype.addNumber = function(item) {
    var n = item.isInteger() ? parseInt(item.value) : parseFloat(item.value);
    if (Number.isNaN(n))
      throw new InputError("can't parse item value", item.line);

    switch(item.type) {
      case 'u1':
        checkItemNumberValue(item, n, 0, 0xFF);
        this.buffer.setUint8(this.index, n);
        break;
      case 'u2':
        checkItemNumberValue(item, n, 0, 0xFFFF);
        this.buffer.setUint16(this.index, n);
        break;
      case 'u4':
        checkItemNumberValue(item, n, 0, 0xFFFFFFFF);
        this.buffer.setUint32(this.index, n);
        break;
      case 'u8':
        checkItemNumberValue(item, n, 0, Number.MAX_SAFE_INTEGER);
        this.buffer.setUint64(this.index, n);
        break;
      case 's1':
        checkItemNumberValue(item, n, -128, 127);
        this.buffer.setInt8(this.index, n);
        break;
      case 's2':
        checkItemNumberValue(item, n, -32768, 32767);
        this.buffer.setInt16(this.index, n);
        break;
      case 's4':
        checkItemNumberValue(item, n, -2147483648, 2147483647);
        this.buffer.setInt32(this.index, n);
        break;
      case 's8':
        checkItemNumberValue(item, n,
                             Number.MIN_SAFE_INTEGER,
                             Number.MAX_SAFE_INTEGER);
        this.buffer.setInt64(this.index, n);
        break;
      case 'f':
        this.buffer.setFloat32(this.index, n);
        break;
      case 'd':
        this.buffer.setFloat64(this.index, n);
        break;

      default:
        throw new InputError('unrecognized item type', item.line);
      }
  }

  TestMessage.prototype.addByte = function(item) {
    if (!/^[01]{8}$/.test(item.value))
      throw new InputError('invalid byte item value', item.line);
    function b(i) {
      return (item.value.charAt(7 - i) == '1') ? 1 << i : 0;
    }
    var n = b(0) | b(1) | b(2) | b(3) | b(4) | b(5) | b(6) | b(7);
    this.buffer.setUint8(this.index, n);
  }

  TestMessage.prototype.addDistance = function(item) {
    if (this.distances[item.value])
      throw new InputError('duplicate distance item', item.line);
    this.distances[item.value] = {index: this.index, item: item};
  }

  TestMessage.prototype.addAnchor = function(item) {
    var dist = this.distances[item.value];
    if (!dist)
      throw new InputError('unmatched anchor item', item.line);
    delete this.distances[item.value];

    var n = this.index - dist.index;
    // TODO(hansmuller): validate n

    if (dist.item.type == 'dist4')
      this.buffer.setUint32(dist.index, n);
    else if (dist.item.type == 'dist8')
      this.buffer.setUint64(dist.index, n);
    else
      throw new InputError('unrecognzed distance item type', dist.item.line);
  }

  TestMessage.prototype.addHandles = function(item) {
    this.handleCount = parseInt(item.value);
    if (Number.isNaN(this.handleCount))
      throw new InputError("can't parse handleCount", item.line);
  }

  TestMessage.prototype.addItem = function(item) {
    if (item.isNumber())
      this.addNumber(item);
    else if (item.isByte())
      this.addByte(item);
    else if (item.isDistance())
      this.addDistance(item);
    else if (item.isAnchor())
      this.addAnchor(item);
    else if (item.isHandles())
      this.addHandles(item);
    else
      throw new InputError('unrecognized item type', item.line);

    this.index += item.size;
  }

  TestMessage.prototype.unanchoredDistances = function() {
    var names = null;
    for (var name in this.distances) {
      if (this.distances.hasOwnProperty(name))
        names = (names === null) ? name : names + ' ' + name;
    }
    return names;
  }

  function parseTestMessage(text) {
    var file = new File(text);
    var items = [];
    var messageLength = 0;
    while(!file.endReached()) {
      var line = file.nextLine();
      while (!line.endReached()) {
        var item = line.nextItem();
        if (item.isHandles() && items.length > 0)
          throw new InputError('handles item is not first');
        messageLength += item.size;
        items.push(item);
      }
    }

    var msg = new TestMessage(messageLength);
    for (var i = 0; i < items.length; i++)
      msg.addItem(items[i]);

    if (messageLength != msg.index)
      throw new InputError('failed to compute message length');
    var names = msg.unanchoredDistances();
    if (names)
      throw new InputError('no anchors for ' + names, 0);

    return msg;
  }

  var exports = {};
  exports.parseTestMessage = parseTestMessage;
  exports.InputError = InputError;
  return exports;
});
