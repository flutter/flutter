'use strict';

const dotRE = /\./g;
module.exports = function parentPaths(path) {
  if (path.indexOf('.') === -1) {
    return [path];
  }
  const pieces = path.split(dotRE);
  const len = pieces.length;
  const ret = new Array(len);
  let cur = '';
  for (let i = 0; i < len; ++i) {
    cur += (cur.length !== 0) ? '.' + pieces[i] : pieces[i];
    ret[i] = cur;
  }

  return ret;
};
