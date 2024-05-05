'use strict';

module.exports = function pushNestedArrayPaths(paths, nestedArray, path) {
  if (nestedArray == null) {
    return;
  }

  for (let i = 0; i < nestedArray.length; ++i) {
    if (Array.isArray(nestedArray[i])) {
      pushNestedArrayPaths(paths, nestedArray[i], path + '.' + i);
    } else {
      paths.push(path + '.' + i);
    }
  }
};
