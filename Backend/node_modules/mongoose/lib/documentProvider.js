'use strict';

/* eslint-env browser */

/*!
 * Module dependencies.
 */
const Document = require('./document.js');
const BrowserDocument = require('./browserDocument.js');

let isBrowser = false;

/**
 * Returns the Document constructor for the current context
 *
 * @api private
 */
module.exports = function documentProvider() {
  if (isBrowser) {
    return BrowserDocument;
  }
  return Document;
};

/*!
 * ignore
 */
module.exports.setBrowser = function(flag) {
  isBrowser = flag;
};
