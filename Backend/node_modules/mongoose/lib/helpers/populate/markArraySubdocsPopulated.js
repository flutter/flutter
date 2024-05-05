'use strict';

const utils = require('../../utils');

/**
 * If populating a path within a document array, make sure each
 * subdoc within the array knows its subpaths are populated.
 *
 * #### Example:
 *
 *     const doc = await Article.findOne().populate('comments.author');
 *     doc.comments[0].populated('author'); // Should be set
 *
 * @param {Document} doc
 * @param {Object} [populated]
 * @api private
 */

module.exports = function markArraySubdocsPopulated(doc, populated) {
  if (doc._id == null || populated == null || populated.length === 0) {
    return;
  }

  const id = String(doc._id);
  for (const item of populated) {
    if (item.isVirtual) {
      continue;
    }
    const path = item.path;
    const pieces = path.split('.');
    for (let i = 0; i < pieces.length - 1; ++i) {
      const subpath = pieces.slice(0, i + 1).join('.');
      const rest = pieces.slice(i + 1).join('.');
      const val = doc.get(subpath);
      if (val == null) {
        continue;
      }

      if (utils.isMongooseDocumentArray(val)) {
        for (let j = 0; j < val.length; ++j) {
          if (val[j]) {
            val[j].populated(rest, item._docs[id] == null ? void 0 : item._docs[id][j], item);
          }
        }
        break;
      }
    }
  }
};
