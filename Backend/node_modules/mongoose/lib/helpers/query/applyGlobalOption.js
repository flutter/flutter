'use strict';

const utils = require('../../utils');

function applyGlobalMaxTimeMS(options, connectionOptions, baseOptions) {
  applyGlobalOption(options, connectionOptions, baseOptions, 'maxTimeMS');
}

function applyGlobalDiskUse(options, connectionOptions, baseOptions) {
  applyGlobalOption(options, connectionOptions, baseOptions, 'allowDiskUse');
}

module.exports = {
  applyGlobalMaxTimeMS,
  applyGlobalDiskUse
};


function applyGlobalOption(options, connectionOptions, baseOptions, optionName) {
  if (utils.hasUserDefinedProperty(options, optionName)) {
    return;
  }

  if (utils.hasUserDefinedProperty(connectionOptions, optionName)) {
    options[optionName] = connectionOptions[optionName];
  } else if (utils.hasUserDefinedProperty(baseOptions, optionName)) {
    options[optionName] = baseOptions[optionName];
  }
}
