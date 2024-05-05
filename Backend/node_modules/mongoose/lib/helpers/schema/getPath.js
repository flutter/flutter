'use strict';

const numberRE = /^\d+$/;

/**
 * Behaves like `Schema#path()`, except for it also digs into arrays without
 * needing to put `.0.`, so `getPath(schema, 'docArr.elProp')` works.
 * @api private
 */

module.exports = function getPath(schema, path) {
  let schematype = schema.path(path);
  if (schematype != null) {
    return schematype;
  }
  const pieces = path.split('.');
  let cur = '';
  let isArray = false;

  for (const piece of pieces) {
    if (isArray && numberRE.test(piece)) {
      continue;
    }
    cur = cur.length === 0 ? piece : cur + '.' + piece;

    schematype = schema.path(cur);
    if (schematype != null && schematype.schema) {
      schema = schematype.schema;
      cur = '';
      if (!isArray && schematype.$isMongooseDocumentArray) {
        isArray = true;
      }
    }
  }

  return schematype;
};
