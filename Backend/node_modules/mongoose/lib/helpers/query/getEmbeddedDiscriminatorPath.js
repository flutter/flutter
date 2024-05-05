'use strict';

const cleanPositionalOperators = require('../schema/cleanPositionalOperators');
const get = require('../get');
const getDiscriminatorByValue = require('../discriminator/getDiscriminatorByValue');
const updatedPathsByArrayFilter = require('../update/updatedPathsByArrayFilter');

/**
 * Like `schema.path()`, except with a document, because impossible to
 * determine path type without knowing the embedded discriminator key.
 * @param {Schema} schema
 * @param {Object} [update]
 * @param {Object} [filter]
 * @param {String} path
 * @param {Object} [options]
 * @api private
 */

module.exports = function getEmbeddedDiscriminatorPath(schema, update, filter, path, options) {
  const parts = path.split('.');
  let schematype = null;
  let type = 'adhocOrUndefined';

  filter = filter || {};
  update = update || {};
  const arrayFilters = options != null && Array.isArray(options.arrayFilters) ?
    options.arrayFilters : [];
  const updatedPathsByFilter = updatedPathsByArrayFilter(update);

  for (let i = 0; i < parts.length; ++i) {
    const subpath = cleanPositionalOperators(parts.slice(0, i + 1).join('.'));
    schematype = schema.path(subpath);
    if (schematype == null) {
      continue;
    }

    type = schema.pathType(subpath);
    if ((schematype.$isSingleNested || schematype.$isMongooseDocumentArrayElement) &&
        schematype.schema.discriminators != null) {
      const key = get(schematype, 'schema.options.discriminatorKey');
      const discriminatorValuePath = subpath + '.' + key;
      const discriminatorFilterPath =
        discriminatorValuePath.replace(/\.\d+\./, '.');
      let discriminatorKey = null;

      if (discriminatorValuePath in filter) {
        discriminatorKey = filter[discriminatorValuePath];
      }
      if (discriminatorFilterPath in filter) {
        discriminatorKey = filter[discriminatorFilterPath];
      }

      const wrapperPath = subpath.replace(/\.\d+$/, '');
      if (schematype.$isMongooseDocumentArrayElement &&
          get(filter[wrapperPath], '$elemMatch.' + key) != null) {
        discriminatorKey = filter[wrapperPath].$elemMatch[key];
      }

      if (discriminatorValuePath in update) {
        discriminatorKey = update[discriminatorValuePath];
      }

      for (const filterKey of Object.keys(updatedPathsByFilter)) {
        const schemaKey = updatedPathsByFilter[filterKey] + '.' + key;
        const arrayFilterKey = filterKey + '.' + key;
        if (schemaKey === discriminatorFilterPath) {
          const filter = arrayFilters.find(filter => filter.hasOwnProperty(arrayFilterKey));
          if (filter != null) {
            discriminatorKey = filter[arrayFilterKey];
          }
        }
      }

      if (discriminatorKey == null) {
        continue;
      }

      const discriminator = getDiscriminatorByValue(schematype.caster.discriminators, discriminatorKey);
      const discriminatorSchema = discriminator && discriminator.schema;
      if (discriminatorSchema == null) {
        continue;
      }

      const rest = parts.slice(i + 1).join('.');
      schematype = discriminatorSchema.path(rest);
      if (schematype != null) {
        type = discriminatorSchema._getPathType(rest);
        break;
      }
    }
  }

  return { type: type, schematype: schematype };
};
