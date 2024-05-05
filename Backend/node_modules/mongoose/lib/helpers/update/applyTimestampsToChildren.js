'use strict';

const cleanPositionalOperators = require('../schema/cleanPositionalOperators');
const handleTimestampOption = require('../schema/handleTimestampOption');

module.exports = applyTimestampsToChildren;

/*!
 * ignore
 */

function applyTimestampsToChildren(now, update, schema) {
  if (update == null) {
    return;
  }

  const keys = Object.keys(update);
  const hasDollarKey = keys.some(key => key[0] === '$');

  if (hasDollarKey) {
    if (update.$push) {
      _applyTimestampToUpdateOperator(update.$push);
    }
    if (update.$addToSet) {
      _applyTimestampToUpdateOperator(update.$addToSet);
    }
    if (update.$set != null) {
      const keys = Object.keys(update.$set);
      for (const key of keys) {
        applyTimestampsToUpdateKey(schema, key, update.$set, now);
      }
    }
    if (update.$setOnInsert != null) {
      const keys = Object.keys(update.$setOnInsert);
      for (const key of keys) {
        applyTimestampsToUpdateKey(schema, key, update.$setOnInsert, now);
      }
    }
  }

  const updateKeys = Object.keys(update).filter(key => key[0] !== '$');
  for (const key of updateKeys) {
    applyTimestampsToUpdateKey(schema, key, update, now);
  }

  function _applyTimestampToUpdateOperator(op) {
    for (const key of Object.keys(op)) {
      const $path = schema.path(key.replace(/\.\$\./i, '.').replace(/.\$$/, ''));
      if (op[key] &&
          $path &&
          $path.$isMongooseDocumentArray &&
          $path.schema.options.timestamps) {
        const timestamps = $path.schema.options.timestamps;
        const createdAt = handleTimestampOption(timestamps, 'createdAt');
        const updatedAt = handleTimestampOption(timestamps, 'updatedAt');
        if (op[key].$each) {
          op[key].$each.forEach(function(subdoc) {
            if (updatedAt != null) {
              subdoc[updatedAt] = now;
            }
            if (createdAt != null) {
              subdoc[createdAt] = now;
            }

            applyTimestampsToChildren(now, subdoc, $path.schema);
          });
        } else {
          if (updatedAt != null) {
            op[key][updatedAt] = now;
          }
          if (createdAt != null) {
            op[key][createdAt] = now;
          }

          applyTimestampsToChildren(now, op[key], $path.schema);
        }
      }
    }
  }
}

function applyTimestampsToDocumentArray(arr, schematype, now) {
  const timestamps = schematype.schema.options.timestamps;

  const len = arr.length;

  if (!timestamps) {
    for (let i = 0; i < len; ++i) {
      applyTimestampsToChildren(now, arr[i], schematype.schema);
    }
    return;
  }

  const createdAt = handleTimestampOption(timestamps, 'createdAt');
  const updatedAt = handleTimestampOption(timestamps, 'updatedAt');
  for (let i = 0; i < len; ++i) {
    if (updatedAt != null) {
      arr[i][updatedAt] = now;
    }
    if (createdAt != null) {
      arr[i][createdAt] = now;
    }

    applyTimestampsToChildren(now, arr[i], schematype.schema);
  }
}

function applyTimestampsToSingleNested(subdoc, schematype, now) {
  const timestamps = schematype.schema.options.timestamps;
  if (!timestamps) {
    applyTimestampsToChildren(now, subdoc, schematype.schema);
    return;
  }

  const createdAt = handleTimestampOption(timestamps, 'createdAt');
  const updatedAt = handleTimestampOption(timestamps, 'updatedAt');
  if (updatedAt != null) {
    subdoc[updatedAt] = now;
  }
  if (createdAt != null) {
    subdoc[createdAt] = now;
  }

  applyTimestampsToChildren(now, subdoc, schematype.schema);
}

function applyTimestampsToUpdateKey(schema, key, update, now) {
  // Replace positional operator `$` and array filters `$[]` and `$[.*]`
  const keyToSearch = cleanPositionalOperators(key);
  const path = schema.path(keyToSearch);
  if (!path) {
    return;
  }

  const parentSchemaTypes = [];
  const pieces = keyToSearch.split('.');
  for (let i = pieces.length - 1; i > 0; --i) {
    const s = schema.path(pieces.slice(0, i).join('.'));
    if (s != null &&
      (s.$isMongooseDocumentArray || s.$isSingleNested)) {
      parentSchemaTypes.push({ parentPath: key.split('.').slice(0, i).join('.'), parentSchemaType: s });
    }
  }

  if (Array.isArray(update[key]) && path.$isMongooseDocumentArray) {
    applyTimestampsToDocumentArray(update[key], path, now);
  } else if (update[key] && path.$isSingleNested) {
    applyTimestampsToSingleNested(update[key], path, now);
  } else if (parentSchemaTypes.length > 0) {
    for (const item of parentSchemaTypes) {
      const parentPath = item.parentPath;
      const parentSchemaType = item.parentSchemaType;
      const timestamps = parentSchemaType.schema.options.timestamps;
      const updatedAt = handleTimestampOption(timestamps, 'updatedAt');

      if (!timestamps || updatedAt == null) {
        continue;
      }

      if (parentSchemaType.$isSingleNested) {
        // Single nested is easy
        update[parentPath + '.' + updatedAt] = now;
      } else if (parentSchemaType.$isMongooseDocumentArray) {
        let childPath = key.substring(parentPath.length + 1);

        if (/^\d+$/.test(childPath)) {
          update[parentPath + '.' + childPath][updatedAt] = now;
          continue;
        }

        const firstDot = childPath.indexOf('.');
        childPath = firstDot !== -1 ? childPath.substring(0, firstDot) : childPath;

        update[parentPath + '.' + childPath + '.' + updatedAt] = now;
      }
    }
  } else if (path.schema != null && path.schema != schema && update[key]) {
    const timestamps = path.schema.options.timestamps;
    const createdAt = handleTimestampOption(timestamps, 'createdAt');
    const updatedAt = handleTimestampOption(timestamps, 'updatedAt');

    if (!timestamps) {
      return;
    }

    if (updatedAt != null) {
      update[key][updatedAt] = now;
    }
    if (createdAt != null) {
      update[key][createdAt] = now;
    }
  }
}
