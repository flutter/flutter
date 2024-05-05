'use strict';

const MongooseError = require('../../error/mongooseError');
const util = require('util');

module.exports = validateRef;

function validateRef(ref, path) {
  if (typeof ref === 'string') {
    return;
  }

  if (typeof ref === 'function') {
    return;
  }

  throw new MongooseError('Invalid ref at path "' + path + '". Got ' +
    util.inspect(ref, { depth: 0 }));
}
