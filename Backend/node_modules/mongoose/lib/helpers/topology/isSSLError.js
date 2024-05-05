'use strict';

const getConstructorName = require('../getConstructorName');

const nonSSLMessage = 'Client network socket disconnected before secure TLS ' +
  'connection was established';

module.exports = function isSSLError(topologyDescription) {
  if (getConstructorName(topologyDescription) !== 'TopologyDescription') {
    return false;
  }

  const descriptions = Array.from(topologyDescription.servers.values());
  return descriptions.length > 0 &&
    descriptions.every(descr => descr.error && descr.error.message.indexOf(nonSSLMessage) !== -1);
};
