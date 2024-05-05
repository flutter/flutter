'use strict';

/*!
 * Module dependencies.
 */

const CastError = require('./error/cast');
const DocumentNotFoundError = require('./error/notFound');
const Kareem = require('kareem');
const MongooseError = require('./error/mongooseError');
const ObjectParameterError = require('./error/objectParameter');
const QueryCursor = require('./cursor/queryCursor');
const ValidationError = require('./error/validation');
const { applyGlobalMaxTimeMS, applyGlobalDiskUse } = require('./helpers/query/applyGlobalOption');
const handleReadPreferenceAliases = require('./helpers/query/handleReadPreferenceAliases');
const applyWriteConcern = require('./helpers/schema/applyWriteConcern');
const cast = require('./cast');
const castArrayFilters = require('./helpers/update/castArrayFilters');
const castNumber = require('./cast/number');
const castUpdate = require('./helpers/query/castUpdate');
const clone = require('./helpers/clone');
const getDiscriminatorByValue = require('./helpers/discriminator/getDiscriminatorByValue');
const helpers = require('./queryHelpers');
const immediate = require('./helpers/immediate');
const internalToObjectOptions = require('./options').internalToObjectOptions;
const isExclusive = require('./helpers/projection/isExclusive');
const isInclusive = require('./helpers/projection/isInclusive');
const isPathSelectedInclusive = require('./helpers/projection/isPathSelectedInclusive');
const isSubpath = require('./helpers/projection/isSubpath');
const mpath = require('mpath');
const mquery = require('mquery');
const parseProjection = require('./helpers/projection/parseProjection');
const removeUnusedArrayFilters = require('./helpers/update/removeUnusedArrayFilters');
const sanitizeFilter = require('./helpers/query/sanitizeFilter');
const sanitizeProjection = require('./helpers/query/sanitizeProjection');
const selectPopulatedFields = require('./helpers/query/selectPopulatedFields');
const setDefaultsOnInsert = require('./helpers/setDefaultsOnInsert');
const specialProperties = require('./helpers/specialProperties');
const updateValidators = require('./helpers/updateValidators');
const util = require('util');
const utils = require('./utils');
const queryMiddlewareFunctions = require('./constants').queryMiddlewareFunctions;

const queryOptionMethods = new Set([
  'allowDiskUse',
  'batchSize',
  'collation',
  'comment',
  'explain',
  'hint',
  'j',
  'lean',
  'limit',
  'maxTimeMS',
  'populate',
  'projection',
  'read',
  'select',
  'skip',
  'slice',
  'sort',
  'tailable',
  'w',
  'writeConcern',
  'wtimeout'
]);

/**
 * Query constructor used for building queries. You do not need
 * to instantiate a `Query` directly. Instead use Model functions like
 * [`Model.find()`](https://mongoosejs.com/docs/api/model.html#Model.find()).
 *
 * #### Example:
 *
 *     const query = MyModel.find(); // `query` is an instance of `Query`
 *     query.setOptions({ lean : true });
 *     query.collection(MyModel.collection);
 *     query.where('age').gte(21).exec(callback);
 *
 *     // You can instantiate a query directly. There is no need to do
 *     // this unless you're an advanced user with a very good reason to.
 *     const query = new mongoose.Query();
 *
 * @param {Object} [options]
 * @param {Object} [model]
 * @param {Object} [conditions]
 * @param {Object} [collection] Mongoose collection
 * @api public
 */

function Query(conditions, options, model, collection) {
  // this stuff is for dealing with custom queries created by #toConstructor
  if (!this._mongooseOptions) {
    this._mongooseOptions = {};
  }
  options = options || {};

  this._transforms = [];
  this._hooks = new Kareem();
  this._executionStack = null;

  // this is the case where we have a CustomQuery, we need to check if we got
  // options passed in, and if we did, merge them in
  const keys = Object.keys(options);
  for (const key of keys) {
    this._mongooseOptions[key] = options[key];
  }

  if (collection) {
    this.mongooseCollection = collection;
  }

  if (model) {
    this.model = model;
    this.schema = model.schema;
  }

  // this is needed because map reduce returns a model that can be queried, but
  // all of the queries on said model should be lean
  if (this.model && this.model._mapreduce) {
    this.lean();
  }

  // inherit mquery
  mquery.call(this, null, options);
  if (collection) {
    this.collection(collection);
  }

  if (conditions) {
    this.find(conditions);
  }

  this.options = this.options || {};

  // For gh-6880. mquery still needs to support `fields` by default for old
  // versions of MongoDB
  this.$useProjection = true;

  const collation = this &&
    this.schema &&
    this.schema.options &&
    this.schema.options.collation || null;
  if (collation != null) {
    this.options.collation = collation;
  }
}

/*!
 * inherit mquery
 */

Query.prototype = new mquery();
Query.prototype.constructor = Query;
Query.base = mquery.prototype;

/*!
 * Overwrite mquery's `_distinct`, because Mongoose uses that name
 * to store the field to apply distinct on.
 */

Object.defineProperty(Query.prototype, '_distinct', {
  configurable: true,
  writable: true,
  enumerable: true,
  value: undefined
});

/**
 * Flag to opt out of using `$geoWithin`.
 *
 * ```javascript
 * mongoose.Query.use$geoWithin = false;
 * ```
 *
 * MongoDB 2.4 deprecated the use of `$within`, replacing it with `$geoWithin`. Mongoose uses `$geoWithin` by default (which is 100% backward compatible with `$within`). If you are running an older version of MongoDB, set this flag to `false` so your `within()` queries continue to work.
 *
 * @see geoWithin https://www.mongodb.com/docs/manual/reference/operator/geoWithin/
 * @default true
 * @property use$geoWithin
 * @memberOf Query
 * @static
 * @api public
 */

Query.use$geoWithin = mquery.use$geoWithin;

/**
 * Converts this query to a customized, reusable query constructor with all arguments and options retained.
 *
 * #### Example:
 *
 *     // Create a query for adventure movies and read from the primary
 *     // node in the replica-set unless it is down, in which case we'll
 *     // read from a secondary node.
 *     const query = Movie.find({ tags: 'adventure' }).read('primaryPreferred');
 *
 *     // create a custom Query constructor based off these settings
 *     const Adventure = query.toConstructor();
 *
 *     // further narrow down our query results while still using the previous settings
 *     await Adventure().where({ name: /^Life/ }).exec();
 *
 *     // since Adventure is a stand-alone constructor we can also add our own
 *     // helper methods and getters without impacting global queries
 *     Adventure.prototype.startsWith = function (prefix) {
 *       this.where({ name: new RegExp('^' + prefix) })
 *       return this;
 *     }
 *     Object.defineProperty(Adventure.prototype, 'highlyRated', {
 *       get: function () {
 *         this.where({ rating: { $gt: 4.5 }});
 *         return this;
 *       }
 *     })
 *     await Adventure().highlyRated.startsWith('Life').exec();
 *
 * @return {Query} subclass-of-Query
 * @api public
 */

Query.prototype.toConstructor = function toConstructor() {
  const model = this.model;
  const coll = this.mongooseCollection;

  const CustomQuery = function(criteria, options) {
    if (!(this instanceof CustomQuery)) {
      return new CustomQuery(criteria, options);
    }
    this._mongooseOptions = clone(p._mongooseOptions);
    Query.call(this, criteria, options || null, model, coll);
  };

  util.inherits(CustomQuery, model.Query);

  // set inherited defaults
  const p = CustomQuery.prototype;

  p.options = {};

  // Need to handle `sort()` separately because entries-style `sort()` syntax
  // `sort([['prop1', 1]])` confuses mquery into losing the outer nested array.
  // See gh-8159
  const options = Object.assign({}, this.options);
  if (options.sort != null) {
    p.sort(options.sort);
    delete options.sort;
  }
  p.setOptions(options);

  p.op = this.op;
  p._validateOp();
  p._conditions = clone(this._conditions);
  p._fields = clone(this._fields);
  p._update = clone(this._update, {
    flattenDecimals: false
  });
  p._path = this._path;
  p._distinct = this._distinct;
  p._collection = this._collection;
  p._mongooseOptions = this._mongooseOptions;

  return CustomQuery;
};

/**
 * Make a copy of this query so you can re-execute it.
 *
 * #### Example:
 *
 *     const q = Book.findOne({ title: 'Casino Royale' });
 *     await q.exec();
 *     await q.exec(); // Throws an error because you can't execute a query twice
 *
 *     await q.clone().exec(); // Works
 *
 * @method clone
 * @return {Query} copy
 * @memberOf Query
 * @instance
 * @api public
 */

Query.prototype.clone = function() {
  const model = this.model;
  const collection = this.mongooseCollection;

  const q = new this.model.Query({}, {}, model, collection);

  // Need to handle `sort()` separately because entries-style `sort()` syntax
  // `sort([['prop1', 1]])` confuses mquery into losing the outer nested array.
  // See gh-8159
  const options = Object.assign({}, this.options);
  if (options.sort != null) {
    q.sort(options.sort);
    delete options.sort;
  }
  q.setOptions(options);

  q.op = this.op;
  q._validateOp();
  q._conditions = clone(this._conditions);
  q._fields = clone(this._fields);
  q._update = clone(this._update, {
    flattenDecimals: false
  });
  q._path = this._path;
  q._distinct = this._distinct;
  q._collection = this._collection;
  q._mongooseOptions = this._mongooseOptions;

  return q;
};

/**
 * Specifies a javascript function or expression to pass to MongoDBs query system.
 *
 * #### Example:
 *
 *     query.$where('this.comments.length === 10 || this.name.length === 5')
 *
 *     // or
 *
 *     query.$where(function () {
 *       return this.comments.length === 10 || this.name.length === 5;
 *     })
 *
 * #### Note:
 *
 * Only use `$where` when you have a condition that cannot be met using other MongoDB operators like `$lt`.
 * **Be sure to read about all of [its caveats](https://www.mongodb.com/docs/manual/reference/operator/where/) before using.**
 *
 * @see $where https://www.mongodb.com/docs/manual/reference/operator/where/
 * @method $where
 * @param {String|Function} js javascript string or function
 * @return {Query} this
 * @memberOf Query
 * @instance
 * @method $where
 * @api public
 */

/**
 * Specifies a `path` for use with chaining.
 *
 * #### Example:
 *
 *     // instead of writing:
 *     User.find({age: {$gte: 21, $lte: 65}});
 *
 *     // we can instead write:
 *     User.where('age').gte(21).lte(65);
 *
 *     // passing query conditions is permitted
 *     User.find().where({ name: 'vonderful' })
 *
 *     // chaining
 *     User
 *     .where('age').gte(21).lte(65)
 *     .where('name', /^vonderful/i)
 *     .where('friends').slice(10)
 *     .exec()
 *
 * @method where
 * @memberOf Query
 * @instance
 * @param {String|Object} [path]
 * @param {any} [val]
 * @return {Query} this
 * @api public
 */

/**
 * Specifies a `$slice` projection for an array.
 *
 * #### Example:
 *
 *     query.slice('comments', 5); // Returns the first 5 comments
 *     query.slice('comments', -5); // Returns the last 5 comments
 *     query.slice('comments', [10, 5]); // Returns the first 5 comments after the 10-th
 *     query.where('comments').slice(5); // Returns the first 5 comments
 *     query.where('comments').slice([-10, 5]); // Returns the first 5 comments after the 10-th to last
 *
 * **Note:** If the absolute value of the number of elements to be sliced is greater than the number of elements in the array, all array elements will be returned.
 *
 *      // Given `arr`: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 *      query.slice('arr', 20); // Returns [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 *      query.slice('arr', -20); // Returns [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 *
 * **Note:** If the number of elements to skip is positive and greater than the number of elements in the array, an empty array will be returned.
 *
 *      // Given `arr`: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 *      query.slice('arr', [20, 5]); // Returns []
 *
 * **Note:** If the number of elements to skip is negative and its absolute value is greater than the number of elements in the array, the starting position is the start of the array.
 *
 *      // Given `arr`: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 *      query.slice('arr', [-20, 5]); // Returns [1, 2, 3, 4, 5]
 *
 * @method slice
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Number|Array} val number of elements to slice or array with number of elements to skip and number of elements to slice
 * @return {Query} this
 * @see mongodb https://www.mongodb.com/docs/manual/tutorial/query-documents/#projection
 * @see $slice https://www.mongodb.com/docs/manual/reference/projection/slice/#prj._S_slice
 * @api public
 */

Query.prototype.slice = function() {
  if (arguments.length === 0) {
    return this;
  }

  this._validate('slice');

  let path;
  let val;

  if (arguments.length === 1) {
    const arg = arguments[0];
    if (typeof arg === 'object' && !Array.isArray(arg)) {
      const keys = Object.keys(arg);
      const numKeys = keys.length;
      for (let i = 0; i < numKeys; ++i) {
        this.slice(keys[i], arg[keys[i]]);
      }
      return this;
    }
    this._ensurePath('slice');
    path = this._path;
    val = arguments[0];
  } else if (arguments.length === 2) {
    if ('number' === typeof arguments[0]) {
      this._ensurePath('slice');
      path = this._path;
      val = [arguments[0], arguments[1]];
    } else {
      path = arguments[0];
      val = arguments[1];
    }
  } else if (arguments.length === 3) {
    path = arguments[0];
    val = [arguments[1], arguments[2]];
  }

  const p = {};
  p[path] = { $slice: val };
  this.select(p);

  return this;
};

/*!
 * ignore
 */

const validOpsSet = new Set(queryMiddlewareFunctions);

Query.prototype._validateOp = function() {
  if (this.op != null && !validOpsSet.has(this.op)) {
    this.error(new Error('Query has invalid `op`: "' + this.op + '"'));
  }
};

/**
 * Specifies the complementary comparison value for paths specified with `where()`
 *
 * #### Example:
 *
 *     User.where('age').equals(49);
 *
 *     // is the same as
 *
 *     User.where('age', 49);
 *
 * @method equals
 * @memberOf Query
 * @instance
 * @param {Object} val
 * @return {Query} this
 * @api public
 */

/**
 * Specifies arguments for an `$or` condition.
 *
 * #### Example:
 *
 *     query.or([{ color: 'red' }, { status: 'emergency' }]);
 *
 * @see $or https://www.mongodb.com/docs/manual/reference/operator/or/
 * @method or
 * @memberOf Query
 * @instance
 * @param {Array} array array of conditions
 * @return {Query} this
 * @api public
 */

/**
 * Specifies arguments for a `$nor` condition.
 *
 * #### Example:
 *
 *     query.nor([{ color: 'green' }, { status: 'ok' }]);
 *
 * @see $nor https://www.mongodb.com/docs/manual/reference/operator/nor/
 * @method nor
 * @memberOf Query
 * @instance
 * @param {Array} array array of conditions
 * @return {Query} this
 * @api public
 */

/**
 * Specifies arguments for a `$and` condition.
 *
 * #### Example:
 *
 *     query.and([{ color: 'green' }, { status: 'ok' }])
 *
 * @method and
 * @memberOf Query
 * @instance
 * @see $and https://www.mongodb.com/docs/manual/reference/operator/and/
 * @param {Array} array array of conditions
 * @return {Query} this
 * @api public
 */

/**
 * Specifies a `$gt` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * #### Example:
 *
 *     Thing.find().where('age').gt(21);
 *
 *     // or
 *     Thing.find().gt('age', 21);
 *
 * @method gt
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Number} val
 * @see $gt https://www.mongodb.com/docs/manual/reference/operator/gt/
 * @api public
 */

/**
 * Specifies a `$gte` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method gte
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Number} val
 * @see $gte https://www.mongodb.com/docs/manual/reference/operator/gte/
 * @api public
 */

/**
 * Specifies a `$lt` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method lt
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Number} val
 * @see $lt https://www.mongodb.com/docs/manual/reference/operator/lt/
 * @api public
 */

/**
 * Specifies a `$lte` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method lte
 * @see $lte https://www.mongodb.com/docs/manual/reference/operator/lte/
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a `$ne` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @see $ne https://www.mongodb.com/docs/manual/reference/operator/ne/
 * @method ne
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {any} val
 * @api public
 */

/**
 * Specifies an `$in` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @see $in https://www.mongodb.com/docs/manual/reference/operator/in/
 * @method in
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Array} val
 * @api public
 */

/**
 * Specifies an `$nin` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @see $nin https://www.mongodb.com/docs/manual/reference/operator/nin/
 * @method nin
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Array} val
 * @api public
 */

/**
 * Specifies an `$all` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * #### Example:
 *
 *     MyModel.find().where('pets').all(['dog', 'cat', 'ferret']);
 *     // Equivalent:
 *     MyModel.find().all('pets', ['dog', 'cat', 'ferret']);
 *
 * @see $all https://www.mongodb.com/docs/manual/reference/operator/all/
 * @method all
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Array} val
 * @api public
 */

/**
 * Specifies a `$size` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * #### Example:
 *
 *     const docs = await MyModel.where('tags').size(0).exec();
 *     assert(Array.isArray(docs));
 *     console.log('documents with 0 tags', docs);
 *
 * @see $size https://www.mongodb.com/docs/manual/reference/operator/size/
 * @method size
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a `$regex` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @see $regex https://www.mongodb.com/docs/manual/reference/operator/regex/
 * @method regex
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {String|RegExp} val
 * @api public
 */

/**
 * Specifies a `maxDistance` query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @see $maxDistance https://www.mongodb.com/docs/manual/reference/operator/maxDistance/
 * @method maxDistance
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a `$mod` condition, filters documents for documents whose
 * `path` property is a number that is equal to `remainder` modulo `divisor`.
 *
 * #### Example:
 *
 *     // All find products whose inventory is odd
 *     Product.find().mod('inventory', [2, 1]);
 *     Product.find().where('inventory').mod([2, 1]);
 *     // This syntax is a little strange, but supported.
 *     Product.find().where('inventory').mod(2, 1);
 *
 * @method mod
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Array} val must be of length 2, first element is `divisor`, 2nd element is `remainder`.
 * @return {Query} this
 * @see $mod https://www.mongodb.com/docs/manual/reference/operator/mod/
 * @api public
 */

Query.prototype.mod = function() {
  let val;
  let path;

  if (arguments.length === 1) {
    this._ensurePath('mod');
    val = arguments[0];
    path = this._path;
  } else if (arguments.length === 2 && !Array.isArray(arguments[1])) {
    this._ensurePath('mod');
    val = [arguments[0], arguments[1]];
    path = this._path;
  } else if (arguments.length === 3) {
    val = [arguments[1], arguments[2]];
    path = arguments[0];
  } else {
    val = arguments[1];
    path = arguments[0];
  }

  const conds = this._conditions[path] || (this._conditions[path] = {});
  conds.$mod = val;
  return this;
};

/**
 * Specifies an `$exists` condition
 *
 * #### Example:
 *
 *     // { name: { $exists: true }}
 *     Thing.where('name').exists()
 *     Thing.where('name').exists(true)
 *     Thing.find().exists('name')
 *
 *     // { name: { $exists: false }}
 *     Thing.where('name').exists(false);
 *     Thing.find().exists('name', false);
 *
 * @method exists
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Boolean} val
 * @return {Query} this
 * @see $exists https://www.mongodb.com/docs/manual/reference/operator/exists/
 * @api public
 */

/**
 * Specifies an `$elemMatch` condition
 *
 * #### Example:
 *
 *     query.elemMatch('comment', { author: 'autobot', votes: {$gte: 5}})
 *
 *     query.where('comment').elemMatch({ author: 'autobot', votes: {$gte: 5}})
 *
 *     query.elemMatch('comment', function (elem) {
 *       elem.where('author').equals('autobot');
 *       elem.where('votes').gte(5);
 *     })
 *
 *     query.where('comment').elemMatch(function (elem) {
 *       elem.where({ author: 'autobot' });
 *       elem.where('votes').gte(5);
 *     })
 *
 * @method elemMatch
 * @memberOf Query
 * @instance
 * @param {String|Object|Function} path
 * @param {Object|Function} filter
 * @return {Query} this
 * @see $elemMatch https://www.mongodb.com/docs/manual/reference/operator/elemMatch/
 * @api public
 */

/**
 * Defines a `$within` or `$geoWithin` argument for geo-spatial queries.
 *
 * #### Example:
 *
 *     query.where(path).within().box()
 *     query.where(path).within().circle()
 *     query.where(path).within().geometry()
 *
 *     query.where('loc').within({ center: [50,50], radius: 10, unique: true, spherical: true });
 *     query.where('loc').within({ box: [[40.73, -73.9], [40.7, -73.988]] });
 *     query.where('loc').within({ polygon: [[],[],[],[]] });
 *
 *     query.where('loc').within([], [], []) // polygon
 *     query.where('loc').within([], []) // box
 *     query.where('loc').within({ type: 'LineString', coordinates: [...] }); // geometry
 *
 * **MUST** be used after `where()`.
 *
 * #### Note:
 *
 * As of Mongoose 3.7, `$geoWithin` is always used for queries. To change this behavior, see [Query.use$geoWithin](https://mongoosejs.com/docs/api/query.html#Query.prototype.use$geoWithin).
 *
 * #### Note:
 *
 * In Mongoose 3.7, `within` changed from a getter to a function. If you need the old syntax, use [this](https://github.com/ebensing/mongoose-within).
 *
 * @method within
 * @see $polygon https://www.mongodb.com/docs/manual/reference/operator/polygon/
 * @see $box https://www.mongodb.com/docs/manual/reference/operator/box/
 * @see $geometry https://www.mongodb.com/docs/manual/reference/operator/geometry/
 * @see $center https://www.mongodb.com/docs/manual/reference/operator/center/
 * @see $centerSphere https://www.mongodb.com/docs/manual/reference/operator/centerSphere/
 * @memberOf Query
 * @instance
 * @return {Query} this
 * @api public
 */

/**
 * Specifies the maximum number of documents the query will return.
 *
 * #### Example:
 *
 *     query.limit(20);
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @method limit
 * @memberOf Query
 * @instance
 * @param {Number} val
 * @api public
 */

Query.prototype.limit = function limit(v) {
  this._validate('limit');

  if (typeof v === 'string') {
    try {
      v = castNumber(v);
    } catch (err) {
      throw new CastError('Number', v, 'limit');
    }
  }

  this.options.limit = v;
  return this;
};

/**
 * Specifies the number of documents to skip.
 *
 * #### Example:
 *
 *     query.skip(100).limit(20);
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @method skip
 * @memberOf Query
 * @instance
 * @param {Number} val
 * @see cursor.skip https://www.mongodb.com/docs/manual/reference/method/cursor.skip/
 * @api public
 */

Query.prototype.skip = function skip(v) {
  this._validate('skip');

  if (typeof v === 'string') {
    try {
      v = castNumber(v);
    } catch (err) {
      throw new CastError('Number', v, 'skip');
    }
  }

  this.options.skip = v;
  return this;
};

/**
 * Specifies the batchSize option.
 *
 * #### Example:
 *
 *     query.batchSize(100)
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @method batchSize
 * @memberOf Query
 * @instance
 * @param {Number} val
 * @see batchSize https://www.mongodb.com/docs/manual/reference/method/cursor.batchSize/
 * @api public
 */

/**
 * Specifies the `comment` option.
 *
 * #### Example:
 *
 *     query.comment('login query')
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @method comment
 * @memberOf Query
 * @instance
 * @param {String} val
 * @see comment https://www.mongodb.com/docs/manual/reference/operator/comment/
 * @api public
 */

/**
 * Sets query hints.
 *
 * #### Example:
 *
 *     query.hint({ indexA: 1, indexB: -1 });
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @method hint
 * @memberOf Query
 * @instance
 * @param {Object} val a hint object
 * @return {Query} this
 * @see $hint https://www.mongodb.com/docs/manual/reference/operator/hint/
 * @api public
 */

/**
 * Get/set the current projection (AKA fields). Pass `null` to remove the
 * current projection.
 *
 * Unlike `projection()`, the `select()` function modifies the current
 * projection in place. This function overwrites the existing projection.
 *
 * #### Example:
 *
 *     const q = Model.find();
 *     q.projection(); // null
 *
 *     q.select('a b');
 *     q.projection(); // { a: 1, b: 1 }
 *
 *     q.projection({ c: 1 });
 *     q.projection(); // { c: 1 }
 *
 *     q.projection(null);
 *     q.projection(); // null
 *
 *
 * @method projection
 * @memberOf Query
 * @instance
 * @param {Object|null} arg
 * @return {Object} the current projection
 * @api public
 */

Query.prototype.projection = function(arg) {
  if (arguments.length === 0) {
    return this._fields;
  }

  this._fields = {};
  this._userProvidedFields = {};
  this.select(arg);
  return this._fields;
};

/**
 * Specifies which document fields to include or exclude (also known as the query "projection")
 *
 * When using string syntax, prefixing a path with `-` will flag that path as excluded. When a path does not have the `-` prefix, it is included. Lastly, if a path is prefixed with `+`, it forces inclusion of the path, which is useful for paths excluded at the [schema level](https://mongoosejs.com/docs/api/schematype.html#SchemaType.prototype.select()).
 *
 * A projection _must_ be either inclusive or exclusive. In other words, you must
 * either list the fields to include (which excludes all others), or list the fields
 * to exclude (which implies all other fields are included). The [`_id` field is the only exception because MongoDB includes it by default](https://www.mongodb.com/docs/manual/tutorial/project-fields-from-query-results/#suppress-id-field).
 *
 * #### Example:
 *
 *     // include a and b, exclude other fields
 *     query.select('a b');
 *     // Equivalent syntaxes:
 *     query.select(['a', 'b']);
 *     query.select({ a: 1, b: 1 });
 *
 *     // exclude c and d, include other fields
 *     query.select('-c -d');
 *
 *     // Use `+` to override schema-level `select: false` without making the
 *     // projection inclusive.
 *     const schema = new Schema({
 *       foo: { type: String, select: false },
 *       bar: String
 *     });
 *     // ...
 *     query.select('+foo'); // Override foo's `select: false` without excluding `bar`
 *
 *     // or you may use object notation, useful when
 *     // you have keys already prefixed with a "-"
 *     query.select({ a: 1, b: 1 });
 *     query.select({ c: 0, d: 0 });
 *
 *     Additional calls to select can override the previous selection:
 *     query.select({ a: 1, b: 1 }).select({ b: 0 }); // selection is now { a: 1 }
 *     query.select({ a: 0, b: 0 }).select({ b: 1 }); // selection is now { a: 0 }
 *
 *
 * @method select
 * @memberOf Query
 * @instance
 * @param {Object|String|String[]} arg
 * @return {Query} this
 * @see SchemaType https://mongoosejs.com/docs/api/schematype.html
 * @api public
 */

Query.prototype.select = function select() {
  let arg = arguments[0];
  if (!arg) return this;

  if (arguments.length !== 1) {
    throw new Error('Invalid select: select only takes 1 argument');
  }

  this._validate('select');

  const fields = this._fields || (this._fields = {});
  const userProvidedFields = this._userProvidedFields || (this._userProvidedFields = {});
  let sanitizeProjection = undefined;
  if (this.model != null && utils.hasUserDefinedProperty(this.model.db.options, 'sanitizeProjection')) {
    sanitizeProjection = this.model.db.options.sanitizeProjection;
  } else if (this.model != null && utils.hasUserDefinedProperty(this.model.base.options, 'sanitizeProjection')) {
    sanitizeProjection = this.model.base.options.sanitizeProjection;
  } else {
    sanitizeProjection = this._mongooseOptions.sanitizeProjection;
  }

  function sanitizeValue(value) {
    return typeof value === 'string' && sanitizeProjection ? value = 1 : value;
  }
  arg = parseProjection(arg, true); // we want to keep the minus and pluses, so add boolean arg.
  if (utils.isObject(arg)) {
    if (this.selectedInclusively()) {
      Object.entries(arg).forEach(([key, value]) => {
        if (value) {
          // Add the field to the projection
          if (fields['-' + key] != null) {
            delete fields['-' + key];
          }
          fields[key] = userProvidedFields[key] = sanitizeValue(value);
        } else {
          // Remove the field from the projection
          Object.keys(userProvidedFields).forEach(field => {
            if (isSubpath(key, field)) {
              delete fields[field];
              delete userProvidedFields[field];
            }
          });
        }
      });
    } else if (this.selectedExclusively()) {
      Object.entries(arg).forEach(([key, value]) => {
        if (!value) {
          // Add the field to the projection
          if (fields['+' + key] != null) {
            delete fields['+' + key];
          }
          fields[key] = userProvidedFields[key] = sanitizeValue(value);
        } else {
          // Remove the field from the projection
          Object.keys(userProvidedFields).forEach(field => {
            if (isSubpath(key, field)) {
              delete fields[field];
              delete userProvidedFields[field];
            }
          });
        }
      });
    } else {
      const keys = Object.keys(arg);
      for (let i = 0; i < keys.length; ++i) {
        const value = arg[keys[i]];
        const key = keys[i];
        fields[key] = sanitizeValue(value);
        userProvidedFields[key] = sanitizeValue(value);
      }
    }

    return this;
  }

  throw new TypeError('Invalid select() argument. Must be string or object.');
};

/**
 * Determines the MongoDB nodes from which to read.
 *
 * #### Preferences:
 *
 * ```
 * primary - (default) Read from primary only. Operations will produce an error if primary is unavailable. Cannot be combined with tags.
 * secondary            Read from secondary if available, otherwise error.
 * primaryPreferred     Read from primary if available, otherwise a secondary.
 * secondaryPreferred   Read from a secondary if available, otherwise read from the primary.
 * nearest              All operations read from among the nearest candidates, but unlike other modes, this option will include both the primary and all secondaries in the random selection.
 * ```
 *
 * Aliases
 *
 * ```
 * p   primary
 * pp  primaryPreferred
 * s   secondary
 * sp  secondaryPreferred
 * n   nearest
 * ```
 *
 * #### Example:
 *
 *     new Query().read('primary')
 *     new Query().read('p')  // same as primary
 *
 *     new Query().read('primaryPreferred')
 *     new Query().read('pp') // same as primaryPreferred
 *
 *     new Query().read('secondary')
 *     new Query().read('s')  // same as secondary
 *
 *     new Query().read('secondaryPreferred')
 *     new Query().read('sp') // same as secondaryPreferred
 *
 *     new Query().read('nearest')
 *     new Query().read('n')  // same as nearest
 *
 *     // read from secondaries with matching tags
 *     new Query().read('s', [{ dc:'sf', s: 1 },{ dc:'ma', s: 2 }])
 *
 * Read more about how to use read preferences [here](https://www.mongodb.com/docs/manual/applications/replication/#read-preference).
 *
 * @method read
 * @memberOf Query
 * @instance
 * @param {String} mode one of the listed preference options or aliases
 * @param {Array} [tags] optional tags for this query
 * @see mongodb https://www.mongodb.com/docs/manual/applications/replication/#read-preference
 * @return {Query} this
 * @api public
 */

Query.prototype.read = function read(mode, tags) {
  if (typeof mode === 'string') {
    mode = handleReadPreferenceAliases(mode);
    this.options.readPreference = { mode, tags };
  } else {
    this.options.readPreference = mode;
  }
  return this;
};

/**
 * Overwrite default `.toString` to make logging more useful
 *
 * @memberOf Query
 * @instance
 * @method toString
 * @api private
 */

Query.prototype.toString = function toString() {
  if (this.op === 'count' ||
      this.op === 'countDocuments' ||
      this.op === 'find' ||
      this.op === 'findOne' ||
      this.op === 'deleteMany' ||
      this.op === 'deleteOne' ||
      this.op === 'findOneAndDelete' ||
      this.op === 'remove') {
    return `${this.model.modelName}.${this.op}(${util.inspect(this._conditions)})`;
  }
  if (this.op === 'distinct') {
    return `${this.model.modelName}.distinct('${this._distinct}', ${util.inspect(this._conditions)})`;
  }
  if (this.op === 'findOneAndReplace' ||
      this.op === 'findOneAndUpdate' ||
      this.op === 'replaceOne' ||
      this.op === 'update' ||
      this.op === 'updateMany' ||
      this.op === 'updateOne') {
    return `${this.model.modelName}.${this.op}(${util.inspect(this._conditions)}, ${util.inspect(this._update)})`;
  }

  // 'estimatedDocumentCount' or any others
  return `${this.model.modelName}.${this.op}()`;
};

/**
 * Sets the [MongoDB session](https://www.mongodb.com/docs/manual/reference/server-sessions/)
 * associated with this query. Sessions are how you mark a query as part of a
 * [transaction](https://mongoosejs.com/docs/transactions.html).
 *
 * Calling `session(null)` removes the session from this query.
 *
 * #### Example:
 *
 *     const s = await mongoose.startSession();
 *     await mongoose.model('Person').findOne({ name: 'Axl Rose' }).session(s);
 *
 * @method session
 * @memberOf Query
 * @instance
 * @param {ClientSession} [session] from `await conn.startSession()`
 * @see Connection.prototype.startSession() https://mongoosejs.com/docs/api/connection.html#Connection.prototype.startSession()
 * @see mongoose.startSession() https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.startSession()
 * @return {Query} this
 * @api public
 */

Query.prototype.session = function session(v) {
  if (v == null) {
    delete this.options.session;
  }
  this.options.session = v;
  return this;
};

/**
 * Sets the 3 write concern parameters for this query:
 *
 * - `w`: Sets the specified number of `mongod` servers, or tag set of `mongod` servers, that must acknowledge this write before this write is considered successful.
 * - `j`: Boolean, set to `true` to request acknowledgement that this operation has been persisted to MongoDB's on-disk journal.
 * - `wtimeout`: If [`w > 1`](https://mongoosejs.com/docs/api/query.html#Query.prototype.w()), the maximum amount of time to wait for this write to propagate through the replica set before this operation fails. The default is `0`, which means no timeout.
 *
 * This option is only valid for operations that write to the database:
 *
 * - `deleteOne()`
 * - `deleteMany()`
 * - `findOneAndDelete()`
 * - `findOneAndReplace()`
 * - `findOneAndUpdate()`
 * - `updateOne()`
 * - `updateMany()`
 *
 * Defaults to the schema's [`writeConcern` option](https://mongoosejs.com/docs/guide.html#writeConcern)
 *
 * #### Example:
 *
 *     // The 'majority' option means the `deleteOne()` promise won't resolve
 *     // until the `deleteOne()` has propagated to the majority of the replica set
 *     await mongoose.model('Person').
 *       deleteOne({ name: 'Ned Stark' }).
 *       writeConcern({ w: 'majority' });
 *
 * @method writeConcern
 * @memberOf Query
 * @instance
 * @param {Object} writeConcern the write concern value to set
 * @see WriteConcernSettings https://mongodb.github.io/node-mongodb-native/4.9/interfaces/WriteConcernSettings.html
 * @return {Query} this
 * @api public
 */

Query.prototype.writeConcern = function writeConcern(val) {
  if (val == null) {
    delete this.options.writeConcern;
    return this;
  }
  this.options.writeConcern = val;
  return this;
};

/**
 * Sets the specified number of `mongod` servers, or tag set of `mongod` servers,
 * that must acknowledge this write before this write is considered successful.
 * This option is only valid for operations that write to the database:
 *
 * - `deleteOne()`
 * - `deleteMany()`
 * - `findOneAndDelete()`
 * - `findOneAndReplace()`
 * - `findOneAndUpdate()`
 * - `updateOne()`
 * - `updateMany()`
 *
 * Defaults to the schema's [`writeConcern.w` option](https://mongoosejs.com/docs/guide.html#writeConcern)
 *
 * #### Example:
 *
 *     // The 'majority' option means the `deleteOne()` promise won't resolve
 *     // until the `deleteOne()` has propagated to the majority of the replica set
 *     await mongoose.model('Person').
 *       deleteOne({ name: 'Ned Stark' }).
 *       w('majority');
 *
 * @method w
 * @memberOf Query
 * @instance
 * @param {String|number} val 0 for fire-and-forget, 1 for acknowledged by one server, 'majority' for majority of the replica set, or [any of the more advanced options](https://www.mongodb.com/docs/manual/reference/write-concern/#w-option).
 * @see mongodb https://www.mongodb.com/docs/manual/reference/write-concern/#w-option
 * @return {Query} this
 * @api public
 */

Query.prototype.w = function w(val) {
  if (val == null) {
    delete this.options.w;
  }
  if (this.options.writeConcern != null) {
    this.options.writeConcern.w = val;
  } else {
    this.options.w = val;
  }
  return this;
};

/**
 * Requests acknowledgement that this operation has been persisted to MongoDB's
 * on-disk journal.
 * This option is only valid for operations that write to the database:
 *
 * - `deleteOne()`
 * - `deleteMany()`
 * - `findOneAndDelete()`
 * - `findOneAndReplace()`
 * - `findOneAndUpdate()`
 * - `updateOne()`
 * - `updateMany()`
 *
 * Defaults to the schema's [`writeConcern.j` option](https://mongoosejs.com/docs/guide.html#writeConcern)
 *
 * #### Example:
 *
 *     await mongoose.model('Person').deleteOne({ name: 'Ned Stark' }).j(true);
 *
 * @method j
 * @memberOf Query
 * @instance
 * @param {boolean} val
 * @see mongodb https://www.mongodb.com/docs/manual/reference/write-concern/#j-option
 * @return {Query} this
 * @api public
 */

Query.prototype.j = function j(val) {
  if (val == null) {
    delete this.options.j;
  }
  if (this.options.writeConcern != null) {
    this.options.writeConcern.j = val;
  } else {
    this.options.j = val;
  }
  return this;
};

/**
 * If [`w > 1`](https://mongoosejs.com/docs/api/query.html#Query.prototype.w()), the maximum amount of time to
 * wait for this write to propagate through the replica set before this
 * operation fails. The default is `0`, which means no timeout.
 *
 * This option is only valid for operations that write to the database:
 *
 * - `deleteOne()`
 * - `deleteMany()`
 * - `findOneAndDelete()`
 * - `findOneAndReplace()`
 * - `findOneAndUpdate()`
 * - `updateOne()`
 * - `updateMany()`
 *
 * Defaults to the schema's [`writeConcern.wtimeout` option](https://mongoosejs.com/docs/guide.html#writeConcern)
 *
 * #### Example:
 *
 *     // The `deleteOne()` promise won't resolve until this `deleteOne()` has
 *     // propagated to at least `w = 2` members of the replica set. If it takes
 *     // longer than 1 second, this `deleteOne()` will fail.
 *     await mongoose.model('Person').
 *       deleteOne({ name: 'Ned Stark' }).
 *       w(2).
 *       wtimeout(1000);
 *
 * @method wtimeout
 * @memberOf Query
 * @instance
 * @param {number} ms number of milliseconds to wait
 * @see mongodb https://www.mongodb.com/docs/manual/reference/write-concern/#wtimeout
 * @return {Query} this
 * @api public
 */

Query.prototype.wtimeout = function wtimeout(ms) {
  if (ms == null) {
    delete this.options.wtimeout;
  }
  if (this.options.writeConcern != null) {
    this.options.writeConcern.wtimeout = ms;
  } else {
    this.options.wtimeout = ms;
  }
  return this;
};

/**
 * Sets the readConcern option for the query.
 *
 * #### Example:
 *
 *     new Query().readConcern('local')
 *     new Query().readConcern('l')  // same as local
 *
 *     new Query().readConcern('available')
 *     new Query().readConcern('a')  // same as available
 *
 *     new Query().readConcern('majority')
 *     new Query().readConcern('m')  // same as majority
 *
 *     new Query().readConcern('linearizable')
 *     new Query().readConcern('lz') // same as linearizable
 *
 *     new Query().readConcern('snapshot')
 *     new Query().readConcern('s')  // same as snapshot
 *
 *
 * #### Read Concern Level:
 *
 * ```
 * local         MongoDB 3.2+ The query returns from the instance with no guarantee guarantee that the data has been written to a majority of the replica set members (i.e. may be rolled back).
 * available     MongoDB 3.6+ The query returns from the instance with no guarantee guarantee that the data has been written to a majority of the replica set members (i.e. may be rolled back).
 * majority      MongoDB 3.2+ The query returns the data that has been acknowledged by a majority of the replica set members. The documents returned by the read operation are durable, even in the event of failure.
 * linearizable  MongoDB 3.4+ The query returns data that reflects all successful majority-acknowledged writes that completed prior to the start of the read operation. The query may wait for concurrently executing writes to propagate to a majority of replica set members before returning results.
 * snapshot      MongoDB 4.0+ Only available for operations within multi-document transactions. Upon transaction commit with write concern "majority", the transaction operations are guaranteed to have read from a snapshot of majority-committed data.
 * ```
 *
 * Aliases
 *
 * ```
 * l   local
 * a   available
 * m   majority
 * lz  linearizable
 * s   snapshot
 * ```
 *
 * Read more about how to use read concern [here](https://www.mongodb.com/docs/manual/reference/read-concern/).
 *
 * @memberOf Query
 * @method readConcern
 * @param {String} level one of the listed read concern level or their aliases
 * @see mongodb https://www.mongodb.com/docs/manual/reference/read-concern/
 * @return {Query} this
 * @api public
 */

/**
 * Gets query options.
 *
 * #### Example:
 *
 *     const query = new Query();
 *     query.limit(10);
 *     query.setOptions({ maxTimeMS: 1000 });
 *     query.getOptions(); // { limit: 10, maxTimeMS: 1000 }
 *
 * @return {Object} the options
 * @api public
 */

Query.prototype.getOptions = function() {
  return this.options;
};

/**
 * Sets query options. Some options only make sense for certain operations.
 *
 * #### Options:
 *
 * The following options are only for `find()`:
 *
 * - [tailable](https://www.mongodb.com/docs/manual/core/tailable-cursors/)
 * - [limit](https://www.mongodb.com/docs/manual/reference/method/cursor.limit/)
 * - [skip](https://www.mongodb.com/docs/manual/reference/method/cursor.skip/)
 * - [allowDiskUse](https://www.mongodb.com/docs/manual/reference/method/cursor.allowDiskUse/)
 * - [batchSize](https://www.mongodb.com/docs/manual/reference/method/cursor.batchSize/)
 * - [readPreference](https://www.mongodb.com/docs/manual/applications/replication/#read-preference)
 * - [hint](https://www.mongodb.com/docs/manual/reference/method/cursor.hint/)
 * - [comment](https://www.mongodb.com/docs/manual/reference/method/cursor.comment/)
 *
 * The following options are only for write operations: `updateOne()`, `updateMany()`, `replaceOne()`, `findOneAndUpdate()`, and `findByIdAndUpdate()`:
 *
 * - [upsert](https://www.mongodb.com/docs/manual/reference/method/db.collection.update/)
 * - [writeConcern](https://www.mongodb.com/docs/manual/reference/method/db.collection.update/)
 * - [timestamps](https://mongoosejs.com/docs/guide.html#timestamps): If `timestamps` is set in the schema, set this option to `false` to skip timestamps for that particular update. Has no effect if `timestamps` is not enabled in the schema options.
 * - overwriteDiscriminatorKey: allow setting the discriminator key in the update. Will use the correct discriminator schema if the update changes the discriminator key.
 *
 * The following options are only for `find()`, `findOne()`, `findById()`, `findOneAndUpdate()`, `findOneAndReplace()`, `findOneAndDelete()`, and `findByIdAndUpdate()`:
 *
 * - [lean](https://mongoosejs.com/docs/api/query.html#Query.prototype.lean())
 * - [populate](https://mongoosejs.com/docs/populate.html)
 * - [projection](https://mongoosejs.com/docs/api/query.html#Query.prototype.projection())
 * - sanitizeProjection
 * - useBigInt64
 *
 * The following options are only for all operations **except** `updateOne()`, `updateMany()`, `deleteOne()`, and `deleteMany()`:
 *
 * - [maxTimeMS](https://www.mongodb.com/docs/manual/reference/operator/meta/maxTimeMS/)
 *
 * The following options are for `find()`, `findOne()`, `findOneAndUpdate()`, `findOneAndDelete()`, `updateOne()`, and `deleteOne()`:
 *
 * - [sort](https://www.mongodb.com/docs/manual/reference/method/cursor.sort/)
 *
 * The following options are for `findOneAndUpdate()` and `findOneAndDelete()`
 *
 * - includeResultMetadata
 *
 * The following options are for all operations:
 *
 * - [strict](https://mongoosejs.com/docs/guide.html#strict)
 * - [collation](https://www.mongodb.com/docs/manual/reference/collation/)
 * - [session](https://www.mongodb.com/docs/manual/reference/server-sessions/)
 * - [explain](https://www.mongodb.com/docs/manual/reference/method/cursor.explain/)
 *
 * @param {Object} options
 * @return {Query} this
 * @api public
 */

Query.prototype.setOptions = function(options, overwrite) {
  // overwrite is only for internal use
  if (overwrite) {
    // ensure that _mongooseOptions & options are two different objects
    this._mongooseOptions = (options && clone(options)) || {};
    this.options = options || {};

    if ('populate' in options) {
      this.populate(this._mongooseOptions);
    }
    return this;
  }
  if (options == null) {
    return this;
  }
  if (typeof options !== 'object') {
    throw new Error('Options must be an object, got "' + options + '"');
  }

  options = Object.assign({}, options);

  if (Array.isArray(options.populate)) {
    const populate = options.populate;
    delete options.populate;
    const _numPopulate = populate.length;
    for (let i = 0; i < _numPopulate; ++i) {
      this.populate(populate[i]);
    }
  }

  if ('setDefaultsOnInsert' in options) {
    this._mongooseOptions.setDefaultsOnInsert = options.setDefaultsOnInsert;
    delete options.setDefaultsOnInsert;
  }
  if ('overwriteDiscriminatorKey' in options) {
    this._mongooseOptions.overwriteDiscriminatorKey = options.overwriteDiscriminatorKey;
    delete options.overwriteDiscriminatorKey;
  }
  if ('sanitizeProjection' in options) {
    if (options.sanitizeProjection && !this._mongooseOptions.sanitizeProjection) {
      sanitizeProjection(this._fields);
    }

    this._mongooseOptions.sanitizeProjection = options.sanitizeProjection;
    delete options.sanitizeProjection;
  }
  if ('sanitizeFilter' in options) {
    this._mongooseOptions.sanitizeFilter = options.sanitizeFilter;
    delete options.sanitizeFilter;
  }
  if ('timestamps' in options) {
    this._mongooseOptions.timestamps = options.timestamps;
    delete options.timestamps;
  }
  if ('defaults' in options) {
    this._mongooseOptions.defaults = options.defaults;
    // deleting options.defaults will cause 7287 to fail
  }
  if ('translateAliases' in options) {
    this._mongooseOptions.translateAliases = options.translateAliases;
    delete options.translateAliases;
  }

  if (options.lean == null && this.schema && 'lean' in this.schema.options) {
    this._mongooseOptions.lean = this.schema.options.lean;
  }

  if (typeof options.limit === 'string') {
    try {
      options.limit = castNumber(options.limit);
    } catch (err) {
      throw new CastError('Number', options.limit, 'limit');
    }
  }
  if (typeof options.skip === 'string') {
    try {
      options.skip = castNumber(options.skip);
    } catch (err) {
      throw new CastError('Number', options.skip, 'skip');
    }
  }

  // set arbitrary options
  for (const key of Object.keys(options)) {
    if (queryOptionMethods.has(key)) {
      const args = Array.isArray(options[key]) ?
        options[key] :
        [options[key]];
      this[key].apply(this, args);
    } else {
      this.options[key] = options[key];
    }
  }

  return this;
};

/**
 * Sets the [`explain` option](https://www.mongodb.com/docs/manual/reference/method/cursor.explain/),
 * which makes this query return detailed execution stats instead of the actual
 * query result. This method is useful for determining what index your queries
 * use.
 *
 * Calling `query.explain(v)` is equivalent to `query.setOptions({ explain: v })`
 *
 * #### Example:
 *
 *     const query = new Query();
 *     const res = await query.find({ a: 1 }).explain('queryPlanner');
 *     console.log(res);
 *
 * @param {String} [verbose] The verbosity mode. Either 'queryPlanner', 'executionStats', or 'allPlansExecution'. The default is 'queryPlanner'
 * @return {Query} this
 * @api public
 */

Query.prototype.explain = function explain(verbose) {
  if (arguments.length === 0) {
    this.options.explain = true;
  } else if (verbose === false) {
    delete this.options.explain;
  } else {
    this.options.explain = verbose;
  }
  return this;
};

/**
 * Sets the [`allowDiskUse` option](https://www.mongodb.com/docs/manual/reference/method/cursor.allowDiskUse/),
 * which allows the MongoDB server to use more than 100 MB for this query's `sort()`. This option can
 * let you work around `QueryExceededMemoryLimitNoDiskUseAllowed` errors from the MongoDB server.
 *
 * Note that this option requires MongoDB server >= 4.4. Setting this option is a no-op for MongoDB 4.2
 * and earlier.
 *
 * Calling `query.allowDiskUse(v)` is equivalent to `query.setOptions({ allowDiskUse: v })`
 *
 * #### Example:
 *
 *     await query.find().sort({ name: 1 }).allowDiskUse(true);
 *     // Equivalent:
 *     await query.find().sort({ name: 1 }).allowDiskUse();
 *
 * @param {Boolean} [v] Enable/disable `allowDiskUse`. If called with 0 arguments, sets `allowDiskUse: true`
 * @return {Query} this
 * @api public
 */

Query.prototype.allowDiskUse = function(v) {
  if (arguments.length === 0) {
    this.options.allowDiskUse = true;
  } else if (v === false) {
    delete this.options.allowDiskUse;
  } else {
    this.options.allowDiskUse = v;
  }
  return this;
};

/**
 * Sets the [maxTimeMS](https://www.mongodb.com/docs/manual/reference/method/cursor.maxTimeMS/)
 * option. This will tell the MongoDB server to abort if the query or write op
 * has been running for more than `ms` milliseconds.
 *
 * Calling `query.maxTimeMS(v)` is equivalent to `query.setOptions({ maxTimeMS: v })`
 *
 * #### Example:
 *
 *     const query = new Query();
 *     // Throws an error 'operation exceeded time limit' as long as there's
 *     // >= 1 doc in the queried collection
 *     const res = await query.find({ $where: 'sleep(1000) || true' }).maxTimeMS(100);
 *
 * @param {Number} [ms] The number of milliseconds
 * @return {Query} this
 * @api public
 */

Query.prototype.maxTimeMS = function(ms) {
  this.options.maxTimeMS = ms;
  return this;
};

/**
 * Returns the current query filter (also known as conditions) as a [POJO](https://masteringjs.io/tutorials/fundamentals/pojo).
 *
 * #### Example:
 *
 *     const query = new Query();
 *     query.find({ a: 1 }).where('b').gt(2);
 *     query.getFilter(); // { a: 1, b: { $gt: 2 } }
 *
 * @return {Object} current query filter
 * @api public
 */

Query.prototype.getFilter = function() {
  return this._conditions;
};

/**
 * Returns the current query filter. Equivalent to `getFilter()`.
 *
 * You should use `getFilter()` instead of `getQuery()` where possible. `getQuery()`
 * will likely be deprecated in a future release.
 *
 * #### Example:
 *
 *     const query = new Query();
 *     query.find({ a: 1 }).where('b').gt(2);
 *     query.getQuery(); // { a: 1, b: { $gt: 2 } }
 *
 * @return {Object} current query filter
 * @api public
 */

Query.prototype.getQuery = function() {
  return this._conditions;
};

/**
 * Sets the query conditions to the provided JSON object.
 *
 * #### Example:
 *
 *     const query = new Query();
 *     query.find({ a: 1 })
 *     query.setQuery({ a: 2 });
 *     query.getQuery(); // { a: 2 }
 *
 * @param {Object} new query conditions
 * @return {undefined}
 * @api public
 */

Query.prototype.setQuery = function(val) {
  this._conditions = val;
};

/**
 * Returns the current update operations as a JSON object.
 *
 * #### Example:
 *
 *     const query = new Query();
 *     query.updateOne({}, { $set: { a: 5 } });
 *     query.getUpdate(); // { $set: { a: 5 } }
 *
 * @return {Object} current update operations
 * @api public
 */

Query.prototype.getUpdate = function() {
  return this._update;
};

/**
 * Sets the current update operation to new value.
 *
 * #### Example:
 *
 *     const query = new Query();
 *     query.updateOne({}, { $set: { a: 5 } });
 *     query.setUpdate({ $set: { b: 6 } });
 *     query.getUpdate(); // { $set: { b: 6 } }
 *
 * @param {Object} new update operation
 * @return {undefined}
 * @api public
 */

Query.prototype.setUpdate = function(val) {
  this._update = val;
};

/**
 * Returns fields selection for this query.
 *
 * @method _fieldsForExec
 * @return {Object}
 * @api private
 * @memberOf Query
 */

Query.prototype._fieldsForExec = function() {
  if (this._fields == null) {
    return null;
  }
  if (Object.keys(this._fields).length === 0) {
    return null;
  }
  return clone(this._fields);
};


/**
 * Return an update document with corrected `$set` operations.
 *
 * @method _updateForExec
 * @return {Object}
 * @api private
 * @memberOf Query
 */

Query.prototype._updateForExec = function() {
  const update = clone(this._update, {
    transform: false,
    depopulate: true
  });
  const ops = Object.keys(update);
  let i = ops.length;
  const ret = {};

  while (i--) {
    const op = ops[i];

    if ('$' !== op[0]) {
      // fix up $set sugar
      if (!ret.$set) {
        if (update.$set) {
          ret.$set = update.$set;
        } else {
          ret.$set = {};
        }
      }
      ret.$set[op] = update[op];
      ops.splice(i, 1);
      if (!~ops.indexOf('$set')) ops.push('$set');
    } else if ('$set' === op) {
      if (!ret.$set) {
        ret[op] = update[op];
      }
    } else {
      ret[op] = update[op];
    }
  }

  return ret;
};

/**
 * Makes sure _path is set.
 *
 * This method is inherited by `mquery`
 *
 * @method _ensurePath
 * @param {String} method
 * @api private
 * @memberOf Query
 */

/**
 * Determines if `conds` can be merged using `mquery().merge()`
 *
 * @method canMerge
 * @memberOf Query
 * @instance
 * @param {Object} conds
 * @return {Boolean}
 * @api private
 */

/**
 * Returns default options for this query.
 *
 * @param {Model} model
 * @api private
 */

Query.prototype._optionsForExec = function(model) {
  const options = clone(this.options);
  delete options.populate;
  model = model || this.model;

  if (!model) {
    return options;
  }
  // Apply schema-level `writeConcern` option
  applyWriteConcern(model.schema, options);

  const readPreference = model &&
  model.schema &&
  model.schema.options &&
  model.schema.options.read;
  if (!('readPreference' in options) && readPreference) {
    options.readPreference = readPreference;
  }

  if (options.upsert !== void 0) {
    options.upsert = !!options.upsert;
  }
  if (options.writeConcern) {
    if (options.j) {
      options.writeConcern.j = options.j;
      delete options.j;
    }
    if (options.w) {
      options.writeConcern.w = options.w;
      delete options.w;
    }
    if (options.wtimeout) {
      options.writeConcern.wtimeout = options.wtimeout;
      delete options.wtimeout;
    }
  }

  this._applyPaths();
  if (this._fields != null) {
    this._fields = this._castFields(this._fields);
    const projection = this._fieldsForExec();
    if (projection != null) {
      options.projection = projection;
    }
  }

  return options;
};

/**
 * Sets the lean option.
 *
 * Documents returned from queries with the `lean` option enabled are plain
 * javascript objects, not [Mongoose Documents](https://mongoosejs.com/docs/api/document.html). They have no
 * `save` method, getters/setters, virtuals, or other Mongoose features.
 *
 * #### Example:
 *
 *     new Query().lean() // true
 *     new Query().lean(true)
 *     new Query().lean(false)
 *
 *     const docs = await Model.find().lean();
 *     docs[0] instanceof mongoose.Document; // false
 *
 * [Lean is great for high-performance, read-only cases](https://mongoosejs.com/docs/tutorials/lean.html),
 * especially when combined
 * with [cursors](https://mongoosejs.com/docs/queries.html#streaming).
 *
 * If you need virtuals, getters/setters, or defaults with `lean()`, you need
 * to use a plugin. See:
 *
 * - [mongoose-lean-virtuals](https://plugins.mongoosejs.io/plugins/lean-virtuals)
 * - [mongoose-lean-getters](https://plugins.mongoosejs.io/plugins/lean-getters)
 * - [mongoose-lean-defaults](https://www.npmjs.com/package/mongoose-lean-defaults)
 *
 * @param {Boolean|Object} bool defaults to true
 * @return {Query} this
 * @api public
 */

Query.prototype.lean = function(v) {
  this._mongooseOptions.lean = arguments.length ? v : true;
  return this;
};

/**
 * Adds a `$set` to this query's update without changing the operation.
 * This is useful for query middleware so you can add an update regardless
 * of whether you use `updateOne()`, `updateMany()`, `findOneAndUpdate()`, etc.
 *
 * #### Example:
 *
 *     // Updates `{ $set: { updatedAt: new Date() } }`
 *     new Query().updateOne({}, {}).set('updatedAt', new Date());
 *     new Query().updateMany({}, {}).set({ updatedAt: new Date() });
 *
 * @param {String|Object} path path or object of key/value pairs to set
 * @param {Any} [val] the value to set
 * @return {Query} this
 * @api public
 */

Query.prototype.set = function(path, val) {
  if (typeof path === 'object') {
    const keys = Object.keys(path);
    for (const key of keys) {
      this.set(key, path[key]);
    }
    return this;
  }

  this._update = this._update || {};
  if (path in this._update) {
    delete this._update[path];
  }
  this._update.$set = this._update.$set || {};
  this._update.$set[path] = val;
  return this;
};

/**
 * For update operations, returns the value of a path in the update's `$set`.
 * Useful for writing getters/setters that can work with both update operations
 * and `save()`.
 *
 * #### Example:
 *
 *     const query = Model.updateOne({}, { $set: { name: 'Jean-Luc Picard' } });
 *     query.get('name'); // 'Jean-Luc Picard'
 *
 * @param {String|Object} path path or object of key/value pairs to get
 * @return {Query} this
 * @api public
 */

Query.prototype.get = function get(path) {
  const update = this._update;
  if (update == null) {
    return void 0;
  }
  const $set = update.$set;
  if ($set == null) {
    return update[path];
  }

  if (utils.hasUserDefinedProperty(update, path)) {
    return update[path];
  }
  if (utils.hasUserDefinedProperty($set, path)) {
    return $set[path];
  }

  return void 0;
};

/**
 * Gets/sets the error flag on this query. If this flag is not null or
 * undefined, the `exec()` promise will reject without executing.
 *
 * #### Example:
 *
 *     Query().error(); // Get current error value
 *     Query().error(null); // Unset the current error
 *     Query().error(new Error('test')); // `exec()` will resolve with test
 *     Schema.pre('find', function() {
 *       if (!this.getQuery().userId) {
 *         this.error(new Error('Not allowed to query without setting userId'));
 *       }
 *     });
 *
 * Note that query casting runs **after** hooks, so cast errors will override
 * custom errors.
 *
 * #### Example:
 *
 *     const TestSchema = new Schema({ num: Number });
 *     const TestModel = db.model('Test', TestSchema);
 *     TestModel.find({ num: 'not a number' }).error(new Error('woops')).exec(function(error) {
 *       // `error` will be a cast error because `num` failed to cast
 *     });
 *
 * @param {Error|null} err if set, `exec()` will fail fast before sending the query to MongoDB
 * @return {Query} this
 * @api public
 */

Query.prototype.error = function error(err) {
  if (arguments.length === 0) {
    return this._error;
  }

  this._error = err;
  return this;
};

/**
 * ignore
 * @method _unsetCastError
 * @instance
 * @memberOf Query
 * @api private
 */

Query.prototype._unsetCastError = function _unsetCastError() {
  if (this._error != null && !(this._error instanceof CastError)) {
    return;
  }
  return this.error(null);
};

/**
 * Getter/setter around the current mongoose-specific options for this query
 * Below are the current Mongoose-specific options.
 *
 * - `populate`: an array representing what paths will be populated. Should have one entry for each call to [`Query.prototype.populate()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.populate())
 * - `lean`: if truthy, Mongoose will not [hydrate](https://mongoosejs.com/docs/api/model.html#Model.hydrate()) any documents that are returned from this query. See [`Query.prototype.lean()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.lean()) for more information.
 * - `strict`: controls how Mongoose handles keys that aren't in the schema for updates. This option is `true` by default, which means Mongoose will silently strip any paths in the update that aren't in the schema. See the [`strict` mode docs](https://mongoosejs.com/docs/guide.html#strict) for more information.
 * - `strictQuery`: controls how Mongoose handles keys that aren't in the schema for the query `filter`. This option is `false` by default, which means Mongoose will allow `Model.find({ foo: 'bar' })` even if `foo` is not in the schema. See the [`strictQuery` docs](https://mongoosejs.com/docs/guide.html#strictQuery) for more information.
 * - `nearSphere`: use `$nearSphere` instead of `near()`. See the [`Query.prototype.nearSphere()` docs](https://mongoosejs.com/docs/api/query.html#Query.prototype.nearSphere())
 *
 * Mongoose maintains a separate object for internal options because
 * Mongoose sends `Query.prototype.options` to the MongoDB server, and the
 * above options are not relevant for the MongoDB server.
 *
 * @param {Object} options if specified, overwrites the current options
 * @return {Object} the options
 * @api public
 */

Query.prototype.mongooseOptions = function(v) {
  if (arguments.length > 0) {
    this._mongooseOptions = v;
  }
  return this._mongooseOptions;
};

/**
 * ignore
 * @method _castConditions
 * @memberOf Query
 * @api private
 * @instance
 */

Query.prototype._castConditions = function() {
  let sanitizeFilterOpt = undefined;
  if (this.model != null && utils.hasUserDefinedProperty(this.model.db.options, 'sanitizeFilter')) {
    sanitizeFilterOpt = this.model.db.options.sanitizeFilter;
  } else if (this.model != null && utils.hasUserDefinedProperty(this.model.base.options, 'sanitizeFilter')) {
    sanitizeFilterOpt = this.model.base.options.sanitizeFilter;
  } else {
    sanitizeFilterOpt = this._mongooseOptions.sanitizeFilter;
  }

  if (sanitizeFilterOpt) {
    sanitizeFilter(this._conditions);
  }

  try {
    this.cast(this.model);
    this._unsetCastError();
  } catch (err) {
    this.error(err);
  }
};

/*!
 * ignore
 */

function _castArrayFilters(query) {
  try {
    castArrayFilters(query);
  } catch (err) {
    query.error(err);
  }
}

/**
 * Execute a `find()`
 *
 * @return {Query} this
 * @api private
 */
Query.prototype._find = async function _find() {
  this._castConditions();

  if (this.error() != null) {
    throw this.error();
  }

  const mongooseOptions = this._mongooseOptions;
  const _this = this;
  const userProvidedFields = _this._userProvidedFields || {};

  applyGlobalMaxTimeMS(this.options, this.model.db.options, this.model.base.options);
  applyGlobalDiskUse(this.options, this.model.db.options, this.model.base.options);

  // Separate options to pass down to `completeMany()` in case we need to
  // set a session on the document
  const completeManyOptions = Object.assign({}, {
    session: this && this.options && this.options.session || null,
    lean: mongooseOptions.lean || null
  });

  const options = this._optionsForExec();

  this._applyTranslateAliases(options);

  const filter = this._conditions;
  const fields = options.projection;

  const cursor = await this.mongooseCollection.find(filter, options);
  if (options.explain) {
    return cursor.explain();
  }

  let docs = await cursor.toArray();
  if (docs.length === 0) {
    return docs;
  }

  if (!mongooseOptions.populate) {
    const versionKey = _this.schema.options.versionKey;
    if (mongooseOptions.lean && mongooseOptions.lean.versionKey === false && versionKey) {
      docs.forEach((doc) => {
        if (versionKey in doc) {
          delete doc[versionKey];
        }
      });
    }
    return mongooseOptions.lean ?
      _completeManyLean(_this.model.schema, docs, null, completeManyOptions) :
      _this._completeMany(docs, fields, userProvidedFields, completeManyOptions);
  }
  const pop = helpers.preparePopulationOptionsMQ(_this, mongooseOptions);

  if (mongooseOptions.lean) {
    return _this.model.populate(docs, pop);
  }

  docs = await _this._completeMany(docs, fields, userProvidedFields, completeManyOptions);
  await this.model.populate(docs, pop);

  return docs;
};

/**
 * Find all documents that match `selector`. The result will be an array of documents.
 *
 * If there are too many documents in the result to fit in memory, use
 * [`Query.prototype.cursor()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.cursor())
 *
 * #### Example:
 *
 *     const arr = await Movie.find({ year: { $gte: 1980, $lte: 1989 } });
 *
 * @param {Object|ObjectId} [filter] mongodb filter. If not specified, returns all documents.
 * @return {Query} this
 * @api public
 */

Query.prototype.find = function(conditions) {
  if (typeof conditions === 'function' ||
      typeof arguments[1] === 'function') {
    throw new MongooseError('Query.prototype.find() no longer accepts a callback');
  }

  this.op = 'find';

  if (mquery.canMerge(conditions)) {
    this.merge(conditions);

    prepareDiscriminatorCriteria(this);
  } else if (conditions != null) {
    this.error(new ObjectParameterError(conditions, 'filter', 'find'));
  }

  return this;
};

/**
 * Merges another Query or conditions object into this one.
 *
 * When a Query is passed, conditions, field selection and options are merged.
 *
 * @param {Query|Object} source
 * @return {Query} this
 */

Query.prototype.merge = function(source) {
  if (!source) {
    return this;
  }

  const opts = { overwrite: true };

  if (source instanceof Query) {
    // if source has a feature, apply it to ourselves

    if (source._conditions) {
      opts.omit = {};
      if (this._conditions && this._conditions.$and && source._conditions.$and) {
        opts.omit['$and'] = true;
        this._conditions.$and = this._conditions.$and.concat(source._conditions.$and);
      }
      if (this._conditions && this._conditions.$or && source._conditions.$or) {
        opts.omit['$or'] = true;
        this._conditions.$or = this._conditions.$or.concat(source._conditions.$or);
      }
      utils.merge(this._conditions, source._conditions, opts);
    }

    if (source._fields) {
      this._fields || (this._fields = {});
      utils.merge(this._fields, source._fields, opts);
    }

    if (source.options) {
      this.options || (this.options = {});
      utils.merge(this.options, source.options, opts);
    }

    if (source._update) {
      this._update || (this._update = {});
      utils.mergeClone(this._update, source._update);
    }

    if (source._distinct) {
      this._distinct = source._distinct;
    }

    utils.merge(this._mongooseOptions, source._mongooseOptions);

    return this;
  } else if (this.model != null && source instanceof this.model.base.Types.ObjectId) {
    utils.merge(this._conditions, { _id: source }, opts);

    return this;
  } else if (source && source.$__) {
    source = source.toObject(internalToObjectOptions);
  }

  opts.omit = {};
  if (this._conditions && this._conditions.$and && source.$and) {
    opts.omit['$and'] = true;
    this._conditions.$and = this._conditions.$and.concat(source.$and);
  }
  if (this._conditions && this._conditions.$or && source.$or) {
    opts.omit['$or'] = true;
    this._conditions.$or = this._conditions.$or.concat(source.$or);
  }

  // plain object
  utils.merge(this._conditions, source, opts);

  return this;
};

/**
 * Adds a collation to this op (MongoDB 3.4 and up)
 *
 * @param {Object} value
 * @return {Query} this
 * @see MongoDB docs https://www.mongodb.com/docs/manual/reference/method/cursor.collation/#cursor.collation
 * @api public
 */

Query.prototype.collation = function(value) {
  if (this.options == null) {
    this.options = {};
  }
  this.options.collation = value;
  return this;
};

/**
 * Hydrate a single doc from `findOne()`, `findOneAndUpdate()`, etc.
 *
 * @api private
 */

Query.prototype._completeOne = function(doc, res, callback) {
  if (!doc && !this.options.includeResultMetadata) {
    return callback(null, null);
  }

  const model = this.model;
  const projection = clone(this._fields);
  const userProvidedFields = this._userProvidedFields || {};
  // `populate`, `lean`
  const mongooseOptions = this._mongooseOptions;

  const options = this.options;
  if (!options.lean && mongooseOptions.lean) {
    options.lean = mongooseOptions.lean;
  }

  if (options.explain) {
    return callback(null, doc);
  }

  if (!mongooseOptions.populate) {
    const versionKey = this.schema.options.versionKey;
    if (mongooseOptions.lean && mongooseOptions.lean.versionKey === false && versionKey) {
      if (versionKey in doc) {
        delete doc[versionKey];
      }
    }
    return mongooseOptions.lean ?
      _completeOneLean(model.schema, doc, null, res, options, callback) :
      completeOne(model, doc, res, options, projection, userProvidedFields,
        null, callback);
  }

  const pop = helpers.preparePopulationOptionsMQ(this, this._mongooseOptions);
  if (mongooseOptions.lean) {
    return model.populate(doc, pop).then(
      doc => {
        _completeOneLean(model.schema, doc, null, res, options, callback);
      },
      error => {
        callback(error);
      }
    );
  }

  completeOne(model, doc, res, options, projection, userProvidedFields, [], (err, doc) => {
    if (err != null) {
      return callback(err);
    }
    model.populate(doc, pop).then(res => { callback(null, res); }, err => { callback(err); });
  });
};

/**
 * Given a model and an array of docs, hydrates all the docs to be instances
 * of the model. Used to initialize docs returned from the db from `find()`
 *
 * @param {Array} docs
 * @param {Object} fields the projection used, including `select` from schemas
 * @param {Object} userProvidedFields the user-specified projection
 * @param {Object} [opts]
 * @param {Array} [opts.populated]
 * @param {ClientSession} [opts.session]
 * @api private
 */

Query.prototype._completeMany = async function _completeMany(docs, fields, userProvidedFields, opts) {
  const model = this.model;
  return Promise.all(docs.map(doc => new Promise((resolve, reject) => {
    const rawDoc = doc;
    doc = helpers.createModel(model, doc, fields, userProvidedFields);
    if (opts.session != null) {
      doc.$session(opts.session);
    }
    doc.$init(rawDoc, opts, (err) => {
      if (err != null) {
        return reject(err);
      }
      resolve(doc);
    });
  })));
};

/**
 * Internal helper to execute a findOne() operation
 *
 * @see findOne https://www.mongodb.com/docs/manual/reference/method/db.collection.findOne/
 * @api private
 */

Query.prototype._findOne = async function _findOne() {
  this._castConditions();

  if (this.error()) {
    const err = this.error();
    throw err;
  }

  applyGlobalMaxTimeMS(this.options, this.model.db.options, this.model.base.options);
  applyGlobalDiskUse(this.options, this.model.db.options, this.model.base.options);

  const options = this._optionsForExec();

  this._applyTranslateAliases(options);

  // don't pass in the conditions because we already merged them in
  const doc = await this.mongooseCollection.findOne(this._conditions, options);
  return new Promise((resolve, reject) => {
    this._completeOne(doc, null, (err, res) => {
      if (err) {
        return reject(err);
      }
      resolve(res);
    });
  });
};

/**
 * Declares the query a findOne operation. When executed, the first found document is passed to the callback.
 *
 * The result of the query is a single document, or `null` if no document was found.
 *
 * * *Note:* `conditions` is optional, and if `conditions` is null or undefined,
 * mongoose will send an empty `findOne` command to MongoDB, which will return
 * an arbitrary document. If you're querying by `_id`, use `Model.findById()`
 * instead.
 *
 * This function triggers the following middleware.
 *
 * - `findOne()`
 *
 * #### Example:
 *
 *     const query = Kitten.where({ color: 'white' });
 *     const kitten = await query.findOne();
 *
 * @param {Object} [filter] mongodb selector
 * @param {Object} [projection] optional fields to return
 * @param {Object} [options] see [`setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query} this
 * @see findOne https://www.mongodb.com/docs/manual/reference/method/db.collection.findOne/
 * @see Query.select https://mongoosejs.com/docs/api/query.html#Query.prototype.select()
 * @api public
 */

Query.prototype.findOne = function(conditions, projection, options) {
  if (typeof conditions === 'function' ||
      typeof projection === 'function' ||
      typeof options === 'function' ||
      typeof arguments[3] === 'function') {
    throw new MongooseError('Query.prototype.findOne() no longer accepts a callback');
  }

  this.op = 'findOne';
  this._validateOp();

  if (options) {
    this.setOptions(options);
  }

  if (projection) {
    this.select(projection);
  }

  if (mquery.canMerge(conditions)) {
    this.merge(conditions);

    prepareDiscriminatorCriteria(this);
  } else if (conditions != null) {
    this.error(new ObjectParameterError(conditions, 'filter', 'findOne'));
  }

  return this;
};


/**
 * Execute a countDocuments query
 *
 * @see countDocuments https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#countDocuments
 * @api private
 */

Query.prototype._countDocuments = async function _countDocuments() {
  try {
    this.cast(this.model);
  } catch (err) {
    this.error(err);
  }

  if (this.error()) {
    throw this.error();
  }

  applyGlobalMaxTimeMS(this.options, this.model.db.options, this.model.base.options);
  applyGlobalDiskUse(this.options, this.model.db.options, this.model.base.options);

  const options = this._optionsForExec();

  this._applyTranslateAliases(options);

  const conds = this._conditions;

  return this.mongooseCollection.countDocuments(conds, options);
};

/*!
 * If `translateAliases` option is set, call `Model.translateAliases()`
 * on the following query properties: filter, projection, update, distinct.
 */

Query.prototype._applyTranslateAliases = function _applyTranslateAliases(options) {
  let applyTranslateAliases = false;
  if ('translateAliases' in this._mongooseOptions) {
    applyTranslateAliases = this._mongooseOptions.translateAliases;
  } else if (this.model?.schema?._userProvidedOptions?.translateAliases != null) {
    applyTranslateAliases = this.model.schema._userProvidedOptions.translateAliases;
  } else if (this.model?.base?.options?.translateAliases != null) {
    applyTranslateAliases = this.model.base.options.translateAliases;
  }
  if (!applyTranslateAliases) {
    return;
  }

  if (this.model?.schema?.aliases && Object.keys(this.model.schema.aliases).length > 0) {
    this.model.translateAliases(this._conditions, true);
    this.model.translateAliases(options.projection, true);
    this.model.translateAliases(this._update, true);
    if (this._distinct != null && this.model.schema.aliases[this._distinct] != null) {
      this._distinct = this.model.schema.aliases[this._distinct];
    }
  }
};

/**
 * Execute a estimatedDocumentCount() query
 *
 * @see estimatedDocumentCount https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#estimatedDocumentCount
 * @api private
 */

Query.prototype._estimatedDocumentCount = async function _estimatedDocumentCount() {
  if (this.error()) {
    throw this.error();
  }

  const options = this._optionsForExec();

  return this.mongooseCollection.estimatedDocumentCount(options);
};

/**
 * Specifies this query as a `estimatedDocumentCount()` query. Faster than
 * using `countDocuments()` for large collections because
 * `estimatedDocumentCount()` uses collection metadata rather than scanning
 * the entire collection.
 *
 * `estimatedDocumentCount()` does **not** accept a filter. `Model.find({ foo: bar }).estimatedDocumentCount()`
 * is equivalent to `Model.find().estimatedDocumentCount()`
 *
 * This function triggers the following middleware.
 *
 * - `estimatedDocumentCount()`
 *
 * #### Example:
 *
 *     await Model.find().estimatedDocumentCount();
 *
 * @param {Object} [options] passed transparently to the [MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/EstimatedDocumentCountOptions.html)
 * @return {Query} this
 * @see estimatedDocumentCount https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#estimatedDocumentCount
 * @api public
 */

Query.prototype.estimatedDocumentCount = function(options) {
  if (typeof options === 'function' ||
      typeof arguments[1] === 'function') {
    throw new MongooseError('Query.prototype.estimatedDocumentCount() no longer accepts a callback');
  }

  this.op = 'estimatedDocumentCount';
  this._validateOp();

  if (typeof options === 'object' && options != null) {
    this.setOptions(options);
  }

  return this;
};

/**
 * Specifies this query as a `countDocuments()` query. Behaves like `count()`,
 * except it always does a full collection scan when passed an empty filter `{}`.
 *
 * There are also minor differences in how `countDocuments()` handles
 * [`$where` and a couple geospatial operators](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#countDocuments).
 * versus `count()`.
 *
 * This function triggers the following middleware.
 *
 * - `countDocuments()`
 *
 * #### Example:
 *
 *     const countQuery = model.where({ 'color': 'black' }).countDocuments();
 *
 *     query.countDocuments({ color: 'black' }).count().exec();
 *
 *     await query.countDocuments({ color: 'black' });
 *
 *     query.where('color', 'black').countDocuments().exec();
 *
 * The `countDocuments()` function is similar to `count()`, but there are a
 * [few operators that `countDocuments()` does not support](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#countDocuments).
 * Below are the operators that `count()` supports but `countDocuments()` does not,
 * and the suggested replacement:
 *
 * - `$where`: [`$expr`](https://www.mongodb.com/docs/manual/reference/operator/query/expr/)
 * - `$near`: [`$geoWithin`](https://www.mongodb.com/docs/manual/reference/operator/query/geoWithin/) with [`$center`](https://www.mongodb.com/docs/manual/reference/operator/query/center/#op._S_center)
 * - `$nearSphere`: [`$geoWithin`](https://www.mongodb.com/docs/manual/reference/operator/query/geoWithin/) with [`$centerSphere`](https://www.mongodb.com/docs/manual/reference/operator/query/centerSphere/#op._S_centerSphere)
 *
 * @param {Object} [filter] mongodb selector
 * @param {Object} [options]
 * @return {Query} this
 * @see countDocuments https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#countDocuments
 * @api public
 */

Query.prototype.countDocuments = function(conditions, options) {
  if (typeof conditions === 'function' ||
      typeof options === 'function' ||
      typeof arguments[2] === 'function') {
    throw new MongooseError('Query.prototype.countDocuments() no longer accepts a callback');
  }

  this.op = 'countDocuments';
  this._validateOp();

  if (mquery.canMerge(conditions)) {
    this.merge(conditions);
  }

  if (typeof options === 'object' && options != null) {
    this.setOptions(options);
  }

  return this;
};

/**
 * Execute a `distinct()` query
 *
 * @see distinct https://www.mongodb.com/docs/manual/reference/method/db.collection.distinct/
 * @api private
 */

Query.prototype.__distinct = async function __distinct() {
  this._castConditions();

  if (this.error()) {
    throw this.error();
  }

  applyGlobalMaxTimeMS(this.options, this.model.db.options, this.model.base.options);
  applyGlobalDiskUse(this.options, this.model.db.options, this.model.base.options);

  const options = this._optionsForExec();
  this._applyTranslateAliases(options);

  return this.mongooseCollection.
    distinct(this._distinct, this._conditions, options);
};

/**
 * Declares or executes a distinct() operation.
 *
 * This function does not trigger any middleware.
 *
 * #### Example:
 *
 *     distinct(field, conditions)
 *     distinct(field)
 *     distinct()
 *
 * @param {String} [field]
 * @param {Object|Query} [filter]
 * @return {Query} this
 * @see distinct https://www.mongodb.com/docs/manual/reference/method/db.collection.distinct/
 * @api public
 */

Query.prototype.distinct = function(field, conditions) {
  if (typeof field === 'function' ||
      typeof conditions === 'function' ||
      typeof arguments[2] === 'function') {
    throw new MongooseError('Query.prototype.distinct() no longer accepts a callback');
  }

  this.op = 'distinct';
  this._validateOp();

  if (mquery.canMerge(conditions)) {
    this.merge(conditions);

    prepareDiscriminatorCriteria(this);
  } else if (conditions != null) {
    this.error(new ObjectParameterError(conditions, 'filter', 'distinct'));
  }

  if (field != null) {
    this._distinct = field;
  }

  return this;
};

/**
 * Sets the sort order
 *
 * If an object is passed, values allowed are `asc`, `desc`, `ascending`, `descending`, `1`, and `-1`.
 *
 * If a string is passed, it must be a space delimited list of path names. The
 * sort order of each path is ascending unless the path name is prefixed with `-`
 * which will be treated as descending.
 *
 * #### Example:
 *
 *     // sort by "field" ascending and "test" descending
 *     query.sort({ field: 'asc', test: -1 });
 *
 *     // equivalent
 *     query.sort('field -test');
 *
 *     // also possible is to use a array with array key-value pairs
 *     query.sort([['field', 'asc']]);
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @param {Object|String|Array<Array<(string | number)>>} arg
 * @param {Object} [options]
 * @param {Boolean} [options.override=false] If true, replace existing sort options with `arg`
 * @return {Query} this
 * @see cursor.sort https://www.mongodb.com/docs/manual/reference/method/cursor.sort/
 * @api public
 */

Query.prototype.sort = function(arg, options) {
  if (arguments.length > 2) {
    throw new Error('sort() takes at most 2 arguments');
  }
  if (options != null && typeof options !== 'object') {
    throw new Error('sort() options argument must be an object or nullish');
  }

  if (this.options.sort == null) {
    this.options.sort = {};
  }
  if (options && options.override) {
    this.options.sort = {};
  }
  const sort = this.options.sort;
  if (typeof arg === 'string') {
    const properties = arg.indexOf(' ') === -1 ? [arg] : arg.split(' ');
    for (let property of properties) {
      const ascend = '-' == property[0] ? -1 : 1;
      if (ascend === -1) {
        property = property.slice(1);
      }
      if (specialProperties.has(property)) {
        continue;
      }
      sort[property] = ascend;
    }
  } else if (Array.isArray(arg)) {
    for (const pair of arg) {
      if (!Array.isArray(pair)) {
        throw new TypeError('Invalid sort() argument, must be array of arrays');
      }
      const key = '' + pair[0];
      if (specialProperties.has(key)) {
        continue;
      }
      sort[key] = _handleSortValue(pair[1], key);
    }
  } else if (typeof arg === 'object' && arg != null && !(arg instanceof Map)) {
    for (const key of Object.keys(arg)) {
      if (specialProperties.has(key)) {
        continue;
      }
      sort[key] = _handleSortValue(arg[key], key);
    }
  } else if (arg instanceof Map) {
    for (let key of arg.keys()) {
      key = '' + key;
      if (specialProperties.has(key)) {
        continue;
      }
      sort[key] = _handleSortValue(arg.get(key), key);
    }
  } else if (arg != null) {
    throw new TypeError('Invalid sort() argument. Must be a string, object, array, or map.');
  }

  return this;
};

/*!
 * Convert sort values
 */

function _handleSortValue(val, key) {
  if (val === 1 || val === 'asc' || val === 'ascending') {
    return 1;
  }
  if (val === -1 || val === 'desc' || val === 'descending') {
    return -1;
  }
  if (val?.$meta != null) {
    return { $meta: val.$meta };
  }
  throw new TypeError('Invalid sort value: { ' + key + ': ' + val + ' }');
}

/**
 * Declare and/or execute this query as a `deleteOne()` operation. Works like
 * remove, except it deletes at most one document regardless of the `single`
 * option.
 *
 * This function triggers `deleteOne` middleware.
 *
 * #### Example:
 *
 *     await Character.deleteOne({ name: 'Eddard Stark' });
 *
 * This function calls the MongoDB driver's [`Collection#deleteOne()` function](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#deleteOne).
 * The returned [promise](https://mongoosejs.com/docs/queries.html) resolves to an
 * object that contains 3 properties:
 *
 * - `ok`: `1` if no errors occurred
 * - `deletedCount`: the number of documents deleted
 * - `n`: the number of documents deleted. Equal to `deletedCount`.
 *
 * #### Example:
 *
 *     const res = await Character.deleteOne({ name: 'Eddard Stark' });
 *     // `1` if MongoDB deleted a doc, `0` if no docs matched the filter `{ name: ... }`
 *     res.deletedCount;
 *
 * @param {Object|Query} [filter] mongodb selector
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @return {Query} this
 * @see DeleteResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/DeleteResult.html
 * @see deleteOne https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#deleteOne
 * @api public
 */

Query.prototype.deleteOne = function deleteOne(filter, options) {
  if (typeof filter === 'function' || typeof options === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Query.prototype.deleteOne() no longer accepts a callback');
  }
  this.op = 'deleteOne';
  this.setOptions(options);

  if (mquery.canMerge(filter)) {
    this.merge(filter);

    prepareDiscriminatorCriteria(this);
  } else if (filter != null) {
    this.error(new ObjectParameterError(filter, 'filter', 'deleteOne'));
  }

  return this;
};

/**
 * Internal thunk for `deleteOne()`
 *
 * @method _deleteOne
 * @instance
 * @memberOf Query
 * @api private
 */

Query.prototype._deleteOne = async function _deleteOne() {
  this._castConditions();

  if (this.error() != null) {
    throw this.error();
  }

  const options = this._optionsForExec();
  this._applyTranslateAliases(options);

  return this.mongooseCollection.deleteOne(this._conditions, options);
};

/**
 * Declare and/or execute this query as a `deleteMany()` operation. Works like
 * remove, except it deletes _every_ document that matches `filter` in the
 * collection, regardless of the value of `single`.
 *
 * This function triggers `deleteMany` middleware.
 *
 * #### Example:
 *
 *     await Character.deleteMany({ name: /Stark/, age: { $gte: 18 } });
 *
 * This function calls the MongoDB driver's [`Collection#deleteMany()` function](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#deleteMany).
 * The returned [promise](https://mongoosejs.com/docs/queries.html) resolves to an
 * object that contains 3 properties:
 *
 * - `ok`: `1` if no errors occurred
 * - `deletedCount`: the number of documents deleted
 * - `n`: the number of documents deleted. Equal to `deletedCount`.
 *
 * #### Example:
 *
 *     const res = await Character.deleteMany({ name: /Stark/, age: { $gte: 18 } });
 *     // `0` if no docs matched the filter, number of docs deleted otherwise
 *     res.deletedCount;
 *
 * @param {Object|Query} [filter] mongodb selector
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @return {Query} this
 * @see DeleteResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/DeleteResult.html
 * @see deleteMany https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#deleteMany
 * @api public
 */

Query.prototype.deleteMany = function(filter, options) {
  if (typeof filter === 'function' || typeof options === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Query.prototype.deleteMany() no longer accepts a callback');
  }
  this.setOptions(options);
  this.op = 'deleteMany';

  if (mquery.canMerge(filter)) {
    this.merge(filter);

    prepareDiscriminatorCriteria(this);
  } else if (filter != null) {
    this.error(new ObjectParameterError(filter, 'filter', 'deleteMany'));
  }

  return this;
};

/**
 * Execute a `deleteMany()` query
 *
 * @param {Function} callback
 * @method _deleteMany
 * @instance
 * @memberOf Query
 * @api private
 */

Query.prototype._deleteMany = async function _deleteMany() {
  this._castConditions();

  if (this.error() != null) {
    throw this.error();
  }

  const options = this._optionsForExec();
  this._applyTranslateAliases(options);

  return this.mongooseCollection.deleteMany(this._conditions, options);
};

/**
 * hydrates a document
 *
 * @param {Model} model
 * @param {Document} doc
 * @param {Object} res 3rd parameter to callback
 * @param {Object} fields
 * @param {Query} self
 * @param {Array} [pop] array of paths used in population
 * @param {Function} callback
 * @api private
 */

function completeOne(model, doc, res, options, fields, userProvidedFields, pop, callback) {
  if (options.includeResultMetadata && doc == null) {
    _init(null);
    return null;
  }

  helpers.createModelAndInit(model, doc, fields, userProvidedFields, options, pop, _init);

  function _init(err, casted) {
    if (err) {
      return immediate(() => callback(err));
    }


    if (options.includeResultMetadata) {
      if (doc && casted) {
        if (options.session != null) {
          casted.$session(options.session);
        }
        res.value = casted;
      } else {
        res.value = null;
      }
      return immediate(() => callback(null, res));
    }
    if (options.session != null) {
      casted.$session(options.session);
    }
    immediate(() => callback(null, casted));
  }
}

/**
 * If the model is a discriminator type and not root, then add the key & value to the criteria.
 * @param {Query} query
 * @api private
 */

function prepareDiscriminatorCriteria(query) {
  if (!query || !query.model || !query.model.schema) {
    return;
  }

  const schema = query.model.schema;

  if (schema && schema.discriminatorMapping && !schema.discriminatorMapping.isRoot) {
    query._conditions[schema.discriminatorMapping.key] = schema.discriminatorMapping.value;
  }
}

/**
 * Issues a mongodb `findOneAndUpdate()` command.
 *
 * Finds a matching document, updates it according to the `update` arg, passing any `options`, and returns the found
 * document (if any).
 *
 * This function triggers the following middleware.
 *
 * - `findOneAndUpdate()`
 *
 * #### Available options
 *
 * - `new`: bool - if true, return the modified document rather than the original. defaults to false (changed in 4.0)
 * - `upsert`: bool - creates the object if it doesn't exist. defaults to false.
 * - `fields`: {Object|String} - Field selection. Equivalent to `.select(fields).findOneAndUpdate()`
 * - `sort`: if multiple docs are found by the conditions, sets the sort order to choose which doc to update
 * - `maxTimeMS`: puts a time limit on the query - requires mongodb >= 2.6.0
 * - `runValidators`: if true, runs [update validators](https://mongoosejs.com/docs/validation.html#update-validators) on this command. Update validators validate the update operation against the model's schema.
 * - `setDefaultsOnInsert`: `true` by default. If `setDefaultsOnInsert` and `upsert` are true, mongoose will apply the [defaults](https://mongoosejs.com/docs/defaults.html) specified in the model's schema if a new document is created.
 *
 * #### Example:
 *
 *     query.findOneAndUpdate(conditions, update, options)  // returns Query
 *     query.findOneAndUpdate(conditions, update)           // returns Query
 *     query.findOneAndUpdate(update)                       // returns Query
 *     query.findOneAndUpdate()                             // returns Query
 *
 * @method findOneAndUpdate
 * @memberOf Query
 * @instance
 * @param {Object|Query} [filter]
 * @param {Object} [doc]
 * @param {Object} [options]
 * @param {Boolean} [options.includeResultMetadata] if true, returns the full [ModifyResult from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html) rather than just the document
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean} [options.multipleCastError] by default, mongoose only returns the first error that occurred in casting the query. Turn on this option to aggregate all the cast errors.
 * @param {Boolean} [options.new=false] By default, `findOneAndUpdate()` returns the document as it was **before** `update` was applied. If you set `new: true`, `findOneAndUpdate()` will instead give you the object after `update` was applied.
 * @param {Object} [options.lean] if truthy, mongoose will return the document as a plain JavaScript object rather than a mongoose document. See [`Query.lean()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.lean()) and [the Mongoose lean tutorial](https://mongoosejs.com/docs/tutorials/lean.html).
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Note that this allows you to overwrite timestamps. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.returnOriginal=null] An alias for the `new` option. `returnOriginal: false` is equivalent to `new: true`.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Boolean} [options.overwriteDiscriminatorKey=false] Mongoose removes discriminator key updates from `update` by default, set `overwriteDiscriminatorKey` to `true` to allow updating the discriminator key
 * @see Tutorial https://mongoosejs.com/docs/tutorials/findoneandupdate.html
 * @see findAndModify command https://www.mongodb.com/docs/manual/reference/command/findAndModify/
 * @see ModifyResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html
 * @see findOneAndUpdate https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#findOneAndUpdate
 * @return {Query} this
 * @api public
 */

Query.prototype.findOneAndUpdate = function(filter, doc, options) {
  if (typeof filter === 'function' ||
      typeof doc === 'function' ||
      typeof options === 'function' ||
      typeof arguments[3] === 'function') {
    throw new MongooseError('Query.prototype.findOneAndUpdate() no longer accepts a callback');
  }

  this.op = 'findOneAndUpdate';
  this._validateOp();
  this._validate();

  switch (arguments.length) {
    case 2:
      options = undefined;
      break;
    case 1:
      doc = filter;
      filter = options = undefined;
      break;
  }

  if (mquery.canMerge(filter)) {
    this.merge(filter);
  } else if (filter != null) {
    this.error(
      new ObjectParameterError(filter, 'filter', 'findOneAndUpdate')
    );
  }

  // apply doc
  if (doc) {
    this._mergeUpdate(doc);
  }

  options = options ? clone(options) : {};

  if (options.projection) {
    this.select(options.projection);
    delete options.projection;
  }
  if (options.fields) {
    this.select(options.fields);
    delete options.fields;
  }

  const returnOriginal = this &&
    this.model &&
    this.model.base &&
    this.model.base.options &&
    this.model.base.options.returnOriginal;
  if (options.new == null && options.returnDocument == null && options.returnOriginal == null && returnOriginal != null) {
    options.returnOriginal = returnOriginal;
  }

  this.setOptions(options);

  return this;
};

/**
 * Execute a findOneAndUpdate operation
 *
 * @method _findOneAndUpdate
 * @memberOf Query
 * @api private
 */

Query.prototype._findOneAndUpdate = async function _findOneAndUpdate() {
  this._castConditions();

  _castArrayFilters(this);

  if (this.error()) {
    throw this.error();
  }

  applyGlobalMaxTimeMS(this.options, this.model.db.options, this.model.base.options);
  applyGlobalDiskUse(this.options, this.model.db.options, this.model.base.options);

  if ('strict' in this.options) {
    this._mongooseOptions.strict = this.options.strict;
  }
  const options = this._optionsForExec(this.model);
  convertNewToReturnDocument(options);
  this._applyTranslateAliases(options);

  this._update = this._castUpdate(this._update);

  const _opts = Object.assign({}, options, {
    setDefaultsOnInsert: this._mongooseOptions.setDefaultsOnInsert
  });
  this._update = setDefaultsOnInsert(this._conditions, this.model.schema,
    this._update, _opts);

  if (!this._update || Object.keys(this._update).length === 0) {
    if (options.upsert) {
      // still need to do the upsert to empty doc
      const doc = clone(this._update);
      delete doc._id;
      this._update = { $set: doc };
    } else {
      this._executionStack = null;
      const res = await this._findOne();
      return res;
    }
  } else if (this._update instanceof Error) {
    throw this._update;
  } else {
    // In order to make MongoDB 2.6 happy (see
    // https://jira.mongodb.org/browse/SERVER-12266 and related issues)
    // if we have an actual update document but $set is empty, junk the $set.
    if (this._update.$set && Object.keys(this._update.$set).length === 0) {
      delete this._update.$set;
    }
  }

  const runValidators = _getOption(this, 'runValidators', false);
  if (runValidators) {
    await this.validate(this._update, options, false);
  }

  if (this._update.toBSON) {
    this._update = this._update.toBSON();
  }

  let res = await this.mongooseCollection.findOneAndUpdate(this._conditions, this._update, options);
  for (const fn of this._transforms) {
    res = fn(res);
  }
  const doc = !options.includeResultMetadata ? res : res.value;

  return new Promise((resolve, reject) => {
    this._completeOne(doc, res, (err, res) => {
      if (err) {
        return reject(err);
      }
      resolve(res);
    });
  });
};

/**
 * Issues a MongoDB [findOneAndDelete](https://www.mongodb.com/docs/manual/reference/method/db.collection.findOneAndDelete/) command.
 *
 * Finds a matching document, removes it, and returns the found document (if any).
 *
 * This function triggers the following middleware.
 *
 * - `findOneAndDelete()`
 *
 * #### Available options
 *
 * - `sort`: if multiple docs are found by the conditions, sets the sort order to choose which doc to update
 * - `maxTimeMS`: puts a time limit on the query - requires mongodb >= 2.6.0
 *
 * #### Callback Signature
 *
 *     function(error, doc) {
 *       // error: any errors that occurred
 *       // doc: the document before updates are applied if `new: false`, or after updates if `new = true`
 *     }
 *
 * #### Example:
 *
 *     A.where().findOneAndDelete(conditions, options)  // return Query
 *     A.where().findOneAndDelete(conditions) // returns Query
 *     A.where().findOneAndDelete()           // returns Query
 *
 * @method findOneAndDelete
 * @memberOf Query
 * @param {Object} [filter]
 * @param {Object} [options]
 * @param {Boolean} [options.includeResultMetadata] if true, returns the full [ModifyResult from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html) rather than just the document
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @return {Query} this
 * @see findAndModify command https://www.mongodb.com/docs/manual/reference/command/findAndModify/
 * @api public
 */

Query.prototype.findOneAndDelete = function(filter, options) {
  if (typeof filter === 'function' ||
      typeof options === 'function' ||
      typeof arguments[2] === 'function') {
    throw new MongooseError('Query.prototype.findOneAndDelete() no longer accepts a callback');
  }

  this.op = 'findOneAndDelete';
  this._validateOp();
  this._validate();

  if (mquery.canMerge(filter)) {
    this.merge(filter);
  }

  options && this.setOptions(options);

  return this;
};

/**
 * Execute a `findOneAndDelete()` query
 *
 * @return {Query} this
 * @method _findOneAndDelete
 * @memberOf Query
 * @api private
 */
Query.prototype._findOneAndDelete = async function _findOneAndDelete() {
  this._castConditions();

  if (this.error() != null) {
    throw this.error();
  }

  const includeResultMetadata = this.options.includeResultMetadata;

  const filter = this._conditions;
  const options = this._optionsForExec(this.model);
  this._applyTranslateAliases(options);

  let res = await this.mongooseCollection.findOneAndDelete(filter, options);
  for (const fn of this._transforms) {
    res = fn(res);
  }
  const doc = !includeResultMetadata ? res : res.value;

  return new Promise((resolve, reject) => {
    this._completeOne(doc, res, (err, res) => {
      if (err) {
        return reject(err);
      }
      resolve(res);
    });
  });
};

/**
 * Issues a MongoDB [findOneAndReplace](https://www.mongodb.com/docs/manual/reference/method/db.collection.findOneAndReplace/) command.
 *
 * Finds a matching document, removes it, and returns the found document (if any).
 *
 * This function triggers the following middleware.
 *
 * - `findOneAndReplace()`
 *
 * #### Available options
 *
 * - `sort`: if multiple docs are found by the conditions, sets the sort order to choose which doc to update
 * - `maxTimeMS`: puts a time limit on the query - requires mongodb >= 2.6.0
 * - `includeResultMetadata`: if true, returns the full [ModifyResult from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html) rather than just the document
 *
 * #### Callback Signature
 *
 *     function(error, doc) {
 *       // error: any errors that occurred
 *       // doc: the document before updates are applied if `new: false`, or after updates if `new = true`
 *     }
 *
 * #### Example:
 *
 *     A.where().findOneAndReplace(filter, replacement, options); // return Query
 *     A.where().findOneAndReplace(filter); // returns Query
 *     A.where().findOneAndReplace(); // returns Query
 *
 * @method findOneAndReplace
 * @memberOf Query
 * @param {Object} [filter]
 * @param {Object} [replacement]
 * @param {Object} [options]
 * @param {Boolean} [options.includeResultMetadata] if true, returns the full [ModifyResult from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html) rather than just the document
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.new=false] By default, `findOneAndUpdate()` returns the document as it was **before** `update` was applied. If you set `new: true`, `findOneAndUpdate()` will instead give you the object after `update` was applied.
 * @param {Object} [options.lean] if truthy, mongoose will return the document as a plain JavaScript object rather than a mongoose document. See [`Query.lean()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.lean()) and [the Mongoose lean tutorial](https://mongoosejs.com/docs/tutorials/lean.html).
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Note that this allows you to overwrite timestamps. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.returnOriginal=null] An alias for the `new` option. `returnOriginal: false` is equivalent to `new: true`.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query} this
 * @api public
 */

Query.prototype.findOneAndReplace = function(filter, replacement, options) {
  if (typeof filter === 'function' ||
      typeof replacement === 'function' ||
      typeof options === 'function' ||
      typeof arguments[4] === 'function') {
    throw new MongooseError('Query.prototype.findOneAndReplace() no longer accepts a callback');
  }

  this.op = 'findOneAndReplace';
  this._validateOp();
  this._validate();

  if (mquery.canMerge(filter)) {
    this.merge(filter);
  } else if (filter != null) {
    this.error(
      new ObjectParameterError(filter, 'filter', 'findOneAndReplace')
    );
  }

  if (replacement != null) {
    this._mergeUpdate(replacement);
  }

  options = options || {};

  const returnOriginal = this &&
  this.model &&
  this.model.base &&
  this.model.base.options &&
  this.model.base.options.returnOriginal;
  if (options.new == null && options.returnDocument == null && options.returnOriginal == null && returnOriginal != null) {
    options.returnOriginal = returnOriginal;
  }
  this.setOptions(options);

  return this;
};

/**
 * Execute a findOneAndReplace() query
 *
 * @return {Query} this
 * @method _findOneAndReplace
 * @instance
 * @memberOf Query
 * @api private
 */
Query.prototype._findOneAndReplace = async function _findOneAndReplace() {
  this._castConditions();
  if (this.error() != null) {
    throw this.error();
  }

  if ('strict' in this.options) {
    this._mongooseOptions.strict = this.options.strict;
    delete this.options.strict;
  }

  const filter = this._conditions;
  const options = this._optionsForExec();
  this._applyTranslateAliases(options);
  convertNewToReturnDocument(options);

  const includeResultMetadata = this.options.includeResultMetadata;

  const modelOpts = { skipId: true };
  if ('strict' in this._mongooseOptions) {
    modelOpts.strict = this._mongooseOptions.strict;
  }

  const runValidators = _getOption(this, 'runValidators', false);

  try {
    const update = new this.model(this._update, null, modelOpts);
    if (runValidators) {
      await update.validate();
    } else if (update.$__.validationError) {
      throw update.$__.validationError;
    }
    this._update = update.toBSON();
  } catch (err) {
    if (err instanceof ValidationError) {
      throw err;
    }
    const validationError = new ValidationError();
    validationError.errors[err.path] = err;
    throw validationError;
  }

  let res = await this.mongooseCollection.findOneAndReplace(filter, this._update, options);

  for (const fn of this._transforms) {
    res = fn(res);
  }

  const doc = !includeResultMetadata ? res : res.value;
  return new Promise((resolve, reject) => {
    this._completeOne(doc, res, (err, res) => {
      if (err) {
        return reject(err);
      }
      resolve(res);
    });
  });
};

/**
 * Support the `new` option as an alternative to `returnOriginal` for backwards
 * compat.
 * @api private
 */

function convertNewToReturnDocument(options) {
  if ('new' in options) {
    options.returnDocument = options['new'] ? 'after' : 'before';
    delete options['new'];
  }
  if ('returnOriginal' in options) {
    options.returnDocument = options['returnOriginal'] ? 'before' : 'after';
    delete options['returnOriginal'];
  }
  // Temporary since driver 4.0.0-beta does not support `returnDocument`
  if (typeof options.returnDocument === 'string') {
    options.returnOriginal = options.returnDocument === 'before';
  }
}

/**
 * Get options from query opts, falling back to the base mongoose object.
 * @param {Query} query
 * @param {Object} option
 * @param {Any} def
 * @api private
 */

function _getOption(query, option, def) {
  const opts = query._optionsForExec(query.model);

  if (option in opts) {
    return opts[option];
  }
  if (option in query.model.base.options) {
    return query.model.base.options[option];
  }
  return def;
}

/*!
 * ignore
 */

function _completeOneLean(schema, doc, path, res, opts, callback) {
  if (opts.lean && typeof opts.lean.transform === 'function') {
    opts.lean.transform(doc);

    for (let i = 0; i < schema.childSchemas.length; i++) {
      const childPath = path ? path + '.' + schema.childSchemas[i].model.path : schema.childSchemas[i].model.path;
      const _schema = schema.childSchemas[i].schema;
      const obj = mpath.get(childPath, doc);
      if (obj == null) {
        continue;
      }
      if (Array.isArray(obj)) {
        for (let i = 0; i < obj.length; i++) {
          opts.lean.transform(obj[i]);
        }
      } else {
        opts.lean.transform(obj);
      }
      _completeOneLean(_schema, obj, childPath, res, opts);
    }
    if (callback) {
      return callback(null, doc);
    } else {
      return;
    }
  }
  if (opts.includeResultMetadata) {
    return callback(null, res);
  }
  return callback(null, doc);
}

/*!
 * ignore
 */

function _completeManyLean(schema, docs, path, opts) {
  if (opts.lean && typeof opts.lean.transform === 'function') {
    for (const doc of docs) {
      opts.lean.transform(doc);
    }

    for (let i = 0; i < schema.childSchemas.length; i++) {
      const childPath = path ? path + '.' + schema.childSchemas[i].model.path : schema.childSchemas[i].model.path;
      const _schema = schema.childSchemas[i].schema;
      let doc = mpath.get(childPath, docs);
      if (doc == null) {
        continue;
      }
      doc = doc.flat();
      for (let i = 0; i < doc.length; i++) {
        opts.lean.transform(doc[i]);
      }
      _completeManyLean(_schema, doc, childPath, opts);
    }
  }

  return docs;
}
/**
 * Override mquery.prototype._mergeUpdate to handle mongoose objects in
 * updates.
 *
 * @param {Object} doc
 * @method _mergeUpdate
 * @memberOf Query
 * @instance
 * @api private
 */

Query.prototype._mergeUpdate = function(doc) {
  if (!this._update) {
    this._update = Array.isArray(doc) ? [] : {};
  }

  if (doc == null || (typeof doc === 'object' && Object.keys(doc).length === 0)) {
    return;
  }

  if (doc instanceof Query) {
    if (Array.isArray(this._update)) {
      throw new Error('Cannot mix array and object updates');
    }
    if (doc._update) {
      utils.mergeClone(this._update, doc._update);
    }
  } else if (Array.isArray(doc)) {
    if (!Array.isArray(this._update)) {
      throw new Error('Cannot mix array and object updates');
    }
    this._update = this._update.concat(doc);
  } else {
    if (Array.isArray(this._update)) {
      throw new Error('Cannot mix array and object updates');
    }
    utils.mergeClone(this._update, doc);
  }
};

/*!
 * ignore
 */

async function _updateThunk(op) {
  this._castConditions();

  _castArrayFilters(this);

  if (this.error() != null) {
    throw this.error();
  }

  const castedQuery = this._conditions;
  const options = this._optionsForExec(this.model);
  this._applyTranslateAliases(options);

  this._update = clone(this._update, options);
  const isOverwriting = op === 'replaceOne';
  if (isOverwriting) {
    this._update = new this.model(this._update, null, true);
  } else {
    this._update = this._castUpdate(this._update);

    if (this._update == null || Object.keys(this._update).length === 0) {
      return { acknowledged: false };
    }

    const _opts = Object.assign({}, options, {
      setDefaultsOnInsert: this._mongooseOptions.setDefaultsOnInsert
    });
    this._update = setDefaultsOnInsert(this._conditions, this.model.schema,
      this._update, _opts);
  }

  if (Array.isArray(options.arrayFilters)) {
    options.arrayFilters = removeUnusedArrayFilters(this._update, options.arrayFilters);
  }

  const runValidators = _getOption(this, 'runValidators', false);
  if (runValidators) {
    await this.validate(this._update, options, isOverwriting);
  }

  if (this._update.toBSON) {
    this._update = this._update.toBSON();
  }

  return this.mongooseCollection[op](castedQuery, this._update, options);
}

/**
 * Mongoose calls this function internally to validate the query if
 * `runValidators` is set
 *
 * @param {Object} castedDoc the update, after casting
 * @param {Object} options the options from `_optionsForExec()`
 * @param {Boolean} isOverwriting
 * @method validate
 * @memberOf Query
 * @instance
 * @api private
 */

Query.prototype.validate = async function validate(castedDoc, options, isOverwriting) {
  if (typeof arguments[3] === 'function') {
    throw new MongooseError('Query.prototype.validate() no longer accepts a callback');
  }

  await _executePreHooks(this, 'validate');

  if (isOverwriting) {
    await castedDoc.$validate();
  } else {
    await new Promise((resolve, reject) => {
      updateValidators(this, this.model.schema, castedDoc, options, (err) => {
        if (err != null) {
          return reject(err);
        }
        resolve();
      });
    });
  }

  await _executePostHooks(this, null, null, 'validate');
};

/**
 * Execute an updateMany query
 *
 * @see Model.update https://mongoosejs.com/docs/api/model.html#Model.update()
 * @method _updateMany
 * @memberOf Query
 * @instance
 * @api private
 */
Query.prototype._updateMany = async function _updateMany() {
  return _updateThunk.call(this, 'updateMany');
};

/**
 * Execute an updateOne query
 *
 * @see Model.update https://mongoosejs.com/docs/api/model.html#Model.update()
 * @method _updateOne
 * @memberOf Query
 * @instance
 * @api private
 */
Query.prototype._updateOne = async function _updateOne() {
  return _updateThunk.call(this, 'updateOne');
};

/**
 * Execute a replaceOne query
 *
 * @see Model.replaceOne https://mongoosejs.com/docs/api/model.html#Model.replaceOne()
 * @method _replaceOne
 * @memberOf Query
 * @instance
 * @api private
 */
Query.prototype._replaceOne = async function _replaceOne() {
  return _updateThunk.call(this, 'replaceOne');
};

/**
 * Declare and/or execute this query as an updateMany() operation.
 * MongoDB will update _all_ documents that match `filter` (as opposed to just the first one).
 *
 * **Note** updateMany will _not_ fire update middleware. Use `pre('updateMany')`
 * and `post('updateMany')` instead.
 *
 * #### Example:
 *
 *     const res = await Person.updateMany({ name: /Stark$/ }, { isDeleted: true });
 *     res.n; // Number of documents matched
 *     res.nModified; // Number of documents modified
 *
 * This function triggers the following middleware.
 *
 * - `updateMany()`
 *
 * @param {Object} [filter]
 * @param {Object|Array} [update] the update command. If array, this update will be treated as an update pipeline and not casted.
 * @param {Object} [options]
 * @param {Boolean} [options.multipleCastError] by default, mongoose only returns the first error that occurred in casting the query. Turn on this option to aggregate all the cast errors.
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Object} [options.writeConcern=null] sets the [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/) for replica sets. Overrides the [schema-level write concern](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Boolean} [options.overwriteDiscriminatorKey=false] Mongoose removes discriminator key updates from `update` by default, set `overwriteDiscriminatorKey` to `true` to allow updating the discriminator key
 * @param {Function} [callback] params are (error, writeOpResult)
 * @return {Query} this
 * @see Model.update https://mongoosejs.com/docs/api/model.html#Model.update()
 * @see Query docs https://mongoosejs.com/docs/queries.html
 * @see update https://www.mongodb.com/docs/manual/reference/method/db.collection.update/
 * @see UpdateResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/UpdateResult.html
 * @see MongoDB docs https://www.mongodb.com/docs/manual/reference/command/update/#update-command-output
 * @api public
 */

Query.prototype.updateMany = function(conditions, doc, options, callback) {
  if (typeof options === 'function') {
    // .update(conditions, doc, callback)
    callback = options;
    options = null;
  } else if (typeof doc === 'function') {
    // .update(doc, callback);
    callback = doc;
    doc = conditions;
    conditions = {};
    options = null;
  } else if (typeof conditions === 'function') {
    // .update(callback)
    callback = conditions;
    conditions = undefined;
    doc = undefined;
    options = undefined;
  } else if (typeof conditions === 'object' && !doc && !options && !callback) {
    // .update(doc)
    doc = conditions;
    conditions = undefined;
    options = undefined;
    callback = undefined;
  }

  return _update(this, 'updateMany', conditions, doc, options, callback);
};

/**
 * Declare and/or execute this query as an updateOne() operation.
 * MongoDB will update _only_ the first document that matches `filter`.
 *
 * - Use `replaceOne()` if you want to overwrite an entire document rather than using [atomic operators](https://www.mongodb.com/docs/manual/tutorial/model-data-for-atomic-operations/#pattern) like `$set`.
 *
 * **Note** updateOne will _not_ fire update middleware. Use `pre('updateOne')`
 * and `post('updateOne')` instead.
 *
 * #### Example:
 *
 *     const res = await Person.updateOne({ name: 'Jean-Luc Picard' }, { ship: 'USS Enterprise' });
 *     res.acknowledged; // Indicates if this write result was acknowledged. If not, then all other members of this result will be undefined.
 *     res.matchedCount; // Number of documents that matched the filter
 *     res.modifiedCount; // Number of documents that were modified
 *     res.upsertedCount; // Number of documents that were upserted
 *     res.upsertedId; // Identifier of the inserted document (if an upsert took place)
 *
 * This function triggers the following middleware.
 *
 * - `updateOne()`
 *
 * @param {Object} [filter]
 * @param {Object|Array} [update] the update command. If array, this update will be treated as an update pipeline and not casted.
 * @param {Object} [options]
 * @param {Boolean} [options.multipleCastError] by default, mongoose only returns the first error that occurred in casting the query. Turn on this option to aggregate all the cast errors.
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Object} [options.writeConcern=null] sets the [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/) for replica sets. Overrides the [schema-level write concern](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Note that this allows you to overwrite timestamps. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Boolean} [options.overwriteDiscriminatorKey=false] Mongoose removes discriminator key updates from `update` by default, set `overwriteDiscriminatorKey` to `true` to allow updating the discriminator key
 * @param {Function} [callback] params are (error, writeOpResult)
 * @return {Query} this
 * @see Model.update https://mongoosejs.com/docs/api/model.html#Model.update()
 * @see Query docs https://mongoosejs.com/docs/queries.html
 * @see update https://www.mongodb.com/docs/manual/reference/method/db.collection.update/
 * @see UpdateResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/UpdateResult.html
 * @see MongoDB docs https://www.mongodb.com/docs/manual/reference/command/update/#update-command-output
 * @api public
 */

Query.prototype.updateOne = function(conditions, doc, options, callback) {
  if (typeof options === 'function') {
    // .update(conditions, doc, callback)
    callback = options;
    options = null;
  } else if (typeof doc === 'function') {
    // .update(doc, callback);
    callback = doc;
    doc = conditions;
    conditions = {};
    options = null;
  } else if (typeof conditions === 'function') {
    // .update(callback)
    callback = conditions;
    conditions = undefined;
    doc = undefined;
    options = undefined;
  } else if (typeof conditions === 'object' && !doc && !options && !callback) {
    // .update(doc)
    doc = conditions;
    conditions = undefined;
    options = undefined;
    callback = undefined;
  }

  return _update(this, 'updateOne', conditions, doc, options, callback);
};

/**
 * Declare and/or execute this query as a replaceOne() operation.
 * MongoDB will replace the existing document and will not accept any [atomic operators](https://www.mongodb.com/docs/manual/tutorial/model-data-for-atomic-operations/#pattern) (`$set`, etc.)
 *
 * **Note** replaceOne will _not_ fire update middleware. Use `pre('replaceOne')`
 * and `post('replaceOne')` instead.
 *
 * #### Example:
 *
 *     const res = await Person.replaceOne({ _id: 24601 }, { name: 'Jean Valjean' });
 *     res.acknowledged; // Indicates if this write result was acknowledged. If not, then all other members of this result will be undefined.
 *     res.matchedCount; // Number of documents that matched the filter
 *     res.modifiedCount; // Number of documents that were modified
 *     res.upsertedCount; // Number of documents that were upserted
 *     res.upsertedId; // Identifier of the inserted document (if an upsert took place)
 *
 * This function triggers the following middleware.
 *
 * - `replaceOne()`
 *
 * @param {Object} [filter]
 * @param {Object} [doc] the update command
 * @param {Object} [options]
 * @param {Boolean} [options.multipleCastError] by default, mongoose only returns the first error that occurred in casting the query. Turn on this option to aggregate all the cast errors.
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Object} [options.writeConcern=null] sets the [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/) for replica sets. Overrides the [schema-level write concern](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Function} [callback] params are (error, writeOpResult)
 * @return {Query} this
 * @see Model.update https://mongoosejs.com/docs/api/model.html#Model.update()
 * @see Query docs https://mongoosejs.com/docs/queries.html
 * @see update https://www.mongodb.com/docs/manual/reference/method/db.collection.update/
 * @see UpdateResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/UpdateResult.html
 * @see MongoDB docs https://www.mongodb.com/docs/manual/reference/command/update/#update-command-output
 * @api public
 */

Query.prototype.replaceOne = function(conditions, doc, options, callback) {
  if (typeof options === 'function') {
    // .update(conditions, doc, callback)
    callback = options;
    options = null;
  } else if (typeof doc === 'function') {
    // .update(doc, callback);
    callback = doc;
    doc = conditions;
    conditions = {};
    options = null;
  } else if (typeof conditions === 'function') {
    // .update(callback)
    callback = conditions;
    conditions = undefined;
    doc = undefined;
    options = undefined;
  } else if (typeof conditions === 'object' && !doc && !options && !callback) {
    // .update(doc)
    doc = conditions;
    conditions = undefined;
    options = undefined;
    callback = undefined;
  }

  return _update(this, 'replaceOne', conditions, doc, options, callback);
};

/**
 * Internal helper for update, updateMany, updateOne, replaceOne
 * @param {Query} query
 * @param {String} op
 * @param {Object} filter
 * @param {Document} [doc]
 * @param {Object} [options]
 * @param {Function} callback
 * @api private
 */

function _update(query, op, filter, doc, options, callback) {
  // make sure we don't send in the whole Document to merge()
  query.op = op;
  query._validateOp();
  doc = doc || {};

  // strict is an option used in the update checking, make sure it gets set
  if (options != null) {
    if ('strict' in options) {
      query._mongooseOptions.strict = options.strict;
    }
  }

  if (!(filter instanceof Query) &&
      filter != null &&
      filter.toString() !== '[object Object]') {
    query.error(new ObjectParameterError(filter, 'filter', op));
  } else {
    query.merge(filter);
  }

  if (utils.isObject(options)) {
    query.setOptions(options);
  }

  query._mergeUpdate(doc);

  // Hooks
  if (callback) {
    query.exec(callback);

    return query;
  }

  return query;
}

/**
 * Runs a function `fn` and treats the return value of `fn` as the new value
 * for the query to resolve to.
 *
 * Any functions you pass to `transform()` will run **after** any post hooks.
 *
 * #### Example:
 *
 *     const res = await MyModel.findOne().transform(res => {
 *       // Sets a `loadedAt` property on the doc that tells you the time the
 *       // document was loaded.
 *       return res == null ?
 *         res :
 *         Object.assign(res, { loadedAt: new Date() });
 *     });
 *
 * @method transform
 * @memberOf Query
 * @instance
 * @param {Function} fn function to run to transform the query result
 * @return {Query} this
 */

Query.prototype.transform = function(fn) {
  this._transforms.push(fn);
  return this;
};

/**
 * Make this query throw an error if no documents match the given `filter`.
 * This is handy for integrating with async/await, because `orFail()` saves you
 * an extra `if` statement to check if no document was found.
 *
 * #### Example:
 *
 *     // Throws if no doc returned
 *     await Model.findOne({ foo: 'bar' }).orFail();
 *
 *     // Throws if no document was updated. Note that `orFail()` will still
 *     // throw if the only document that matches is `{ foo: 'bar', name: 'test' }`,
 *     // because `orFail()` will throw if no document was _updated_, not
 *     // if no document was _found_.
 *     await Model.updateOne({ foo: 'bar' }, { name: 'test' }).orFail();
 *
 *     // Throws "No docs found!" error if no docs match `{ foo: 'bar' }`
 *     await Model.find({ foo: 'bar' }).orFail(new Error('No docs found!'));
 *
 *     // Throws "Not found" error if no document was found
 *     await Model.findOneAndUpdate({ foo: 'bar' }, { name: 'test' }).
 *       orFail(() => Error('Not found'));
 *
 * @method orFail
 * @memberOf Query
 * @instance
 * @param {Function|Error} [err] optional error to throw if no docs match `filter`. If not specified, `orFail()` will throw a `DocumentNotFoundError`
 * @return {Query} this
 */

Query.prototype.orFail = function(err) {
  this.transform(res => {
    switch (this.op) {
      case 'find':
        if (res.length === 0) {
          throw _orFailError(err, this);
        }
        break;
      case 'findOne':
        if (res == null) {
          throw _orFailError(err, this);
        }
        break;
      case 'replaceOne':
      case 'updateMany':
      case 'updateOne':
        if (res && res.matchedCount === 0) {
          throw _orFailError(err, this);
        }
        break;
      case 'findOneAndDelete':
      case 'findOneAndUpdate':
      case 'findOneAndReplace':
        if (this.options.includeResultMetadata && res != null && res.value == null) {
          throw _orFailError(err, this);
        }
        if (!this.options.includeResultMetadata && res == null) {
          throw _orFailError(err, this);
        }
        break;
      case 'deleteMany':
      case 'deleteOne':
        if (res.deletedCount === 0) {
          throw _orFailError(err, this);
        }
        break;
      default:
        break;
    }

    return res;
  });
  return this;
};

/**
 * Get the error to throw for `orFail()`
 * @param {Error|undefined} err
 * @param {Query} query
 * @api private
 */

function _orFailError(err, query) {
  if (typeof err === 'function') {
    err = err.call(query);
  }

  if (err == null) {
    err = new DocumentNotFoundError(query.getQuery(), query.model.modelName);
  }

  return err;
}

/**
 * Wrapper function to call isPathSelectedInclusive on a query.
 * @param {String} path
 * @return {Boolean}
 * @api public
 */

Query.prototype.isPathSelectedInclusive = function(path) {
  return isPathSelectedInclusive(this._fields, path);
};

/**
 * Executes the query
 *
 * #### Example:
 *
 *     const promise = query.exec();
 *     const promise = query.exec('update');
 *
 * @param {String|Function} [operation]
 * @return {Promise}
 * @api public
 */

Query.prototype.exec = async function exec(op) {
  if (typeof op === 'function' || (arguments.length >= 2 && typeof arguments[1] === 'function')) {
    throw new MongooseError('Query.prototype.exec() no longer accepts a callback');
  }

  if (typeof op === 'string') {
    this.op = op;
  }

  if (this.op == null) {
    throw new MongooseError('Query must have `op` before executing');
  }
  if (this.model == null) {
    throw new MongooseError('Query must have an associated model before executing');
  }
  this._validateOp();

  if (!this.op) {
    return;
  }

  if (this.options && this.options.sort) {
    const keys = Object.keys(this.options.sort);
    if (keys.includes('')) {
      throw new Error('Invalid field "" passed to sort()');
    }
  }

  let thunk = '_' + this.op;
  if (this.op === 'distinct') {
    thunk = '__distinct';
  }

  if (this._executionStack != null) {
    let str = this.toString();
    if (str.length > 60) {
      str = str.slice(0, 60) + '...';
    }
    const err = new MongooseError('Query was already executed: ' + str);
    err.originalStack = this._executionStack.stack;
    throw err;
  } else {
    this._executionStack = new Error();
  }

  let skipWrappedFunction = null;
  try {
    await _executePreExecHooks(this);
  } catch (err) {
    if (err instanceof Kareem.skipWrappedFunction) {
      skipWrappedFunction = err;
    } else {
      throw err;
    }
  }

  let res;

  let error = null;
  try {
    await _executePreHooks(this);
    res = skipWrappedFunction ? skipWrappedFunction.args[0] : await this[thunk]();

    for (const fn of this._transforms) {
      res = fn(res);
    }
  } catch (err) {
    if (err instanceof Kareem.skipWrappedFunction) {
      res = err.args[0];
    } else {
      error = err;
    }
  }

  res = await _executePostHooks(this, res, error);

  await _executePostExecHooks(this);

  return res;
};

/*!
 * ignore
 */

function _executePostExecHooks(query) {
  return new Promise((resolve, reject) => {
    query._hooks.execPost('exec', query, [], {}, (error) => {
      if (error) {
        return reject(error);
      }

      resolve();
    });
  });
}

/*!
 * ignore
 */

function _executePostHooks(query, res, error, op) {
  if (query._queryMiddleware == null) {
    if (error != null) {
      throw error;
    }
    return res;
  }

  return new Promise((resolve, reject) => {
    const opts = error ? { error } : {};

    query._queryMiddleware.execPost(op || query.op, query, [res], opts, (error, res) => {
      if (error) {
        return reject(error);
      }

      resolve(res);
    });
  });
}

/*!
 * ignore
 */

function _executePreExecHooks(query) {
  return new Promise((resolve, reject) => {
    query._hooks.execPre('exec', query, [], (error) => {
      if (error != null) {
        return reject(error);
      }
      resolve();
    });
  });
}

/*!
 * ignore
 */

function _executePreHooks(query, op) {
  if (query._queryMiddleware == null) {
    return;
  }

  return new Promise((resolve, reject) => {
    query._queryMiddleware.execPre(op || query.op, query, [], (error) => {
      if (error != null) {
        return reject(error);
      }
      resolve();
    });
  });
}

/**
 * Executes the query returning a `Promise` which will be
 * resolved with either the doc(s) or rejected with the error.
 *
 * More about [`then()` in JavaScript](https://masteringjs.io/tutorials/fundamentals/then).
 *
 * @param {Function} [resolve]
 * @param {Function} [reject]
 * @return {Promise}
 * @api public
 */

Query.prototype.then = function(resolve, reject) {
  return this.exec().then(resolve, reject);
};

/**
 * Executes the query returning a `Promise` which will be
 * resolved with either the doc(s) or rejected with the error.
 * Like `.then()`, but only takes a rejection handler.
 *
 * More about [Promise `catch()` in JavaScript](https://masteringjs.io/tutorials/fundamentals/catch).
 *
 * @param {Function} [reject]
 * @return {Promise}
 * @api public
 */

Query.prototype.catch = function(reject) {
  return this.exec().then(null, reject);
};

/**
 * Executes the query returning a `Promise` which will be
 * resolved with `.finally()` chained.
 *
 * More about [Promise `finally()` in JavaScript](https://thecodebarbarian.com/using-promise-finally-in-node-js.html).
 *
 * @param {Function} [onFinally]
 * @return {Promise}
 * @api public
 */

Query.prototype.finally = function(onFinally) {
  return this.exec().finally(onFinally);
};

/**
 * Returns a string representation of this query.
 *
 * More about [`toString()` in JavaScript](https://masteringjs.io/tutorials/fundamentals/tostring).
 *
 * #### Example:
 *     const q = Model.find();
 *     console.log(q); // Prints "Query { find }"
 *
 * @return {String}
 * @api public
 * @method [Symbol.toStringTag]
 * @memberOf Query
 */

Query.prototype[Symbol.toStringTag] = function toString() {
  return `Query { ${this.op} }`;
};

/**
 * Add pre [middleware](https://mongoosejs.com/docs/middleware.html) to this query instance. Doesn't affect
 * other queries.
 *
 * #### Example:
 *
 *     const q1 = Question.find({ answer: 42 });
 *     q1.pre(function middleware() {
 *       console.log(this.getFilter());
 *     });
 *     await q1.exec(); // Prints "{ answer: 42 }"
 *
 *     // Doesn't print anything, because `middleware()` is only
 *     // registered on `q1`.
 *     await Question.find({ answer: 42 });
 *
 * @param {Function} fn
 * @return {Promise}
 * @api public
 */

Query.prototype.pre = function(fn) {
  this._hooks.pre('exec', fn);
  return this;
};

/**
 * Add post [middleware](https://mongoosejs.com/docs/middleware.html) to this query instance. Doesn't affect
 * other queries.
 *
 * #### Example:
 *
 *     const q1 = Question.find({ answer: 42 });
 *     q1.post(function middleware() {
 *       console.log(this.getFilter());
 *     });
 *     await q1.exec(); // Prints "{ answer: 42 }"
 *
 *     // Doesn't print anything, because `middleware()` is only
 *     // registered on `q1`.
 *     await Question.find({ answer: 42 });
 *
 * @param {Function} fn
 * @return {Promise}
 * @api public
 */

Query.prototype.post = function(fn) {
  this._hooks.post('exec', fn);
  return this;
};

/**
 * Casts obj for an update command.
 *
 * @param {Object} obj
 * @return {Object} obj after casting its values
 * @method _castUpdate
 * @memberOf Query
 * @instance
 * @api private
 */

Query.prototype._castUpdate = function _castUpdate(obj) {
  let schema = this.schema;

  const discriminatorKey = schema.options.discriminatorKey;
  const baseSchema = schema._baseSchema ? schema._baseSchema : schema;
  if (this._mongooseOptions.overwriteDiscriminatorKey &&
      obj[discriminatorKey] != null &&
      baseSchema.discriminators) {
    const _schema = Object.values(baseSchema.discriminators).find(
      discriminator => discriminator.discriminatorMapping.value === obj[discriminatorKey]
    );
    if (_schema != null) {
      schema = _schema;
    }
  }

  let upsert;
  if ('upsert' in this.options) {
    upsert = this.options.upsert;
  }

  const filter = this._conditions;
  if (schema != null &&
      utils.hasUserDefinedProperty(filter, schema.options.discriminatorKey) &&
      typeof filter[schema.options.discriminatorKey] !== 'object' &&
      schema.discriminators != null) {
    const discriminatorValue = filter[schema.options.discriminatorKey];
    const byValue = getDiscriminatorByValue(this.model.discriminators, discriminatorValue);
    schema = schema.discriminators[discriminatorValue] ||
      (byValue && byValue.schema) ||
      schema;
  }

  return castUpdate(schema, obj, {
    strict: this._mongooseOptions.strict,
    upsert: upsert,
    arrayFilters: this.options.arrayFilters,
    overwriteDiscriminatorKey: this._mongooseOptions.overwriteDiscriminatorKey
  }, this, this._conditions);
};

/**
 * Specifies paths which should be populated with other documents.
 *
 * #### Example:
 *
 *     let book = await Book.findOne().populate('authors');
 *     book.title; // 'Node.js in Action'
 *     book.authors[0].name; // 'TJ Holowaychuk'
 *     book.authors[1].name; // 'Nathan Rajlich'
 *
 *     let books = await Book.find().populate({
 *       path: 'authors',
 *       // `match` and `sort` apply to the Author model,
 *       // not the Book model. These options do not affect
 *       // which documents are in `books`, just the order and
 *       // contents of each book document's `authors`.
 *       match: { name: new RegExp('.*h.*', 'i') },
 *       sort: { name: -1 }
 *     });
 *     books[0].title; // 'Node.js in Action'
 *     // Each book's `authors` are sorted by name, descending.
 *     books[0].authors[0].name; // 'TJ Holowaychuk'
 *     books[0].authors[1].name; // 'Marc Harter'
 *
 *     books[1].title; // 'Professional AngularJS'
 *     // Empty array, no authors' name has the letter 'h'
 *     books[1].authors; // []
 *
 * Paths are populated after the query executes and a response is received. A
 * separate query is then executed for each path specified for population. After
 * a response for each query has also been returned, the results are passed to
 * the callback.
 *
 * @param {Object|String|String[]} path either the path(s) to populate or an object specifying all parameters
 * @param {Object|String} [select] Field selection for the population query
 * @param {Model} [model] The model you wish to use for population. If not specified, populate will look up the model by the name in the Schema's `ref` field.
 * @param {Object} [match] Conditions for the population query
 * @param {Object} [options] Options for the population query (sort, etc)
 * @param {String} [options.path=null] The path to populate.
 * @param {boolean} [options.retainNullValues=false] by default, Mongoose removes null and undefined values from populated arrays. Use this option to make `populate()` retain `null` and `undefined` array entries.
 * @param {boolean} [options.getters=false] if true, Mongoose will call any getters defined on the `localField`. By default, Mongoose gets the raw value of `localField`. For example, you would need to set this option to `true` if you wanted to [add a `lowercase` getter to your `localField`](https://mongoosejs.com/docs/schematypes.html#schematype-options).
 * @param {boolean} [options.clone=false] When you do `BlogPost.find().populate('author')`, blog posts with the same author will share 1 copy of an `author` doc. Enable this option to make Mongoose clone populated docs before assigning them.
 * @param {Object|Function} [options.match=null] Add an additional filter to the populate query. Can be a filter object containing [MongoDB query syntax](https://www.mongodb.com/docs/manual/tutorial/query-documents/), or a function that returns a filter object.
 * @param {Function} [options.transform=null] Function that Mongoose will call on every populated document that allows you to transform the populated document.
 * @param {Object} [options.options=null] Additional options like `limit` and `lean`.
 * @see population https://mongoosejs.com/docs/populate.html
 * @see Query#select https://mongoosejs.com/docs/api/query.html#Query.prototype.select()
 * @see Model.populate https://mongoosejs.com/docs/api/model.html#Model.populate()
 * @return {Query} this
 * @api public
 */

Query.prototype.populate = function() {
  // Bail when given no truthy arguments
  if (!Array.from(arguments).some(Boolean)) {
    return this;
  }

  const res = utils.populate.apply(null, arguments);

  // Propagate readConcern and readPreference and lean from parent query,
  // unless one already specified
  if (this.options != null) {
    const readConcern = this.options.readConcern;
    const readPref = this.options.readPreference;

    for (const populateOptions of res) {
      if (readConcern != null && (populateOptions && populateOptions.options && populateOptions.options.readConcern) == null) {
        populateOptions.options = populateOptions.options || {};
        populateOptions.options.readConcern = readConcern;
      }
      if (readPref != null && (populateOptions && populateOptions.options && populateOptions.options.readPreference) == null) {
        populateOptions.options = populateOptions.options || {};
        populateOptions.options.readPreference = readPref;
      }
    }
  }

  const opts = this._mongooseOptions;

  if (opts.lean != null) {
    const lean = opts.lean;
    for (const populateOptions of res) {
      if ((populateOptions && populateOptions.options && populateOptions.options.lean) == null) {
        populateOptions.options = populateOptions.options || {};
        populateOptions.options.lean = lean;
      }
    }
  }

  if (!utils.isObject(opts.populate)) {
    opts.populate = {};
  }

  const pop = opts.populate;

  for (const populateOptions of res) {
    const path = populateOptions.path;
    if (pop[path] && pop[path].populate && populateOptions.populate) {
      populateOptions.populate = pop[path].populate.concat(populateOptions.populate);
    }

    pop[populateOptions.path] = populateOptions;
  }
  return this;
};

/**
 * Gets a list of paths to be populated by this query
 *
 * #### Example:
 *
 *      bookSchema.pre('findOne', function() {
 *        let keys = this.getPopulatedPaths(); // ['author']
 *      });
 *      ...
 *      Book.findOne({}).populate('author');
 *
 * #### Example:
 *
 *      // Deep populate
 *      const q = L1.find().populate({
 *        path: 'level2',
 *        populate: { path: 'level3' }
 *      });
 *      q.getPopulatedPaths(); // ['level2', 'level2.level3']
 *
 * @return {Array} an array of strings representing populated paths
 * @api public
 */

Query.prototype.getPopulatedPaths = function getPopulatedPaths() {
  const obj = this._mongooseOptions.populate || {};
  const ret = Object.keys(obj);
  for (const path of Object.keys(obj)) {
    const pop = obj[path];
    if (!Array.isArray(pop.populate)) {
      continue;
    }
    _getPopulatedPaths(ret, pop.populate, path + '.');
  }
  return ret;
};

/*!
 * ignore
 */

function _getPopulatedPaths(list, arr, prefix) {
  for (const pop of arr) {
    list.push(prefix + pop.path);
    if (!Array.isArray(pop.populate)) {
      continue;
    }
    _getPopulatedPaths(list, pop.populate, prefix + pop.path + '.');
  }
}

/**
 * Casts this query to the schema of `model`
 *
 * #### Note:
 *
 * If `obj` is present, it is cast instead of this query.
 *
 * @param {Model} [model] the model to cast to. If not set, defaults to `this.model`
 * @param {Object} [obj]
 * @return {Object}
 * @api public
 */

Query.prototype.cast = function(model, obj) {
  obj || (obj = this._conditions);
  model = model || this.model;
  const discriminatorKey = model.schema.options.discriminatorKey;
  if (obj != null &&
      obj.hasOwnProperty(discriminatorKey)) {
    model = getDiscriminatorByValue(model.discriminators, obj[discriminatorKey]) || model;
  }

  const opts = { upsert: this.options && this.options.upsert };
  if (this.options) {
    if ('strict' in this.options) {
      opts.strict = this.options.strict;
    }
    if ('strictQuery' in this.options) {
      opts.strictQuery = this.options.strictQuery;
    }
  }

  try {
    return cast(model.schema, obj, opts, this);
  } catch (err) {
    // CastError, assign model
    if (typeof err.setModel === 'function') {
      err.setModel(model);
    }
    throw err;
  }
};

/**
 * Casts selected field arguments for field selection with mongo 2.2
 *
 *     query.select({ ids: { $elemMatch: { $in: [hexString] }})
 *
 * @param {Object} fields
 * @see https://github.com/Automattic/mongoose/issues/1091
 * @see https://www.mongodb.com/docs/manual/reference/projection/elemMatch/
 * @api private
 */

Query.prototype._castFields = function _castFields(fields) {
  let selected,
      elemMatchKeys,
      keys,
      key,
      out;

  if (fields) {
    keys = Object.keys(fields);
    elemMatchKeys = [];

    // collect $elemMatch args
    for (let i = 0; i < keys.length; ++i) {
      key = keys[i];
      if (fields[key].$elemMatch) {
        selected || (selected = {});
        selected[key] = fields[key];
        elemMatchKeys.push(key);
      }
    }
  }

  if (selected) {
    // they passed $elemMatch, cast em
    try {
      out = this.cast(this.model, selected);
    } catch (err) {
      return err;
    }

    // apply the casted field args
    for (let i = 0; i < elemMatchKeys.length; ++i) {
      key = elemMatchKeys[i];
      fields[key] = out[key];
    }
  }

  return fields;
};

/**
 * Applies schematype selected options to this query.
 * @api private
 */

Query.prototype._applyPaths = function applyPaths() {
  if (!this.model) {
    return;
  }
  this._fields = this._fields || {};
  helpers.applyPaths(this._fields, this.model.schema);

  let _selectPopulatedPaths = true;

  if ('selectPopulatedPaths' in this.model.base.options) {
    _selectPopulatedPaths = this.model.base.options.selectPopulatedPaths;
  }
  if ('selectPopulatedPaths' in this.model.schema.options) {
    _selectPopulatedPaths = this.model.schema.options.selectPopulatedPaths;
  }

  if (_selectPopulatedPaths) {
    selectPopulatedFields(this._fields, this._userProvidedFields, this._mongooseOptions.populate);
  }
};

/**
 * Returns a wrapper around a [mongodb driver cursor](https://mongodb.github.io/node-mongodb-native/4.9/classes/FindCursor.html).
 * A QueryCursor exposes a Streams3 interface, as well as a `.next()` function.
 *
 * The `.cursor()` function triggers pre find hooks, but **not** post find hooks.
 *
 * #### Example:
 *
 *     // There are 2 ways to use a cursor. First, as a stream:
 *     Thing.
 *       find({ name: /^hello/ }).
 *       cursor().
 *       on('data', function(doc) { console.log(doc); }).
 *       on('end', function() { console.log('Done!'); });
 *
 *     // Or you can use `.next()` to manually get the next doc in the stream.
 *     // `.next()` returns a promise, so you can use promises or callbacks.
 *     const cursor = Thing.find({ name: /^hello/ }).cursor();
 *     cursor.next(function(error, doc) {
 *       console.log(doc);
 *     });
 *
 *     // Because `.next()` returns a promise, you can use co
 *     // to easily iterate through all documents without loading them
 *     // all into memory.
 *     const cursor = Thing.find({ name: /^hello/ }).cursor();
 *     for (let doc = await cursor.next(); doc != null; doc = await cursor.next()) {
 *       console.log(doc);
 *     }
 *
 * #### Valid options
 *
 *   - `transform`: optional function which accepts a mongoose document. The return value of the function will be emitted on `data` and returned by `.next()`.
 *
 * @return {QueryCursor}
 * @param {Object} [options]
 * @see QueryCursor https://mongoosejs.com/docs/api/querycursor.html
 * @api public
 */

Query.prototype.cursor = function cursor(opts) {
  if (opts) {
    this.setOptions(opts);
  }

  try {
    this.cast(this.model);
  } catch (err) {
    return (new QueryCursor(this))._markError(err);
  }

  return new QueryCursor(this);
};

// the rest of these are basically to support older Mongoose syntax with mquery

/**
 * Sets the tailable option (for use with capped collections).
 *
 * #### Example:
 *
 *     query.tailable(); // true
 *     query.tailable(true);
 *     query.tailable(false);
 *
 *     // Set both `tailable` and `awaitData` options
 *     query.tailable({ awaitData: true });
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @param {Boolean} bool defaults to true
 * @param {Object} [opts] options to set
 * @param {Boolean} [opts.awaitData] false by default. Set to true to keep the cursor open even if there's no data.
 * @param {Number} [opts.maxAwaitTimeMS] the maximum amount of time for the server to wait on new documents to satisfy a tailable cursor query. Requires `tailable` and `awaitData` to be true
 * @see tailable https://www.mongodb.com/docs/manual/tutorial/create-tailable-cursor/
 * @api public
 */

Query.prototype.tailable = function(val, opts) {
  // we need to support the tailable({ awaitData : true }) as well as the
  // tailable(true, {awaitData :true}) syntax that mquery does not support
  if (val != null && typeof val.constructor === 'function' && val.constructor.name === 'Object') {
    opts = val;
    val = true;
  }

  if (val === undefined) {
    val = true;
  }

  if (opts && typeof opts === 'object') {
    for (const key of Object.keys(opts)) {
      if (key === 'awaitData' || key === 'awaitdata') { // backwards compat, see gh-10875
        // For backwards compatibility
        this.options['awaitData'] = !!opts[key];
      } else {
        this.options[key] = opts[key];
      }
    }
  }

  this.options.tailable = arguments.length ? !!val : true;

  return this;
};

/**
 * Declares an intersects query for `geometry()`.
 *
 * #### Example:
 *
 *     query.where('path').intersects().geometry({
 *       type: 'LineString',
 *       coordinates: [[180.0, 11.0], [180, 9.0]]
 *     });
 *
 *     query.where('path').intersects({
 *       type: 'LineString',
 *       coordinates: [[180.0, 11.0], [180, 9.0]]
 *     });
 *
 * #### Note:
 *
 * **MUST** be used after `where()`.
 *
 * #### Note:
 *
 * In Mongoose 3.7, `intersects` changed from a getter to a function. If you need the old syntax, use [this](https://github.com/ebensing/mongoose-within).
 *
 * @method intersects
 * @memberOf Query
 * @instance
 * @param {Object} [arg]
 * @return {Query} this
 * @see $geometry https://www.mongodb.com/docs/manual/reference/operator/geometry/
 * @see geoIntersects https://www.mongodb.com/docs/manual/reference/operator/geoIntersects/
 * @api public
 */

/**
 * Specifies a `$geometry` condition
 *
 * #### Example:
 *
 *     const polyA = [[[ 10, 20 ], [ 10, 40 ], [ 30, 40 ], [ 30, 20 ]]]
 *     query.where('loc').within().geometry({ type: 'Polygon', coordinates: polyA })
 *
 *     // or
 *     const polyB = [[ 0, 0 ], [ 1, 1 ]]
 *     query.where('loc').within().geometry({ type: 'LineString', coordinates: polyB })
 *
 *     // or
 *     const polyC = [ 0, 0 ]
 *     query.where('loc').within().geometry({ type: 'Point', coordinates: polyC })
 *
 *     // or
 *     query.where('loc').intersects().geometry({ type: 'Point', coordinates: polyC })
 *
 * The argument is assigned to the most recent path passed to `where()`.
 *
 * #### Note:
 *
 * `geometry()` **must** come after either `intersects()` or `within()`.
 *
 * The `object` argument must contain `type` and `coordinates` properties.
 * - type {String}
 * - coordinates {Array}
 *
 * @method geometry
 * @memberOf Query
 * @instance
 * @param {Object} object Must contain a `type` property which is a String and a `coordinates` property which is an Array. See the examples.
 * @return {Query} this
 * @see $geometry https://www.mongodb.com/docs/manual/reference/operator/geometry/
 * @see Geospatial Support Enhancements https://www.mongodb.com/docs/manual/release-notes/2.4/#geospatial-support-enhancements
 * @see MongoDB Geospatial Indexing https://www.mongodb.com/docs/manual/core/geospatial-indexes/
 * @api public
 */

/**
 * Specifies a `$near` or `$nearSphere` condition
 *
 * These operators return documents sorted by distance.
 *
 * #### Example:
 *
 *     query.where('loc').near({ center: [10, 10] });
 *     query.where('loc').near({ center: [10, 10], maxDistance: 5 });
 *     query.where('loc').near({ center: [10, 10], maxDistance: 5, spherical: true });
 *     query.near('loc', { center: [10, 10], maxDistance: 5 });
 *
 * @method near
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Object} val
 * @return {Query} this
 * @see $near https://www.mongodb.com/docs/manual/reference/operator/near/
 * @see $nearSphere https://www.mongodb.com/docs/manual/reference/operator/nearSphere/
 * @see $maxDistance https://www.mongodb.com/docs/manual/reference/operator/maxDistance/
 * @see MongoDB Geospatial Indexing https://www.mongodb.com/docs/manual/core/geospatial-indexes/
 * @api public
 */

/**
 * Overwriting mquery is needed to support a couple different near() forms found in older
 * versions of mongoose
 * near([1,1])
 * near(1,1)
 * near(field, [1,2])
 * near(field, 1, 2)
 * In addition to all of the normal forms supported by mquery
 *
 * @method near
 * @memberOf Query
 * @instance
 * @api private
 */

Query.prototype.near = function() {
  const params = [];
  const sphere = this._mongooseOptions.nearSphere;

  // TODO refactor

  if (arguments.length === 1) {
    if (Array.isArray(arguments[0])) {
      params.push({ center: arguments[0], spherical: sphere });
    } else if (typeof arguments[0] === 'string') {
      // just passing a path
      params.push(arguments[0]);
    } else if (utils.isObject(arguments[0])) {
      if (typeof arguments[0].spherical !== 'boolean') {
        arguments[0].spherical = sphere;
      }
      params.push(arguments[0]);
    } else {
      throw new TypeError('invalid argument');
    }
  } else if (arguments.length === 2) {
    if (typeof arguments[0] === 'number' && typeof arguments[1] === 'number') {
      params.push({ center: [arguments[0], arguments[1]], spherical: sphere });
    } else if (typeof arguments[0] === 'string' && Array.isArray(arguments[1])) {
      params.push(arguments[0]);
      params.push({ center: arguments[1], spherical: sphere });
    } else if (typeof arguments[0] === 'string' && utils.isObject(arguments[1])) {
      params.push(arguments[0]);
      if (typeof arguments[1].spherical !== 'boolean') {
        arguments[1].spherical = sphere;
      }
      params.push(arguments[1]);
    } else {
      throw new TypeError('invalid argument');
    }
  } else if (arguments.length === 3) {
    if (typeof arguments[0] === 'string' && typeof arguments[1] === 'number'
        && typeof arguments[2] === 'number') {
      params.push(arguments[0]);
      params.push({ center: [arguments[1], arguments[2]], spherical: sphere });
    } else {
      throw new TypeError('invalid argument');
    }
  } else {
    throw new TypeError('invalid argument');
  }

  return Query.base.near.apply(this, params);
};

/**
 * _DEPRECATED_ Specifies a `$nearSphere` condition
 *
 * #### Example:
 *
 *     query.where('loc').nearSphere({ center: [10, 10], maxDistance: 5 });
 *
 * **Deprecated.** Use `query.near()` instead with the `spherical` option set to `true`.
 *
 * #### Example:
 *
 *     query.where('loc').near({ center: [10, 10], spherical: true });
 *
 * @deprecated
 * @see near() https://mongoosejs.com/docs/api/query.html#Query.prototype.near()
 * @see $near https://www.mongodb.com/docs/manual/reference/operator/near/
 * @see $nearSphere https://www.mongodb.com/docs/manual/reference/operator/nearSphere/
 * @see $maxDistance https://www.mongodb.com/docs/manual/reference/operator/maxDistance/
 */

Query.prototype.nearSphere = function() {
  this._mongooseOptions.nearSphere = true;
  this.near.apply(this, arguments);
  return this;
};

/**
 * Returns an asyncIterator for use with [`for/await/of` loops](https://thecodebarbarian.com/getting-started-with-async-iterators-in-node-js)
 * This function *only* works for `find()` queries.
 * You do not need to call this function explicitly, the JavaScript runtime
 * will call it for you.
 *
 * #### Example:
 *
 *     for await (const doc of Model.aggregate([{ $sort: { name: 1 } }])) {
 *       console.log(doc.name);
 *     }
 *
 * Node.js 10.x supports async iterators natively without any flags. You can
 * enable async iterators in Node.js 8.x using the [`--harmony_async_iteration` flag](https://github.com/tc39/proposal-async-iteration/issues/117#issuecomment-346695187).
 *
 * **Note:** This function is not if `Symbol.asyncIterator` is undefined. If
 * `Symbol.asyncIterator` is undefined, that means your Node.js version does not
 * support async iterators.
 *
 * @method [Symbol.asyncIterator]
 * @memberOf Query
 * @instance
 * @api public
 */

if (Symbol.asyncIterator != null) {
  Query.prototype[Symbol.asyncIterator] = function() {
    return this.cursor().transformNull()._transformForAsyncIterator();
  };
}

/**
 * Specifies a `$polygon` condition
 *
 * #### Example:
 *
 *     query.where('loc').within().polygon([10, 20], [13, 25], [7, 15]);
 *     query.polygon('loc', [10, 20], [13, 25], [7, 15]);
 *
 * @method polygon
 * @memberOf Query
 * @instance
 * @param {String|Array} [path]
 * @param {...Array|Object} [coordinatePairs]
 * @return {Query} this
 * @see $polygon https://www.mongodb.com/docs/manual/reference/operator/polygon/
 * @see MongoDB Geospatial Indexing https://www.mongodb.com/docs/manual/core/geospatial-indexes/
 * @api public
 */

/**
 * Specifies a `$box` condition
 *
 * #### Example:
 *
 *     const lowerLeft = [40.73083, -73.99756]
 *     const upperRight= [40.741404,  -73.988135]
 *
 *     query.where('loc').within().box(lowerLeft, upperRight)
 *     query.box({ ll : lowerLeft, ur : upperRight })
 *
 * @method box
 * @memberOf Query
 * @instance
 * @see $box https://www.mongodb.com/docs/manual/reference/operator/box/
 * @see within() Query#within https://mongoosejs.com/docs/api/query.html#Query.prototype.within()
 * @see MongoDB Geospatial Indexing https://www.mongodb.com/docs/manual/core/geospatial-indexes/
 * @param {Object|Array<Number>} val1 Lower Left Coordinates OR a object of lower-left(ll) and upper-right(ur) Coordinates
 * @param {Array<Number>} [val2] Upper Right Coordinates
 * @return {Query} this
 * @api public
 */

/**
 * this is needed to support the mongoose syntax of:
 * box(field, { ll : [x,y], ur : [x2,y2] })
 * box({ ll : [x,y], ur : [x2,y2] })
 *
 * @method box
 * @memberOf Query
 * @instance
 * @api private
 */

Query.prototype.box = function(ll, ur) {
  if (!Array.isArray(ll) && utils.isObject(ll)) {
    ur = ll.ur;
    ll = ll.ll;
  }
  return Query.base.box.call(this, ll, ur);
};

/**
 * Specifies a `$center` or `$centerSphere` condition.
 *
 * #### Example:
 *
 *     const area = { center: [50, 50], radius: 10, unique: true }
 *     query.where('loc').within().circle(area)
 *     // alternatively
 *     query.circle('loc', area);
 *
 *     // spherical calculations
 *     const area = { center: [50, 50], radius: 10, unique: true, spherical: true }
 *     query.where('loc').within().circle(area)
 *     // alternatively
 *     query.circle('loc', area);
 *
 * @method circle
 * @memberOf Query
 * @instance
 * @param {String} [path]
 * @param {Object} area
 * @return {Query} this
 * @see $center https://www.mongodb.com/docs/manual/reference/operator/center/
 * @see $centerSphere https://www.mongodb.com/docs/manual/reference/operator/centerSphere/
 * @see $geoWithin https://www.mongodb.com/docs/manual/reference/operator/geoWithin/
 * @see MongoDB Geospatial Indexing https://www.mongodb.com/docs/manual/core/geospatial-indexes/
 * @api public
 */

/**
 * _DEPRECATED_ Alias for [circle](https://mongoosejs.com/docs/api/query.html#Query.prototype.circle())
 *
 * **Deprecated.** Use [circle](https://mongoosejs.com/docs/api/query.html#Query.prototype.circle()) instead.
 *
 * @deprecated
 * @method center
 * @memberOf Query
 * @instance
 * @api public
 */

Query.prototype.center = Query.base.circle;

/**
 * _DEPRECATED_ Specifies a `$centerSphere` condition
 *
 * **Deprecated.** Use [circle](https://mongoosejs.com/docs/api/query.html#Query.prototype.circle()) instead.
 *
 * #### Example:
 *
 *     const area = { center: [50, 50], radius: 10 };
 *     query.where('loc').within().centerSphere(area);
 *
 * @deprecated
 * @param {String} [path]
 * @param {Object} val
 * @return {Query} this
 * @see MongoDB Geospatial Indexing https://www.mongodb.com/docs/manual/core/geospatial-indexes/
 * @see $centerSphere https://www.mongodb.com/docs/manual/reference/operator/centerSphere/
 * @api public
 */

Query.prototype.centerSphere = function() {
  if (arguments[0] != null && typeof arguments[0].constructor === 'function' && arguments[0].constructor.name === 'Object') {
    arguments[0].spherical = true;
  }

  if (arguments[1] != null && typeof arguments[1].constructor === 'function' && arguments[1].constructor.name === 'Object') {
    arguments[1].spherical = true;
  }

  Query.base.circle.apply(this, arguments);
};

/**
 * Determines if field selection has been made.
 *
 * @method selected
 * @memberOf Query
 * @instance
 * @return {Boolean}
 * @api public
 */

/**
 * Determines if inclusive field selection has been made.
 *
 *     query.selectedInclusively(); // false
 *     query.select('name');
 *     query.selectedInclusively(); // true
 *
 * @method selectedInclusively
 * @memberOf Query
 * @instance
 * @return {Boolean}
 * @api public
 */

Query.prototype.selectedInclusively = function selectedInclusively() {
  return isInclusive(this._fields);
};

/**
 * Determines if exclusive field selection has been made.
 *
 *     query.selectedExclusively(); // false
 *     query.select('-name');
 *     query.selectedExclusively(); // true
 *     query.selectedInclusively(); // false
 *
 * @method selectedExclusively
 * @memberOf Query
 * @instance
 * @return {Boolean}
 * @api public
 */

Query.prototype.selectedExclusively = function selectedExclusively() {
  return isExclusive(this._fields);
};

/**
 * The model this query is associated with.
 *
 * #### Example:
 *
 *     const q = MyModel.find();
 *     q.model === MyModel; // true
 *
 * @api public
 * @property model
 * @memberOf Query
 * @instance
 */

Query.prototype.model;

/*!
 * Export
 */

module.exports = Query;
