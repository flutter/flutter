'use strict';

exports.isMongooseArray = function(mongooseArray) {
  return Array.isArray(mongooseArray) && mongooseArray.isMongooseArray;
};
