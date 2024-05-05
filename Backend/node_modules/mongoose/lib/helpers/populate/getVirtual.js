'use strict';

module.exports = getVirtual;

/*!
 * ignore
 */

function getVirtual(schema, name) {
  if (schema.virtuals[name]) {
    return { virtual: schema.virtuals[name], path: void 0 };
  }

  const parts = name.split('.');
  let cur = '';
  let nestedSchemaPath = '';
  for (let i = 0; i < parts.length; ++i) {
    cur += (cur.length > 0 ? '.' : '') + parts[i];
    if (schema.virtuals[cur]) {
      if (i === parts.length - 1) {
        return { virtual: schema.virtuals[cur], path: nestedSchemaPath };
      }
      continue;
    }

    if (schema.nested[cur]) {
      continue;
    }

    if (schema.paths[cur] && schema.paths[cur].schema) {
      schema = schema.paths[cur].schema;
      const rest = parts.slice(i + 1).join('.');

      if (schema.virtuals[rest]) {
        if (i === parts.length - 2) {
          return {
            virtual: schema.virtuals[rest],
            nestedSchemaPath: [nestedSchemaPath, cur].filter(v => !!v).join('.')
          };
        }
        continue;
      }

      if (i + 1 < parts.length && schema.discriminators) {
        for (const key of Object.keys(schema.discriminators)) {
          const res = getVirtual(schema.discriminators[key], rest);
          if (res != null) {
            const _path = [nestedSchemaPath, cur, res.nestedSchemaPath].
              filter(v => !!v).join('.');
            return {
              virtual: res.virtual,
              nestedSchemaPath: _path
            };
          }
        }
      }

      nestedSchemaPath += (nestedSchemaPath.length > 0 ? '.' : '') + cur;
      cur = '';
      continue;
    }

    if (schema.discriminators) {
      for (const discriminatorKey of Object.keys(schema.discriminators)) {
        const virtualFromDiscriminator = getVirtual(schema.discriminators[discriminatorKey], name);
        if (virtualFromDiscriminator) return virtualFromDiscriminator;
      }
    }

    return null;
  }
}
