'use strict';

/*!
 * ignore
 */

const get = require('../get');

module.exports = applyTimestampsToUpdate;

/*!
 * ignore
 */

function applyTimestampsToUpdate(now, createdAt, updatedAt, currentUpdate, options, isReplace) {
  const updates = currentUpdate;
  let _updates = updates;
  const timestamps = get(options, 'timestamps', true);

  // Support skipping timestamps at the query level, see gh-6980
  if (!timestamps || updates == null) {
    return currentUpdate;
  }

  const skipCreatedAt = timestamps != null && timestamps.createdAt === false;
  const skipUpdatedAt = timestamps != null && timestamps.updatedAt === false;

  if (isReplace) {
    if (currentUpdate && currentUpdate.$set) {
      currentUpdate = currentUpdate.$set;
      updates.$set = {};
      _updates = updates.$set;
    }
    if (!skipUpdatedAt && updatedAt && !currentUpdate[updatedAt]) {
      _updates[updatedAt] = now;
    }
    if (!skipCreatedAt && createdAt && !currentUpdate[createdAt]) {
      _updates[createdAt] = now;
    }
    return updates;
  }
  currentUpdate = currentUpdate || {};

  if (Array.isArray(updates)) {
    // Update with aggregation pipeline
    if (updatedAt == null) {
      return updates;
    }
    updates.push({ $set: { [updatedAt]: now } });
    return updates;
  }
  updates.$set = updates.$set || {};
  if (!skipUpdatedAt && updatedAt &&
      (!currentUpdate.$currentDate || !currentUpdate.$currentDate[updatedAt])) {
    let timestampSet = false;
    if (updatedAt.indexOf('.') !== -1) {
      const pieces = updatedAt.split('.');
      for (let i = 1; i < pieces.length; ++i) {
        const remnant = pieces.slice(-i).join('.');
        const start = pieces.slice(0, -i).join('.');
        if (currentUpdate[start] != null) {
          currentUpdate[start][remnant] = now;
          timestampSet = true;
          break;
        } else if (currentUpdate.$set && currentUpdate.$set[start]) {
          currentUpdate.$set[start][remnant] = now;
          timestampSet = true;
          break;
        }
      }
    }

    if (!timestampSet) {
      updates.$set[updatedAt] = now;
    }

    if (updates.hasOwnProperty(updatedAt)) {
      delete updates[updatedAt];
    }
  }

  if (!skipCreatedAt && createdAt) {
    if (currentUpdate[createdAt]) {
      delete currentUpdate[createdAt];
    }
    if (currentUpdate.$set && currentUpdate.$set[createdAt]) {
      delete currentUpdate.$set[createdAt];
    }
    let timestampSet = false;
    if (createdAt.indexOf('.') !== -1) {
      const pieces = createdAt.split('.');
      for (let i = 1; i < pieces.length; ++i) {
        const remnant = pieces.slice(-i).join('.');
        const start = pieces.slice(0, -i).join('.');
        if (currentUpdate[start] != null) {
          currentUpdate[start][remnant] = now;
          timestampSet = true;
          break;
        } else if (currentUpdate.$set && currentUpdate.$set[start]) {
          currentUpdate.$set[start][remnant] = now;
          timestampSet = true;
          break;
        }
      }
    }

    if (!timestampSet) {
      updates.$setOnInsert = updates.$setOnInsert || {};
      updates.$setOnInsert[createdAt] = now;
    }
  }

  if (Object.keys(updates.$set).length === 0) {
    delete updates.$set;
  }
  return updates;
}
