'use strict';

const Document = require('../document');
const immediate = require('../helpers/immediate');
const internalToObjectOptions = require('../options').internalToObjectOptions;
const util = require('util');
const utils = require('../utils');

module.exports = Subdocument;

/**
 * Subdocument constructor.
 *
 * @inherits Document
 * @api private
 */

function Subdocument(value, fields, parent, skipId, options) {
  if (typeof skipId === 'object' && skipId != null && options == null) {
    options = skipId;
    skipId = undefined;
  }
  if (parent != null) {
    // If setting a nested path, should copy isNew from parent re: gh-7048
    const parentOptions = { isNew: parent.isNew };
    if ('defaults' in parent.$__) {
      parentOptions.defaults = parent.$__.defaults;
    }
    options = Object.assign(parentOptions, options);
  }
  if (options != null && options.path != null) {
    this.$basePath = options.path;
  }
  Document.call(this, value, fields, skipId, options);

  delete this.$__.priorDoc;
}

Subdocument.prototype = Object.create(Document.prototype);

Object.defineProperty(Subdocument.prototype, '$isSubdocument', {
  configurable: false,
  writable: false,
  value: true
});

Object.defineProperty(Subdocument.prototype, '$isSingleNested', {
  configurable: false,
  writable: false,
  value: true
});

/*!
 * ignore
 */

Subdocument.prototype.toBSON = function() {
  return this.toObject(internalToObjectOptions);
};

/**
 * Used as a stub for middleware
 *
 * #### Note:
 *
 * _This is a no-op. Does not actually save the doc to the db._
 *
 * @param {Function} [fn]
 * @return {Promise} resolved Promise
 * @api private
 */

Subdocument.prototype.save = async function save(options) {
  options = options || {};

  if (!options.suppressWarning) {
    utils.warn('mongoose: calling `save()` on a subdoc does **not** save ' +
      'the document to MongoDB, it only runs save middleware. ' +
      'Use `subdoc.save({ suppressWarning: true })` to hide this warning ' +
      'if you\'re sure this behavior is right for your app.');
  }

  return new Promise((resolve, reject) => {
    this.$__save((err) => {
      if (err != null) {
        return reject(err);
      }
      resolve(this);
    });
  });
};

/**
 * Given a path relative to this document, return the path relative
 * to the top-level document.
 * @param {String} path
 * @method $__fullPath
 * @memberOf Subdocument
 * @instance
 * @returns {String}
 * @api private
 */

Subdocument.prototype.$__fullPath = function(path) {
  if (!this.$__.fullPath) {
    this.ownerDocument();
  }

  return path ?
    this.$__.fullPath + '.' + path :
    this.$__.fullPath;
};

/**
 * Given a path relative to this document, return the path relative
 * to the top-level document.
 * @param {String} p
 * @returns {String}
 * @method $__pathRelativeToParent
 * @memberOf Subdocument
 * @instance
 * @api private
 */

Subdocument.prototype.$__pathRelativeToParent = function(p) {
  if (p == null) {
    return this.$basePath;
  }
  return [this.$basePath, p].join('.');
};

/**
 * Used as a stub for middleware
 *
 * #### Note:
 *
 * _This is a no-op. Does not actually save the doc to the db._
 *
 * @param {Function} [fn]
 * @method $__save
 * @api private
 */

Subdocument.prototype.$__save = function(fn) {
  return immediate(() => fn(null, this));
};

/*!
 * ignore
 */

Subdocument.prototype.$isValid = function(path) {
  const parent = this.$parent();
  const fullPath = this.$__pathRelativeToParent(path);
  if (parent != null && fullPath != null) {
    return parent.$isValid(fullPath);
  }
  return Document.prototype.$isValid.call(this, path);
};

/*!
 * ignore
 */

Subdocument.prototype.markModified = function(path) {
  Document.prototype.markModified.call(this, path);
  const parent = this.$parent();
  const fullPath = this.$__pathRelativeToParent(path);

  if (parent == null || fullPath == null) {
    return;
  }

  const myPath = this.$__pathRelativeToParent().replace(/\.$/, '');
  if (parent.isDirectModified(myPath) || this.isNew) {
    return;
  }
  this.$__parent.markModified(fullPath, this);
};

/*!
 * ignore
 */

Subdocument.prototype.isModified = function(paths, options, modifiedPaths) {
  const parent = this.$parent();
  if (parent != null) {
    if (Array.isArray(paths) || typeof paths === 'string') {
      paths = (Array.isArray(paths) ? paths : paths.split(' '));
      paths = paths.map(p => this.$__pathRelativeToParent(p)).filter(p => p != null);
    } else if (!paths) {
      paths = this.$__pathRelativeToParent();
    }

    return parent.$isModified(paths, options, modifiedPaths);
  }

  return Document.prototype.isModified.call(this, paths, options, modifiedPaths);
};

/**
 * Marks a path as valid, removing existing validation errors.
 *
 * @param {String} path the field to mark as valid
 * @api private
 * @method $markValid
 * @memberOf Subdocument
 */

Subdocument.prototype.$markValid = function(path) {
  Document.prototype.$markValid.call(this, path);
  const parent = this.$parent();
  const fullPath = this.$__pathRelativeToParent(path);
  if (parent != null && fullPath != null) {
    parent.$markValid(fullPath);
  }
};

/*!
 * ignore
 */

Subdocument.prototype.invalidate = function(path, err, val) {
  Document.prototype.invalidate.call(this, path, err, val);

  const parent = this.$parent();
  const fullPath = this.$__pathRelativeToParent(path);
  if (parent != null && fullPath != null) {
    parent.invalidate(fullPath, err, val);
  } else if (err.kind === 'cast' || err.name === 'CastError' || fullPath == null) {
    throw err;
  }

  return this.ownerDocument().$__.validationError;
};

/*!
 * ignore
 */

Subdocument.prototype.$ignore = function(path) {
  Document.prototype.$ignore.call(this, path);
  const parent = this.$parent();
  const fullPath = this.$__pathRelativeToParent(path);
  if (parent != null && fullPath != null) {
    parent.$ignore(fullPath);
  }
};

/**
 * Returns the top level document of this sub-document.
 *
 * @return {Document}
 */

Subdocument.prototype.ownerDocument = function() {
  if (this.$__.ownerDocument) {
    return this.$__.ownerDocument;
  }

  let parent = this; // eslint-disable-line consistent-this
  const paths = [];
  const seenDocs = new Set([parent]);

  while (true) {
    if (typeof parent.$__pathRelativeToParent !== 'function') {
      break;
    }
    paths.unshift(parent.$__pathRelativeToParent(void 0, true));
    const _parent = parent.$parent();
    if (_parent == null) {
      break;
    }
    parent = _parent;
    if (seenDocs.has(parent)) {
      throw new Error('Infinite subdocument loop: subdoc with _id ' + parent._id + ' is a parent of itself');
    }

    seenDocs.add(parent);
  }

  this.$__.fullPath = paths.join('.');

  this.$__.ownerDocument = parent;
  return this.$__.ownerDocument;
};

/*!
 * ignore
 */

Subdocument.prototype.$__fullPathWithIndexes = function() {
  let parent = this; // eslint-disable-line consistent-this
  const paths = [];
  const seenDocs = new Set([parent]);

  while (true) {
    if (typeof parent.$__pathRelativeToParent !== 'function') {
      break;
    }
    paths.unshift(parent.$__pathRelativeToParent(void 0, false));
    const _parent = parent.$parent();
    if (_parent == null) {
      break;
    }
    parent = _parent;
    if (seenDocs.has(parent)) {
      throw new Error('Infinite subdocument loop: subdoc with _id ' + parent._id + ' is a parent of itself');
    }

    seenDocs.add(parent);
  }

  return paths.join('.');
};

/**
 * Returns this sub-documents parent document.
 *
 * @api public
 */

Subdocument.prototype.parent = function() {
  return this.$__parent;
};

/**
 * Returns this sub-documents parent document.
 *
 * @api public
 * @method $parent
 */

Subdocument.prototype.$parent = Subdocument.prototype.parent;

/**
 * no-op for hooks
 * @param {Function} cb
 * @method $__deleteOne
 * @memberOf Subdocument
 * @instance
 * @api private
 */

Subdocument.prototype.$__deleteOne = function(cb) {
  if (cb == null) {
    return;
  }
  return cb(null, this);
};

/**
 * ignore
 * @method $__removeFromParent
 * @memberOf Subdocument
 * @instance
 * @api private
 */

Subdocument.prototype.$__removeFromParent = function() {
  this.$__parent.set(this.$basePath, null);
};

/**
 * Null-out this subdoc
 *
 * @param {Object} [options]
 * @param {Function} [callback] optional callback for compatibility with Document.prototype.remove
 */

Subdocument.prototype.deleteOne = function(options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = null;
  }
  registerRemoveListener(this);

  // If removing entire doc, no need to remove subdoc
  if (!options || !options.noop) {
    this.$__removeFromParent();
  }

  return this.$__deleteOne(callback);
};

/*!
 * ignore
 */

Subdocument.prototype.populate = function() {
  throw new Error('Mongoose does not support calling populate() on nested ' +
    'docs. Instead of `doc.nested.populate("path")`, use ' +
    '`doc.populate("nested.path")`');
};

/**
 * Helper for console.log
 *
 * @api public
 */

Subdocument.prototype.inspect = function() {
  return this.toObject();
};

if (util.inspect.custom) {
  // Avoid Node deprecation warning DEP0079
  Subdocument.prototype[util.inspect.custom] = Subdocument.prototype.inspect;
}

/**
 * Registers remove event listeners for triggering
 * on subdocuments.
 *
 * @param {Subdocument} sub
 * @api private
 */

function registerRemoveListener(sub) {
  let owner = sub.ownerDocument();

  function emitRemove() {
    owner.$removeListener('save', emitRemove);
    owner.$removeListener('deleteOne', emitRemove);
    sub.emit('deleteOne', sub);
    sub.constructor.emit('deleteOne', sub);
    owner = sub = null;
  }

  owner.$on('save', emitRemove);
  owner.$on('deleteOne', emitRemove);
}
