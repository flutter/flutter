'use strict';

const get = require('../get');
const mpath = require('mpath');
const parseProjection = require('../projection/parseProjection');

/*!
 * ignore
 */

module.exports = function removeDeselectedForeignField(foreignFields, options, docs) {
  const projection = parseProjection(get(options, 'select', null), true) ||
    parseProjection(get(options, 'options.select', null), true);

  if (projection == null) {
    return;
  }
  for (const foreignField of foreignFields) {
    if (!projection.hasOwnProperty('-' + foreignField)) {
      continue;
    }

    for (const val of docs) {
      if (val.$__ != null) {
        mpath.unset(foreignField, val._doc);
      } else {
        mpath.unset(foreignField, val);
      }
    }
  }
};
