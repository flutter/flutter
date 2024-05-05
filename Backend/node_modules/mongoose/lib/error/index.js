'use strict';

/**
 * MongooseError constructor. MongooseError is the base class for all
 * Mongoose-specific errors.
 *
 * #### Example:
 *
 *     const Model = mongoose.model('Test', new mongoose.Schema({ answer: Number }));
 *     const doc = new Model({ answer: 'not a number' });
 *     const err = doc.validateSync();
 *
 *     err instanceof mongoose.Error.ValidationError; // true
 *
 * @constructor Error
 * @param {String} msg Error message
 * @inherits Error https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error
 */

const MongooseError = require('./mongooseError');

/**
 * The name of the error. The name uniquely identifies this Mongoose error. The
 * possible values are:
 *
 * - `MongooseError`: general Mongoose error
 * - `CastError`: Mongoose could not convert a value to the type defined in the schema path. May be in a `ValidationError` class' `errors` property.
 * - `DivergentArrayError`: You attempted to `save()` an array that was modified after you loaded it with a `$elemMatch` or similar projection
 * - `MissingSchemaError`: You tried to access a model with [`mongoose.model()`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.model()) that was not defined
 * - `DocumentNotFoundError`: The document you tried to [`save()`](https://mongoosejs.com/docs/api/document.html#Document.prototype.save()) was not found
 * - `ValidatorError`: error from an individual schema path's validator
 * - `ValidationError`: error returned from [`validate()`](https://mongoosejs.com/docs/api/document.html#Document.prototype.validate()) or [`validateSync()`](https://mongoosejs.com/docs/api/document.html#Document.prototype.validateSync()). Contains zero or more `ValidatorError` instances in `.errors` property.
 * - `MissingSchemaError`: You called `mongoose.Document()` without a schema
 * - `ObjectExpectedError`: Thrown when you set a nested path to a non-object value with [strict mode set](https://mongoosejs.com/docs/guide.html#strict).
 * - `ObjectParameterError`: Thrown when you pass a non-object value to a function which expects an object as a paramter
 * - `OverwriteModelError`: Thrown when you call [`mongoose.model()`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.model()) to re-define a model that was already defined.
 * - `ParallelSaveError`: Thrown when you call [`save()`](https://mongoosejs.com/docs/api/model.html#Model.prototype.save()) on a document when the same document instance is already saving.
 * - `StrictModeError`: Thrown when you set a path that isn't the schema and [strict mode](https://mongoosejs.com/docs/guide.html#strict) is set to `throw`.
 * - `VersionError`: Thrown when the [document is out of sync](https://mongoosejs.com/docs/guide.html#versionKey)
 *
 * @api public
 * @property {String} name
 * @memberOf Error
 * @instance
 */

/*!
 * Module exports.
 */

module.exports = exports = MongooseError;

/**
 * The default built-in validator error messages.
 *
 * @see Error.messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.messages = require('./messages');

// backward compat
MongooseError.Messages = MongooseError.messages;

/**
 * An instance of this error class will be returned when `save()` fails
 * because the underlying
 * document was not found. The constructor takes one parameter, the
 * conditions that mongoose passed to `updateOne()` when trying to update
 * the document.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.DocumentNotFoundError = require('./notFound');

/**
 * An instance of this error class will be returned when mongoose failed to
 * cast a value.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.CastError = require('./cast');

/**
 * An instance of this error class will be returned when [validation](https://mongoosejs.com/docs/validation.html) failed.
 * The `errors` property contains an object whose keys are the paths that failed and whose values are
 * instances of CastError or ValidationError.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.ValidationError = require('./validation');

/**
 * A `ValidationError` has a hash of `errors` that contain individual
 * `ValidatorError` instances.
 *
 * #### Example:
 *
 *     const schema = Schema({ name: { type: String, required: true } });
 *     const Model = mongoose.model('Test', schema);
 *     const doc = new Model({});
 *
 *     // Top-level error is a ValidationError, **not** a ValidatorError
 *     const err = doc.validateSync();
 *     err instanceof mongoose.Error.ValidationError; // true
 *
 *     // A ValidationError `err` has 0 or more ValidatorErrors keyed by the
 *     // path in the `err.errors` property.
 *     err.errors['name'] instanceof mongoose.Error.ValidatorError;
 *
 *     err.errors['name'].kind; // 'required'
 *     err.errors['name'].path; // 'name'
 *     err.errors['name'].value; // undefined
 *
 * Instances of `ValidatorError` have the following properties:
 *
 * - `kind`: The validator's `type`, like `'required'` or `'regexp'`
 * - `path`: The path that failed validation
 * - `value`: The value that failed validation
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.ValidatorError = require('./validator');

/**
 * An instance of this error class will be returned when you call `save()` after
 * the document in the database was changed in a potentially unsafe way. See
 * the [`versionKey` option](https://mongoosejs.com/docs/guide.html#versionKey) for more information.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.VersionError = require('./version');

/**
 * An instance of this error class will be returned when you call `save()` multiple
 * times on the same document in parallel. See the [FAQ](https://mongoosejs.com/docs/faq.html) for more
 * information.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.ParallelSaveError = require('./parallelSave');

/**
 * Thrown when a model with the given name was already registered on the connection.
 * See [the FAQ about `OverwriteModelError`](https://mongoosejs.com/docs/faq.html#overwrite-model-error).
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.OverwriteModelError = require('./overwriteModel');

/**
 * Thrown when you try to access a model that has not been registered yet
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.MissingSchemaError = require('./missingSchema');

/**
 * Thrown when the MongoDB Node driver can't connect to a valid server
 * to send an operation to.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.MongooseServerSelectionError = require('./serverSelection');

/**
 * An instance of this error will be returned if you used an array projection
 * and then modified the array in an unsafe way.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.DivergentArrayError = require('./divergentArray');

/**
 * Thrown when your try to pass values to model constructor that
 * were not specified in schema or change immutable properties when
 * `strict` mode is `"throw"`
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.StrictModeError = require('./strict');

/**
 * An instance of this error class will be returned when mongoose failed to
 * populate with a path that is not existing.
 *
 * @api public
 * @memberOf Error
 * @static
 */

MongooseError.StrictPopulateError = require('./strictPopulate');
