'use strict';

const CastError = require('../../error/cast');
const castBoolean = require('../../cast/boolean');
const castString = require('../../cast/string');

/**
 * Casts val to an object suitable for `$text`. Throws an error if the object
 * can't be casted.
 *
 * @param {Any} val value to cast
 * @param {String} [path] path to associate with any errors that occured
 * @return {Object} casted object
 * @see https://www.mongodb.com/docs/manual/reference/operator/query/text/
 * @api private
 */

module.exports = function(val, path) {
  if (val == null || typeof val !== 'object') {
    throw new CastError('$text', val, path);
  }

  if (val.$search != null) {
    val.$search = castString(val.$search, path + '.$search');
  }
  if (val.$language != null) {
    val.$language = castString(val.$language, path + '.$language');
  }
  if (val.$caseSensitive != null) {
    val.$caseSensitive = castBoolean(val.$caseSensitive,
      path + '.$castSensitive');
  }
  if (val.$diacriticSensitive != null) {
    val.$diacriticSensitive = castBoolean(val.$diacriticSensitive,
      path + '.$diacriticSensitive');
  }

  return val;
};
