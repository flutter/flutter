'use strict';

exports.isMongooseDocumentArray = function(mongooseDocumentArray) {
  return Array.isArray(mongooseDocumentArray) && mongooseDocumentArray.isMongooseDocumentArray;
};
