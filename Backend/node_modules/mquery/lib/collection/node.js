'use strict';

/**
 * Module dependencies
 */

const Collection = require('./collection');

class NodeCollection extends Collection {
  constructor(col) {
    super();

    this.collection = col;
    this.collectionName = col.collectionName;
  }

  /**
   * find(match, options)
   */
  async find(match, options) {
    const cursor = this.collection.find(match, options);

    return cursor.toArray();
  }

  /**
   * findOne(match, options)
   */
  async findOne(match, options) {
    return this.collection.findOne(match, options);
  }

  /**
   * count(match, options)
   */
  async count(match, options) {
    return this.collection.count(match, options);
  }

  /**
   * distinct(prop, match, options)
   */
  async distinct(prop, match, options) {
    return this.collection.distinct(prop, match, options);
  }

  /**
   * updateMany(match, update, options)
   */
  async updateMany(match, update, options) {
    return this.collection.updateMany(match, update, options);
  }

  /**
   * updateOne(match, update, options)
   */
  async updateOne(match, update, options) {
    return this.collection.updateOne(match, update, options);
  }

  /**
   * replaceOne(match, update, options)
   */
  async replaceOne(match, update, options) {
    return this.collection.replaceOne(match, update, options);
  }

  /**
   * deleteOne(match, options)
   */
  async deleteOne(match, options) {
    return this.collection.deleteOne(match, options);
  }

  /**
   * deleteMany(match, options)
   */
  async deleteMany(match, options) {
    return this.collection.deleteMany(match, options);
  }

  /**
   * findOneAndDelete(match, options, function(err[, result])
   */
  async findOneAndDelete(match, options) {
    return this.collection.findOneAndDelete(match, options);
  }

  /**
   * findOneAndUpdate(match, update, options)
   */
  async findOneAndUpdate(match, update, options) {
    return this.collection.findOneAndUpdate(match, update, options);
  }

  /**
   * var cursor = findCursor(match, options)
   */
  findCursor(match, options) {
    return this.collection.find(match, options);
  }

  /**
   * aggregation(operators...)
   * TODO
   */
}


/**
 * Expose
 */

module.exports = exports = NodeCollection;
