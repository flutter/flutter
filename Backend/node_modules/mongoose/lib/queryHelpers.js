'use strict';

/*!
 * Module dependencies
 */

const checkEmbeddedDiscriminatorKeyProjection =
  require('./helpers/discriminator/checkEmbeddedDiscriminatorKeyProjection');
const get = require('./helpers/get');
const getDiscriminatorByValue =
  require('./helpers/discriminator/getDiscriminatorByValue');
const isDefiningProjection = require('./helpers/projection/isDefiningProjection');
const clone = require('./helpers/clone');
const isPathSelectedInclusive = require('./helpers/projection/isPathSelectedInclusive');

/**
 * Prepare a set of path options for query population.
 *
 * @param {Query} query
 * @param {Object} options
 * @return {Array}
 */

exports.preparePopulationOptions = function preparePopulationOptions(query, options) {
  const _populate = query.options.populate;
  const pop = Object.keys(_populate).reduce((vals, key) => vals.concat([_populate[key]]), []);

  // lean options should trickle through all queries
  if (options.lean != null) {
    pop
      .filter(p => (p && p.options && p.options.lean) == null)
      .forEach(makeLean(options.lean));
  }

  pop.forEach(opts => {
    opts._localModel = query.model;
  });

  return pop;
};

/**
 * Prepare a set of path options for query population. This is the MongooseQuery
 * version
 *
 * @param {Query} query
 * @param {Object} options
 * @return {Array}
 */

exports.preparePopulationOptionsMQ = function preparePopulationOptionsMQ(query, options) {
  const _populate = query._mongooseOptions.populate;
  const pop = Object.keys(_populate).reduce((vals, key) => vals.concat([_populate[key]]), []);

  // lean options should trickle through all queries
  if (options.lean != null) {
    pop
      .filter(p => (p && p.options && p.options.lean) == null)
      .forEach(makeLean(options.lean));
  }

  const session = query && query.options && query.options.session || null;
  if (session != null) {
    pop.forEach(path => {
      if (path.options == null) {
        path.options = { session: session };
        return;
      }
      if (!('session' in path.options)) {
        path.options.session = session;
      }
    });
  }

  const projection = query._fieldsForExec();
  pop.forEach(p => {
    p._queryProjection = projection;
  });
  pop.forEach(opts => {
    opts._localModel = query.model;
  });

  return pop;
};

/**
 * If the document is a mapped discriminator type, it returns a model instance for that type, otherwise,
 * it returns an instance of the given model.
 *
 * @param {Model}  model
 * @param {Object} doc
 * @param {Object} fields
 *
 * @return {Document}
 */
exports.createModel = function createModel(model, doc, fields, userProvidedFields, options) {
  model.hooks.execPreSync('createModel', doc);
  const discriminatorMapping = model.schema ?
    model.schema.discriminatorMapping :
    null;

  const key = discriminatorMapping && discriminatorMapping.isRoot ?
    discriminatorMapping.key :
    null;

  const value = doc[key];
  if (key && value && model.discriminators) {
    const discriminator = model.discriminators[value] || getDiscriminatorByValue(model.discriminators, value);
    if (discriminator) {
      const _fields = clone(userProvidedFields);
      exports.applyPaths(_fields, discriminator.schema);
      return new discriminator(undefined, _fields, true);
    }
  }

  const _opts = {
    skipId: true,
    isNew: false,
    willInit: true
  };
  if (options != null && 'defaults' in options) {
    _opts.defaults = options.defaults;
  }
  return new model(undefined, fields, _opts);
};

/*!
 * ignore
 */

exports.createModelAndInit = function createModelAndInit(model, doc, fields, userProvidedFields, options, populatedIds, callback) {
  const initOpts = populatedIds ?
    { populated: populatedIds } :
    undefined;

  const casted = exports.createModel(model, doc, fields, userProvidedFields, options);
  try {
    casted.$init(doc, initOpts, callback);
  } catch (error) {
    callback(error, casted);
  }
};

/*!
 * ignore
 */

exports.applyPaths = function applyPaths(fields, schema) {
  // determine if query is selecting or excluding fields
  let exclude;
  let keys;
  const minusPathsToSkip = new Set();

  if (fields) {
    keys = Object.keys(fields);

    // Collapse minus paths
    const minusPaths = [];
    for (let i = 0; i < keys.length; ++i) {
      const key = keys[i];
      if (keys[i][0] !== '-') {
        continue;
      }

      delete fields[key];
      if (key === '-_id') {
        fields['_id'] = 0;
      } else {
        minusPaths.push(key.slice(1));
      }
    }

    keys = Object.keys(fields);
    for (let keyIndex = 0; keyIndex < keys.length; ++keyIndex) {
      if (keys[keyIndex][0] === '+') {
        continue;
      }
      const field = fields[keys[keyIndex]];
      // Skip `$meta` and `$slice`
      if (!isDefiningProjection(field)) {
        continue;
      }
      if (keys[keyIndex] === '_id' && keys.length > 1) {
        continue;
      }
      if (keys[keyIndex] === schema.options.discriminatorKey && keys.length > 1 && field != null && !field) {
        continue;
      }
      exclude = !field;
      break;
    }

    // Potentially add back minus paths based on schema-level path config
    // and whether the projection is inclusive
    for (const path of minusPaths) {
      const type = schema.path(path);
      // If the path isn't selected by default or the projection is not
      // inclusive, minus path is treated as equivalent to `key: 0`.
      // But we also allow using `-name` to remove `name` from an inclusive
      // projection if `name` has schema-level `select: true`.
      if ((!type || !type.selected) || exclude !== false) {
        fields[path] = 0;
        exclude = true;
      } else if (type && type.selected && exclude === false) {
        // Make a note of minus paths that are overwriting paths that are
        // included by default.
        minusPathsToSkip.add(path);
      }
    }
  }

  // if selecting, apply default schematype select:true fields
  // if excluding, apply schematype select:false fields
  const selected = [];
  const excluded = [];
  const stack = [];

  analyzeSchema(schema);
  switch (exclude) {
    case true:
      for (const fieldName of excluded) {
        fields[fieldName] = 0;
      }
      break;
    case false:
      if (schema &&
          schema.paths['_id'] &&
          schema.paths['_id'].options &&
          schema.paths['_id'].options.select === false) {
        fields._id = 0;
      }

      for (const fieldName of selected) {
        if (minusPathsToSkip.has(fieldName)) {
          continue;
        }
        if (isPathSelectedInclusive(fields, fieldName)) {
          continue;
        }
        fields[fieldName] = fields[fieldName] || 1;
      }
      break;
    case undefined:
      if (fields == null) {
        break;
      }
      // Any leftover plus paths must in the schema, so delete them (gh-7017)
      for (const key of Object.keys(fields || {})) {
        if (key.startsWith('+')) {
          delete fields[key];
        }
      }

      // user didn't specify fields, implies returning all fields.
      // only need to apply excluded fields and delete any plus paths
      for (const fieldName of excluded) {
        if (fields[fieldName] != null) {
          // Skip applying default projections to fields with non-defining
          // projections, like `$slice`
          continue;
        }
        fields[fieldName] = 0;
      }
      break;
  }

  function analyzeSchema(schema, prefix) {
    prefix || (prefix = '');

    // avoid recursion
    if (stack.indexOf(schema) !== -1) {
      return [];
    }
    stack.push(schema);

    const addedPaths = [];
    schema.eachPath(function(path, type) {
      if (prefix) path = prefix + '.' + path;
      if (type.$isSchemaMap || path.endsWith('.$*')) {
        const plusPath = '+' + path;
        const hasPlusPath = fields && plusPath in fields;
        if (type.options && type.options.select === false && !hasPlusPath) {
          excluded.push(path);
        }
        return;
      }
      let addedPath = analyzePath(path, type);
      // arrays
      if (addedPath == null && !Array.isArray(type) && type.$isMongooseArray && !type.$isMongooseDocumentArray) {
        addedPath = analyzePath(path, type.caster);
      }
      if (addedPath != null) {
        addedPaths.push(addedPath);
      }

      // nested schemas
      if (type.schema) {
        const _addedPaths = analyzeSchema(type.schema, path);

        // Special case: if discriminator key is the only field that would
        // be projected in, remove it.
        if (exclude === false) {
          checkEmbeddedDiscriminatorKeyProjection(fields, path, type.schema,
            selected, _addedPaths);
        }
      }
    });
    stack.pop();
    return addedPaths;
  }

  function analyzePath(path, type) {
    if (fields == null) {
      return;
    }

    // If schema-level selected not set, nothing to do
    if (typeof type.selected !== 'boolean') {
      return;
    }

    // User overwriting default exclusion
    if (type.selected === false && fields[path]) {
      return;
    }

    // If set to 0, we're explicitly excluding the discriminator key. Can't do this for all fields,
    // because we have tests that assert that using `-path` to exclude schema-level `select: true`
    // fields counts as an exclusive projection. See gh-11546
    if (!exclude && type.selected && path === schema.options.discriminatorKey && fields[path] != null && !fields[path]) {
      delete fields[path];
      return;
    }

    if (exclude === false && type.selected && fields[path] != null && !fields[path]) {
      delete fields[path];
      return;
    }

    const plusPath = '+' + path;
    const hasPlusPath = fields && plusPath in fields;
    if (hasPlusPath) {
      // forced inclusion
      delete fields[plusPath];

      // if there are other fields being included, add this one
      // if no other included fields, leave this out (implied inclusion)
      if (exclude === false && keys.length > 1 && !~keys.indexOf(path)) {
        fields[path] = 1;
      }

      return;
    }

    // check for parent exclusions
    const pieces = path.split('.');
    let cur = '';
    for (let i = 0; i < pieces.length; ++i) {
      cur += cur.length ? '.' + pieces[i] : pieces[i];
      if (excluded.indexOf(cur) !== -1) {
        return;
      }
    }

    // Special case: if user has included a parent path of a discriminator key,
    // don't explicitly project in the discriminator key because that will
    // project out everything else under the parent path
    if (!exclude && (type && type.options && type.options.$skipDiscriminatorCheck || false)) {
      let cur = '';
      for (let i = 0; i < pieces.length; ++i) {
        cur += (cur.length === 0 ? '' : '.') + pieces[i];
        const projection = get(fields, cur, false) || get(fields, cur + '.$', false);
        if (projection && typeof projection !== 'object') {
          return;
        }
      }
    }

    (type.selected ? selected : excluded).push(path);
    return path;
  }
};

/**
 * Set each path query option to lean
 *
 * @param {Object} option
 */

function makeLean(val) {
  return function(option) {
    option.options || (option.options = {});

    if (val != null && Array.isArray(val.virtuals)) {
      val = Object.assign({}, val);
      val.virtuals = val.virtuals.
        filter(path => typeof path === 'string' && path.startsWith(option.path + '.')).
        map(path => path.slice(option.path.length + 1));
    }

    option.options.lean = val;
  };
}
