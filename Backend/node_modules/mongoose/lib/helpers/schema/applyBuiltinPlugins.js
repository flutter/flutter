'use strict';

const builtinPlugins = require('../../plugins');

module.exports = function applyBuiltinPlugins(schema) {
  for (const plugin of Object.values(builtinPlugins)) {
    plugin(schema, { deduplicate: true });
  }
  schema.plugins = Object.values(builtinPlugins).
    map(fn => ({ fn, opts: { deduplicate: true } })).
    concat(schema.plugins);
};
