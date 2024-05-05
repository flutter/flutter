'use strict';

module.exports = arrayDepth;

function arrayDepth(arr) {
  if (!Array.isArray(arr)) {
    return { min: 0, max: 0, containsNonArrayItem: true };
  }
  if (arr.length === 0) {
    return { min: 1, max: 1, containsNonArrayItem: false };
  }
  if (arr.length === 1 && !Array.isArray(arr[0])) {
    return { min: 1, max: 1, containsNonArrayItem: false };
  }

  const res = arrayDepth(arr[0]);

  for (let i = 1; i < arr.length; ++i) {
    const _res = arrayDepth(arr[i]);
    if (_res.min < res.min) {
      res.min = _res.min;
    }
    if (_res.max > res.max) {
      res.max = _res.max;
    }
    res.containsNonArrayItem = res.containsNonArrayItem || _res.containsNonArrayItem;
  }

  res.min = res.min + 1;
  res.max = res.max + 1;

  return res;
}
