'use strict';

const clone = require('../helpers/clone');

class SaveOptions {
  constructor(obj) {
    if (obj == null) {
      return;
    }
    Object.assign(this, clone(obj));
  }
}

module.exports = SaveOptions;
