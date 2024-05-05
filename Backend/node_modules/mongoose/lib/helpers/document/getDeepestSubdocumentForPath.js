'use strict';

/**
 * Find the deepest subdocument along a given path to ensure setter functions run
 * with the correct subdocument as `this`. If no subdocuments, returns the top-level
 * document.
 *
 * @param {Document} doc
 * @param {String[]} parts
 * @param {Schema} schema
 * @returns Document
 */

module.exports = function getDeepestSubdocumentForPath(doc, parts, schema) {
  let curPath = parts[0];
  let curSchema = schema;
  let subdoc = doc;
  for (let i = 0; i < parts.length - 1; ++i) {
    const curSchemaType = curSchema.path(curPath);
    if (curSchemaType && curSchemaType.schema) {
      let newSubdoc = subdoc.get(curPath);
      curSchema = curSchemaType.schema;
      curPath = parts[i + 1];
      if (Array.isArray(newSubdoc) && !isNaN(curPath)) {
        newSubdoc = newSubdoc[curPath];
        curPath = '';
      }
      if (newSubdoc == null) {
        break;
      }
      subdoc = newSubdoc;
    } else {
      curPath += curPath.length ? '.' + parts[i + 1] : parts[i + 1];
    }
  }

  return subdoc;
};
