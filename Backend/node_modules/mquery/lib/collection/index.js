'use strict';

const env = require('../env');

if ('unknown' == env.type) {
  throw new Error('Unknown environment');
}

module.exports =
  env.isNode ? require('./node') :
    env.isMongo ? require('./collection') :
      require('./collection');

