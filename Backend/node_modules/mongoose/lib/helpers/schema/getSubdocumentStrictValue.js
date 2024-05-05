'use strict';

/**
 * Find the `strict` mode setting for the deepest subdocument along a given path
 * to ensure we have the correct default value for `strict`. When setting values
 * underneath a subdocument, we should use the subdocument's `strict` setting by
 * default, not the top-level document's.
 *
 * @param {Schema} schema
 * @param {String[]} parts
 * @returns {boolean | 'throw' | undefined}
 */

module.exports = function getSubdocumentStrictValue(schema, parts) {
  if (parts.length === 1) {
    return undefined;
  }
  let cur = parts[0];
  let strict = undefined;
  for (let i = 0; i < parts.length - 1; ++i) {
    const curSchemaType = schema.path(cur);
    if (curSchemaType && curSchemaType.schema) {
      strict = curSchemaType.schema.options.strict;
      schema = curSchemaType.schema;
      cur = curSchemaType.$isMongooseDocumentArray && !isNaN(parts[i + 1]) ? '' : parts[i + 1];
    } else {
      cur += cur.length ? ('.' + parts[i + 1]) : parts[i + 1];
    }
  }

  return strict;
};
