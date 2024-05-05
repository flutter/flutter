'use strict';

/**
 * Dependencies
 */

const assert = require('assert');
const util = require('util');
const utils = require('./utils');
const debug = require('debug')('mquery');

/**
 * Query constructor used for building queries.
 *
 * #### Example:
 *
 *     var query = new Query({ name: 'mquery' });
 *     query.setOptions({ collection: moduleCollection })
 *     await query.where('age').gte(21).exec();
 *
 * @param {Object} [criteria] criteria for the query OR the collection instance to use
 * @param {Object} [options]
 * @api public
 */

function Query(criteria, options) {
  if (!(this instanceof Query))
    return new Query(criteria, options);

  const proto = this.constructor.prototype;

  this.op = proto.op || undefined;

  this.options = Object.assign({}, proto.options);

  this._conditions = proto._conditions
    ? utils.clone(proto._conditions)
    : {};

  this._fields = proto._fields
    ? utils.clone(proto._fields)
    : undefined;

  this._updateDoc = proto._updateDoc
    ? utils.clone(proto._updateDoc)
    : undefined;

  this._path = proto._path || undefined;
  this._distinctDoc = proto._distinctDoc || undefined;
  this._collection = proto._collection || undefined;
  this._traceFunction = proto._traceFunction || undefined;

  if (options) {
    this.setOptions(options);
  }

  if (criteria) {
    this.find(criteria);
  }
}

/**
 * This is a parameter that the user can set which determines if mquery
 * uses $within or $geoWithin for queries. It defaults to true which
 * means $geoWithin will be used. If using MongoDB < 2.4 you should
 * set this to false.
 *
 * @api public
 * @property use$geoWithin
 */

let $withinCmd = '$geoWithin';
Object.defineProperty(Query, 'use$geoWithin', {
  get: function() { return $withinCmd == '$geoWithin'; },
  set: function(v) {
    if (true === v) {
      // mongodb >= 2.4
      $withinCmd = '$geoWithin';
    } else {
      $withinCmd = '$within';
    }
  }
});

/**
 * Converts this query to a constructor function with all arguments and options retained.
 *
 * #### Example:
 *
 *     // Create a query that will read documents with a "video" category from
 *     // `aCollection` on the primary node in the replica-set unless it is down,
 *     // in which case we'll read from a secondary node.
 *     var query = mquery({ category: 'video' })
 *     query.setOptions({ collection: aCollection, read: 'primaryPreferred' });
 *
 *     // create a constructor based off these settings
 *     var Video = query.toConstructor();
 *
 *     // Video is now a subclass of mquery() and works the same way but with the
 *     // default query parameters and options set.
 *
 *     // run a query with the previous settings but filter for movies with names
 *     // that start with "Life".
 *     Video().where({ name: /^Life/ }).exec(cb);
 *
 * @return {Query} new Query
 * @api public
 */

Query.prototype.toConstructor = function toConstructor() {
  function CustomQuery(criteria, options) {
    if (!(this instanceof CustomQuery))
      return new CustomQuery(criteria, options);
    Query.call(this, criteria, options);
  }

  utils.inherits(CustomQuery, Query);

  // set inherited defaults
  const p = CustomQuery.prototype;

  p.options = {};
  p.setOptions(this.options);

  p.op = this.op;
  p._conditions = utils.clone(this._conditions);
  p._fields = utils.clone(this._fields);
  p._updateDoc = utils.clone(this._updateDoc);
  p._path = this._path;
  p._distinctDoc = this._distinctDoc;
  p._collection = this._collection;
  p._traceFunction = this._traceFunction;

  return CustomQuery;
};

/**
 * Sets query options.
 *
 * #### Options:
 *
 * - [tailable](http://www.mongodb.org/display/DOCS/Tailable+Cursors) *
 * - [sort](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%7B%7Bsort(\)%7D%7D) *
 * - [limit](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%7B%7Blimit%28%29%7D%7D) *
 * - [skip](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%7B%7Bskip%28%29%7D%7D) *
 * - [maxTime](http://docs.mongodb.org/manual/reference/operator/meta/maxTimeMS/#op._S_maxTimeMS) *
 * - [batchSize](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%7B%7BbatchSize%28%29%7D%7D) *
 * - [comment](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%24comment) *
 * - [hint](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%24hint) *
 * - [slaveOk](http://docs.mongodb.org/manual/applications/replication/#read-preference) *
 * - [safe](http://www.mongodb.org/display/DOCS/getLastError+Command)
 * - collection the collection to query against
 *
 * _* denotes a query helper method is also available_
 *
 * @param {Object} options
 * @api public
 */

Query.prototype.setOptions = function(options) {
  if (!(options && utils.isObject(options)))
    return this;

  // set arbitrary options
  const methods = utils.keys(options);
  let method;

  for (let i = 0; i < methods.length; ++i) {
    method = methods[i];

    // use methods if exist (safer option manipulation)
    if ('function' == typeof this[method]) {
      const args = Array.isArray(options[method])
        ? options[method]
        : [options[method]];
      this[method].apply(this, args);
    } else {
      this.options[method] = options[method];
    }
  }

  return this;
};

/**
 * Sets this Querys collection.
 *
 * @param {Collection} coll
 * @return {Query} this
 */

Query.prototype.collection = function collection(coll) {
  this._collection = new Query.Collection(coll);

  return this;
};

/**
 * Adds a collation to this op (MongoDB 3.4 and up)
 *
 * #### Example:
 *
 *     query.find().collation({ locale: "en_US", strength: 1 })
 *
 * @param {Object} value
 * @return {Query} this
 * @see MongoDB docs https://docs.mongodb.com/manual/reference/method/cursor.collation/#cursor.collation
 * @api public
 */

Query.prototype.collation = function(value) {
  this.options.collation = value;
  return this;
};

/**
 * Specifies a `$where` condition
 *
 * Use `$where` when you need to select documents using a JavaScript expression.
 *
 * #### Example:
 *
 *     query.$where('this.comments.length > 10 || this.name.length > 5')
 *
 *     query.$where(function () {
 *       return this.comments.length > 10 || this.name.length > 5;
 *     })
 *
 * @param {String|Function} js javascript string or function
 * @return {Query} this
 * @memberOf Query
 * @method $where
 * @api public
 */

Query.prototype.$where = function(js) {
  this._conditions.$where = js;
  return this;
};

/**
 * Specifies a `path` for use with chaining.
 *
 * #### Example:
 *
 *     // instead of writing:
 *     await User.find({age: {$gte: 21, $lte: 65}});
 *
 *     // we can instead write:
 *     User.where('age').gte(21).lte(65);
 *
 *     // passing query conditions is permitted
 *     User.find().where({ name: 'vonderful' })
 *
 *     // chaining
 *     await User
 *       .where('age').gte(21).lte(65)
 *       .where('name', /^vonderful/i)
 *       .where('friends').slice(10)
 *       .exec()
 *
 * @param {String} [path]
 * @param {Object} [val]
 * @return {Query} this
 * @api public
 */

Query.prototype.where = function() {
  if (!arguments.length) return this;
  if (!this.op) this.op = 'find';

  const type = typeof arguments[0];

  if ('string' == type) {
    this._path = arguments[0];

    if (2 === arguments.length) {
      this._conditions[this._path] = arguments[1];
    }

    return this;
  }

  if ('object' == type && !Array.isArray(arguments[0])) {
    return this.merge(arguments[0]);
  }

  throw new TypeError('path must be a string or object');
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
 * @param {Object} val
 * @return {Query} this
 * @api public
 */

Query.prototype.equals = function equals(val) {
  this._ensurePath('equals');
  const path = this._path;
  this._conditions[path] = val;
  return this;
};

/**
 * Specifies the complementary comparison value for paths specified with `where()`
 * This is alias of `equals`
 *
 * #### Example:
 *
 *     User.where('age').eq(49);
 *
 *     // is the same as
 *
 *     User.shere('age').equals(49);
 *
 *     // is the same as
 *
 *     User.where('age', 49);
 *
 * @param {Object} val
 * @return {Query} this
 * @api public
 */

Query.prototype.eq = function eq(val) {
  this._ensurePath('eq');
  const path = this._path;
  this._conditions[path] = val;
  return this;
};

/**
 * Specifies arguments for an `$or` condition.
 *
 * #### Example:
 *
 *     query.or([{ color: 'red' }, { status: 'emergency' }])
 *
 * @param {Array} array array of conditions
 * @return {Query} this
 * @api public
 */

Query.prototype.or = function or(array) {
  const or = this._conditions.$or || (this._conditions.$or = []);
  if (!Array.isArray(array)) array = [array];
  or.push.apply(or, array);
  return this;
};

/**
 * Specifies arguments for a `$nor` condition.
 *
 * #### Example:
 *
 *     query.nor([{ color: 'green' }, { status: 'ok' }])
 *
 * @param {Array} array array of conditions
 * @return {Query} this
 * @api public
 */

Query.prototype.nor = function nor(array) {
  const nor = this._conditions.$nor || (this._conditions.$nor = []);
  if (!Array.isArray(array)) array = [array];
  nor.push.apply(nor, array);
  return this;
};

/**
 * Specifies arguments for a `$and` condition.
 *
 * #### Example:
 *
 *     query.and([{ color: 'green' }, { status: 'ok' }])
 *
 * @see $and http://docs.mongodb.org/manual/reference/operator/and/
 * @param {Array} array array of conditions
 * @return {Query} this
 * @api public
 */

Query.prototype.and = function and(array) {
  const and = this._conditions.$and || (this._conditions.$and = []);
  if (!Array.isArray(array)) array = [array];
  and.push.apply(and, array);
  return this;
};

/**
 * Specifies a $gt query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * #### Example:
 *
 *     Thing.find().where('age').gt(21)
 *
 *     // or
 *     Thing.find().gt('age', 21)
 *
 * @method gt
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a $gte query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method gte
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a $lt query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method lt
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a $lte query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method lte
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a $ne query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method ne
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies an $in query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method in
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies an $nin query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method nin
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies an $all query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method all
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a $size query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method size
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/**
 * Specifies a $regex query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method regex
 * @memberOf Query
 * @param {String} [path]
 * @param {String|RegExp} val
 * @api public
 */

/**
 * Specifies a $maxDistance query condition.
 *
 * When called with one argument, the most recent path passed to `where()` is used.
 *
 * @method maxDistance
 * @memberOf Query
 * @param {String} [path]
 * @param {Number} val
 * @api public
 */

/*!
 * gt, gte, lt, lte, ne, in, nin, all, regex, size, maxDistance
 *
 *     Thing.where('type').nin(array)
 */

'gt gte lt lte ne in nin all regex size maxDistance minDistance'.split(' ').forEach(function($conditional) {
  Query.prototype[$conditional] = function() {
    let path, val;

    if (1 === arguments.length) {
      this._ensurePath($conditional);
      val = arguments[0];
      path = this._path;
    } else {
      val = arguments[1];
      path = arguments[0];
    }

    const conds = this._conditions[path] === null || typeof this._conditions[path] === 'object' ?
      this._conditions[path] :
      (this._conditions[path] = {});
    conds['$' + $conditional] = val;
    return this;
  };
});

/**
 * Specifies a `$mod` condition
 *
 * @param {String} [path]
 * @param {Number} val
 * @return {Query} this
 * @api public
 */

Query.prototype.mod = function() {
  let val, path;

  if (1 === arguments.length) {
    this._ensurePath('mod');
    val = arguments[0];
    path = this._path;
  } else if (2 === arguments.length && !Array.isArray(arguments[1])) {
    this._ensurePath('mod');
    val = [arguments[0], arguments[1]];
    path = this._path;
  } else if (3 === arguments.length) {
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
 * @param {String} [path]
 * @param {Number} val
 * @return {Query} this
 * @api public
 */

Query.prototype.exists = function() {
  let path, val;

  if (0 === arguments.length) {
    this._ensurePath('exists');
    path = this._path;
    val = true;
  } else if (1 === arguments.length) {
    if ('boolean' === typeof arguments[0]) {
      this._ensurePath('exists');
      path = this._path;
      val = arguments[0];
    } else {
      path = arguments[0];
      val = true;
    }
  } else if (2 === arguments.length) {
    path = arguments[0];
    val = arguments[1];
  }

  const conds = this._conditions[path] || (this._conditions[path] = {});
  conds.$exists = val;
  return this;
};

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
 * @param {String|Object|Function} path
 * @param {Object|Function} criteria
 * @return {Query} this
 * @api public
 */

Query.prototype.elemMatch = function() {
  if (null == arguments[0])
    throw new TypeError('Invalid argument');

  let fn, path, criteria;

  if ('function' === typeof arguments[0]) {
    this._ensurePath('elemMatch');
    path = this._path;
    fn = arguments[0];
  } else if (utils.isObject(arguments[0])) {
    this._ensurePath('elemMatch');
    path = this._path;
    criteria = arguments[0];
  } else if ('function' === typeof arguments[1]) {
    path = arguments[0];
    fn = arguments[1];
  } else if (arguments[1] && utils.isObject(arguments[1])) {
    path = arguments[0];
    criteria = arguments[1];
  } else {
    throw new TypeError('Invalid argument');
  }

  if (fn) {
    criteria = new Query;
    fn(criteria);
    criteria = criteria._conditions;
  }

  const conds = this._conditions[path] || (this._conditions[path] = {});
  conds.$elemMatch = criteria;
  return this;
};

// Spatial queries

/**
 * Sugar for geo-spatial queries.
 *
 * #### Example:
 *
 *     query.within().box()
 *     query.within().circle()
 *     query.within().geometry()
 *
 *     query.where('loc').within({ center: [50,50], radius: 10, unique: true, spherical: true });
 *     query.where('loc').within({ box: [[40.73, -73.9], [40.7, -73.988]] });
 *     query.where('loc').within({ polygon: [[],[],[],[]] });
 *
 *     query.where('loc').within([], [], []) // polygon
 *     query.where('loc').within([], []) // box
 *     query.where('loc').within({ type: 'LineString', coordinates: [...] }); // geometry
 *
 * #### Note:
 *
 * Must be used after `where()`.
 *
 * @memberOf Query
 * @return {Query} this
 * @api public
 */

Query.prototype.within = function within() {
  // opinionated, must be used after where
  this._ensurePath('within');
  this._geoComparison = $withinCmd;

  if (0 === arguments.length) {
    return this;
  }

  if (2 === arguments.length) {
    return this.box.apply(this, arguments);
  } else if (2 < arguments.length) {
    return this.polygon.apply(this, arguments);
  }

  const area = arguments[0];

  if (!area)
    throw new TypeError('Invalid argument');

  if (area.center)
    return this.circle(area);

  if (area.box)
    return this.box.apply(this, area.box);

  if (area.polygon)
    return this.polygon.apply(this, area.polygon);

  if (area.type && area.coordinates)
    return this.geometry(area);

  throw new TypeError('Invalid argument');
};

/**
 * Specifies a $box condition
 *
 * #### Example:
 *
 *     var lowerLeft = [40.73083, -73.99756]
 *     var upperRight= [40.741404,  -73.988135]
 *
 *     query.where('loc').within().box(lowerLeft, upperRight)
 *     query.box('loc', lowerLeft, upperRight )
 *
 * @see http://www.mongodb.org/display/DOCS/Geospatial+Indexing
 * @see Query#within #query_Query-within
 * @param {String} path
 * @param {Object} val
 * @return {Query} this
 * @api public
 */

Query.prototype.box = function() {
  let path, box;

  if (3 === arguments.length) {
    // box('loc', [], [])
    path = arguments[0];
    box = [arguments[1], arguments[2]];
  } else if (2 === arguments.length) {
    // box([], [])
    this._ensurePath('box');
    path = this._path;
    box = [arguments[0], arguments[1]];
  } else {
    throw new TypeError('Invalid argument');
  }

  const conds = this._conditions[path] || (this._conditions[path] = {});
  conds[this._geoComparison || $withinCmd] = { $box: box };
  return this;
};

/**
 * Specifies a $polygon condition
 *
 * #### Example:
 *
 *     query.where('loc').within().polygon([10,20], [13, 25], [7,15])
 *     query.polygon('loc', [10,20], [13, 25], [7,15])
 *
 * @param {String|Array} [path]
 * @param {Array|Object} [val]
 * @return {Query} this
 * @see http://www.mongodb.org/display/DOCS/Geospatial+Indexing
 * @api public
 */

Query.prototype.polygon = function() {
  let val, path;

  if ('string' == typeof arguments[0]) {
    // polygon('loc', [],[],[])
    val = Array.from(arguments);
    path = val.shift();
  } else {
    // polygon([],[],[])
    this._ensurePath('polygon');
    path = this._path;
    val = Array.from(arguments);
  }

  const conds = this._conditions[path] || (this._conditions[path] = {});
  conds[this._geoComparison || $withinCmd] = { $polygon: val };
  return this;
};

/**
 * Specifies a $center or $centerSphere condition.
 *
 * #### Example:
 *
 *     var area = { center: [50, 50], radius: 10, unique: true }
 *     query.where('loc').within().circle(area)
 *     query.center('loc', area);
 *
 *     // for spherical calculations
 *     var area = { center: [50, 50], radius: 10, unique: true, spherical: true }
 *     query.where('loc').within().circle(area)
 *     query.center('loc', area);
 *
 * @param {String} [path]
 * @param {Object} area
 * @return {Query} this
 * @see http://www.mongodb.org/display/DOCS/Geospatial+Indexing
 * @api public
 */

Query.prototype.circle = function() {
  let path, val;

  if (1 === arguments.length) {
    this._ensurePath('circle');
    path = this._path;
    val = arguments[0];
  } else if (2 === arguments.length) {
    path = arguments[0];
    val = arguments[1];
  } else {
    throw new TypeError('Invalid argument');
  }

  if (!('radius' in val && val.center))
    throw new Error('center and radius are required');

  const conds = this._conditions[path] || (this._conditions[path] = {});

  const type = val.spherical
    ? '$centerSphere'
    : '$center';

  const wKey = this._geoComparison || $withinCmd;
  conds[wKey] = {};
  conds[wKey][type] = [val.center, val.radius];

  if ('unique' in val)
    conds[wKey].$uniqueDocs = !!val.unique;

  return this;
};

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
 *     query.near({ center: { type: 'Point', coordinates: [..] }})
 *     query.near().geometry({ type: 'Point', coordinates: [..] })
 *
 * @param {String} [path]
 * @param {Object} val
 * @return {Query} this
 * @see http://www.mongodb.org/display/DOCS/Geospatial+Indexing
 * @api public
 */

Query.prototype.near = function near() {
  let path, val;

  this._geoComparison = '$near';

  if (0 === arguments.length) {
    return this;
  } else if (1 === arguments.length) {
    this._ensurePath('near');
    path = this._path;
    val = arguments[0];
  } else if (2 === arguments.length) {
    path = arguments[0];
    val = arguments[1];
  } else {
    throw new TypeError('Invalid argument');
  }

  if (!val.center) {
    throw new Error('center is required');
  }

  const conds = this._conditions[path] || (this._conditions[path] = {});

  const type = val.spherical
    ? '$nearSphere'
    : '$near';

  // center could be a GeoJSON object or an Array
  if (Array.isArray(val.center)) {
    conds[type] = val.center;

    const radius = 'maxDistance' in val
      ? val.maxDistance
      : null;

    if (null != radius) {
      conds.$maxDistance = radius;
    }
    if (null != val.minDistance) {
      conds.$minDistance = val.minDistance;
    }
  } else {
    // GeoJSON?
    if (val.center.type != 'Point' || !Array.isArray(val.center.coordinates)) {
      throw new Error(util.format('Invalid GeoJSON specified for %s', type));
    }
    conds[type] = { $geometry: val.center };

    // MongoDB 2.6 insists on maxDistance being in $near / $nearSphere
    if ('maxDistance' in val) {
      conds[type]['$maxDistance'] = val.maxDistance;
    }
    if ('minDistance' in val) {
      conds[type]['$minDistance'] = val.minDistance;
    }
  }

  return this;
};

/**
 * Declares an intersects query for `geometry()`.
 *
 * #### Example:
 *
 *     query.where('path').intersects().geometry({
 *         type: 'LineString'
 *       , coordinates: [[180.0, 11.0], [180, 9.0]]
 *     })
 *
 *     query.where('path').intersects({
 *         type: 'LineString'
 *       , coordinates: [[180.0, 11.0], [180, 9.0]]
 *     })
 *
 * @param {Object} [arg]
 * @return {Query} this
 * @api public
 */

Query.prototype.intersects = function intersects() {
  // opinionated, must be used after where
  this._ensurePath('intersects');

  this._geoComparison = '$geoIntersects';

  if (0 === arguments.length) {
    return this;
  }

  const area = arguments[0];

  if (null != area && area.type && area.coordinates)
    return this.geometry(area);

  throw new TypeError('Invalid argument');
};

/**
 * Specifies a `$geometry` condition
 *
 * #### Example:
 *
 *     var polyA = [[[ 10, 20 ], [ 10, 40 ], [ 30, 40 ], [ 30, 20 ]]]
 *     query.where('loc').within().geometry({ type: 'Polygon', coordinates: polyA })
 *
 *     // or
 *     var polyB = [[ 0, 0 ], [ 1, 1 ]]
 *     query.where('loc').within().geometry({ type: 'LineString', coordinates: polyB })
 *
 *     // or
 *     var polyC = [ 0, 0 ]
 *     query.where('loc').within().geometry({ type: 'Point', coordinates: polyC })
 *
 *     // or
 *     query.where('loc').intersects().geometry({ type: 'Point', coordinates: polyC })
 *
 * #### Note:
 *
 * `geometry()` **must** come after either `intersects()` or `within()`.
 *
 * The `object` argument must contain `type` and `coordinates` properties.
 * - type {String}
 * - coordinates {Array}
 *
 * The most recent path passed to `where()` is used.
 *
 * @param {Object} object Must contain a `type` property which is a String and a `coordinates` property which is an Array. See the examples.
 * @return {Query} this
 * @see http://docs.mongodb.org/manual/release-notes/2.4/#new-geospatial-indexes-with-geojson-and-improved-spherical-geometry
 * @see http://www.mongodb.org/display/DOCS/Geospatial+Indexing
 * @see $geometry http://docs.mongodb.org/manual/reference/operator/geometry/
 * @api public
 */

Query.prototype.geometry = function geometry() {
  if (!('$within' == this._geoComparison ||
        '$geoWithin' == this._geoComparison ||
        '$near' == this._geoComparison ||
        '$geoIntersects' == this._geoComparison)) {
    throw new Error('geometry() must come after `within()`, `intersects()`, or `near()');
  }

  let val, path;

  if (1 === arguments.length) {
    this._ensurePath('geometry');
    path = this._path;
    val = arguments[0];
  } else {
    throw new TypeError('Invalid argument');
  }

  if (!(val.type && Array.isArray(val.coordinates))) {
    throw new TypeError('Invalid argument');
  }

  const conds = this._conditions[path] || (this._conditions[path] = {});
  conds[this._geoComparison] = { $geometry: val };

  return this;
};

// end spatial

/**
 * Specifies which document fields to include or exclude
 *
 * #### String syntax
 *
 * When passing a string, prefixing a path with `-` will flag that path as excluded. When a path does not have the `-` prefix, it is included.
 *
 * #### Example:
 *
 *     // include a and b, exclude c
 *     query.select('a b -c');
 *
 *     // or you may use object notation, useful when
 *     // you have keys already prefixed with a "-"
 *     query.select({a: 1, b: 1, c: 0});
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @param {Object|String} arg
 * @return {Query} this
 * @see SchemaType
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
  const type = typeof arg;
  let i, len;

  if (('string' == type || utils.isArgumentsObject(arg)) &&
    'number' == typeof arg.length || Array.isArray(arg)) {
    if ('string' == type)
      arg = arg.split(/\s+/);

    for (i = 0, len = arg.length; i < len; ++i) {
      let field = arg[i];
      if (!field) continue;
      const include = '-' == field[0] ? 0 : 1;
      if (include === 0) field = field.substring(1);
      fields[field] = include;
    }

    return this;
  }

  if (utils.isObject(arg)) {
    const keys = utils.keys(arg);
    for (i = 0; i < keys.length; ++i) {
      fields[keys[i]] = arg[keys[i]];
    }
    return this;
  }

  throw new TypeError('Invalid select() argument. Must be string or object.');
};

/**
 * Specifies a $slice condition for a `path`
 *
 * #### Example:
 *
 *     query.slice('comments', 5)
 *     query.slice('comments', -5)
 *     query.slice('comments', [10, 5])
 *     query.where('comments').slice(5)
 *     query.where('comments').slice([-10, 5])
 *
 * @param {String} [path]
 * @param {Number} val number/range of elements to slice
 * @return {Query} this
 * @see mongodb http://www.mongodb.org/display/DOCS/Retrieving+a+Subset+of+Fields#RetrievingaSubsetofFields-RetrievingaSubrangeofArrayElements
 * @api public
 */

Query.prototype.slice = function() {
  if (0 === arguments.length)
    return this;

  this._validate('slice');

  let path, val;

  if (1 === arguments.length) {
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
  } else if (2 === arguments.length) {
    if ('number' === typeof arguments[0]) {
      this._ensurePath('slice');
      path = this._path;
      val = [arguments[0], arguments[1]];
    } else {
      path = arguments[0];
      val = arguments[1];
    }
  } else if (3 === arguments.length) {
    path = arguments[0];
    val = [arguments[1], arguments[2]];
  }

  const myFields = this._fields || (this._fields = {});
  myFields[path] = { $slice: val };
  return this;
};

/**
 * Sets the sort order
 *
 * If an object is passed, values allowed are 'asc', 'desc', 'ascending', 'descending', 1, and -1.
 *
 * If a string is passed, it must be a space delimited list of path names. The sort order of each path is ascending unless the path name is prefixed with `-` which will be treated as descending.
 *
 * #### Example:
 *
 *     // these are equivalent
 *     query.sort({ field: 'asc', test: -1 });
 *     query.sort('field -test');
 *     query.sort([['field', 1], ['test', -1]]);
 *
 * #### Note:
 *
 *  - The array syntax `.sort([['field', 1], ['test', -1]])` can only be used with [mongodb driver >= 2.0.46](https://github.com/mongodb/node-mongodb-native/blob/2.1/HISTORY.md#2046-2015-10-15).
 *  - Cannot be used with `distinct()`
 *
 * @param {Object|String|Array} arg
 * @return {Query} this
 * @api public
 */

Query.prototype.sort = function(arg) {
  if (!arg) return this;
  let i, len, field;

  this._validate('sort');

  const type = typeof arg;

  // .sort([['field', 1], ['test', -1]])
  if (Array.isArray(arg)) {
    len = arg.length;
    for (i = 0; i < arg.length; ++i) {
      if (!Array.isArray(arg[i])) {
        throw new Error('Invalid sort() argument, must be array of arrays');
      }
      _pushArr(this.options, arg[i][0], arg[i][1]);
    }
    return this;
  }

  // .sort('field -test')
  if (1 === arguments.length && 'string' == type) {
    arg = arg.split(/\s+/);
    len = arg.length;
    for (i = 0; i < len; ++i) {
      field = arg[i];
      if (!field) continue;
      const ascend = '-' == field[0] ? -1 : 1;
      if (ascend === -1) field = field.substring(1);
      push(this.options, field, ascend);
    }

    return this;
  }

  // .sort({ field: 1, test: -1 })
  if (utils.isObject(arg)) {
    const keys = utils.keys(arg);
    for (i = 0; i < keys.length; ++i) {
      field = keys[i];
      push(this.options, field, arg[field]);
    }

    return this;
  }

  if (typeof Map !== 'undefined' && arg instanceof Map) {
    _pushMap(this.options, arg);
    return this;
  }
  throw new TypeError('Invalid sort() argument. Must be a string, object, or array.');
};

/*!
 * @ignore
 */

const _validSortValue = {
  1: 1,
  '-1': -1,
  asc: 1,
  ascending: 1,
  desc: -1,
  descending: -1
};

function push(opts, field, value) {
  if (Array.isArray(opts.sort)) {
    throw new TypeError('Can\'t mix sort syntaxes. Use either array or object:' +
      '\n- `.sort([[\'field\', 1], [\'test\', -1]])`' +
      '\n- `.sort({ field: 1, test: -1 })`');
  }

  let s;
  if (value && value.$meta) {
    s = opts.sort || (opts.sort = {});
    s[field] = { $meta: value.$meta };
    return;
  }

  s = opts.sort || (opts.sort = {});
  let val = String(value || 1).toLowerCase();
  val = _validSortValue[val];
  if (!val) throw new TypeError('Invalid sort value: { ' + field + ': ' + value + ' }');

  s[field] = val;
}

function _pushArr(opts, field, value) {
  opts.sort = opts.sort || [];
  if (!Array.isArray(opts.sort)) {
    throw new TypeError('Can\'t mix sort syntaxes. Use either array or object:' +
      '\n- `.sort([[\'field\', 1], [\'test\', -1]])`' +
      '\n- `.sort({ field: 1, test: -1 })`');
  }

  let val = String(value || 1).toLowerCase();
  val = _validSortValue[val];
  if (!val) throw new TypeError('Invalid sort value: [ ' + field + ', ' + value + ' ]');

  opts.sort.push([field, val]);
}

function _pushMap(opts, map) {
  opts.sort = opts.sort || new Map();
  if (!(opts.sort instanceof Map)) {
    throw new TypeError('Can\'t mix sort syntaxes. Use either array or ' +
      'object or map consistently');
  }
  map.forEach(function(value, key) {
    let val = String(value || 1).toLowerCase();
    val = _validSortValue[val];
    if (!val) throw new TypeError('Invalid sort value: < ' + key + ': ' + value + ' >');

    opts.sort.set(key, val);
  });
}


/**
 * Specifies the limit option.
 *
 * #### Example:
 *
 *     query.limit(20)
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @method limit
 * @memberOf Query
 * @param {Number} val
 * @see mongodb http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%7B%7Blimit%28%29%7D%7D
 * @api public
 */
/**
 * Specifies the skip option.
 *
 * #### Example:
 *
 *     query.skip(100).limit(20)
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @method skip
 * @memberOf Query
 * @param {Number} val
 * @see mongodb http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%7B%7Bskip%28%29%7D%7D
 * @api public
 */
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
 * @param {Number} val
 * @see mongodb http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%7B%7BbatchSize%28%29%7D%7D
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
 * @param {Number} val
 * @see mongodb http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%24comment
 * @api public
 */

/*!
 * limit, skip, batchSize, comment
 *
 * Sets these associated options.
 *
 *     query.comment('feed query');
 */

['limit', 'skip', 'batchSize', 'comment'].forEach(function(method) {
  Query.prototype[method] = function(v) {
    this._validate(method);
    this.options[method] = v;
    return this;
  };
});

/**
 * Specifies the maxTimeMS option.
 *
 * #### Example:
 *
 *     query.maxTime(100)
 *     query.maxTimeMS(100)
 *
 * @method maxTime
 * @memberOf Query
 * @param {Number} ms
 * @see mongodb http://docs.mongodb.org/manual/reference/operator/meta/maxTimeMS/#op._S_maxTimeMS
 * @api public
 */

Query.prototype.maxTime = Query.prototype.maxTimeMS = function(ms) {
  this._validate('maxTime');
  this.options.maxTimeMS = ms;
  return this;
};

/**
 * Sets query hints.
 *
 * #### Example:
 *
 *     query.hint({ indexA: 1, indexB: -1});
 *     query.hint('indexA_1_indexB_1');
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @param {Object|string} val a hint object or the index name
 * @return {Query} this
 * @see mongodb http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%24hint
 * @api public
 */

Query.prototype.hint = function() {
  if (0 === arguments.length) return this;

  this._validate('hint');

  const arg = arguments[0];
  if (utils.isObject(arg)) {
    const hint = this.options.hint || (this.options.hint = {});

    // must keep object keys in order so don't use Object.keys()
    for (const k in arg) {
      hint[k] = arg[k];
    }

    return this;
  }
  if (typeof arg === 'string') {
    this.options.hint = arg;
    return this;
  }

  throw new TypeError('Invalid hint. ' + arg);
};

/**
 * Requests acknowledgement that this operation has been persisted to MongoDB's
 * on-disk journal.
 * This option is only valid for operations that write to the database:
 *
 * - `deleteOne()`
 * - `deleteMany()`
 * - `findOneAndDelete()`
 * - `findOneAndUpdate()`
 * - `updateOne()`
 * - `updateMany()`
 *
 * Defaults to the `j` value if it is specified in writeConcern options
 *
 * #### Example:
 *
 *     mquery().w(2).j(true).wtimeout(2000);
 *
 * @method j
 * @memberOf Query
 * @instance
 * @param {boolean} val
 * @see mongodb https://docs.mongodb.com/manual/reference/write-concern/#j-option
 * @return {Query} this
 * @api public
 */

Query.prototype.j = function j(val) {
  this.options.j = val;
  return this;
};

/**
 * Sets the slaveOk option. _Deprecated_ in MongoDB 2.2 in favor of read preferences.
 *
 * #### Example:
 *
 *     query.slaveOk() // true
 *     query.slaveOk(true)
 *     query.slaveOk(false)
 *
 * @deprecated use read() preferences instead if on mongodb >= 2.2
 * @param {Boolean} v defaults to true
 * @see mongodb http://docs.mongodb.org/manual/applications/replication/#read-preference
 * @see read()
 * @return {Query} this
 * @api public
 */

Query.prototype.slaveOk = function(v) {
  this.options.slaveOk = arguments.length ? !!v : true;
  return this;
};

/**
 * Sets the readPreference option for the query.
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
 *     // you can also use mongodb.ReadPreference class to also specify tags
 *     new Query().read(mongodb.ReadPreference('secondary', [{ dc:'sf', s: 1 },{ dc:'ma', s: 2 }]))
 *
 *     new Query().setReadPreference('primary') // alias of .read()
 *
 * #### Preferences:
 *
 *     primary - (default)  Read from primary only. Operations will produce an error if primary is unavailable. Cannot be combined with tags.
 *     secondary            Read from secondary if available, otherwise error.
 *     primaryPreferred     Read from primary if available, otherwise a secondary.
 *     secondaryPreferred   Read from a secondary if available, otherwise read from the primary.
 *     nearest              All operations read from among the nearest candidates, but unlike other modes, this option will include both the primary and all secondaries in the random selection.
 *
 * Aliases
 *
 *     p   primary
 *     pp  primaryPreferred
 *     s   secondary
 *     sp  secondaryPreferred
 *     n   nearest
 *
 * Read more about how to use read preferences [here](http://docs.mongodb.org/manual/applications/replication/#read-preference) and [here](http://mongodb.github.com/node-mongodb-native/driver-articles/anintroductionto1_1and2_2.html#read-preferences).
 *
 * @param {String|ReadPreference} pref one of the listed preference options or their aliases
 * @see mongodb http://docs.mongodb.org/manual/applications/replication/#read-preference
 * @see driver http://mongodb.github.com/node-mongodb-native/driver-articles/anintroductionto1_1and2_2.html#read-preferences
 * @return {Query} this
 * @api public
 */

Query.prototype.read = Query.prototype.setReadPreference = function(pref) {
  if (arguments.length > 1 && !Query.prototype.read.deprecationWarningIssued) {
    console.error('Deprecation warning: \'tags\' argument is not supported anymore in Query.read() method. Please use mongodb.ReadPreference object instead.');
    Query.prototype.read.deprecationWarningIssued = true;
  }
  this.options.readPreference = utils.readPref(pref);
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
 *     new Query().r('s') // r is alias of readConcern
 *
 *
 * #### Read Concern Level:
 *
 *     local         MongoDB 3.2+ The query returns from the instance with no guarantee guarantee that the data has been written to a majority of the replica set members (i.e. may be rolled back).
 *     available     MongoDB 3.6+ The query returns from the instance with no guarantee guarantee that the data has been written to a majority of the replica set members (i.e. may be rolled back).
 *     majority      MongoDB 3.2+ The query returns the data that has been acknowledged by a majority of the replica set members. The documents returned by the read operation are durable, even in the event of failure.
 *     linearizable  MongoDB 3.4+ The query returns data that reflects all successful majority-acknowledged writes that completed prior to the start of the read operation. The query may wait for concurrently executing writes to propagate to a majority of replica set members before returning results.
 *     snapshot      MongoDB 4.0+ Only available for operations within multi-document transactions. Upon transaction commit with write concern "majority", the transaction operations are guaranteed to have read from a snapshot of majority-committed data.
 *
 * Aliases
 *
 *     l   local
 *     a   available
 *     m   majority
 *     lz  linearizable
 *     s   snapshot
 *
 * Read more about how to use read concern [here](https://docs.mongodb.com/manual/reference/read-concern/).
 *
 * @param {String} level one of the listed read concern level or their aliases
 * @see mongodb https://docs.mongodb.com/manual/reference/read-concern/
 * @return {Query} this
 * @api public
 */

Query.prototype.readConcern = Query.prototype.r = function(level) {
  this.options.readConcern = utils.readConcern(level);
  return this;
};

/**
 * Sets tailable option.
 *
 * #### Example:
 *
 *     query.tailable() <== true
 *     query.tailable(true)
 *     query.tailable(false)
 *
 * #### Note:
 *
 * Cannot be used with `distinct()`
 *
 * @param {Boolean} v defaults to true
 * @see mongodb http://www.mongodb.org/display/DOCS/Tailable+Cursors
 * @api public
 */

Query.prototype.tailable = function() {
  this._validate('tailable');

  this.options.tailable = arguments.length
    ? !!arguments[0]
    : true;

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
 * - `findOneAndUpdate()`
 * - `updateOne()`
 * - `updateMany()`
 *
 * Defaults to the `w` value if it is specified in writeConcern options
 *
 * #### Example:
 *
 *     mquery().writeConcern(0)
 *     mquery().writeConcern(1)
 *     mquery().writeConcern({ w: 1, j: true, wtimeout: 2000 })
 *     mquery().writeConcern('majority')
 *     mquery().writeConcern('m') // same as majority
 *     mquery().writeConcern('tagSetName') // if the tag set is 'm', use .writeConcern({ w: 'm' }) instead
 *     mquery().w(1) // w is alias of writeConcern
 *
 * @method writeConcern
 * @memberOf Query
 * @instance
 * @param {String|number|object} concern 0 for fire-and-forget, 1 for acknowledged by one server, 'majority' for majority of the replica set, or [any of the more advanced options](https://docs.mongodb.com/manual/reference/write-concern/#w-option).
 * @see mongodb https://docs.mongodb.com/manual/reference/write-concern/#w-option
 * @return {Query} this
 * @api public
 */

Query.prototype.writeConcern = Query.prototype.w = function writeConcern(concern) {
  if ('object' === typeof concern) {
    if ('undefined' !== typeof concern.j) this.options.j = concern.j;
    if ('undefined' !== typeof concern.w) this.options.w = concern.w;
    if ('undefined' !== typeof concern.wtimeout) this.options.wtimeout = concern.wtimeout;
  } else {
    this.options.w = 'm' === concern ? 'majority' : concern;
  }
  return this;
};

/**
 * Specifies a time limit, in milliseconds, for the write concern.
 * If `ms > 1`, it is maximum amount of time to wait for this write
 * to propagate through the replica set before this operation fails.
 * The default is `0`, which means no timeout.
 *
 * This option is only valid for operations that write to the database:
 *
 * - `deleteOne()`
 * - `deleteMany()`
 * - `findOneAndDelete()`
 * - `findOneAndUpdate()`
 * - `updateOne()`
 * - `updateMany()`
 *
 * Defaults to `wtimeout` value if it is specified in writeConcern
 *
 * #### Example:
 *
 *     mquery().w(2).j(true).wtimeout(2000)
 *
 * @method wtimeout
 * @memberOf Query
 * @instance
 * @param {number} ms number of milliseconds to wait
 * @see mongodb https://docs.mongodb.com/manual/reference/write-concern/#wtimeout
 * @return {Query} this
 * @api public
 */

Query.prototype.wtimeout = Query.prototype.wTimeout = function wtimeout(ms) {
  this.options.wtimeout = ms;
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
  if (!source)
    return this;

  if (!Query.canMerge(source))
    throw new TypeError('Invalid argument. Expected instanceof mquery or plain object');

  if (source instanceof Query) {
    // if source has a feature, apply it to ourselves

    if (source._conditions) {
      utils.merge(this._conditions, source._conditions);
    }

    if (source._fields) {
      this._fields || (this._fields = {});
      utils.merge(this._fields, source._fields);
    }

    if (source.options) {
      this.options || (this.options = {});
      utils.merge(this.options, source.options);
    }

    if (source._updateDoc) {
      this._updateDoc || (this._updateDoc = {});
      utils.mergeClone(this._updateDoc, source._updateDoc);
    }

    if (source._distinctDoc) {
      this._distinctDoc = source._distinctDoc;
    }

    return this;
  }

  // plain object
  utils.merge(this._conditions, source);

  return this;
};

/**
 * Finds documents.
 *
 * #### Example:
 *
 *     query.find()
 *     await query.find()
 *     await query.find({ name: 'Burning Lights' })
 *
 * @param {Object} [criteria] mongodb selector
 * @return {Query} this
 * @api public
 */

Query.prototype.find = function(criteria) {
  this.op = 'find';

  if (Query.canMerge(criteria)) {
    this.merge(criteria);
  }

  return this;
};

/**
 * Executes a `find` Query
 * @returns the result
 */
Query.prototype._find = async function _find() {
  const conds = this._conditions;
  const options = this._optionsForExec();

  if (this.$useProjection) {
    options.projection = this._fieldsForExec();
  } else {
    options.fields = this._fieldsForExec();
  }

  debug('_find', this._collection.collectionName, conds, options);

  return this._collection.find(conds, options);
};

/**
 * Returns the query cursor
 *
 * #### Examples:
 *
 *     query.find().cursor();
 *     query.cursor({ name: 'Burning Lights' });
 *
 * @param {Object} [criteria] mongodb selector
 * @return {Object} cursor
 * @api public
 */

Query.prototype.cursor = function cursor(criteria) {
  if (this.op) {
    if (this.op !== 'find') {
      throw new TypeError('.cursor only support .find method');
    }
  } else {
    this.find(criteria);
  }

  const conds = this._conditions;
  const options = this._optionsForExec();

  if (this.$useProjection) {
    options.projection = this._fieldsForExec();
  } else {
    options.fields = this._fieldsForExec();
  }

  debug('findCursor', this._collection.collectionName, conds, options);
  return this._collection.findCursor(conds, options);
};

/**
 * Executes the query as a findOne() operation.
 *
 * #### Example:
 *
 *     query.findOne().where('name', /^Burning/);
 *
 *     query.findOne({ name: /^Burning/ })
 *
 *     await query.findOne({ name: /^Burning/ }); // executes
 *
 * @param {Object|Query} [criteria] mongodb selector
 * @return {Query} this
 * @api public
 */

Query.prototype.findOne = function(criteria) {
  this.op = 'findOne';

  if (Query.canMerge(criteria)) {
    this.merge(criteria);
  }

  return this;
};

/**
 * Executes a `findOne` Query
 * @returns the results
 */
Query.prototype._findOne = async function _findOne() {
  const conds = this._conditions;
  const options = this._optionsForExec();

  if (this.$useProjection) {
    options.projection = this._fieldsForExec();
  } else {
    options.fields = this._fieldsForExec();
  }

  debug('findOne', this._collection.collectionName, conds, options);

  return this._collection.findOne(conds, options);
};

/**
 * Exectues the query as a count() operation.
 *
 * #### Example:
 *
 *     query.count().where('color', 'black').exec();
 *
 *     query.count({ color: 'black' })
 *
 *     await query.count({ color: 'black' });
 *
 *     const doc = await query.where('color', 'black').count();
 *     console.log('there are %d kittens', count);
 *
 * @param {Object} [criteria] mongodb selector
 * @return {Query} this
 * @see mongodb http://www.mongodb.org/display/DOCS/Aggregation#Aggregation-Count
 * @api public
 */

Query.prototype.count = function(criteria) {
  this.op = 'count';
  this._validate();

  if (Query.canMerge(criteria)) {
    this.merge(criteria);
  }

  return this;
};

/**
 * Executes a `count` Query
 * @returns the results
 */
Query.prototype._count = async function _count() {
  const conds = this._conditions,
      options = this._optionsForExec();

  debug('count', this._collection.collectionName, conds, options);

  return this._collection.count(conds, options);
};

/**
 * Declares or executes a distinct() operation.
 *
 * #### Example:
 *
 *     await distinct(criteria, field)
 *     distinct(criteria, field)
 *     await distinct(field)
 *     distinct(field)
 *     await distinct()
 *     distinct()
 *
 * @param {Object|Query} [criteria]
 * @param {String} [field]
 * @return {Query} this
 * @see mongodb http://www.mongodb.org/display/DOCS/Aggregation#Aggregation-Distinct
 * @api public
 */

Query.prototype.distinct = function(criteria, field) {
  this.op = 'distinct';
  this._validate();

  if (!field && typeof criteria === 'string') {
    field = criteria;
    criteria = undefined;
  }

  if ('string' == typeof field) {
    this._distinctDoc = field;
  }

  if (Query.canMerge(criteria)) {
    this.merge(criteria);
  }

  return this;
};

/**
 * Executes a `distinct` Query
 * @returns the results
 */
Query.prototype._distinct = async function _distinct() {
  if (!this._distinctDoc) {
    throw new Error('No value for `distinct` has been declared');
  }

  const conds = this._conditions,
      options = this._optionsForExec();

  debug('distinct', this._collection.collectionName, conds, options);

  return this._collection.distinct(this._distinctDoc, conds, options);
};

/**
 * Declare and/or execute this query as an `updateMany()` operation. This function will update _all_ documents that match
 * `criteria`, rather than just the first one.
 *
 * _All paths passed that are not $atomic operations will become $set ops._
 *
 * #### Example:
 *
 *     // Update every document whose `title` contains 'test'
 *     mquery().updateMany({ title: /test/ }, { year: 2017 })
 *
 * @param {Object} [criteria]
 * @param {Object} [doc] the update command
 * @param {Object} [options]
 * @return {Query} this
 * @api public
 */

Query.prototype.updateMany = function updateMany(criteria, doc, options) {
  if (arguments.length === 1) {
    doc = criteria;
    criteria = options = undefined;
  }

  return _update(this, 'updateMany', criteria, doc, options);
};

/**
 * Executes a `updateMany` Query
 * @returns the results
 */
Query.prototype._updateMany = async function() {
  return _updateExec(this, 'updateMany');
};

/**
 * Declare and/or execute this query as an `updateOne()` operation. This function will _always_ update just one document,
 * regardless of the `multi` option.
 *
 * _All paths passed that are not $atomic operations will become $set ops._
 *
 * #### Example:
 *
 *     // Update the first document whose `title` contains 'test'
 *     mquery().updateMany({ title: /test/ }, { year: 2017 })
 *
 * @param {Object} [criteria]
 * @param {Object} [doc] the update command
 * @param {Object} [options]
 * @return {Query} this
 * @api public
 */

Query.prototype.updateOne = function updateOne(criteria, doc, options) {
  if (arguments.length === 1) {
    doc = criteria;
    criteria = options = undefined;
  }

  return _update(this, 'updateOne', criteria, doc, options);
};

/**
 * Executes a `updateOne` Query
 * @returns the results
 */
Query.prototype._updateOne = async function() {
  return _updateExec(this, 'updateOne');
};

/**
 * Declare and/or execute this query as an `replaceOne()` operation. Similar
 * to `updateOne()`, except `replaceOne()` is not allowed to use atomic
 * modifiers (`$set`, `$push`, etc.). Calling `replaceOne()` will always
 * replace the existing doc.
 *
 * #### Example:
 *
 *     // Replace the document with `_id` 1 with `{ _id: 1, year: 2017 }`
 *     mquery().replaceOne({ _id: 1 }, { year: 2017 })
 *
 * @param {Object} [criteria]
 * @param {Object} [doc] the update command
 * @param {Object} [options]
 * @return {Query} this
 * @api public
 */

Query.prototype.replaceOne = function replaceOne(criteria, doc, options) {
  if (arguments.length === 1) {
    doc = criteria;
    criteria = options = undefined;
  }

  this.setOptions({ overwrite: true });
  return _update(this, 'replaceOne', criteria, doc, options);
};

/**
 * Executes a `replaceOne` Query
 * @returns the results
 */
Query.prototype._replaceOne = async function() {
  return _updateExec(this, 'replaceOne');
};

/*!
 * Internal helper for updateMany, updateOne
 */

function _update(query, op, criteria, doc, options) {
  query.op = op;

  if (Query.canMerge(criteria)) {
    query.merge(criteria);
  }

  if (doc) {
    query._mergeUpdate(doc);
  }

  if (utils.isObject(options)) {
    // { overwrite: true }
    query.setOptions(options);
  }

  return query;
}

/**
 * Helper for de-duplicating "update*" functions
 * @param {Query} query The Query Object (replacement for "this")
 * @param {String} op The Operation to be done
 * @returns the results
 */
async function _updateExec(query, op) {
  const options = query._optionsForExec();

  const criteria = query._conditions;
  const doc = query._updateForExec();

  debug('update', query._collection.collectionName, criteria, doc, options);

  return query._collection[op](criteria, doc, options);
}

/**
 * Declare and/or execute this query as a `deleteOne()` operation.
 *
 * #### Example:
 *
 *     await mquery(collection).deleteOne({ artist: 'Anne Murray' })
 *
 * @param {Object|Query} [criteria] mongodb selector
 * @return {Query} this
 * @api public
 */

Query.prototype.deleteOne = function(criteria) {
  this.op = 'deleteOne';

  if (Query.canMerge(criteria)) {
    this.merge(criteria);
  }

  return this;
};

/**
 * Executes a `deleteOne` Query
 * @returns the results
 */
Query.prototype._deleteOne = async function() {
  const options = this._optionsForExec();
  delete options.justOne;

  const conds = this._conditions;

  debug('deleteOne', this._collection.collectionName, conds, options);

  return this._collection.deleteOne(conds, options);
};

/**
 * Declare and/or execute this query as a `deleteMany()` operation. Always deletes
 * _every_ document that matches `criteria`.
 *
 * #### Example:
 *
 *     await mquery(collection).deleteMany({ artist: 'Anne Murray' })
 *
 * @param {Object|Query} [criteria] mongodb selector
 * @return {Query} this
 * @api public
 */

Query.prototype.deleteMany = function(criteria) {
  this.op = 'deleteMany';

  if (Query.canMerge(criteria)) {
    this.merge(criteria);
  }

  return this;
};

/**
 * Executes a `deleteMany` Query
 * @returns the results
 */
Query.prototype._deleteMany = async function() {
  const options = this._optionsForExec();
  delete options.justOne;

  const conds = this._conditions;

  debug('deleteOne', this._collection.collectionName, conds, options);

  return this._collection.deleteMany(conds, options);
};

/**
 * Issues a mongodb [findAndModify](http://www.mongodb.org/display/DOCS/findAndModify+Command) update command.
 *
 * Finds a matching document, updates it according to the `update` arg, passing any `options`, and returns the found document (if any).
 *
 * #### Available options
 *
 * - `new`: bool - true to return the modified document rather than the original. defaults to true
 * - `upsert`: bool - creates the object if it doesn't exist. defaults to false.
 * - `sort`: if multiple docs are found by the conditions, sets the sort order to choose which doc to update
 *
 * #### Examples:
 *
 *     await query.findOneAndUpdate(conditions, update, options) // executes
 *     query.findOneAndUpdate(conditions, update, options)  // returns Query
 *     await query.findOneAndUpdate(conditions, update) // executes
 *     query.findOneAndUpdate(conditions, update)           // returns Query
 *     await query.findOneAndUpdate(update)             // returns Query
 *     query.findOneAndUpdate(update)                       // returns Query
 *     await query.findOneAndUpdate()                     // executes
 *     query.findOneAndUpdate()                             // returns Query
 *
 * @param {Object|Query} [query]
 * @param {Object} [doc]
 * @param {Object} [options]
 * @see mongodb http://www.mongodb.org/display/DOCS/findAndModify+Command
 * @return {Query} this
 * @api public
 */

Query.prototype.findOneAndUpdate = function(criteria, doc, options) {
  this.op = 'findOneAndUpdate';
  this._validate();

  if (arguments.length === 1) {
    doc = criteria;
    criteria = options = undefined;
  }

  if (Query.canMerge(criteria)) {
    this.merge(criteria);
  }

  // apply doc
  if (doc) {
    this._mergeUpdate(doc);
  }

  options && this.setOptions(options);

  return this;
};

/**
 * Executes a `findOneAndUpdate` Query
 * @returns the results
 */
Query.prototype._findOneAndUpdate = async function() {
  const conds = this._conditions;
  const update = this._updateForExec();
  const options = this._optionsForExec();

  return this._collection.findOneAndUpdate(conds, update, options);
};

/**
 * Issues a mongodb [findAndModify](http://www.mongodb.org/display/DOCS/findAndModify+Command) remove command.
 *
 * Finds a matching document, removes it, returning the found document (if any).
 *
 * #### Available options
 *
 * - `sort`: if multiple docs are found by the conditions, sets the sort order to choose which doc to update
 *
 * #### Examples:
 *
 *     await A.where().findOneAndRemove(conditions, options) // executes
 *     A.where().findOneAndRemove(conditions, options)  // return Query
 *     await A.where().findOneAndRemove(conditions) // executes
 *     A.where().findOneAndRemove(conditions) // returns Query
 *     await A.where().findOneAndRemove()   // executes
 *     A.where().findOneAndRemove()           // returns Query
 *     A.where().findOneAndDelete()           // alias of .findOneAndRemove()
 *
 * @param {Object} [conditions]
 * @param {Object} [options]
 * @return {Query} this
 * @see mongodb http://www.mongodb.org/display/DOCS/findAndModify+Command
 * @api public
 */

Query.prototype.findOneAndRemove = Query.prototype.findOneAndDelete = function(conditions, options) {
  this.op = 'findOneAndRemove';
  this._validate();

  // apply conditions
  if (Query.canMerge(conditions)) {
    this.merge(conditions);
  }

  // apply options
  options && this.setOptions(options);

  return this;
};

/**
 * Executes a `findOneAndRemove` Query
 * @returns the results
 */
Query.prototype._findOneAndRemove = async function() {
  const options = this._optionsForExec();
  const conds = this._conditions;

  return this._collection.findOneAndDelete(conds, options);
};

/**
 * Add trace function that gets called when the query is executed.
 * The function will be called with (method, queryInfo, query) and
 * should return a callback function which will be called
 * with (err, result, millis) when the query is complete.
 *
 * queryInfo is an object containing: {
 *   collectionName: <name of the collection>,
 *   conditions: <query criteria>,
 *   options: <comment, fields, readPreference, etc>,
 *   doc: [document to update, if applicable]
 * }
 *
 * NOTE: Does not trace stream queries.
 *
 * @param {Function} traceFunction
 * @return {Query} this
 * @api public
 */
Query.prototype.setTraceFunction = function(traceFunction) {
  this._traceFunction = traceFunction;
  return this;
};

/**
 * Executes the query
 *
 * #### Examples:
 *
 *     query.exec();
 *     await query.exec();
 *     query.exec('update');
 *     await query.exec('find');
 *
 * @param {String|Function} [operation]
 * @api public
 */

Query.prototype.exec = async function exec(op) {
  if (typeof op === 'string') {
    this.op = op;
  }

  assert.ok(this.op, 'Missing query type: (find, etc)');

  const fnName = '_' + this.op;

  // better error, because default would list it as "this[fnName] is not a function"
  if (typeof this[fnName] !== 'function') {
    throw new TypeError(`this[${fnName}] is not a function`);
  }

  return this[fnName]();
};

/**
 * Executes the query returning a `Promise` which will be
 * resolved with either the doc(s) or rejected with the error.
 *
 * @param {Function} [resolve]
 * @param {Function} [reject]
 * @return {Promise}
 * @api public
 */

Query.prototype.then = async function(res, rej) {
  return this.exec().then(res, rej);
};

/**
 * Returns a cursor for the given `find` query.
 *
 * @throws Error if operation is not a find
 * @returns {Cursor} MongoDB driver cursor
 */

Query.prototype.cursor = function() {
  if ('find' != this.op)
    throw new Error('cursor() is only available for find');

  const conds = this._conditions;

  const options = this._optionsForExec();
  if (this.$useProjection) {
    options.projection = this._fieldsForExec();
  } else {
    options.fields = this._fieldsForExec();
  }

  debug('cursor', this._collection.collectionName, conds, options);

  return this._collection.findCursor(conds, options);
};

/**
 * Determines if field selection has been made.
 *
 * @return {Boolean}
 * @api public
 */

Query.prototype.selected = function selected() {
  return !!(this._fields && Object.keys(this._fields).length > 0);
};

/**
 * Determines if inclusive field selection has been made.
 *
 *     query.selectedInclusively() // false
 *     query.select('name')
 *     query.selectedInclusively() // true
 *     query.selectedExlusively() // false
 *
 * @returns {Boolean}
 */

Query.prototype.selectedInclusively = function selectedInclusively() {
  if (!this._fields) return false;

  const keys = Object.keys(this._fields);
  if (0 === keys.length) return false;

  for (let i = 0; i < keys.length; ++i) {
    const key = keys[i];
    if (0 === this._fields[key]) return false;
    if (this._fields[key] &&
        typeof this._fields[key] === 'object' &&
        this._fields[key].$meta) {
      return false;
    }
  }

  return true;
};

/**
 * Determines if exclusive field selection has been made.
 *
 *     query.selectedExlusively() // false
 *     query.select('-name')
 *     query.selectedExlusively() // true
 *     query.selectedInclusively() // false
 *
 * @returns {Boolean}
 */

Query.prototype.selectedExclusively = function selectedExclusively() {
  if (!this._fields) return false;

  const keys = Object.keys(this._fields);
  if (0 === keys.length) return false;

  for (let i = 0; i < keys.length; ++i) {
    const key = keys[i];
    if (0 === this._fields[key]) return true;
  }

  return false;
};

/**
 * Merges `doc` with the current update object.
 *
 * @param {Object} doc
 */

Query.prototype._mergeUpdate = function(doc) {
  if (!this._updateDoc) this._updateDoc = {};
  if (doc instanceof Query) {
    if (doc._updateDoc) {
      utils.mergeClone(this._updateDoc, doc._updateDoc);
    }
  } else {
    utils.mergeClone(this._updateDoc, doc);
  }
};

/**
 * Returns default options.
 *
 * @return {Object}
 * @api private
 */

Query.prototype._optionsForExec = function() {
  const options = utils.clone(this.options);
  return options;
};

/**
 * Returns fields selection for this query.
 *
 * @return {Object}
 * @api private
 */

Query.prototype._fieldsForExec = function() {
  return utils.clone(this._fields);
};

/**
 * Return an update document with corrected $set operations.
 *
 * @api private
 */

Query.prototype._updateForExec = function() {
  const update = utils.clone(this._updateDoc);
  const ops = utils.keys(update);
  const ret = {};

  for (const op of ops) {
    if (this.options.overwrite) {
      ret[op] = update[op];
      continue;
    }

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
      if (!~ops.indexOf('$set')) ops.push('$set');
    } else if ('$set' === op) {
      if (!ret.$set) {
        ret[op] = update[op];
      }
    } else {
      ret[op] = update[op];
    }
  }

  this._compiledUpdate = ret;
  return ret;
};

/**
 * Make sure _path is set.
 *
 * @parmam {String} method
 */

Query.prototype._ensurePath = function(method) {
  if (!this._path) {
    const msg = method + '() must be used after where() '
                     + 'when called with these arguments';
    throw new Error(msg);
  }
};

/*!
 * Permissions
 */

Query.permissions = require('./permissions');

Query._isPermitted = function(a, b) {
  const denied = Query.permissions[b];
  if (!denied) return true;
  return true !== denied[a];
};

Query.prototype._validate = function(action) {
  let fail;
  let validator;

  if (undefined === action) {

    validator = Query.permissions[this.op];
    if ('function' != typeof validator) return true;

    fail = validator(this);

  } else if (!Query._isPermitted(action, this.op)) {
    fail = action;
  }

  if (fail) {
    throw new Error(fail + ' cannot be used with ' + this.op);
  }
};

/**
 * Determines if `conds` can be merged using `mquery().merge()`
 *
 * @param {Object} conds
 * @return {Boolean}
 */

Query.canMerge = function(conds) {
  return conds instanceof Query || utils.isObject(conds);
};

/**
 * Set a trace function that will get called whenever a
 * query is executed.
 *
 * See `setTraceFunction()` for details.
 *
 * @param {Object} conds
 * @return {Boolean}
 */
Query.setGlobalTraceFunction = function(traceFunction) {
  Query.traceFunction = traceFunction;
};

/*!
 * Exports.
 */

Query.utils = utils;
Query.env = require('./env');
Query.Collection = require('./collection');
Query.BaseCollection = require('./collection/collection');
module.exports = exports = Query;

// TODO
// test utils
