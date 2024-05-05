'use strict';

const get = require('../get');
const getSchemaDiscriminatorByValue = require('../discriminator/getSchemaDiscriminatorByValue');

/**
 * Like `schema.path()`, except with a document, because impossible to
 * determine path type without knowing the embedded discriminator key.
 *
 * @param {Document} doc
 * @param {String|String[]} path
 * @param {Object} [options]
 * @api private
 */

module.exports = function getEmbeddedDiscriminatorPath(doc, path, options) {
  options = options || {};
  const typeOnly = options.typeOnly;
  const parts = Array.isArray(path) ?
    path :
    (path.indexOf('.') === -1 ? [path] : path.split('.'));
  let schemaType = null;
  let type = 'adhocOrUndefined';

  const schema = getSchemaDiscriminatorByValue(doc.schema, doc.get(doc.schema.options.discriminatorKey)) || doc.schema;

  for (let i = 0; i < parts.length; ++i) {
    const subpath = parts.slice(0, i + 1).join('.');
    schemaType = schema.path(subpath);
    if (schemaType == null) {
      type = 'adhocOrUndefined';
      continue;
    }
    if (schemaType.instance === 'Mixed') {
      return typeOnly ? 'real' : schemaType;
    }
    type = schema.pathType(subpath);
    if ((schemaType.$isSingleNested || schemaType.$isMongooseDocumentArrayElement) &&
    schemaType.schema.discriminators != null) {
      const discriminators = schemaType.schema.discriminators;
      const discriminatorKey = doc.get(subpath + '.' +
        get(schemaType, 'schema.options.discriminatorKey'));
      if (discriminatorKey == null || discriminators[discriminatorKey] == null) {
        continue;
      }
      const rest = parts.slice(i + 1).join('.');
      return getEmbeddedDiscriminatorPath(doc.get(subpath), rest, options);
    }
  }

  // Are we getting the whole schema or just the type, 'real', 'nested', etc.
  return typeOnly ? type : schemaType;
};
