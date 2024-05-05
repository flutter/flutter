'use strict';
function getDefaultBulkwriteResult() {
  return {
    result: {
      ok: 1,
      writeErrors: [],
      writeConcernErrors: [],
      insertedIds: [],
      nInserted: 0,
      nUpserted: 0,
      nMatched: 0,
      nModified: 0,
      nRemoved: 0,
      upserted: []
    },
    insertedCount: 0,
    matchedCount: 0,
    modifiedCount: 0,
    deletedCount: 0,
    upsertedCount: 0,
    upsertedIds: {},
    insertedIds: {},
    n: 0
  };
}

module.exports = getDefaultBulkwriteResult;
