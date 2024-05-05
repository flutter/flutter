'use strict';

/*!
 * Module dependencies.
 */

const ValidationError = require('../error/validation');
const cleanPositionalOperators = require('./schema/cleanPositionalOperators');
const flatten = require('./common').flatten;
const modifiedPaths = require('./common').modifiedPaths;

/**
 * Applies validators and defaults to update and findOneAndUpdate operations,
 * specifically passing a null doc as `this` to validators and defaults
 *
 * @param {Query} query
 * @param {Schema} schema
 * @param {Object} castedDoc
 * @param {Object} options
 * @method runValidatorsOnUpdate
 * @api private
 */

module.exports = function(query, schema, castedDoc, options, callback) {
  const keys = Object.keys(castedDoc || {});
  let updatedKeys = {};
  let updatedValues = {};
  const isPull = {};
  const arrayAtomicUpdates = {};
  const numKeys = keys.length;
  let hasDollarUpdate = false;
  const modified = {};
  let currentUpdate;
  let key;
  let i;

  for (i = 0; i < numKeys; ++i) {
    if (keys[i].startsWith('$')) {
      hasDollarUpdate = true;
      if (keys[i] === '$push' || keys[i] === '$addToSet') {
        const _keys = Object.keys(castedDoc[keys[i]]);
        for (let ii = 0; ii < _keys.length; ++ii) {
          currentUpdate = castedDoc[keys[i]][_keys[ii]];
          if (currentUpdate && currentUpdate.$each) {
            arrayAtomicUpdates[_keys[ii]] = (arrayAtomicUpdates[_keys[ii]] || []).
              concat(currentUpdate.$each);
          } else {
            arrayAtomicUpdates[_keys[ii]] = (arrayAtomicUpdates[_keys[ii]] || []).
              concat([currentUpdate]);
          }
        }
        continue;
      }
      modifiedPaths(castedDoc[keys[i]], '', modified);
      const flat = flatten(castedDoc[keys[i]], null, null, schema);
      const paths = Object.keys(flat);
      const numPaths = paths.length;
      for (let j = 0; j < numPaths; ++j) {
        const updatedPath = cleanPositionalOperators(paths[j]);
        key = keys[i];
        // With `$pull` we might flatten `$in`. Skip stuff nested under `$in`
        // for the rest of the logic, it will get handled later.
        if (updatedPath.includes('$')) {
          continue;
        }
        if (key === '$set' || key === '$setOnInsert' ||
            key === '$pull' || key === '$pullAll') {
          updatedValues[updatedPath] = flat[paths[j]];
          isPull[updatedPath] = key === '$pull' || key === '$pullAll';
        } else if (key === '$unset') {
          updatedValues[updatedPath] = undefined;
        }
        updatedKeys[updatedPath] = true;
      }
    }
  }

  if (!hasDollarUpdate) {
    modifiedPaths(castedDoc, '', modified);
    updatedValues = flatten(castedDoc, null, null, schema);
    updatedKeys = Object.keys(updatedValues);
  }

  const updates = Object.keys(updatedValues);
  const numUpdates = updates.length;
  const validatorsToExecute = [];
  const validationErrors = [];

  const alreadyValidated = [];

  const context = query;
  function iter(i, v) {
    const schemaPath = schema._getSchema(updates[i]);
    if (schemaPath == null) {
      return;
    }
    if (schemaPath.instance === 'Mixed' && schemaPath.path !== updates[i]) {
      return;
    }

    if (v && Array.isArray(v.$in)) {
      v.$in.forEach((v, i) => {
        validatorsToExecute.push(function(callback) {
          schemaPath.doValidate(
            v,
            function(err) {
              if (err) {
                err.path = updates[i] + '.$in.' + i;
                validationErrors.push(err);
              }
              callback(null);
            },
            context,
            { updateValidator: true });
        });
      });
    } else {
      if (isPull[updates[i]] &&
          schemaPath.$isMongooseArray) {
        return;
      }

      if (schemaPath.$isMongooseDocumentArrayElement && v != null && v.$__ != null) {
        alreadyValidated.push(updates[i]);
        validatorsToExecute.push(function(callback) {
          schemaPath.doValidate(v, function(err) {
            if (err) {
              if (err.errors) {
                for (const key of Object.keys(err.errors)) {
                  const _err = err.errors[key];
                  _err.path = updates[i] + '.' + key;
                  validationErrors.push(_err);
                }
              } else {
                err.path = updates[i];
                validationErrors.push(err);
              }
            }

            return callback(null);
          }, context, { updateValidator: true });
        });
      } else {
        validatorsToExecute.push(function(callback) {
          for (const path of alreadyValidated) {
            if (updates[i].startsWith(path + '.')) {
              return callback(null);
            }
          }

          schemaPath.doValidate(v, function(err) {
            if (schemaPath.schema != null &&
                schemaPath.schema.options.storeSubdocValidationError === false &&
                err instanceof ValidationError) {
              return callback(null);
            }

            if (err) {
              err.path = updates[i];
              validationErrors.push(err);
            }
            callback(null);
          }, context, { updateValidator: true });
        });
      }
    }
  }
  for (i = 0; i < numUpdates; ++i) {
    iter(i, updatedValues[updates[i]]);
  }

  const arrayUpdates = Object.keys(arrayAtomicUpdates);
  for (const arrayUpdate of arrayUpdates) {
    let schemaPath = schema._getSchema(arrayUpdate);
    if (schemaPath && schemaPath.$isMongooseDocumentArray) {
      validatorsToExecute.push(function(callback) {
        schemaPath.doValidate(
          arrayAtomicUpdates[arrayUpdate],
          getValidationCallback(arrayUpdate, validationErrors, callback),
          options && options.context === 'query' ? query : null);
      });
    } else {
      schemaPath = schema._getSchema(arrayUpdate + '.0');
      for (const atomicUpdate of arrayAtomicUpdates[arrayUpdate]) {
        validatorsToExecute.push(function(callback) {
          schemaPath.doValidate(
            atomicUpdate,
            getValidationCallback(arrayUpdate, validationErrors, callback),
            options && options.context === 'query' ? query : null,
            { updateValidator: true });
        });
      }
    }
  }

  if (callback != null) {
    let numValidators = validatorsToExecute.length;
    if (numValidators === 0) {
      return _done(callback);
    }
    for (const validator of validatorsToExecute) {
      validator(function() {
        if (--numValidators <= 0) {
          _done(callback);
        }
      });
    }

    return;
  }

  return function(callback) {
    let numValidators = validatorsToExecute.length;
    if (numValidators === 0) {
      return _done(callback);
    }
    for (const validator of validatorsToExecute) {
      validator(function() {
        if (--numValidators <= 0) {
          _done(callback);
        }
      });
    }
  };

  function _done(callback) {
    if (validationErrors.length) {
      const err = new ValidationError(null);

      for (const validationError of validationErrors) {
        err.addError(validationError.path, validationError);
      }

      return callback(err);
    }
    callback(null);
  }

  function getValidationCallback(arrayUpdate, validationErrors, callback) {
    return function(err) {
      if (err) {
        err.path = arrayUpdate;
        validationErrors.push(err);
      }
      callback(null);
    };
  }
};

