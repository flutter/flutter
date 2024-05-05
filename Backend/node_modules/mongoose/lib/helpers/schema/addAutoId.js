'use strict';

module.exports = function addAutoId(schema) {
  const _obj = { _id: { auto: true } };
  _obj._id[schema.options.typeKey] = 'ObjectId';
  schema.add(_obj);
};
