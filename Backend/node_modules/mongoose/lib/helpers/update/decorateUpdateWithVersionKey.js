'use strict';

const modifiedPaths = require('./modifiedPaths');

/**
 * Decorate the update with a version key, if necessary
 * @api private
 */

module.exports = function decorateUpdateWithVersionKey(update, options, versionKey) {
  if (!versionKey || !(options && options.upsert || false)) {
    return;
  }

  const updatedPaths = modifiedPaths(update);
  if (!updatedPaths[versionKey]) {
    if (options.overwrite) {
      update[versionKey] = 0;
    } else {
      if (!update.$setOnInsert) {
        update.$setOnInsert = {};
      }
      update.$setOnInsert[versionKey] = 0;
    }
  }
};
