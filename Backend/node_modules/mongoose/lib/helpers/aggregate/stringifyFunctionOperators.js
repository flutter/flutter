'use strict';

module.exports = function stringifyFunctionOperators(pipeline) {
  if (!Array.isArray(pipeline)) {
    return;
  }

  for (const stage of pipeline) {
    if (stage == null) {
      continue;
    }

    const canHaveAccumulator = stage.$group || stage.$bucket || stage.$bucketAuto;
    if (canHaveAccumulator != null) {
      for (const key of Object.keys(canHaveAccumulator)) {
        handleAccumulator(canHaveAccumulator[key]);
      }
    }

    const stageType = Object.keys(stage)[0];
    if (stageType && typeof stage[stageType] === 'object') {
      const stageOptions = stage[stageType];
      for (const key of Object.keys(stageOptions)) {
        if (stageOptions[key] != null &&
            stageOptions[key].$function != null &&
            typeof stageOptions[key].$function.body === 'function') {
          stageOptions[key].$function.body = stageOptions[key].$function.body.toString();
        }
      }
    }

    if (stage.$facet != null) {
      for (const key of Object.keys(stage.$facet)) {
        stringifyFunctionOperators(stage.$facet[key]);
      }
    }
  }
};

function handleAccumulator(operator) {
  if (operator == null || operator.$accumulator == null) {
    return;
  }

  for (const key of ['init', 'accumulate', 'merge', 'finalize']) {
    if (typeof operator.$accumulator[key] === 'function') {
      operator.$accumulator[key] = String(operator.$accumulator[key]);
    }
  }
}
