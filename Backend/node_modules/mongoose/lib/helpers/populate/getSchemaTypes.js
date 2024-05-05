'use strict';

/*!
 * ignore
 */

const Mixed = require('../../schema/mixed');
const get = require('../get');
const getDiscriminatorByValue = require('../discriminator/getDiscriminatorByValue');
const leanPopulateMap = require('./leanPopulateMap');
const mpath = require('mpath');

const populateModelSymbol = require('../symbols').populateModelSymbol;

/**
 * Given a model and its schema, find all possible schema types for `path`,
 * including searching through discriminators. If `doc` is specified, will
 * use the doc's values for discriminator keys when searching, otherwise
 * will search all discriminators.
 *
 * @param {Model} model
 * @param {Schema} schema
 * @param {Object} doc POJO
 * @param {string} path
 * @api private
 */

module.exports = function getSchemaTypes(model, schema, doc, path) {
  const pathschema = schema.path(path);
  const topLevelDoc = doc;
  if (pathschema) {
    return pathschema;
  }

  const discriminatorKey = schema.discriminatorMapping &&
    schema.discriminatorMapping.key;
  if (discriminatorKey && model != null) {
    if (doc != null && doc[discriminatorKey] != null) {
      const discriminator = getDiscriminatorByValue(model.discriminators, doc[discriminatorKey]);
      schema = discriminator ? discriminator.schema : schema;
    } else if (model.discriminators != null) {
      return Object.keys(model.discriminators).reduce((arr, name) => {
        const disc = model.discriminators[name];
        return arr.concat(getSchemaTypes(disc, disc.schema, null, path));
      }, []);
    }
  }

  function search(parts, schema, subdoc, nestedPath) {
    let p = parts.length + 1;
    let foundschema;
    let trypath;

    while (p--) {
      trypath = parts.slice(0, p).join('.');
      foundschema = schema.path(trypath);
      if (foundschema == null) {
        continue;
      }

      if (foundschema.caster) {
        // array of Mixed?
        if (foundschema.caster instanceof Mixed) {
          return foundschema.caster;
        }

        let schemas = null;
        if (foundschema.schema != null && foundschema.schema.discriminators != null) {
          const discriminators = foundschema.schema.discriminators;
          const discriminatorKeyPath = trypath + '.' +
            foundschema.schema.options.discriminatorKey;
          const keys = subdoc ? mpath.get(discriminatorKeyPath, subdoc) || [] : [];
          schemas = Object.keys(discriminators).
            reduce(function(cur, discriminator) {
              const tiedValue = discriminators[discriminator].discriminatorMapping.value;
              if (doc == null || keys.indexOf(discriminator) !== -1 || keys.indexOf(tiedValue) !== -1) {
                cur.push(discriminators[discriminator]);
              }
              return cur;
            }, []);
        }

        // Now that we found the array, we need to check if there
        // are remaining document paths to look up for casting.
        // Also we need to handle array.$.path since schema.path
        // doesn't work for that.
        // If there is no foundschema.schema we are dealing with
        // a path like array.$
        if (p !== parts.length && foundschema.schema) {
          let ret;
          if (parts[p] === '$') {
            if (p + 1 === parts.length) {
              // comments.$
              return foundschema;
            }
            // comments.$.comments.$.title
            ret = search(
              parts.slice(p + 1),
              schema,
              subdoc ? mpath.get(trypath, subdoc) : null,
              nestedPath.concat(parts.slice(0, p))
            );
            if (ret) {
              ret.$parentSchemaDocArray = ret.$parentSchemaDocArray ||
                (foundschema.schema.$isSingleNested ? null : foundschema);
            }
            return ret;
          }

          if (schemas != null && schemas.length > 0) {
            ret = [];
            for (const schema of schemas) {
              const _ret = search(
                parts.slice(p),
                schema,
                subdoc ? mpath.get(trypath, subdoc) : null,
                nestedPath.concat(parts.slice(0, p))
              );
              if (_ret != null) {
                _ret.$parentSchemaDocArray = _ret.$parentSchemaDocArray ||
                  (foundschema.schema.$isSingleNested ? null : foundschema);
                if (_ret.$parentSchemaDocArray) {
                  ret.$parentSchemaDocArray = _ret.$parentSchemaDocArray;
                }
                ret.push(_ret);
              }
            }
            return ret;
          } else {
            ret = search(
              parts.slice(p),
              foundschema.schema,
              subdoc ? mpath.get(trypath, subdoc) : null,
              nestedPath.concat(parts.slice(0, p))
            );

            if (ret) {
              ret.$parentSchemaDocArray = ret.$parentSchemaDocArray ||
                (foundschema.schema.$isSingleNested ? null : foundschema);
            }
            return ret;
          }
        } else if (p !== parts.length &&
            foundschema.$isMongooseArray &&
            foundschema.casterConstructor.$isMongooseArray) {
          // Nested arrays. Drill down to the bottom of the nested array.
          let type = foundschema;
          while (type.$isMongooseArray && !type.$isMongooseDocumentArray) {
            type = type.casterConstructor;
          }

          const ret = search(
            parts.slice(p),
            type.schema,
            null,
            nestedPath.concat(parts.slice(0, p))
          );
          if (ret != null) {
            return ret;
          }

          if (type.schema.discriminators) {
            const discriminatorPaths = [];
            for (const discriminatorName of Object.keys(type.schema.discriminators)) {
              const _schema = type.schema.discriminators[discriminatorName] || type.schema;
              const ret = search(parts.slice(p), _schema, null, nestedPath.concat(parts.slice(0, p)));
              if (ret != null) {
                discriminatorPaths.push(ret);
              }
            }
            if (discriminatorPaths.length > 0) {
              return discriminatorPaths;
            }
          }
        }
      } else if (foundschema.$isSchemaMap && foundschema.$__schemaType instanceof Mixed) {
        return foundschema.$__schemaType;
      }

      const fullPath = nestedPath.concat([trypath]).join('.');
      if (topLevelDoc != null && topLevelDoc.$__ && topLevelDoc.$populated(fullPath) && p < parts.length) {
        const model = doc.$__.populated[fullPath].options[populateModelSymbol];
        if (model != null) {
          const ret = search(
            parts.slice(p),
            model.schema,
            subdoc ? mpath.get(trypath, subdoc) : null,
            nestedPath.concat(parts.slice(0, p))
          );

          return ret;
        }
      }

      const _val = get(topLevelDoc, trypath);
      if (_val != null) {
        const model = Array.isArray(_val) && _val.length > 0 ?
          leanPopulateMap.get(_val[0]) :
          leanPopulateMap.get(_val);
        // Populated using lean, `leanPopulateMap` value is the foreign model
        const schema = model != null ? model.schema : null;
        if (schema != null) {
          const ret = search(
            parts.slice(p),
            schema,
            subdoc ? mpath.get(trypath, subdoc) : null,
            nestedPath.concat(parts.slice(0, p))
          );

          if (ret != null) {
            ret.$parentSchemaDocArray = ret.$parentSchemaDocArray ||
              (schema.$isSingleNested ? null : schema);
            return ret;
          }
        }
      }
      return foundschema;
    }
  }
  // look for arrays
  const parts = path.split('.');
  for (let i = 0; i < parts.length; ++i) {
    if (parts[i] === '$') {
      // Re: gh-5628, because `schema.path()` doesn't take $ into account.
      parts[i] = '0';
    }
  }
  return search(parts, schema, doc, []);
};
