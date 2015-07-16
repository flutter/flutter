// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/public/js/validator", [
  "mojo/public/js/codec",
], function(codec) {

  var validationError = {
    NONE: 'VALIDATION_ERROR_NONE',
    MISALIGNED_OBJECT: 'VALIDATION_ERROR_MISALIGNED_OBJECT',
    ILLEGAL_MEMORY_RANGE: 'VALIDATION_ERROR_ILLEGAL_MEMORY_RANGE',
    UNEXPECTED_STRUCT_HEADER: 'VALIDATION_ERROR_UNEXPECTED_STRUCT_HEADER',
    UNEXPECTED_ARRAY_HEADER: 'VALIDATION_ERROR_UNEXPECTED_ARRAY_HEADER',
    ILLEGAL_HANDLE: 'VALIDATION_ERROR_ILLEGAL_HANDLE',
    UNEXPECTED_INVALID_HANDLE: 'VALIDATION_ERROR_UNEXPECTED_INVALID_HANDLE',
    ILLEGAL_POINTER: 'VALIDATION_ERROR_ILLEGAL_POINTER',
    UNEXPECTED_NULL_POINTER: 'VALIDATION_ERROR_UNEXPECTED_NULL_POINTER',
    MESSAGE_HEADER_INVALID_FLAGS:
        'VALIDATION_ERROR_MESSAGE_HEADER_INVALID_FLAGS',
    MESSAGE_HEADER_MISSING_REQUEST_ID:
        'VALIDATION_ERROR_MESSAGE_HEADER_MISSING_REQUEST_ID',
    DIFFERENT_SIZED_ARRAYS_IN_MAP:
        'VALIDATION_ERROR_DIFFERENT_SIZED_ARRAYS_IN_MAP',
    INVALID_UNION_SIZE: 'VALIDATION_ERROR_INVALID_UNION_SIZE',
    UNEXPECTED_NULL_UNION: 'VALIDATION_ERROR_UNEXPECTED_NULL_UNION',
  };

  var NULL_MOJO_POINTER = "NULL_MOJO_POINTER";

  function isStringClass(cls) {
    return cls === codec.String || cls === codec.NullableString;
  }

  function isHandleClass(cls) {
    return cls === codec.Handle || cls === codec.NullableHandle;
  }

  function isInterfaceClass(cls) {
    return cls === codec.Interface || cls === codec.NullableInterface;
  }

  function isNullable(type) {
    return type === codec.NullableString || type === codec.NullableHandle ||
        type === codec.NullableInterface ||
        type instanceof codec.NullableArrayOf ||
        type instanceof codec.NullablePointerTo;
  }

  function Validator(message) {
    this.message = message;
    this.offset = 0;
    this.handleIndex = 0;
  }

  Object.defineProperty(Validator.prototype, "offsetLimit", {
    get: function() { return this.message.buffer.byteLength; }
  });

  Object.defineProperty(Validator.prototype, "handleIndexLimit", {
    get: function() { return this.message.handles.length; }
  });

  // True if we can safely allocate a block of bytes from start to
  // to start + numBytes.
  Validator.prototype.isValidRange = function(start, numBytes) {
    // Only positive JavaScript integers that are less than 2^53
    // (Number.MAX_SAFE_INTEGER) can be represented exactly.
    if (start < this.offset || numBytes <= 0 ||
        !Number.isSafeInteger(start) ||
        !Number.isSafeInteger(numBytes))
      return false;

    var newOffset = start + numBytes;
    if (!Number.isSafeInteger(newOffset) || newOffset > this.offsetLimit)
      return false;

    return true;
  }

  Validator.prototype.claimRange = function(start, numBytes) {
    if (this.isValidRange(start, numBytes)) {
      this.offset = start + numBytes;
      return true;
    }
    return false;
  }

  Validator.prototype.claimHandle = function(index) {
    if (index === codec.kEncodedInvalidHandleValue)
      return true;

    if (index < this.handleIndex || index >= this.handleIndexLimit)
      return false;

    // This is safe because handle indices are uint32.
    this.handleIndex = index + 1;
    return true;
  }

  Validator.prototype.validateHandle = function(offset, nullable) {
    var index = this.message.buffer.getUint32(offset);

    if (index === codec.kEncodedInvalidHandleValue)
      return nullable ?
          validationError.NONE : validationError.UNEXPECTED_INVALID_HANDLE;

    if (!this.claimHandle(index))
      return validationError.ILLEGAL_HANDLE;
    return validationError.NONE;
  }

  Validator.prototype.validateInterface = function(offset, nullable) {
    return this.validateHandle(offset, nullable);
  }

  Validator.prototype.validateStructHeader =
      function(offset, minNumBytes, minVersion) {
    if (!codec.isAligned(offset))
      return validationError.MISALIGNED_OBJECT;

    if (!this.isValidRange(offset, codec.kStructHeaderSize))
      return validationError.ILLEGAL_MEMORY_RANGE;

    var numBytes = this.message.buffer.getUint32(offset);
    var version = this.message.buffer.getUint32(offset + 4);

    // Backward compatibility is not yet supported.
    if (numBytes < minNumBytes || version < minVersion)
      return validationError.UNEXPECTED_STRUCT_HEADER;

    if (!this.claimRange(offset, numBytes))
      return validationError.ILLEGAL_MEMORY_RANGE;

    return validationError.NONE;
  }

  Validator.prototype.validateMessageHeader = function() {
    var err = this.validateStructHeader(0, codec.kMessageHeaderSize, 0);
    if (err != validationError.NONE)
      return err;

    var numBytes = this.message.getHeaderNumBytes();
    var version = this.message.getHeaderVersion();

    var validVersionAndNumBytes =
        (version == 0 && numBytes == codec.kMessageHeaderSize) ||
        (version == 1 &&
         numBytes == codec.kMessageWithRequestIDHeaderSize) ||
        (version > 1 &&
         numBytes >= codec.kMessageWithRequestIDHeaderSize);
    if (!validVersionAndNumBytes)
      return validationError.UNEXPECTED_STRUCT_HEADER;

    var expectsResponse = this.message.expectsResponse();
    var isResponse = this.message.isResponse();

    if (version == 0 && (expectsResponse || isResponse))
      return validationError.MESSAGE_HEADER_MISSING_REQUEST_ID;

    if (isResponse && expectsResponse)
      return validationError.MESSAGE_HEADER_INVALID_FLAGS;

    return validationError.NONE;
  }

  // Returns the message.buffer relative offset this pointer "points to",
  // NULL_MOJO_POINTER if the pointer represents a null, or JS null if the
  // pointer's value is not valid.
  Validator.prototype.decodePointer = function(offset) {
    var pointerValue = this.message.buffer.getUint64(offset);
    if (pointerValue === 0)
      return NULL_MOJO_POINTER;
    var bufferOffset = offset + pointerValue;
    return Number.isSafeInteger(bufferOffset) ? bufferOffset : null;
  }

  Validator.prototype.decodeUnionSize = function(offset) {
    return this.message.buffer.getUint32(offset);
  };

  Validator.prototype.decodeUnionTag = function(offset) {
    return this.message.buffer.getUint32(offset + 4);
  };

  Validator.prototype.validateArrayPointer = function(
      offset, elementSize, elementType, nullable, expectedDimensionSizes,
      currentDimension) {
    var arrayOffset = this.decodePointer(offset);
    if (arrayOffset === null)
      return validationError.ILLEGAL_POINTER;

    if (arrayOffset === NULL_MOJO_POINTER)
      return nullable ?
          validationError.NONE : validationError.UNEXPECTED_NULL_POINTER;

    return this.validateArray(arrayOffset, elementSize, elementType,
                              expectedDimensionSizes, currentDimension);
  }

  Validator.prototype.validateStructPointer = function(
      offset, structClass, nullable) {
    var structOffset = this.decodePointer(offset);
    if (structOffset === null)
      return validationError.ILLEGAL_POINTER;

    if (structOffset === NULL_MOJO_POINTER)
      return nullable ?
          validationError.NONE : validationError.UNEXPECTED_NULL_POINTER;

    return structClass.validate(this, structOffset);
  }

  Validator.prototype.validateUnion = function(
      offset, unionClass, nullable) {
    var size = this.message.buffer.getUint32(offset);
    if (size == 0) {
      return nullable ?
          validationError.NONE : validationError.UNEXPECTED_NULL_UNION;
    }

    return unionClass.validate(this, offset);
  }

  Validator.prototype.validateNestedUnion = function(
      offset, unionClass, nullable) {
    var unionOffset = this.decodePointer(offset);
    if (unionOffset === null)
      return validationError.ILLEGAL_POINTER;

    if (unionOffset === NULL_MOJO_POINTER)
      return nullable ?
          validationError.NONE : validationError.UNEXPECTED_NULL_UNION;

    return this.validateUnion(unionOffset, unionClass, nullable);
  }

  // This method assumes that the array at arrayPointerOffset has
  // been validated.

  Validator.prototype.arrayLength = function(arrayPointerOffset) {
    var arrayOffset = this.decodePointer(arrayPointerOffset);
    return this.message.buffer.getUint32(arrayOffset + 4);
  }

  Validator.prototype.validateMapPointer = function(
      offset, mapIsNullable, keyClass, valueClass, valueIsNullable) {
    // Validate the implicit map struct:
    // struct {array<keyClass> keys; array<valueClass> values};
    var structOffset = this.decodePointer(offset);
    if (structOffset === null)
      return validationError.ILLEGAL_POINTER;

    if (structOffset === NULL_MOJO_POINTER)
      return mapIsNullable ?
          validationError.NONE : validationError.UNEXPECTED_NULL_POINTER;

    var mapEncodedSize = codec.kStructHeaderSize + codec.kMapStructPayloadSize;
    var err = this.validateStructHeader(structOffset, mapEncodedSize, 0);
    if (err !== validationError.NONE)
        return err;

    // Validate the keys array.
    var keysArrayPointerOffset = structOffset + codec.kStructHeaderSize;
    err = this.validateArrayPointer(
        keysArrayPointerOffset, keyClass.encodedSize, keyClass, false, [0], 0);
    if (err !== validationError.NONE)
        return err;

    // Validate the values array.
    var valuesArrayPointerOffset = keysArrayPointerOffset + 8;
    var valuesArrayDimensions = [0]; // Validate the actual length below.
    if (valueClass instanceof codec.ArrayOf)
      valuesArrayDimensions =
          valuesArrayDimensions.concat(valueClass.dimensions());
    var err = this.validateArrayPointer(valuesArrayPointerOffset,
                                        valueClass.encodedSize,
                                        valueClass,
                                        valueIsNullable,
                                        valuesArrayDimensions,
                                        0);
    if (err !== validationError.NONE)
        return err;

    // Validate the lengths of the keys and values arrays.
    var keysArrayLength = this.arrayLength(keysArrayPointerOffset);
    var valuesArrayLength = this.arrayLength(valuesArrayPointerOffset);
    if (keysArrayLength != valuesArrayLength)
      return validationError.DIFFERENT_SIZED_ARRAYS_IN_MAP;

    return validationError.NONE;
  }

  Validator.prototype.validateStringPointer = function(offset, nullable) {
    return this.validateArrayPointer(
        offset, codec.Uint8.encodedSize, codec.Uint8, nullable, [0], 0);
  }

  // Similar to Array_Data<T>::Validate()
  // mojo/public/cpp/bindings/lib/array_internal.h

  Validator.prototype.validateArray =
      function (offset, elementSize, elementType, expectedDimensionSizes,
                currentDimension) {
    if (!codec.isAligned(offset))
      return validationError.MISALIGNED_OBJECT;

    if (!this.isValidRange(offset, codec.kArrayHeaderSize))
      return validationError.ILLEGAL_MEMORY_RANGE;

    var numBytes = this.message.buffer.getUint32(offset);
    var numElements = this.message.buffer.getUint32(offset + 4);

    // Note: this computation is "safe" because elementSize <= 8 and
    // numElements is a uint32.
    var elementsTotalSize = (elementType === codec.PackedBool) ?
        Math.ceil(numElements / 8) : (elementSize * numElements);

    if (numBytes < codec.kArrayHeaderSize + elementsTotalSize)
      return validationError.UNEXPECTED_ARRAY_HEADER;

    if (expectedDimensionSizes[currentDimension] != 0 &&
        numElements != expectedDimensionSizes[currentDimension]) {
      return validationError.UNEXPECTED_ARRAY_HEADER;
    }

    if (!this.claimRange(offset, numBytes))
      return validationError.ILLEGAL_MEMORY_RANGE;

    // Validate the array's elements if they are pointers or handles.

    var elementsOffset = offset + codec.kArrayHeaderSize;
    var nullable = isNullable(elementType);

    if (isHandleClass(elementType))
      return this.validateHandleElements(elementsOffset, numElements, nullable);
    if (isInterfaceClass(elementType))
      return this.validateInterfaceElements(
          elementsOffset, numElements, nullable);
    if (isStringClass(elementType))
      return this.validateArrayElements(
          elementsOffset, numElements, codec.Uint8, nullable, [0], 0);
    if (elementType instanceof codec.PointerTo)
      return this.validateStructElements(
          elementsOffset, numElements, elementType.cls, nullable);
    if (elementType instanceof codec.ArrayOf)
      return this.validateArrayElements(
          elementsOffset, numElements, elementType.cls, nullable,
          expectedDimensionSizes, currentDimension + 1);

    return validationError.NONE;
  }

  // Note: the |offset + i * elementSize| computation in the validateFooElements
  // methods below is "safe" because elementSize <= 8, offset and
  // numElements are uint32, and 0 <= i < numElements.

  Validator.prototype.validateHandleElements =
      function(offset, numElements, nullable) {
    var elementSize = codec.Handle.encodedSize;
    for (var i = 0; i < numElements; i++) {
      var elementOffset = offset + i * elementSize;
      var err = this.validateHandle(elementOffset, nullable);
      if (err != validationError.NONE)
        return err;
    }
    return validationError.NONE;
  }

  Validator.prototype.validateInterfaceElements =
      function(offset, numElements, nullable) {
    var elementSize = codec.Interface.encodedSize;
    for (var i = 0; i < numElements; i++) {
      var elementOffset = offset + i * elementSize;
      var err = this.validateInterface(elementOffset, nullable);
      if (err != validationError.NONE)
        return err;
    }
    return validationError.NONE;
  }

  // The elementClass parameter is the element type of the element arrays.
  Validator.prototype.validateArrayElements =
      function(offset, numElements, elementClass, nullable,
               expectedDimensionSizes, currentDimension) {
    var elementSize = codec.PointerTo.prototype.encodedSize;
    for (var i = 0; i < numElements; i++) {
      var elementOffset = offset + i * elementSize;
      var err = this.validateArrayPointer(
          elementOffset, elementClass.encodedSize, elementClass, nullable,
          expectedDimensionSizes, currentDimension);
      if (err != validationError.NONE)
        return err;
    }
    return validationError.NONE;
  }

  Validator.prototype.validateStructElements =
      function(offset, numElements, structClass, nullable) {
    var elementSize = codec.PointerTo.prototype.encodedSize;
    for (var i = 0; i < numElements; i++) {
      var elementOffset = offset + i * elementSize;
      var err =
          this.validateStructPointer(elementOffset, structClass, nullable);
      if (err != validationError.NONE)
        return err;
    }
    return validationError.NONE;
  }

  var exports = {};
  exports.validationError = validationError;
  exports.Validator = Validator;
  return exports;
});
