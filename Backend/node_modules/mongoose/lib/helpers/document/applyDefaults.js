'use strict';

const isNestedProjection = require('../projection/isNestedProjection');

module.exports = function applyDefaults(doc, fields, exclude, hasIncludedChildren, isBeforeSetters, pathsToSkip) {
  const paths = Object.keys(doc.$__schema.paths);
  const plen = paths.length;

  for (let i = 0; i < plen; ++i) {
    let def;
    let curPath = '';
    const p = paths[i];

    if (p === '_id' && doc.$__.skipId) {
      continue;
    }

    const type = doc.$__schema.paths[p];
    const path = type.splitPath();
    const len = path.length;
    let included = false;
    let doc_ = doc._doc;
    for (let j = 0; j < len; ++j) {
      if (doc_ == null) {
        break;
      }

      const piece = path[j];
      curPath += (!curPath.length ? '' : '.') + piece;

      if (exclude === true) {
        if (curPath in fields) {
          break;
        }
      } else if (exclude === false && fields && !included) {
        const hasSubpaths = type.$isSingleNested || type.$isMongooseDocumentArray;
        if ((curPath in fields && !isNestedProjection(fields[curPath])) || (j === len - 1 && hasSubpaths && hasIncludedChildren != null && hasIncludedChildren[curPath])) {
          included = true;
        } else if (hasIncludedChildren != null && !hasIncludedChildren[curPath]) {
          break;
        }
      }

      if (j === len - 1) {
        if (doc_[piece] !== void 0) {
          break;
        }

        if (isBeforeSetters != null) {
          if (typeof type.defaultValue === 'function') {
            if (!type.defaultValue.$runBeforeSetters && isBeforeSetters) {
              break;
            }
            if (type.defaultValue.$runBeforeSetters && !isBeforeSetters) {
              break;
            }
          } else if (!isBeforeSetters) {
            // Non-function defaults should always run **before** setters
            continue;
          }
        }

        if (pathsToSkip && pathsToSkip[curPath]) {
          break;
        }

        if (fields && exclude !== null) {
          if (exclude === true) {
            // apply defaults to all non-excluded fields
            if (p in fields) {
              continue;
            }

            try {
              def = type.getDefault(doc, false);
            } catch (err) {
              doc.invalidate(p, err);
              break;
            }

            if (typeof def !== 'undefined') {
              doc_[piece] = def;
              applyChangeTracking(doc, p);
            }
          } else if (included) {
            // selected field
            try {
              def = type.getDefault(doc, false);
            } catch (err) {
              doc.invalidate(p, err);
              break;
            }

            if (typeof def !== 'undefined') {
              doc_[piece] = def;
              applyChangeTracking(doc, p);
            }
          }
        } else {
          try {
            def = type.getDefault(doc, false);
          } catch (err) {
            doc.invalidate(p, err);
            break;
          }

          if (typeof def !== 'undefined') {
            doc_[piece] = def;
            applyChangeTracking(doc, p);
          }
        }
      } else {
        doc_ = doc_[piece];
      }
    }
  }
};

/*!
 * ignore
 */

function applyChangeTracking(doc, fullPath) {
  doc.$__.activePaths.default(fullPath);
  if (doc.$isSubdocument && doc.$isSingleNested && doc.$parent() != null) {
    doc.$parent().$__.activePaths.default(doc.$__pathRelativeToParent(fullPath));
  }
}
