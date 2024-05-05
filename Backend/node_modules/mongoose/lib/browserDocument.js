/*!
 * Module dependencies.
 */

'use strict';

const NodeJSDocument = require('./document');
const EventEmitter = require('events').EventEmitter;
const MongooseError = require('./error/index');
const Schema = require('./schema');
const ObjectId = require('./types/objectid');
const ValidationError = MongooseError.ValidationError;
const applyHooks = require('./helpers/model/applyHooks');
const isObject = require('./helpers/isObject');

/**
 * Document constructor.
 *
 * @param {Object} obj the values to set
 * @param {Object} schema
 * @param {Object} [fields] optional object containing the fields which were selected in the query returning this document and any populated paths data
 * @param {Boolean} [skipId] bool, should we auto create an ObjectId _id
 * @inherits NodeJS EventEmitter https://nodejs.org/api/events.html#class-eventemitter
 * @event `init`: Emitted on a document after it has was retrieved from the db and fully hydrated by Mongoose.
 * @event `save`: Emitted when the document is successfully saved
 * @api private
 */

function Document(obj, schema, fields, skipId, skipInit) {
  if (!(this instanceof Document)) {
    return new Document(obj, schema, fields, skipId, skipInit);
  }

  if (isObject(schema) && !schema.instanceOfSchema) {
    schema = new Schema(schema);
  }

  // When creating EmbeddedDocument, it already has the schema and he doesn't need the _id
  schema = this.schema || schema;

  // Generate ObjectId if it is missing, but it requires a scheme
  if (!this.schema && schema.options._id) {
    obj = obj || {};

    if (obj._id === undefined) {
      obj._id = new ObjectId();
    }
  }

  if (!schema) {
    throw new MongooseError.MissingSchemaError();
  }

  this.$__setSchema(schema);

  NodeJSDocument.call(this, obj, fields, skipId, skipInit);

  applyHooks(this, schema, { decorateDoc: true });

  // apply methods
  for (const m in schema.methods) {
    this[m] = schema.methods[m];
  }
  // apply statics
  for (const s in schema.statics) {
    this[s] = schema.statics[s];
  }
}

/*!
 * Inherit from the NodeJS document
 */

Document.prototype = Object.create(NodeJSDocument.prototype);
Document.prototype.constructor = Document;

/*!
 * ignore
 */

Document.events = new EventEmitter();

/*!
 * Browser doc exposes the event emitter API
 */

Document.$emitter = new EventEmitter();

['on', 'once', 'emit', 'listeners', 'removeListener', 'setMaxListeners',
  'removeAllListeners', 'addListener'].forEach(function(emitterFn) {
  Document[emitterFn] = function() {
    return Document.$emitter[emitterFn].apply(Document.$emitter, arguments);
  };
});

/*!
 * Module exports.
 */

Document.ValidationError = ValidationError;
module.exports = exports = Document;
