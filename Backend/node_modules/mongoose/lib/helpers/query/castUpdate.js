'use strict';

const CastError = require('../../error/cast');
const MongooseError = require('../../error/mongooseError');
const StrictModeError = require('../../error/strict');
const ValidationError = require('../../error/validation');
const castNumber = require('../../cast/number');
const cast = require('../../cast');
const getConstructorName = require('../getConstructorName');
const getEmbeddedDiscriminatorPath = require('./getEmbeddedDiscriminatorPath');
const handleImmutable = require('./handleImmutable');
const moveImmutableProperties = require('../update/moveImmutableProperties');
const schemaMixedSymbol = require('../../schema/symbols').schemaMixedSymbol;
const setDottedPath = require('../path/setDottedPath');
const utils = require('../../utils');
const { internalToObjectOptions } = require('../../options');

const mongodbUpdateOperators = new Set([
  '$currentDate',
  '$inc',
  '$min',
  '$max',
  '$mul',
  '$rename',
  '$set',
  '$setOnInsert',
  '$unset',
  '$addToSet',
  '$pop',
  '$pull',
  '$push',
  '$pullAll',
  '$bit'
]);

/**
 * Casts an update op based on the given schema
 *
 * @param {Schema} schema
 * @param {Object} obj
 * @param {Object} [options]
 * @param {Boolean|String} [options.strict] defaults to true
 * @param {Query} context passed to setters
 * @return {Boolean} true iff the update is non-empty
 * @api private
 */
module.exports = function castUpdate(schema, obj, options, context, filter) {
  if (obj == null) {
    return undefined;
  }
  options = options || {};
  // Update pipeline
  if (Array.isArray(obj)) {
    const len = obj.length;
    for (let i = 0; i < len; ++i) {
      const ops = Object.keys(obj[i]);
      for (const op of ops) {
        obj[i][op] = castPipelineOperator(op, obj[i][op]);
      }
    }
    return obj;
  }

  if (options.upsert) {
    moveImmutableProperties(schema, obj, context);
  }

  const ops = Object.keys(obj);
  let i = ops.length;
  const ret = {};
  let val;
  let hasDollarKey = false;

  filter = filter || {};
  while (i--) {
    const op = ops[i];
    if (!mongodbUpdateOperators.has(op)) {
      // fix up $set sugar
      if (!ret.$set) {
        if (obj.$set) {
          ret.$set = obj.$set;
        } else {
          ret.$set = {};
        }
      }
      ret.$set[op] = obj[op];
      ops.splice(i, 1);
      if (!~ops.indexOf('$set')) ops.push('$set');
    } else if (op === '$set') {
      if (!ret.$set) {
        ret[op] = obj[op];
      }
    } else {
      ret[op] = obj[op];
    }
  }
  // cast each value
  i = ops.length;
  while (i--) {
    const op = ops[i];
    val = ret[op];
    hasDollarKey = hasDollarKey || op.startsWith('$');
    if (val != null && val.$__) {
      val = val.toObject(internalToObjectOptions);
      ret[op] = val;
    }
    if (val &&
        typeof val === 'object' &&
        !Buffer.isBuffer(val) &&
        mongodbUpdateOperators.has(op)) {
      walkUpdatePath(schema, val, op, options, context, filter);
    } else {
      const msg = 'Invalid atomic update value for ' + op + '. '
          + 'Expected an object, received ' + typeof val;
      throw new Error(msg);
    }

    if (op.startsWith('$') && utils.isEmptyObject(val)) {
      delete ret[op];
    }
  }

  if (Object.keys(ret).length === 0 &&
      options.upsert &&
      Object.keys(filter).length > 0) {
    // Trick the driver into allowing empty upserts to work around
    // https://github.com/mongodb/node-mongodb-native/pull/2490
    // Shallow clone to avoid passing defaults in re: gh-13962
    return { $setOnInsert: { ...filter } };
  }
  return ret;
};

/*!
 * ignore
 */

function castPipelineOperator(op, val) {
  if (op === '$unset') {
    if (typeof val !== 'string' && (!Array.isArray(val) || val.find(v => typeof v !== 'string'))) {
      throw new MongooseError('Invalid $unset in pipeline, must be ' +
        ' a string or an array of strings');
    }
    return val;
  }
  if (op === '$project') {
    if (val == null || typeof val !== 'object') {
      throw new MongooseError('Invalid $project in pipeline, must be an object');
    }
    return val;
  }
  if (op === '$addFields' || op === '$set') {
    if (val == null || typeof val !== 'object') {
      throw new MongooseError('Invalid ' + op + ' in pipeline, must be an object');
    }
    return val;
  } else if (op === '$replaceRoot' || op === '$replaceWith') {
    if (val == null || typeof val !== 'object') {
      throw new MongooseError('Invalid ' + op + ' in pipeline, must be an object');
    }
    return val;
  }

  throw new MongooseError('Invalid update pipeline operator: "' + op + '"');
}

/**
 * Walk each path of obj and cast its values
 * according to its schema.
 *
 * @param {Schema} schema
 * @param {Object} obj part of a query
 * @param {String} op the atomic operator ($pull, $set, etc)
 * @param {Object} [options]
 * @param {Boolean|String} [options.strict]
 * @param {Query} context
 * @param {Object} filter
 * @param {String} pref path prefix (internal only)
 * @return {Bool} true if this path has keys to update
 * @api private
 */

function walkUpdatePath(schema, obj, op, options, context, filter, pref) {
  const strict = options.strict;
  const prefix = pref ? pref + '.' : '';
  const keys = Object.keys(obj);
  let i = keys.length;
  let hasKeys = false;
  let schematype;
  let key;
  let val;

  let aggregatedError = null;

  const strictMode = strict != null ? strict : schema.options.strict;

  while (i--) {
    key = keys[i];
    val = obj[key];

    // `$pull` is special because we need to cast the RHS as a query, not as
    // an update.
    if (op === '$pull') {
      schematype = schema._getSchema(prefix + key);
      if (schematype != null && schematype.schema != null) {
        obj[key] = cast(schematype.schema, obj[key], options, context);
        hasKeys = true;
        continue;
      }
    }

    const discriminatorKey = (prefix ? prefix + key : key);
    if (
      schema.discriminatorMapping != null &&
      discriminatorKey === schema.options.discriminatorKey &&
      schema.discriminatorMapping.value !== obj[key] &&
      !options.overwriteDiscriminatorKey
    ) {
      if (strictMode === 'throw') {
        const err = new Error('Can\'t modify discriminator key "' + discriminatorKey + '" on discriminator model');
        aggregatedError = _appendError(err, context, discriminatorKey, aggregatedError);
        continue;
      } else if (strictMode) {
        delete obj[key];
        continue;
      }
    }

    if (getConstructorName(val) === 'Object') {
      // watch for embedded doc schemas
      schematype = schema._getSchema(prefix + key);

      if (schematype == null) {
        const _res = getEmbeddedDiscriminatorPath(schema, obj, filter, prefix + key, options);
        if (_res.schematype != null) {
          schematype = _res.schematype;
        }
      }

      if (op !== '$setOnInsert' &&
          handleImmutable(schematype, strict, obj, key, prefix + key, context)) {
        continue;
      }

      if (schematype && schematype.caster && op in castOps) {
        // embedded doc schema
        if ('$each' in val) {
          hasKeys = true;
          try {
            obj[key] = {
              $each: castUpdateVal(schematype, val.$each, op, key, context, prefix + key)
            };
          } catch (error) {
            aggregatedError = _appendError(error, context, key, aggregatedError);
          }

          if (val.$slice != null) {
            obj[key].$slice = val.$slice | 0;
          }

          if (val.$sort) {
            obj[key].$sort = val.$sort;
          }

          if (val.$position != null) {
            obj[key].$position = castNumber(val.$position);
          }
        } else {
          if (schematype != null && schematype.$isSingleNested) {
            const _strict = strict == null ? schematype.schema.options.strict : strict;
            try {
              obj[key] = schematype.castForQuery(null, val, context, { strict: _strict });
            } catch (error) {
              aggregatedError = _appendError(error, context, key, aggregatedError);
            }
          } else {
            try {
              obj[key] = castUpdateVal(schematype, val, op, key, context, prefix + key);
            } catch (error) {
              aggregatedError = _appendError(error, context, key, aggregatedError);
            }
          }

          if (obj[key] === void 0) {
            delete obj[key];
            continue;
          }

          hasKeys = true;
        }
      } else if ((op === '$currentDate') || (op in castOps && schematype)) {
        // $currentDate can take an object
        try {
          obj[key] = castUpdateVal(schematype, val, op, key, context, prefix + key);
        } catch (error) {
          aggregatedError = _appendError(error, context, key, aggregatedError);
        }

        if (obj[key] === void 0) {
          delete obj[key];
          continue;
        }

        hasKeys = true;
      } else {
        const pathToCheck = (prefix + key);
        const v = schema._getPathType(pathToCheck);
        let _strict = strict;
        if (v && v.schema && _strict == null) {
          _strict = v.schema.options.strict;
        }

        if (v.pathType === 'undefined') {
          if (_strict === 'throw') {
            throw new StrictModeError(pathToCheck);
          } else if (_strict) {
            delete obj[key];
            continue;
          }
        }

        // gh-2314
        // we should be able to set a schema-less field
        // to an empty object literal
        hasKeys |= walkUpdatePath(schema, val, op, options, context, filter, prefix + key) ||
          (utils.isObject(val) && Object.keys(val).length === 0);
      }
    } else {
      const checkPath = (key === '$each' || key === '$or' || key === '$and' || key === '$in') ?
        pref : prefix + key;
      schematype = schema._getSchema(checkPath);

      // You can use `$setOnInsert` with immutable keys
      if (op !== '$setOnInsert' &&
          handleImmutable(schematype, strict, obj, key, prefix + key, context)) {
        continue;
      }

      let pathDetails = schema._getPathType(checkPath);

      // If no schema type, check for embedded discriminators because the
      // filter or update may imply an embedded discriminator type. See #8378
      if (schematype == null) {
        const _res = getEmbeddedDiscriminatorPath(schema, obj, filter, checkPath, options);
        if (_res.schematype != null) {
          schematype = _res.schematype;
          pathDetails = _res.type;
        }
      }

      let isStrict = strict;
      if (pathDetails && pathDetails.schema && strict == null) {
        isStrict = pathDetails.schema.options.strict;
      }

      const skip = isStrict &&
        !schematype &&
        !/real|nested/.test(pathDetails.pathType);

      if (skip) {
        // Even if strict is `throw`, avoid throwing an error because of
        // virtuals because of #6731
        if (isStrict === 'throw' && schema.virtuals[checkPath] == null) {
          throw new StrictModeError(prefix + key);
        } else {
          delete obj[key];
        }
      } else {
        // gh-1845 temporary fix: ignore $rename. See gh-3027 for tracking
        // improving this.
        if (op === '$rename') {
          hasKeys = true;
          continue;
        }

        try {
          if (prefix.length === 0 || key.indexOf('.') === -1) {
            obj[key] = castUpdateVal(schematype, val, op, key, context, prefix + key);
          } else if (isStrict !== false || schematype != null) {
            // Setting a nested dotted path that's in the schema. We don't allow paths with '.' in
            // a schema, so replace the dotted path with a nested object to avoid ending up with
            // dotted properties in the updated object. See (gh-10200)
            setDottedPath(obj, key, castUpdateVal(schematype, val, op, key, context, prefix + key));
            delete obj[key];
          }
        } catch (error) {
          aggregatedError = _appendError(error, context, key, aggregatedError);
        }

        if (Array.isArray(obj[key]) && (op === '$addToSet' || op === '$push') && key !== '$each') {
          if (schematype &&
              schematype.caster &&
              !schematype.caster.$isMongooseArray &&
              !schematype.caster[schemaMixedSymbol]) {
            obj[key] = { $each: obj[key] };
          }
        }

        if (obj[key] === void 0) {
          delete obj[key];
          continue;
        }

        hasKeys = true;
      }
    }
  }

  if (aggregatedError != null) {
    throw aggregatedError;
  }

  return hasKeys;
}

/*!
 * ignore
 */

function _appendError(error, query, key, aggregatedError) {
  if (typeof query !== 'object' || !query.options.multipleCastError) {
    throw error;
  }
  aggregatedError = aggregatedError || new ValidationError();
  aggregatedError.addError(key, error);
  return aggregatedError;
}

/**
 * These operators should be cast to numbers instead
 * of their path schema type.
 * @api private
 */

const numberOps = {
  $pop: 1,
  $inc: 1
};

/**
 * These ops require no casting because the RHS doesn't do anything.
 * @api private
 */

const noCastOps = {
  $unset: 1
};

/**
 * These operators require casting docs
 * to real Documents for Update operations.
 * @api private
 */

const castOps = {
  $push: 1,
  $addToSet: 1,
  $set: 1,
  $setOnInsert: 1
};

/*!
 * ignore
 */

const overwriteOps = {
  $set: 1,
  $setOnInsert: 1
};

/**
 * Casts `val` according to `schema` and atomic `op`.
 *
 * @param {SchemaType} schema
 * @param {Object} val
 * @param {String} op the atomic operator ($pull, $set, etc)
 * @param {String} $conditional
 * @param {Query} context
 * @param {String} path
 * @api private
 */

function castUpdateVal(schema, val, op, $conditional, context, path) {
  if (!schema) {
    // non-existing schema path
    if (op in numberOps) {
      try {
        return castNumber(val);
      } catch (err) {
        throw new CastError('number', val, path);
      }
    }
    return val;
  }

  // console.log('CastUpdateVal', path, op, val, schema);

  const cond = schema.caster && op in castOps &&
      (utils.isObject(val) || Array.isArray(val));
  if (cond && !overwriteOps[op]) {
    // Cast values for ops that add data to MongoDB.
    // Ensures embedded documents get ObjectIds etc.
    let schemaArrayDepth = 0;
    let cur = schema;
    while (cur.$isMongooseArray) {
      ++schemaArrayDepth;
      cur = cur.caster;
    }
    let arrayDepth = 0;
    let _val = val;
    while (Array.isArray(_val)) {
      ++arrayDepth;
      _val = _val[0];
    }

    const additionalNesting = schemaArrayDepth - arrayDepth;
    while (arrayDepth < schemaArrayDepth) {
      val = [val];
      ++arrayDepth;
    }

    let tmp = schema.applySetters(Array.isArray(val) ? val : [val], context);

    for (let i = 0; i < additionalNesting; ++i) {
      tmp = tmp[0];
    }
    return tmp;
  }

  if (op in noCastOps) {
    return val;
  }
  if (op in numberOps) {
    // Null and undefined not allowed for $pop, $inc
    if (val == null) {
      throw new CastError('number', val, schema.path);
    }
    if (op === '$inc') {
      // Support `$inc` with long, int32, etc. (gh-4283)
      return schema.castForQuery(
        null,
        val,
        context
      );
    }
    try {
      return castNumber(val);
    } catch (error) {
      throw new CastError('number', val, schema.path);
    }
  }
  if (op === '$currentDate') {
    if (typeof val === 'object') {
      return { $type: val.$type };
    }
    return Boolean(val);
  }

  if (mongodbUpdateOperators.has($conditional)) {
    return schema.castForQuery(
      $conditional,
      val,
      context
    );
  }

  if (overwriteOps[op]) {
    const skipQueryCastForUpdate = val != null && schema.$isMongooseArray && schema.$fullPath != null && !schema.$fullPath.match(/\d+$/);
    const applySetters = schema[schemaMixedSymbol] != null;
    if (skipQueryCastForUpdate || applySetters) {
      return schema.applySetters(val, context);
    }
    return schema.castForQuery(
      null,
      val,
      context
    );
  }

  return schema.castForQuery(null, val, context);
}
