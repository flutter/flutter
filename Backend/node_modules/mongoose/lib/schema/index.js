
/*!
 * Module exports.
 */

'use strict';

exports.Array = require('./array');
exports.BigInt = require('./bigint');
exports.Boolean = require('./boolean');
exports.Buffer = require('./buffer');
exports.Date = require('./date');
exports.Decimal128 = exports.Decimal = require('./decimal128');
exports.DocumentArray = require('./documentArray');
exports.Map = require('./map');
exports.Mixed = require('./mixed');
exports.Number = require('./number');
exports.ObjectId = require('./objectId');
exports.String = require('./string');
exports.Subdocument = require('./subdocument');
exports.UUID = require('./uuid');

// alias

exports.Oid = exports.ObjectId;
exports.Object = exports.Mixed;
exports.Bool = exports.Boolean;
exports.ObjectID = exports.ObjectId;
