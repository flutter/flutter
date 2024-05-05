/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./mongooseError');
const allServersUnknown = require('../helpers/topology/allServersUnknown');
const isAtlas = require('../helpers/topology/isAtlas');
const isSSLError = require('../helpers/topology/isSSLError');

/*!
 * ignore
 */

const atlasMessage = 'Could not connect to any servers in your MongoDB Atlas cluster. ' +
  'One common reason is that you\'re trying to access the database from ' +
  'an IP that isn\'t whitelisted. Make sure your current IP address is on your Atlas ' +
  'cluster\'s IP whitelist: https://www.mongodb.com/docs/atlas/security-whitelist/';

const sslMessage = 'Mongoose is connecting with SSL enabled, but the server is ' +
  'not accepting SSL connections. Please ensure that the MongoDB server you are ' +
  'connecting to is configured to accept SSL connections. Learn more: ' +
  'https://mongoosejs.com/docs/tutorials/ssl.html';

class MongooseServerSelectionError extends MongooseError {
  /**
   * MongooseServerSelectionError constructor
   *
   * @api private
   */
  assimilateError(err) {
    const reason = err.reason;
    // Special message for a case that is likely due to IP whitelisting issues.
    const isAtlasWhitelistError = isAtlas(reason) &&
      allServersUnknown(reason) &&
      err.message.indexOf('bad auth') === -1 &&
      err.message.indexOf('Authentication failed') === -1;

    if (isAtlasWhitelistError) {
      this.message = atlasMessage;
    } else if (isSSLError(reason)) {
      this.message = sslMessage;
    } else {
      this.message = err.message;
    }
    for (const key in err) {
      if (key !== 'name') {
        this[key] = err[key];
      }
    }

    return this;
  }
}

Object.defineProperty(MongooseServerSelectionError.prototype, 'name', {
  value: 'MongooseServerSelectionError'
});

module.exports = MongooseServerSelectionError;
