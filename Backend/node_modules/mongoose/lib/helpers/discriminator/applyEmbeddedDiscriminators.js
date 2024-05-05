'use strict';

module.exports = applyEmbeddedDiscriminators;

function applyEmbeddedDiscriminators(schema, seen = new WeakSet(), overwriteExisting = false) {
  if (seen.has(schema)) {
    return;
  }
  seen.add(schema);
  for (const path of Object.keys(schema.paths)) {
    const schemaType = schema.paths[path];
    if (!schemaType.schema) {
      continue;
    }
    applyEmbeddedDiscriminators(schemaType.schema, seen);
    if (!schemaType.schema._applyDiscriminators) {
      continue;
    }
    if (schemaType._appliedDiscriminators && !overwriteExisting) {
      continue;
    }
    for (const discriminatorKey of schemaType.schema._applyDiscriminators.keys()) {
      const {
        schema: discriminatorSchema,
        options
      } = schemaType.schema._applyDiscriminators.get(discriminatorKey);
      applyEmbeddedDiscriminators(discriminatorSchema, seen);
      schemaType.discriminator(
        discriminatorKey,
        discriminatorSchema,
        overwriteExisting ? { ...options, overwriteExisting: true } : options
      );
    }
    schemaType._appliedDiscriminators = true;
  }
}
