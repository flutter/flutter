'use strict';

const clone = require('../../helpers/clone');
const leanPopulateMap = require('./leanPopulateMap');
const modelSymbol = require('../symbols').modelSymbol;
const utils = require('../../utils');

module.exports = assignRawDocsToIdStructure;

const kHasArray = Symbol('mongoose#assignRawDocsToIdStructure#hasArray');

/**
 * Assign `vals` returned by mongo query to the `rawIds`
 * structure returned from utils.getVals() honoring
 * query sort order if specified by user.
 *
 * This can be optimized.
 *
 * Rules:
 *
 *   if the value of the path is not an array, use findOne rules, else find.
 *   for findOne the results are assigned directly to doc path (including null results).
 *   for find, if user specified sort order, results are assigned directly
 *   else documents are put back in original order of array if found in results
 *
 * @param {Array} rawIds
 * @param {Array} resultDocs
 * @param {Array} resultOrder
 * @param {Object} options
 * @param {Boolean} recursed
 * @api private
 */

function assignRawDocsToIdStructure(rawIds, resultDocs, resultOrder, options, recursed) {
  // honor user specified sort order, unless we're populating a single
  // virtual underneath an array (e.g. populating `employees.mostRecentShift` where
  // `mostRecentShift` is a virtual with `justOne`)
  const newOrder = [];
  const sorting = options.isVirtual && options.justOne && rawIds.length > 1
    ? false :
    options.sort && rawIds.length > 1;
  const nullIfNotFound = options.$nullIfNotFound;
  let doc;
  let sid;
  let id;

  if (utils.isMongooseArray(rawIds)) {
    rawIds = rawIds.__array;
  }

  let i = 0;
  const len = rawIds.length;

  if (sorting && recursed && options[kHasArray] === undefined) {
    options[kHasArray] = false;
    for (const key in resultOrder) {
      if (Array.isArray(resultOrder[key])) {
        options[kHasArray] = true;
        break;
      }
    }
  }

  for (i = 0; i < len; ++i) {
    id = rawIds[i];

    if (Array.isArray(id)) {
      // handle [ [id0, id2], [id3] ]
      assignRawDocsToIdStructure(id, resultDocs, resultOrder, options, true);
      newOrder.push(id);
      continue;
    }

    if (id === null && sorting === false) {
      // keep nulls for findOne unless sorting, which always
      // removes them (backward compat)
      newOrder.push(id);
      continue;
    }

    sid = String(id);
    doc = resultDocs[sid];
    // If user wants separate copies of same doc, use this option
    if (options.clone && doc != null) {
      if (options.lean) {
        const _model = leanPopulateMap.get(doc);
        doc = clone(doc);
        leanPopulateMap.set(doc, _model);
      } else {
        doc = doc.constructor.hydrate(doc._doc);
      }
    }

    if (recursed) {
      if (doc) {
        if (sorting) {
          const _resultOrder = resultOrder[sid];
          if (options[kHasArray]) {
            // If result arrays, rely on the MongoDB server response for ordering
            newOrder.push(doc);
          } else {
            newOrder[_resultOrder] = doc;
          }
        } else {
          newOrder.push(doc);
        }
      } else if (id != null && id[modelSymbol] != null) {
        newOrder.push(id);
      } else {
        newOrder.push(options.retainNullValues || nullIfNotFound ? null : id);
      }
    } else {
      // apply findOne behavior - if document in results, assign, else assign null
      newOrder[i] = doc || null;
    }
  }

  rawIds.length = 0;
  if (newOrder.length) {
    // reassign the documents based on corrected order

    // forEach skips over sparse entries in arrays so we
    // can safely use this to our advantage dealing with sorted
    // result sets too.
    newOrder.forEach(function(doc, i) {
      rawIds[i] = doc;
    });
  }
}
