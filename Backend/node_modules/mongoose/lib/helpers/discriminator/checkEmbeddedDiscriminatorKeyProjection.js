'use strict';

module.exports = function checkEmbeddedDiscriminatorKeyProjection(userProjection, path, schema, selected, addedPaths) {
  const userProjectedInPath = Object.keys(userProjection).
    reduce((cur, key) => cur || key.startsWith(path + '.'), false);
  const _discriminatorKey = path + '.' + schema.options.discriminatorKey;
  if (!userProjectedInPath &&
      addedPaths.length === 1 &&
      addedPaths[0] === _discriminatorKey) {
    selected.splice(selected.indexOf(_discriminatorKey), 1);
  }
};
