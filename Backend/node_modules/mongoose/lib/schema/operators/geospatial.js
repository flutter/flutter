/*!
 * Module requirements.
 */

'use strict';

const castArraysOfNumbers = require('./helpers').castArraysOfNumbers;
const castToNumber = require('./helpers').castToNumber;

/*!
 * ignore
 */

exports.cast$geoIntersects = cast$geoIntersects;
exports.cast$near = cast$near;
exports.cast$within = cast$within;

function cast$near(val) {
  const SchemaArray = require('../array');

  if (Array.isArray(val)) {
    castArraysOfNumbers(val, this);
    return val;
  }

  _castMinMaxDistance(this, val);

  if (val && val.$geometry) {
    return cast$geometry(val, this);
  }

  if (!Array.isArray(val)) {
    throw new TypeError('$near must be either an array or an object ' +
      'with a $geometry property');
  }

  return SchemaArray.prototype.castForQuery.call(this, null, val);
}

function cast$geometry(val, self) {
  switch (val.$geometry.type) {
    case 'Polygon':
    case 'LineString':
    case 'Point':
      castArraysOfNumbers(val.$geometry.coordinates, self);
      break;
    default:
      // ignore unknowns
      break;
  }

  _castMinMaxDistance(self, val);

  return val;
}

function cast$within(val) {
  _castMinMaxDistance(this, val);

  if (val.$box || val.$polygon) {
    const type = val.$box ? '$box' : '$polygon';
    val[type].forEach(arr => {
      if (!Array.isArray(arr)) {
        const msg = 'Invalid $within $box argument. '
            + 'Expected an array, received ' + arr;
        throw new TypeError(msg);
      }
      arr.forEach((v, i) => {
        arr[i] = castToNumber.call(this, v);
      });
    });
  } else if (val.$center || val.$centerSphere) {
    const type = val.$center ? '$center' : '$centerSphere';
    val[type].forEach((item, i) => {
      if (Array.isArray(item)) {
        item.forEach((v, j) => {
          item[j] = castToNumber.call(this, v);
        });
      } else {
        val[type][i] = castToNumber.call(this, item);
      }
    });
  } else if (val.$geometry) {
    cast$geometry(val, this);
  }

  return val;
}

function cast$geoIntersects(val) {
  const geo = val.$geometry;
  if (!geo) {
    return;
  }

  cast$geometry(val, this);
  return val;
}

function _castMinMaxDistance(self, val) {
  if (val.$maxDistance) {
    val.$maxDistance = castToNumber.call(self, val.$maxDistance);
  }
  if (val.$minDistance) {
    val.$minDistance = castToNumber.call(self, val.$minDistance);
  }
}
