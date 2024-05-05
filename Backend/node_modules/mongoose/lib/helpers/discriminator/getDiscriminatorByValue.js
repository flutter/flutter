'use strict';

const areDiscriminatorValuesEqual = require('./areDiscriminatorValuesEqual');

/**
 * returns discriminator by discriminatorMapping.value
 *
 * @param {Object} discriminators
 * @param {string} value
 * @api private
 */

module.exports = function getDiscriminatorByValue(discriminators, value) {
  if (discriminators == null) {
    return null;
  }
  for (const name of Object.keys(discriminators)) {
    const it = discriminators[name];
    if (
      it.schema &&
      it.schema.discriminatorMapping &&
      areDiscriminatorValuesEqual(it.schema.discriminatorMapping.value, value)
    ) {
      return it;
    }
  }
  return null;
};
