'use strict';

const getConstructorName = require('../getConstructorName');

module.exports = function allServersUnknown(topologyDescription) {
  if (getConstructorName(topologyDescription) !== 'TopologyDescription') {
    return false;
  }

  const servers = Array.from(topologyDescription.servers.values());
  return servers.length > 0 && servers.every(server => server.type === 'Unknown');
};
