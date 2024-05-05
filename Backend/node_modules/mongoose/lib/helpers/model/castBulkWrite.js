'use strict';

const MongooseError = require('../../error/mongooseError');
const getDiscriminatorByValue = require('../../helpers/discriminator/getDiscriminatorByValue');
const applyTimestampsToChildren = require('../update/applyTimestampsToChildren');
const applyTimestampsToUpdate = require('../update/applyTimestampsToUpdate');
const cast = require('../../cast');
const castUpdate = require('../query/castUpdate');
const clone = require('../clone');
const decorateUpdateWithVersionKey = require('../update/decorateUpdateWithVersionKey');
const { inspect } = require('util');
const setDefaultsOnInsert = require('../setDefaultsOnInsert');

/**
 * Given a model and a bulkWrite op, return a thunk that handles casting and
 * validating the individual op.
 * @param {Model} originalModel
 * @param {Object} op
 * @param {Object} [options]
 * @api private
 */

module.exports = function castBulkWrite(originalModel, op, options) {
  const now = originalModel.base.now();

  const globalSetDefaultsOnInsert = originalModel.base.options.setDefaultsOnInsert;
  if (op['insertOne']) {
    return (callback) => {
      const model = decideModelByObject(originalModel, op['insertOne']['document']);

      const doc = new model(op['insertOne']['document']);
      if (model.schema.options.timestamps && options.timestamps !== false) {
        doc.initializeTimestamps();
      }
      if (options.session != null) {
        doc.$session(options.session);
      }
      const versionKey = model?.schema?.options?.versionKey;
      if (versionKey && doc[versionKey] == null) {
        doc[versionKey] = 0;
      }
      op['insertOne']['document'] = doc;

      if (options.skipValidation || op['insertOne'].skipValidation) {
        callback(null);
        return;
      }

      op['insertOne']['document'].$validate().then(
        () => { callback(null); },
        err => { callback(err, null); }
      );
    };
  } else if (op['updateOne']) {
    return (callback) => {
      try {
        if (!op['updateOne']['filter']) {
          throw new Error('Must provide a filter object.');
        }
        if (!op['updateOne']['update']) {
          throw new Error('Must provide an update object.');
        }

        const model = decideModelByObject(originalModel, op['updateOne']['filter']);
        const schema = model.schema;
        const strict = options.strict != null ? options.strict : model.schema.options.strict;

        const update = clone(op['updateOne']['update']);

        _addDiscriminatorToObject(schema, op['updateOne']['filter']);

        if (model.schema.$timestamps != null && op['updateOne'].timestamps !== false) {
          const createdAt = model.schema.$timestamps.createdAt;
          const updatedAt = model.schema.$timestamps.updatedAt;
          applyTimestampsToUpdate(now, createdAt, updatedAt, update, {});
        }

        if (op['updateOne'].timestamps !== false) {
          applyTimestampsToChildren(now, update, model.schema);
        }

        const shouldSetDefaultsOnInsert = op['updateOne'].setDefaultsOnInsert == null ?
          globalSetDefaultsOnInsert :
          op['updateOne'].setDefaultsOnInsert;
        if (shouldSetDefaultsOnInsert !== false) {
          setDefaultsOnInsert(op['updateOne']['filter'], model.schema, update, {
            setDefaultsOnInsert: true,
            upsert: op['updateOne'].upsert
          });
        }

        decorateUpdateWithVersionKey(
          update,
          op['updateOne'],
          model.schema.options.versionKey
        );

        op['updateOne']['filter'] = cast(model.schema, op['updateOne']['filter'], {
          strict: strict,
          upsert: op['updateOne'].upsert
        });
        op['updateOne']['update'] = castUpdate(model.schema, update, {
          strict: strict,
          upsert: op['updateOne'].upsert
        }, model, op['updateOne']['filter']);
      } catch (error) {
        return callback(error, null);
      }

      callback(null);
    };
  } else if (op['updateMany']) {
    return (callback) => {
      try {
        if (!op['updateMany']['filter']) {
          throw new Error('Must provide a filter object.');
        }
        if (!op['updateMany']['update']) {
          throw new Error('Must provide an update object.');
        }

        const model = decideModelByObject(originalModel, op['updateMany']['filter']);
        const schema = model.schema;
        const strict = options.strict != null ? options.strict : model.schema.options.strict;

        const shouldSetDefaultsOnInsert = op['updateMany'].setDefaultsOnInsert == null ?
          globalSetDefaultsOnInsert :
          op['updateMany'].setDefaultsOnInsert;

        if (shouldSetDefaultsOnInsert !== false) {
          setDefaultsOnInsert(op['updateMany']['filter'], model.schema, op['updateMany']['update'], {
            setDefaultsOnInsert: true,
            upsert: op['updateMany'].upsert
          });
        }

        if (model.schema.$timestamps != null && op['updateMany'].timestamps !== false) {
          const createdAt = model.schema.$timestamps.createdAt;
          const updatedAt = model.schema.$timestamps.updatedAt;
          applyTimestampsToUpdate(now, createdAt, updatedAt, op['updateMany']['update'], {});
        }
        if (op['updateMany'].timestamps !== false) {
          applyTimestampsToChildren(now, op['updateMany']['update'], model.schema);
        }

        _addDiscriminatorToObject(schema, op['updateMany']['filter']);

        decorateUpdateWithVersionKey(
          op['updateMany']['update'],
          op['updateMany'],
          model.schema.options.versionKey
        );

        op['updateMany']['filter'] = cast(model.schema, op['updateMany']['filter'], {
          strict: strict,
          upsert: op['updateMany'].upsert
        });

        op['updateMany']['update'] = castUpdate(model.schema, op['updateMany']['update'], {
          strict: strict,
          upsert: op['updateMany'].upsert
        }, model, op['updateMany']['filter']);
      } catch (error) {
        return callback(error, null);
      }

      callback(null);
    };
  } else if (op['replaceOne']) {
    return (callback) => {
      const model = decideModelByObject(originalModel, op['replaceOne']['filter']);
      const schema = model.schema;
      const strict = options.strict != null ? options.strict : model.schema.options.strict;

      _addDiscriminatorToObject(schema, op['replaceOne']['filter']);
      try {
        op['replaceOne']['filter'] = cast(model.schema, op['replaceOne']['filter'], {
          strict: strict,
          upsert: op['replaceOne'].upsert
        });
      } catch (error) {
        return callback(error, null);
      }

      // set `skipId`, otherwise we get "_id field cannot be changed"
      const doc = new model(op['replaceOne']['replacement'], strict, true);
      if (model.schema.options.timestamps) {
        doc.initializeTimestamps();
      }
      if (options.session != null) {
        doc.$session(options.session);
      }
      const versionKey = model?.schema?.options?.versionKey;
      if (versionKey && doc[versionKey] == null) {
        doc[versionKey] = 0;
      }
      op['replaceOne']['replacement'] = doc;

      if (options.skipValidation || op['replaceOne'].skipValidation) {
        op['replaceOne']['replacement'] = op['replaceOne']['replacement'].toBSON();
        callback(null);
        return;
      }

      op['replaceOne']['replacement'].$validate().then(
        () => {
          op['replaceOne']['replacement'] = op['replaceOne']['replacement'].toBSON();
          callback(null);
        },
        error => {
          callback(error, null);
        }
      );
    };
  } else if (op['deleteOne']) {
    return (callback) => {
      const model = decideModelByObject(originalModel, op['deleteOne']['filter']);
      const schema = model.schema;

      _addDiscriminatorToObject(schema, op['deleteOne']['filter']);

      try {
        op['deleteOne']['filter'] = cast(model.schema,
          op['deleteOne']['filter']);
      } catch (error) {
        return callback(error, null);
      }

      callback(null);
    };
  } else if (op['deleteMany']) {
    return (callback) => {
      const model = decideModelByObject(originalModel, op['deleteMany']['filter']);
      const schema = model.schema;

      _addDiscriminatorToObject(schema, op['deleteMany']['filter']);

      try {
        op['deleteMany']['filter'] = cast(model.schema,
          op['deleteMany']['filter']);
      } catch (error) {
        return callback(error, null);
      }

      callback(null);
    };
  } else {
    return (callback) => {
      const error = new MongooseError(`Invalid op passed to \`bulkWrite()\`: ${inspect(op)}`);
      callback(error, null);
    };
  }
};

function _addDiscriminatorToObject(schema, obj) {
  if (schema == null) {
    return;
  }
  if (schema.discriminatorMapping && !schema.discriminatorMapping.isRoot) {
    obj[schema.discriminatorMapping.key] = schema.discriminatorMapping.value;
  }
}

/**
 * gets discriminator model if discriminator key is present in object
 * @api private
 */

function decideModelByObject(model, object) {
  const discriminatorKey = model.schema.options.discriminatorKey;
  if (object != null && object.hasOwnProperty(discriminatorKey)) {
    model = getDiscriminatorByValue(model.discriminators, object[discriminatorKey]) || model;
  }
  return model;
}
