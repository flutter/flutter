'use strict';

const MongooseError = require('../../error/index');
const SkipPopulateValue = require('./skipPopulateValue');
const clone = require('../clone');
const get = require('../get');
const getDiscriminatorByValue = require('../discriminator/getDiscriminatorByValue');
const getConstructorName = require('../getConstructorName');
const getSchemaTypes = require('./getSchemaTypes');
const getVirtual = require('./getVirtual');
const lookupLocalFields = require('./lookupLocalFields');
const mpath = require('mpath');
const modelNamesFromRefPath = require('./modelNamesFromRefPath');
const utils = require('../../utils');

const modelSymbol = require('../symbols').modelSymbol;
const populateModelSymbol = require('../symbols').populateModelSymbol;
const schemaMixedSymbol = require('../../schema/symbols').schemaMixedSymbol;
const StrictPopulate = require('../../error/strictPopulate');

module.exports = function getModelsMapForPopulate(model, docs, options) {
  let doc;
  const len = docs.length;
  const map = [];
  const modelNameFromQuery = options.model && options.model.modelName || options.model;
  let schema;
  let refPath;
  let modelNames;
  const available = {};

  const modelSchema = model.schema;

  // Populating a nested path should always be a no-op re: #9073.
  // People shouldn't do this, but apparently they do.
  if (options._localModel != null && options._localModel.schema.nested[options.path]) {
    return [];
  }

  const _virtualRes = getVirtual(model.schema, options.path);
  const virtual = _virtualRes == null ? null : _virtualRes.virtual;
  if (virtual != null) {
    return _virtualPopulate(model, docs, options, _virtualRes);
  }

  let allSchemaTypes = getSchemaTypes(model, modelSchema, null, options.path);
  allSchemaTypes = Array.isArray(allSchemaTypes) ? allSchemaTypes : [allSchemaTypes].filter(v => v != null);

  const isStrictPopulateDisabled = options.strictPopulate === false || options.options?.strictPopulate === false;
  if (!isStrictPopulateDisabled && allSchemaTypes.length === 0 && options._localModel != null) {
    return new StrictPopulate(options._fullPath || options.path);
  }

  for (let i = 0; i < len; i++) {
    doc = docs[i];
    let justOne = null;

    const docSchema = doc != null && doc.$__ != null ? doc.$__schema : modelSchema;
    schema = getSchemaTypes(model, docSchema, doc, options.path);

    // Special case: populating a path that's a DocumentArray unless
    // there's an explicit `ref` or `refPath` re: gh-8946
    if (schema != null &&
        schema.$isMongooseDocumentArray &&
        schema.options.ref == null &&
        schema.options.refPath == null) {
      continue;
    }
    const isUnderneathDocArray = schema && schema.$parentSchemaDocArray;
    if (isUnderneathDocArray && get(options, 'options.sort') != null) {
      return new MongooseError('Cannot populate with `sort` on path ' + options.path +
        ' because it is a subproperty of a document array');
    }

    modelNames = null;
    let isRefPath = false;
    let normalizedRefPath = null;
    let schemaOptions = null;
    let modelNamesInOrder = null;

    if (schema != null && schema.instance === 'Embedded') {
      if (schema.options.ref) {
        const data = {
          localField: options.path + '._id',
          foreignField: '_id',
          justOne: true
        };
        const res = _getModelNames(doc, schema, modelNameFromQuery, model);

        const unpopulatedValue = mpath.get(options.path, doc);
        const id = mpath.get('_id', unpopulatedValue);
        addModelNamesToMap(model, map, available, res.modelNames, options, data, id, doc, schemaOptions, unpopulatedValue);
      }
      // No-op if no `ref` set. See gh-11538
      continue;
    }

    if (Array.isArray(schema)) {
      const schemasArray = schema;
      for (const _schema of schemasArray) {
        let _modelNames;
        let res;
        try {
          res = _getModelNames(doc, _schema, modelNameFromQuery, model);
          _modelNames = res.modelNames;
          isRefPath = isRefPath || res.isRefPath;
          normalizedRefPath = normalizedRefPath || res.refPath;
          justOne = res.justOne;
        } catch (error) {
          return error;
        }

        if (isRefPath && !res.isRefPath) {
          continue;
        }
        if (!_modelNames) {
          continue;
        }
        modelNames = modelNames || [];
        for (const modelName of _modelNames) {
          if (modelNames.indexOf(modelName) === -1) {
            modelNames.push(modelName);
          }
        }
      }
    } else {
      try {
        const res = _getModelNames(doc, schema, modelNameFromQuery, model);
        modelNames = res.modelNames;
        isRefPath = res.isRefPath;
        normalizedRefPath = normalizedRefPath || res.refPath;
        justOne = res.justOne;
        schemaOptions = get(schema, 'options.populate', null);
        // Dedupe, because `refPath` can return duplicates of the same model name,
        // and that causes perf issues.
        if (isRefPath) {
          modelNamesInOrder = modelNames;
          modelNames = Array.from(new Set(modelNames));
        }
      } catch (error) {
        return error;
      }

      if (!modelNames) {
        continue;
      }
    }

    const data = {};
    const localField = options.path;
    const foreignField = '_id';

    // `justOne = null` means we don't know from the schema whether the end
    // result should be an array or a single doc. This can result from
    // populating a POJO using `Model.populate()`
    if ('justOne' in options && options.justOne !== void 0) {
      justOne = options.justOne;
    } else if (schema && !schema[schemaMixedSymbol]) {
      // Skip Mixed types because we explicitly don't do casting on those.
      if (options.path.endsWith('.' + schema.path) || options.path === schema.path) {
        justOne = Array.isArray(schema) ?
          schema.every(schema => !schema.$isMongooseArray) :
          !schema.$isMongooseArray;
      }
    }

    if (!modelNames) {
      continue;
    }

    data.isVirtual = false;
    data.justOne = justOne;
    data.localField = localField;
    data.foreignField = foreignField;

    // Get local fields
    const ret = _getLocalFieldValues(doc, localField, model, options, null, schema);

    const id = String(utils.getValue(foreignField, doc));
    options._docs[id] = Array.isArray(ret) ? ret.slice() : ret;

    let match = get(options, 'match', null);

    const hasMatchFunction = typeof match === 'function';
    if (hasMatchFunction) {
      match = match.call(doc, doc);
    }
    data.match = match;
    data.hasMatchFunction = hasMatchFunction;
    data.isRefPath = isRefPath;
    data.modelNamesInOrder = modelNamesInOrder;

    if (isRefPath) {
      const embeddedDiscriminatorModelNames = _findRefPathForDiscriminators(doc,
        modelSchema, data, options, normalizedRefPath, ret);

      modelNames = embeddedDiscriminatorModelNames || modelNames;
    }

    try {
      addModelNamesToMap(model, map, available, modelNames, options, data, ret, doc, schemaOptions);
    } catch (err) {
      return err;
    }
  }
  return map;

  function _getModelNames(doc, schema, modelNameFromQuery, model) {
    let modelNames;
    let isRefPath = false;
    let justOne = null;

    const originalSchema = schema;
    if (schema && schema.instance === 'Array') {
      schema = schema.caster;
    }
    if (schema && schema.$isSchemaMap) {
      schema = schema.$__schemaType;
    }

    const ref = schema && schema.options && schema.options.ref;
    refPath = schema && schema.options && schema.options.refPath;
    if (schema != null &&
        schema[schemaMixedSymbol] &&
        !ref &&
        !refPath &&
        !modelNameFromQuery) {
      return { modelNames: null };
    }

    if (modelNameFromQuery) {
      modelNames = [modelNameFromQuery]; // query options
    } else if (refPath != null) {
      if (typeof refPath === 'function') {
        const subdocPath = options.path.slice(0, options.path.length - schema.path.length - 1);
        const vals = mpath.get(subdocPath, doc, lookupLocalFields);
        const subdocsBeingPopulated = Array.isArray(vals) ?
          utils.array.flatten(vals) :
          (vals ? [vals] : []);

        modelNames = new Set();
        for (const subdoc of subdocsBeingPopulated) {
          refPath = refPath.call(subdoc, subdoc, options.path);
          modelNamesFromRefPath(refPath, doc, options.path, modelSchema, options._queryProjection).
            forEach(name => modelNames.add(name));
        }
        modelNames = Array.from(modelNames);
      } else {
        modelNames = modelNamesFromRefPath(refPath, doc, options.path, modelSchema, options._queryProjection);
      }

      isRefPath = true;
    } else {
      let ref;
      let refPath;
      let schemaForCurrentDoc;
      let discriminatorValue;
      let modelForCurrentDoc = model;
      const discriminatorKey = model.schema.options.discriminatorKey;

      if (!schema && discriminatorKey && (discriminatorValue = utils.getValue(discriminatorKey, doc))) {
        // `modelNameForFind` is the discriminator value, so we might need
        // find the discriminated model name
        const discriminatorModel = getDiscriminatorByValue(model.discriminators, discriminatorValue) || model;
        if (discriminatorModel != null) {
          modelForCurrentDoc = discriminatorModel;
        } else {
          try {
            modelForCurrentDoc = _getModelFromConn(model.db, discriminatorValue);
          } catch (error) {
            return error;
          }
        }

        schemaForCurrentDoc = modelForCurrentDoc.schema._getSchema(options.path);

        if (schemaForCurrentDoc && schemaForCurrentDoc.caster) {
          schemaForCurrentDoc = schemaForCurrentDoc.caster;
        }
      } else {
        schemaForCurrentDoc = schema;
      }

      if (originalSchema && originalSchema.path.endsWith('.$*')) {
        justOne = !originalSchema.$isMongooseArray && !originalSchema._arrayPath;
      } else if (schemaForCurrentDoc != null) {
        justOne = !schemaForCurrentDoc.$isMongooseArray && !schemaForCurrentDoc._arrayPath;
      }

      if ((ref = get(schemaForCurrentDoc, 'options.ref')) != null) {
        if (schemaForCurrentDoc != null &&
            typeof ref === 'function' &&
            options.path.endsWith('.' + schemaForCurrentDoc.path)) {
          // Ensure correct context for ref functions: subdoc, not top-level doc. See gh-8469
          modelNames = new Set();

          const subdocPath = options.path.slice(0, options.path.length - schemaForCurrentDoc.path.length - 1);
          const vals = mpath.get(subdocPath, doc, lookupLocalFields);
          const subdocsBeingPopulated = Array.isArray(vals) ?
            utils.array.flatten(vals) :
            (vals ? [vals] : []);
          for (const subdoc of subdocsBeingPopulated) {
            modelNames.add(handleRefFunction(ref, subdoc));
          }

          if (subdocsBeingPopulated.length === 0) {
            modelNames = [handleRefFunction(ref, doc)];
          } else {
            modelNames = Array.from(modelNames);
          }
        } else {
          ref = handleRefFunction(ref, doc);
          modelNames = [ref];
        }
      } else if ((schemaForCurrentDoc = get(schema, 'options.refPath')) != null) {
        isRefPath = true;
        if (typeof refPath === 'function') {
          const subdocPath = options.path.slice(0, options.path.length - schemaForCurrentDoc.path.length - 1);
          const vals = mpath.get(subdocPath, doc, lookupLocalFields);
          const subdocsBeingPopulated = Array.isArray(vals) ?
            utils.array.flatten(vals) :
            (vals ? [vals] : []);

          modelNames = new Set();
          for (const subdoc of subdocsBeingPopulated) {
            refPath = refPath.call(subdoc, subdoc, options.path);
            modelNamesFromRefPath(refPath, doc, options.path, modelSchema, options._queryProjection).
              forEach(name => modelNames.add(name));
          }
          modelNames = Array.from(modelNames);
        } else {
          modelNames = modelNamesFromRefPath(refPath, doc, options.path, modelSchema, options._queryProjection);
        }
      }
    }

    if (!modelNames) {
      // `Model.populate()` on a POJO with no known local model. Default to using the `Model`
      if (options._localModel == null) {
        modelNames = [model.modelName];
      } else {
        return { modelNames: modelNames, justOne: justOne, isRefPath: isRefPath, refPath: refPath };
      }
    }

    if (!Array.isArray(modelNames)) {
      modelNames = [modelNames];
    }

    return { modelNames: modelNames, justOne: justOne, isRefPath: isRefPath, refPath: refPath };
  }
};

/*!
 * ignore
 */

function _virtualPopulate(model, docs, options, _virtualRes) {
  const map = [];
  const available = {};
  const virtual = _virtualRes.virtual;

  for (const doc of docs) {
    let modelNames = null;
    const data = {};

    // localField and foreignField
    let localField;
    const virtualPrefix = _virtualRes.nestedSchemaPath ?
      _virtualRes.nestedSchemaPath + '.' : '';
    if (typeof options.localField === 'string') {
      localField = options.localField;
    } else if (typeof virtual.options.localField === 'function') {
      localField = virtualPrefix + virtual.options.localField.call(doc, doc);
    } else if (Array.isArray(virtual.options.localField)) {
      localField = virtual.options.localField.map(field => virtualPrefix + field);
    } else {
      localField = virtualPrefix + virtual.options.localField;
    }
    data.count = virtual.options.count;

    if (virtual.options.skip != null && !options.hasOwnProperty('skip')) {
      options.skip = virtual.options.skip;
    }
    if (virtual.options.limit != null && !options.hasOwnProperty('limit')) {
      options.limit = virtual.options.limit;
    }
    if (virtual.options.perDocumentLimit != null && !options.hasOwnProperty('perDocumentLimit')) {
      options.perDocumentLimit = virtual.options.perDocumentLimit;
    }
    let foreignField = virtual.options.foreignField;

    if (!localField || !foreignField) {
      return new MongooseError(`Cannot populate virtual \`${options.path}\` on model \`${model.modelName}\`, because options \`localField\` and / or \`foreignField\` are missing`);
    }

    if (typeof localField === 'function') {
      localField = localField.call(doc, doc);
    }
    if (typeof foreignField === 'function') {
      foreignField = foreignField.call(doc, doc);
    }

    data.isRefPath = false;

    // `justOne = null` means we don't know from the schema whether the end
    // result should be an array or a single doc. This can result from
    // populating a POJO using `Model.populate()`
    let justOne = null;
    if ('justOne' in options && options.justOne !== void 0) {
      justOne = options.justOne;
    }

    if (virtual.options.refPath) {
      modelNames =
        modelNamesFromRefPath(virtual.options.refPath, doc, options.path);
      justOne = !!virtual.options.justOne;
      data.isRefPath = true;
    } else if (virtual.options.ref) {
      let normalizedRef;
      if (typeof virtual.options.ref === 'function' && !virtual.options.ref[modelSymbol]) {
        normalizedRef = virtual.options.ref.call(doc, doc);
      } else {
        normalizedRef = virtual.options.ref;
      }
      justOne = !!virtual.options.justOne;
      // When referencing nested arrays, the ref should be an Array
      // of modelNames.
      if (Array.isArray(normalizedRef)) {
        modelNames = normalizedRef;
      } else {
        modelNames = [normalizedRef];
      }
    }

    data.isVirtual = true;
    data.virtual = virtual;
    data.justOne = justOne;

    // `match`
    const baseMatch = get(data, 'virtual.options.match', null) ||
      get(data, 'virtual.options.options.match', null);
    let match = get(options, 'match', null) || baseMatch;

    let hasMatchFunction = typeof match === 'function';
    if (hasMatchFunction) {
      match = match.call(doc, doc, data.virtual);
    }

    if (Array.isArray(localField) && Array.isArray(foreignField) && localField.length === foreignField.length) {
      match = Object.assign({}, match);
      for (let i = 1; i < localField.length; ++i) {
        match[foreignField[i]] = convertTo_id(mpath.get(localField[i], doc, lookupLocalFields), model.schema);
        hasMatchFunction = true;
      }

      localField = localField[0];
      foreignField = foreignField[0];
    }
    data.localField = localField;
    data.foreignField = foreignField;
    data.match = match;
    data.hasMatchFunction = hasMatchFunction;

    // Get local fields
    const ret = _getLocalFieldValues(doc, localField, model, options, virtual);

    try {
      addModelNamesToMap(model, map, available, modelNames, options, data, ret, doc);
    } catch (err) {
      return err;
    }
  }

  return map;
}

/*!
 * ignore
 */

function addModelNamesToMap(model, map, available, modelNames, options, data, ret, doc, schemaOptions, unpopulatedValue) {
  // `PopulateOptions#connection`: if the model is passed as a string, the
  // connection matters because different connections have different models.
  const connection = options.connection != null ? options.connection : model.db;

  unpopulatedValue = unpopulatedValue === void 0 ? ret : unpopulatedValue;
  if (Array.isArray(unpopulatedValue)) {
    unpopulatedValue = utils.cloneArrays(unpopulatedValue);
  }

  if (modelNames == null) {
    return;
  }

  let k = modelNames.length;
  while (k--) {
    let modelName = modelNames[k];
    if (modelName == null) {
      continue;
    }

    let Model;
    if (options.model && options.model[modelSymbol]) {
      Model = options.model;
    } else if (modelName[modelSymbol]) {
      Model = modelName;
      modelName = Model.modelName;
    } else {
      try {
        Model = _getModelFromConn(connection, modelName);
      } catch (err) {
        if (ret !== void 0) {
          throw err;
        }
        Model = null;
      }
    }

    let ids = ret;
    const flat = Array.isArray(ret) ? utils.array.flatten(ret) : [];

    const modelNamesForRefPath = data.modelNamesInOrder ? data.modelNamesInOrder : modelNames;
    if (data.isRefPath && Array.isArray(ret) && flat.length === modelNamesForRefPath.length) {
      ids = flat.filter((val, i) => modelNamesForRefPath[i] === modelName);
    }

    const perDocumentLimit = options.perDocumentLimit == null ?
      get(options, 'options.perDocumentLimit', null) :
      options.perDocumentLimit;

    if (!available[modelName] || perDocumentLimit != null) {
      const currentOptions = {
        model: Model
      };
      if (data.isVirtual && get(data.virtual, 'options.options')) {
        currentOptions.options = clone(data.virtual.options.options);
      } else if (schemaOptions != null) {
        currentOptions.options = Object.assign({}, schemaOptions);
      }
      utils.merge(currentOptions, options);

      // Used internally for checking what model was used to populate this
      // path.
      options[populateModelSymbol] = Model;
      currentOptions[populateModelSymbol] = Model;
      available[modelName] = {
        model: Model,
        options: currentOptions,
        match: data.hasMatchFunction ? [data.match] : data.match,
        docs: [doc],
        ids: [ids],
        allIds: [ret],
        unpopulatedValues: [unpopulatedValue],
        localField: new Set([data.localField]),
        foreignField: new Set([data.foreignField]),
        justOne: data.justOne,
        isVirtual: data.isVirtual,
        virtual: data.virtual,
        count: data.count,
        [populateModelSymbol]: Model
      };
      map.push(available[modelName]);
    } else {
      available[modelName].localField.add(data.localField);
      available[modelName].foreignField.add(data.foreignField);
      available[modelName].docs.push(doc);
      available[modelName].ids.push(ids);
      available[modelName].allIds.push(ret);
      available[modelName].unpopulatedValues.push(unpopulatedValue);
      if (data.hasMatchFunction) {
        available[modelName].match.push(data.match);
      }
    }
  }
}

function _getModelFromConn(conn, modelName) {
  /* If this connection has a parent from `useDb()`, bubble up to parent's models */
  if (conn.models[modelName] == null && conn._parent != null) {
    return _getModelFromConn(conn._parent, modelName);
  }

  return conn.model(modelName);
}

/*!
 * ignore
 */

function handleRefFunction(ref, doc) {
  if (typeof ref === 'function' && !ref[modelSymbol]) {
    return ref.call(doc, doc);
  }
  return ref;
}

/*!
 * ignore
 */

function _getLocalFieldValues(doc, localField, model, options, virtual, schema) {
  // Get Local fields
  const localFieldPathType = model.schema._getPathType(localField);
  const localFieldPath = localFieldPathType === 'real' ?
    model.schema.path(localField) :
    localFieldPathType.schema;
  const localFieldGetters = localFieldPath && localFieldPath.getters ?
    localFieldPath.getters : [];

  localField = localFieldPath != null && localFieldPath.instance === 'Embedded' ? localField + '._id' : localField;

  const _populateOptions = get(options, 'options', {});

  const getters = 'getters' in _populateOptions ?
    _populateOptions.getters :
    get(virtual, 'options.getters', false);
  if (localFieldGetters.length !== 0 && getters) {
    const hydratedDoc = (doc.$__ != null) ? doc : model.hydrate(doc);
    const localFieldValue = utils.getValue(localField, doc);
    if (Array.isArray(localFieldValue)) {
      const localFieldHydratedValue = utils.getValue(localField.split('.').slice(0, -1), hydratedDoc);
      return localFieldValue.map((localFieldArrVal, localFieldArrIndex) =>
        localFieldPath.applyGetters(localFieldArrVal, localFieldHydratedValue[localFieldArrIndex]));
    } else {
      return localFieldPath.applyGetters(localFieldValue, hydratedDoc);
    }
  } else {
    return convertTo_id(mpath.get(localField, doc, lookupLocalFields), schema);
  }
}

/**
 * Retrieve the _id of `val` if a Document or Array of Documents.
 *
 * @param {Array|Document|Any} val
 * @param {Schema} schema
 * @return {Array|Document|Any}
 * @api private
 */

function convertTo_id(val, schema) {
  if (val != null && val.$__ != null) {
    return val._id;
  }
  if (val != null && val._id != null && (schema == null || !schema.$isSchemaMap)) {
    return val._id;
  }

  if (Array.isArray(val)) {
    const rawVal = val.__array != null ? val.__array : val;
    for (let i = 0; i < rawVal.length; ++i) {
      if (rawVal[i] != null && rawVal[i].$__ != null) {
        rawVal[i] = rawVal[i]._id;
      }
    }
    if (utils.isMongooseArray(val) && val.$schema()) {
      return val.$schema()._castForPopulate(val, val.$parent());
    }

    return [].concat(val);
  }

  // `populate('map')` may be an object if populating on a doc that hasn't
  // been hydrated yet
  if (getConstructorName(val) === 'Object' &&
      // The intent here is we should only flatten the object if we expect
      // to get a Map in the end. Avoid doing this for mixed types.
      (schema == null || schema[schemaMixedSymbol] == null)) {
    const ret = [];
    for (const key of Object.keys(val)) {
      ret.push(val[key]);
    }
    return ret;
  }
  // If doc has already been hydrated, e.g. `doc.populate('map')`
  // then `val` will already be a map
  if (val instanceof Map) {
    return Array.from(val.values());
  }

  return val;
}

/*!
 * ignore
 */

function _findRefPathForDiscriminators(doc, modelSchema, data, options, normalizedRefPath, ret) {
  // Re: gh-8452. Embedded discriminators may not have `refPath`, so clear
  // out embedded discriminator docs that don't have a `refPath` on the
  // populated path.
  if (!data.isRefPath || normalizedRefPath == null) {
    return;
  }

  const pieces = normalizedRefPath.split('.');
  let cur = '';
  let modelNames = void 0;
  for (let i = 0; i < pieces.length; ++i) {
    const piece = pieces[i];
    cur = cur + (cur.length === 0 ? '' : '.') + piece;
    const schematype = modelSchema.path(cur);
    if (schematype != null &&
        schematype.$isMongooseArray &&
        schematype.caster.discriminators != null &&
        Object.keys(schematype.caster.discriminators).length !== 0) {
      const subdocs = utils.getValue(cur, doc);
      const remnant = options.path.substring(cur.length + 1);
      const discriminatorKey = schematype.caster.schema.options.discriminatorKey;
      modelNames = [];
      for (const subdoc of subdocs) {
        const discriminatorName = utils.getValue(discriminatorKey, subdoc);
        const discriminator = schematype.caster.discriminators[discriminatorName];
        const discriminatorSchema = discriminator && discriminator.schema;
        if (discriminatorSchema == null) {
          continue;
        }
        const _path = discriminatorSchema.path(remnant);
        if (_path == null || _path.options.refPath == null) {
          const docValue = utils.getValue(data.localField.substring(cur.length + 1), subdoc);
          ret.forEach((v, i) => {
            if (v === docValue) {
              ret[i] = SkipPopulateValue(v);
            }
          });
          continue;
        }
        const modelName = utils.getValue(pieces.slice(i + 1).join('.'), subdoc);
        modelNames.push(modelName);
      }
    }
  }

  return modelNames;
}
