'use strict';

module.exports = function prepareDiscriminatorPipeline(pipeline, schema, prefix) {
  const discriminatorMapping = schema && schema.discriminatorMapping;
  prefix = prefix || '';

  if (discriminatorMapping && !discriminatorMapping.isRoot) {
    const originalPipeline = pipeline;
    const filterKey = (prefix.length > 0 ? prefix + '.' : prefix) + discriminatorMapping.key;
    const discriminatorValue = discriminatorMapping.value;

    // If the first pipeline stage is a match and it doesn't specify a `__t`
    // key, add the discriminator key to it. This allows for potential
    // aggregation query optimizations not to be disturbed by this feature.
    if (originalPipeline[0] != null &&
        originalPipeline[0].$match &&
        (originalPipeline[0].$match[filterKey] === undefined || originalPipeline[0].$match[filterKey] === discriminatorValue)) {
      originalPipeline[0].$match[filterKey] = discriminatorValue;
      // `originalPipeline` is a ref, so there's no need for
      // aggregate._pipeline = originalPipeline
    } else if (originalPipeline[0] != null && originalPipeline[0].$geoNear) {
      originalPipeline[0].$geoNear.query =
          originalPipeline[0].$geoNear.query || {};
      originalPipeline[0].$geoNear.query[filterKey] = discriminatorValue;
    } else if (originalPipeline[0] != null && originalPipeline[0].$search) {
      if (originalPipeline[1] && originalPipeline[1].$match != null) {
        originalPipeline[1].$match[filterKey] = originalPipeline[1].$match[filterKey] || discriminatorValue;
      } else {
        const match = {};
        match[filterKey] = discriminatorValue;
        originalPipeline.splice(1, 0, { $match: match });
      }
    } else {
      const match = {};
      match[filterKey] = discriminatorValue;
      originalPipeline.unshift({ $match: match });
    }
  }
};
