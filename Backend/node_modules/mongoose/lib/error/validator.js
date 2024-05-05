/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');


class ValidatorError extends MongooseError {
  /**
   * Schema validator error
   *
   * @param {Object} properties
   * @param {Document} doc
   * @api private
   */
  constructor(properties, doc) {
    let msg = properties.message;
    if (!msg) {
      msg = MongooseError.messages.general.default;
    }

    const message = formatMessage(msg, properties, doc);
    super(message);

    properties = Object.assign({}, properties, { message: message });
    this.properties = properties;
    this.kind = properties.type;
    this.path = properties.path;
    this.value = properties.value;
    this.reason = properties.reason;
  }

  /**
   * toString helper
   * TODO remove? This defaults to `${this.name}: ${this.message}`
   * @api private
   */
  toString() {
    return this.message;
  }

  /**
   * Ensure `name` and `message` show up in toJSON output re: gh-9296
   * @api private
   */

  toJSON() {
    return Object.assign({ name: this.name, message: this.message }, this);
  }
}


Object.defineProperty(ValidatorError.prototype, 'name', {
  value: 'ValidatorError'
});

/**
 * The object used to define this validator. Not enumerable to hide
 * it from `require('util').inspect()` output re: gh-3925
 * @api private
 */

Object.defineProperty(ValidatorError.prototype, 'properties', {
  enumerable: false,
  writable: true,
  value: null
});

// Exposed for testing
ValidatorError.prototype.formatMessage = formatMessage;

/**
 * Formats error messages
 * @api private
 */

function formatMessage(msg, properties, doc) {
  if (typeof msg === 'function') {
    return msg(properties, doc);
  }

  const propertyNames = Object.keys(properties);
  for (const propertyName of propertyNames) {
    if (propertyName === 'message') {
      continue;
    }
    msg = msg.replace('{' + propertyName.toUpperCase() + '}', properties[propertyName]);
  }

  return msg;
}

/*!
 * exports
 */

module.exports = ValidatorError;
