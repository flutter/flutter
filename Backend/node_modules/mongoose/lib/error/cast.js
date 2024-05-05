'use strict';

/*!
 * Module dependencies.
 */

const MongooseError = require('./mongooseError');
const util = require('util');

/**
 * Casting Error constructor.
 *
 * @param {String} type
 * @param {String} value
 * @inherits MongooseError
 * @api private
 */

class CastError extends MongooseError {
  constructor(type, value, path, reason, schemaType) {
    // If no args, assume we'll `init()` later.
    if (arguments.length > 0) {
      const valueType = getValueType(value);
      const messageFormat = getMessageFormat(schemaType);
      const msg = formatMessage(null, type, value, path, messageFormat, valueType, reason);
      super(msg);
      this.init(type, value, path, reason, schemaType);
    } else {
      super(formatMessage());
    }
  }

  toJSON() {
    return {
      stringValue: this.stringValue,
      valueType: this.valueType,
      kind: this.kind,
      value: this.value,
      path: this.path,
      reason: this.reason,
      name: this.name,
      message: this.message
    };
  }
  /*!
   * ignore
   */
  init(type, value, path, reason, schemaType) {
    this.stringValue = getStringValue(value);
    this.messageFormat = getMessageFormat(schemaType);
    this.kind = type;
    this.value = value;
    this.path = path;
    this.reason = reason;
    this.valueType = getValueType(value);
  }

  /**
   * ignore
   * @param {Readonly<CastError>} other
   * @api private
   */
  copy(other) {
    this.messageFormat = other.messageFormat;
    this.stringValue = other.stringValue;
    this.kind = other.kind;
    this.value = other.value;
    this.path = other.path;
    this.reason = other.reason;
    this.message = other.message;
    this.valueType = other.valueType;
  }

  /*!
   * ignore
   */
  setModel(model) {
    this.model = model;
    this.message = formatMessage(model, this.kind, this.value, this.path,
      this.messageFormat, this.valueType);
  }
}

Object.defineProperty(CastError.prototype, 'name', {
  value: 'CastError'
});

function getStringValue(value) {
  let stringValue = util.inspect(value);
  stringValue = stringValue.replace(/^'|'$/g, '"');
  if (!stringValue.startsWith('"')) {
    stringValue = '"' + stringValue + '"';
  }
  return stringValue;
}

function getValueType(value) {
  if (value == null) {
    return '' + value;
  }

  const t = typeof value;
  if (t !== 'object') {
    return t;
  }
  if (typeof value.constructor !== 'function') {
    return t;
  }
  return value.constructor.name;
}

function getMessageFormat(schemaType) {
  const messageFormat = schemaType && schemaType._castErrorMessage || null;
  if (typeof messageFormat === 'string' || typeof messageFormat === 'function') {
    return messageFormat;
  }
}

/*!
 * ignore
 */

function formatMessage(model, kind, value, path, messageFormat, valueType, reason) {
  if (typeof messageFormat === 'string') {
    const stringValue = getStringValue(value);
    let ret = messageFormat.
      replace('{KIND}', kind).
      replace('{VALUE}', stringValue).
      replace('{PATH}', path);
    if (model != null) {
      ret = ret.replace('{MODEL}', model.modelName);
    }

    return ret;
  } else if (typeof messageFormat === 'function') {
    return messageFormat(value, path, model, kind);
  } else {
    const stringValue = getStringValue(value);
    const valueTypeMsg = valueType ? ' (type ' + valueType + ')' : '';
    let ret = 'Cast to ' + kind + ' failed for value ' +
      stringValue + valueTypeMsg + ' at path "' + path + '"';
    if (model != null) {
      ret += ' for model "' + model.modelName + '"';
    }
    if (reason != null &&
        typeof reason.constructor === 'function' &&
        reason.constructor.name !== 'AssertionError' &&
        reason.constructor.name !== 'Error') {
      ret += ' because of "' + reason.constructor.name + '"';
    }
    return ret;
  }
}

/*!
 * exports
 */

module.exports = CastError;
