'use strict';

module.exports = function applyPlugins(schema, plugins, options, cacheKey) {
  if (schema[cacheKey]) {
    return;
  }
  schema[cacheKey] = true;

  if (!options || !options.skipTopLevel) {
    let pluginTags = null;
    for (const plugin of plugins) {
      const tags = plugin[1] == null ? null : plugin[1].tags;
      if (!Array.isArray(tags)) {
        schema.plugin(plugin[0], plugin[1]);
        continue;
      }

      pluginTags = pluginTags || new Set(schema.options.pluginTags || []);
      if (!tags.find(tag => pluginTags.has(tag))) {
        continue;
      }
      schema.plugin(plugin[0], plugin[1]);
    }
  }

  options = Object.assign({}, options);
  delete options.skipTopLevel;

  if (options.applyPluginsToChildSchemas !== false) {
    for (const path of Object.keys(schema.paths)) {
      const type = schema.paths[path];
      if (type.schema != null) {
        applyPlugins(type.schema, plugins, options, cacheKey);

        // Recompile schema because plugins may have changed it, see gh-7572
        type.caster.prototype.$__setSchema(type.schema);
      }
    }
  }

  const discriminators = schema.discriminators;
  if (discriminators == null) {
    return;
  }

  const applyPluginsToDiscriminators = options.applyPluginsToDiscriminators;

  const keys = Object.keys(discriminators);
  for (const discriminatorKey of keys) {
    const discriminatorSchema = discriminators[discriminatorKey];

    applyPlugins(discriminatorSchema, plugins,
      { skipTopLevel: !applyPluginsToDiscriminators }, cacheKey);
  }
};
