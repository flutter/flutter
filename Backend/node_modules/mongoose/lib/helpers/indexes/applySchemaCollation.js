'use strict';

const isTextIndex = require('./isTextIndex');

module.exports = function applySchemaCollation(indexKeys, indexOptions, schemaOptions) {
  if (isTextIndex(indexKeys)) {
    return;
  }

  if (schemaOptions.hasOwnProperty('collation') && !indexOptions.hasOwnProperty('collation')) {
    indexOptions.collation = schemaOptions.collation;
  }
};
