'use strict';

const getDiscriminatorByValue = require('./getDiscriminatorByValue');

/**
 * Find the correct constructor, taking into account discriminators
 * @api private
 */

module.exports = function getConstructor(Constructor, value, defaultDiscriminatorValue) {
  const discriminatorKey = Constructor.schema.options.discriminatorKey;
  let discriminatorValue = (value != null && value[discriminatorKey]);
  if (discriminatorValue == null) {
    discriminatorValue = defaultDiscriminatorValue;
  }
  if (Constructor.discriminators &&
      discriminatorValue != null) {
    if (Constructor.discriminators[discriminatorValue]) {
      Constructor = Constructor.discriminators[discriminatorValue];
    } else {
      const constructorByValue = getDiscriminatorByValue(Constructor.discriminators, discriminatorValue);
      if (constructorByValue) {
        Constructor = constructorByValue;
      }
    }
  }

  return Constructor;
};
