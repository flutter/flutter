'use strict';

const castFilterPath = require('../query/castFilterPath');
const cleanPositionalOperators = require('../schema/cleanPositionalOperators');
const getPath = require('../schema/getPath');
const updatedPathsByArrayFilter = require('./updatedPathsByArrayFilter');

module.exports = function castArrayFilters(query) {
  const arrayFilters = query.options.arrayFilters;
  const update = query.getUpdate();
  const schema = query.schema;
  const updatedPathsByFilter = updatedPathsByArrayFilter(update);

  let strictQuery = schema.options.strict;
  if (query._mongooseOptions.strict != null) {
    strictQuery = query._mongooseOptions.strict;
  }
  if (query.model && query.model.base.options.strictQuery != null) {
    strictQuery = query.model.base.options.strictQuery;
  }
  if (schema._userProvidedOptions.strictQuery != null) {
    strictQuery = schema._userProvidedOptions.strictQuery;
  }
  if (query._mongooseOptions.strictQuery != null) {
    strictQuery = query._mongooseOptions.strictQuery;
  }

  _castArrayFilters(arrayFilters, schema, strictQuery, updatedPathsByFilter, query);
};

function _castArrayFilters(arrayFilters, schema, strictQuery, updatedPathsByFilter, query) {
  if (!Array.isArray(arrayFilters)) {
    return;
  }

  for (const filter of arrayFilters) {
    if (filter == null) {
      throw new Error(`Got null array filter in ${arrayFilters}`);
    }
    const keys = Object.keys(filter).filter(key => filter[key] != null);
    if (keys.length === 0) {
      continue;
    }

    const firstKey = keys[0];
    if (firstKey === '$and' || firstKey === '$or') {
      for (const key of keys) {
        _castArrayFilters(filter[key], schema, strictQuery, updatedPathsByFilter, query);
      }
      continue;
    }
    const dot = firstKey.indexOf('.');
    const filterWildcardPath = dot === -1 ? firstKey : firstKey.substring(0, dot);
    if (updatedPathsByFilter[filterWildcardPath] == null) {
      continue;
    }
    const baseFilterPath = cleanPositionalOperators(
      updatedPathsByFilter[filterWildcardPath]
    );

    const baseSchematype = getPath(schema, baseFilterPath);
    let filterBaseSchema = baseSchematype != null ? baseSchematype.schema : null;
    if (filterBaseSchema != null &&
        filterBaseSchema.discriminators != null &&
        filter[filterWildcardPath + '.' + filterBaseSchema.options.discriminatorKey]) {
      filterBaseSchema = filterBaseSchema.discriminators[filter[filterWildcardPath + '.' + filterBaseSchema.options.discriminatorKey]] || filterBaseSchema;
    }

    for (const key of keys) {
      if (updatedPathsByFilter[key] === null) {
        continue;
      }
      if (Object.keys(updatedPathsByFilter).length === 0) {
        continue;
      }
      const dot = key.indexOf('.');

      let filterPathRelativeToBase = dot === -1 ? null : key.substring(dot);
      let schematype;
      if (filterPathRelativeToBase == null || filterBaseSchema == null) {
        schematype = baseSchematype;
      } else {
        // If there are multiple array filters in the path being updated, make sure
        // to replace them so we can get the schema path.
        filterPathRelativeToBase = cleanPositionalOperators(filterPathRelativeToBase);
        schematype = getPath(filterBaseSchema, filterPathRelativeToBase);
      }

      if (schematype == null) {
        if (!strictQuery) {
          return;
        }
        const filterPath = filterPathRelativeToBase == null ?
          baseFilterPath + '.0' :
          baseFilterPath + '.0' + filterPathRelativeToBase;
        // For now, treat `strictQuery = true` and `strictQuery = 'throw'` as
        // equivalent for casting array filters. `strictQuery = true` doesn't
        // quite work in this context because we never want to silently strip out
        // array filters, even if the path isn't in the schema.
        throw new Error(`Could not find path "${filterPath}" in schema`);
      }
      if (typeof filter[key] === 'object') {
        filter[key] = castFilterPath(query, schematype, filter[key]);
      } else {
        filter[key] = schematype.castForQuery(null, filter[key]);
      }
    }
  }
}
