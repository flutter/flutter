'use strict';

module.exports = function merge(s1, s2, skipConflictingPaths) {
  const paths = Object.keys(s2.tree);
  const pathsToAdd = {};
  for (const key of paths) {
    if (skipConflictingPaths && (s1.paths[key] || s1.nested[key] || s1.singleNestedPaths[key])) {
      continue;
    }
    pathsToAdd[key] = s2.tree[key];
  }
  s1.options._isMerging = true;
  s1.add(pathsToAdd, null);
  delete s1.options._isMerging;

  s1.callQueue = s1.callQueue.concat(s2.callQueue);
  s1.method(s2.methods);
  s1.static(s2.statics);

  for (const [option, value] of Object.entries(s2._userProvidedOptions)) {
    if (!(option in s1._userProvidedOptions)) {
      s1.set(option, value);
    }
  }

  for (const query in s2.query) {
    s1.query[query] = s2.query[query];
  }

  for (const virtual in s2.virtuals) {
    s1.virtuals[virtual] = s2.virtuals[virtual].clone();
  }

  s1._indexes = s1._indexes.concat(s2._indexes || []);
  s1.s.hooks.merge(s2.s.hooks, false);
};
