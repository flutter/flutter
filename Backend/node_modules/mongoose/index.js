/**
 * Export lib/mongoose
 *
 */

'use strict';

const mongoose = require('./lib/');

module.exports = mongoose;
module.exports.default = mongoose;
module.exports.mongoose = mongoose;

// Re-export for ESM support
module.exports.cast = mongoose.cast;
module.exports.STATES = mongoose.STATES;
module.exports.setDriver = mongoose.setDriver;
module.exports.set = mongoose.set;
module.exports.get = mongoose.get;
module.exports.createConnection = mongoose.createConnection;
module.exports.connect = mongoose.connect;
module.exports.disconnect = mongoose.disconnect;
module.exports.startSession = mongoose.startSession;
module.exports.pluralize = mongoose.pluralize;
module.exports.model = mongoose.model;
module.exports.deleteModel = mongoose.deleteModel;
module.exports.modelNames = mongoose.modelNames;
module.exports.plugin = mongoose.plugin;
module.exports.connections = mongoose.connections;
module.exports.version = mongoose.version;
module.exports.Mongoose = mongoose.Mongoose;
module.exports.Schema = mongoose.Schema;
module.exports.SchemaType = mongoose.SchemaType;
module.exports.SchemaTypes = mongoose.SchemaTypes;
module.exports.VirtualType = mongoose.VirtualType;
module.exports.Types = mongoose.Types;
module.exports.Query = mongoose.Query;
module.exports.Model = mongoose.Model;
module.exports.Document = mongoose.Document;
module.exports.ObjectId = mongoose.ObjectId;
module.exports.isValidObjectId = mongoose.isValidObjectId;
module.exports.isObjectIdOrHexString = mongoose.isObjectIdOrHexString;
module.exports.syncIndexes = mongoose.syncIndexes;
module.exports.Decimal128 = mongoose.Decimal128;
module.exports.Mixed = mongoose.Mixed;
module.exports.Date = mongoose.Date;
module.exports.Number = mongoose.Number;
module.exports.Error = mongoose.Error;
module.exports.MongooseError = mongoose.MongooseError;
module.exports.now = mongoose.now;
module.exports.CastError = mongoose.CastError;
module.exports.SchemaTypeOptions = mongoose.SchemaTypeOptions;
module.exports.mongo = mongoose.mongo;
module.exports.mquery = mongoose.mquery;
module.exports.sanitizeFilter = mongoose.sanitizeFilter;
module.exports.trusted = mongoose.trusted;
module.exports.skipMiddlewareFunction = mongoose.skipMiddlewareFunction;
module.exports.overwriteMiddlewareResult = mongoose.overwriteMiddlewareResult;

// The following properties are not exported using ESM because `setDriver()` can mutate these
// module.exports.connection = mongoose.connection;
// module.exports.Collection = mongoose.Collection;
// module.exports.Connection = mongoose.Connection;
