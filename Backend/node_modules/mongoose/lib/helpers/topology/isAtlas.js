'use strict';

const getConstructorName = require('../getConstructorName');

/**
 * @typedef { import('mongodb').TopologyDescription } TopologyDescription
 */

/**
 * Checks if topologyDescription contains servers connected to an atlas instance
 *
 * @param  {TopologyDescription} topologyDescription
 * @returns {boolean}
 */
module.exports = function isAtlas(topologyDescription) {
  if (getConstructorName(topologyDescription) !== 'TopologyDescription') {
    return false;
  }

  if (topologyDescription.servers.size === 0) {
    return false;
  }

  for (const server of topologyDescription.servers.values()) {
    if (server.host.endsWith('.mongodb.net') === false || server.port !== 27017) {
      return false;
    }
  }

  return true;
};
