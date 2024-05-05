'use strict';

const ArrayMethods = require('../../array/methods');
const Document = require('../../../document');
const castObjectId = require('../../../cast/objectid');
const getDiscriminatorByValue = require('../../../helpers/discriminator/getDiscriminatorByValue');
const internalToObjectOptions = require('../../../options').internalToObjectOptions;
const utils = require('../../../utils');
const isBsonType = require('../../../helpers/isBsonType');

const arrayParentSymbol = require('../../../helpers/symbols').arrayParentSymbol;
const arrayPathSymbol = require('../../../helpers/symbols').arrayPathSymbol;
const arraySchemaSymbol = require('../../../helpers/symbols').arraySchemaSymbol;
const documentArrayParent = require('../../../helpers/symbols').documentArrayParent;

const _baseToString = Array.prototype.toString;

const methods = {
  /*!
   * ignore
   */

  toBSON() {
    return this.toObject(internalToObjectOptions);
  },

  toString() {
    return _baseToString.call(this.__array.map(subdoc => {
      if (subdoc != null && subdoc.$__ != null) {
        return subdoc.toString();
      }
      return subdoc;
    }));
  },

  /*!
   * ignore
   */

  getArrayParent() {
    return this[arrayParentSymbol];
  },

  /**
   * Overrides MongooseArray#cast
   *
   * @method _cast
   * @api private
   * @memberOf MongooseDocumentArray
   */

  _cast(value, index, options) {
    if (this[arraySchemaSymbol] == null) {
      return value;
    }
    let Constructor = this[arraySchemaSymbol].casterConstructor;
    const isInstance = Constructor.$isMongooseDocumentArray ?
      utils.isMongooseDocumentArray(value) :
      value instanceof Constructor;
    if (isInstance ||
        // Hack re: #5001, see #5005
        (value && value.constructor && value.constructor.baseCasterConstructor === Constructor)) {
      if (!(value[documentArrayParent] && value.__parentArray)) {
        // value may have been created using array.create()
        value[documentArrayParent] = this[arrayParentSymbol];
        value.__parentArray = this;
      }
      value.$setIndex(index);
      return value;
    }

    if (value === undefined || value === null) {
      return null;
    }

    // handle cast('string') or cast(ObjectId) etc.
    // only objects are permitted so we can safely assume that
    // non-objects are to be interpreted as _id
    if (Buffer.isBuffer(value) ||
        isBsonType(value, 'ObjectId') || !utils.isObject(value)) {
      value = { _id: value };
    }

    if (value &&
        Constructor.discriminators &&
        Constructor.schema &&
        Constructor.schema.options &&
        Constructor.schema.options.discriminatorKey) {
      if (typeof value[Constructor.schema.options.discriminatorKey] === 'string' &&
          Constructor.discriminators[value[Constructor.schema.options.discriminatorKey]]) {
        Constructor = Constructor.discriminators[value[Constructor.schema.options.discriminatorKey]];
      } else {
        const constructorByValue = getDiscriminatorByValue(Constructor.discriminators, value[Constructor.schema.options.discriminatorKey]);
        if (constructorByValue) {
          Constructor = constructorByValue;
        }
      }
    }

    if (Constructor.$isMongooseDocumentArray) {
      return Constructor.cast(value, this, undefined, undefined, index);
    }
    const ret = new Constructor(value, this, options, undefined, index);
    ret.isNew = true;
    return ret;
  },

  /**
   * Searches array items for the first document with a matching _id.
   *
   * #### Example:
   *
   *     const embeddedDoc = m.array.id(some_id);
   *
   * @return {EmbeddedDocument|null} the subdocument or null if not found.
   * @param {ObjectId|String|Number|Buffer} id
   * @TODO cast to the _id based on schema for proper comparison
   * @method id
   * @api public
   * @memberOf MongooseDocumentArray
   */

  id(id) {
    let casted;
    let sid;
    let _id;

    try {
      casted = castObjectId(id).toString();
    } catch (e) {
      casted = null;
    }

    for (const val of this) {
      if (!val) {
        continue;
      }

      _id = val.get('_id');

      if (_id === null || typeof _id === 'undefined') {
        continue;
      } else if (_id instanceof Document) {
        sid || (sid = String(id));
        if (sid == _id._id) {
          return val;
        }
      } else if (!isBsonType(id, 'ObjectId') && !isBsonType(_id, 'ObjectId')) {
        if (id == _id || utils.deepEqual(id, _id)) {
          return val;
        }
      } else if (casted == _id) {
        return val;
      }
    }

    return null;
  },

  /**
   * Returns a native js Array of plain js objects
   *
   * #### Note:
   *
   * _Each sub-document is converted to a plain object by calling its `#toObject` method._
   *
   * @param {Object} [options] optional options to pass to each documents `toObject` method call during conversion
   * @return {Array}
   * @method toObject
   * @api public
   * @memberOf MongooseDocumentArray
   */

  toObject(options) {
    // `[].concat` coerces the return value into a vanilla JS array, rather
    // than a Mongoose array.
    return [].concat(this.map(function(doc) {
      if (doc == null) {
        return null;
      }
      if (typeof doc.toObject !== 'function') {
        return doc;
      }
      return doc.toObject(options);
    }));
  },

  $toObject() {
    return this.constructor.prototype.toObject.apply(this, arguments);
  },

  /**
   * Wraps [`Array#push`](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/push) with proper change tracking.
   *
   * @param {...Object} [args]
   * @api public
   * @method push
   * @memberOf MongooseDocumentArray
   */

  push() {
    const ret = ArrayMethods.push.apply(this, arguments);

    _updateParentPopulated(this);

    return ret;
  },

  /**
   * Pulls items from the array atomically.
   *
   * @param {...Object} [args]
   * @api public
   * @method pull
   * @memberOf MongooseDocumentArray
   */

  pull() {
    const ret = ArrayMethods.pull.apply(this, arguments);

    _updateParentPopulated(this);

    return ret;
  },

  /**
   * Wraps [`Array#shift`](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/unshift) with proper change tracking.
   * @api private
   */

  shift() {
    const ret = ArrayMethods.shift.apply(this, arguments);

    _updateParentPopulated(this);

    return ret;
  },

  /**
   * Wraps [`Array#splice`](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/splice) with proper change tracking and casting.
   * @api private
   */

  splice() {
    const ret = ArrayMethods.splice.apply(this, arguments);

    _updateParentPopulated(this);

    return ret;
  },

  /**
   * Helper for console.log
   *
   * @method inspect
   * @api public
   * @memberOf MongooseDocumentArray
   */

  inspect() {
    return this.toObject();
  },

  /**
   * Creates a subdocument casted to this schema.
   *
   * This is the same subdocument constructor used for casting.
   *
   * @param {Object} obj the value to cast to this arrays SubDocument schema
   * @method create
   * @api public
   * @memberOf MongooseDocumentArray
   */

  create(obj) {
    let Constructor = this[arraySchemaSymbol].casterConstructor;
    if (obj &&
        Constructor.discriminators &&
        Constructor.schema &&
        Constructor.schema.options &&
        Constructor.schema.options.discriminatorKey) {
      if (typeof obj[Constructor.schema.options.discriminatorKey] === 'string' &&
          Constructor.discriminators[obj[Constructor.schema.options.discriminatorKey]]) {
        Constructor = Constructor.discriminators[obj[Constructor.schema.options.discriminatorKey]];
      } else {
        const constructorByValue = getDiscriminatorByValue(Constructor.discriminators, obj[Constructor.schema.options.discriminatorKey]);
        if (constructorByValue) {
          Constructor = constructorByValue;
        }
      }
    }

    return new Constructor(obj, this);
  },

  /*!
   * ignore
   */

  notify(event) {
    const _this = this;
    return function notify(val, _arr) {
      _arr = _arr || _this;
      let i = _arr.length;
      while (i--) {
        if (_arr[i] == null) {
          continue;
        }
        switch (event) {
          // only swap for save event for now, we may change this to all event types later
          case 'save':
            val = _this[i];
            break;
          default:
            // NO-OP
            break;
        }

        if (utils.isMongooseArray(_arr[i])) {
          notify(val, _arr[i]);
        } else if (_arr[i]) {
          _arr[i].emit(event, val);
        }
      }
    };
  },

  set(i, val, skipModified) {
    const arr = this.__array;
    if (skipModified) {
      arr[i] = val;
      return this;
    }
    const value = methods._cast.call(this, val, i);
    methods._markModified.call(this, i);
    arr[i] = value;
    return this;
  },

  _markModified(elem, embeddedPath) {
    const parent = this[arrayParentSymbol];
    let dirtyPath;

    if (parent) {
      dirtyPath = this[arrayPathSymbol];

      if (arguments.length) {
        if (embeddedPath != null) {
          // an embedded doc bubbled up the change
          const index = elem.__index;
          dirtyPath = dirtyPath + '.' + index + '.' + embeddedPath;
        } else {
          // directly set an index
          dirtyPath = dirtyPath + '.' + elem;
        }
      }

      if (dirtyPath != null && dirtyPath.endsWith('.$')) {
        return this;
      }

      parent.markModified(dirtyPath, arguments.length !== 0 ? elem : parent);
    }

    return this;
  }
};

module.exports = methods;

/**
 * If this is a document array, each element may contain single
 * populated paths, so we need to modify the top-level document's
 * populated cache. See gh-8247, gh-8265.
 * @param {Array} arr
 * @api private
 */

function _updateParentPopulated(arr) {
  const parent = arr[arrayParentSymbol];
  if (!parent || parent.$__.populated == null) return;

  const populatedPaths = Object.keys(parent.$__.populated).
    filter(p => p.startsWith(arr[arrayPathSymbol] + '.'));

  for (const path of populatedPaths) {
    const remnant = path.slice((arr[arrayPathSymbol] + '.').length);
    if (!Array.isArray(parent.$__.populated[path].value)) {
      continue;
    }

    parent.$__.populated[path].value = arr.map(val => val.$populated(remnant));
  }
}
