'use strict';

/*!
 * Module dependencies.
 */

require('./driver').set(require('./drivers/node-mongodb-native'));

const mongoose = require('./mongoose');

mongoose.Mongoose.prototype.mongo = require('mongodb');

module.exports = mongoose;
