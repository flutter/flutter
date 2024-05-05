'use strict';

const objectIdSymbol = require('../helpers/symbols').objectIdSymbol;
const utils = require('../utils');

/*!
 * ignore
 */

module.exports = function shardingPlugin(schema) {
  schema.post('init', function shardingPluginPostInit() {
    storeShard.call(this);
    return this;
  });
  schema.pre('save', function shardingPluginPreSave(next) {
    applyWhere.call(this);
    next();
  });
  schema.pre('remove', function shardingPluginPreRemove(next) {
    applyWhere.call(this);
    next();
  });
  schema.post('save', function shardingPluginPostSave() {
    storeShard.call(this);
  });
};

/*!
 * ignore
 */

function applyWhere() {
  let paths;
  let len;

  if (this.$__.shardval) {
    paths = Object.keys(this.$__.shardval);
    len = paths.length;

    this.$where = this.$where || {};
    for (let i = 0; i < len; ++i) {
      this.$where[paths[i]] = this.$__.shardval[paths[i]];
    }
  }
}

/*!
 * ignore
 */

module.exports.storeShard = storeShard;

/*!
 * ignore
 */

function storeShard() {
  // backwards compat
  const key = this.$__schema.options.shardKey || this.$__schema.options.shardkey;
  if (!utils.isPOJO(key)) {
    return;
  }

  const orig = this.$__.shardval = {};
  const paths = Object.keys(key);
  const len = paths.length;
  let val;

  for (let i = 0; i < len; ++i) {
    val = this.$__getValue(paths[i]);
    if (val == null) {
      orig[paths[i]] = val;
    } else if (utils.isMongooseObject(val)) {
      orig[paths[i]] = val.toObject({ depopulate: true, _isNested: true });
    } else if (val instanceof Date || val[objectIdSymbol]) {
      orig[paths[i]] = val;
    } else if (typeof val.valueOf === 'function') {
      orig[paths[i]] = val.valueOf();
    } else {
      orig[paths[i]] = val;
    }
  }
}
