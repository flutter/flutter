'use strict';

module.exports = exports = rebuild;

exports.usage = 'Runs "clean" and "build" at once';

const napi = require('./util/napi.js');

function rebuild(gyp, argv, callback) {
  const package_json = gyp.package_json;
  let commands = [
    { name: 'clean', args: [] },
    { name: 'build', args: ['rebuild'] }
  ];
  commands = napi.expand_commands(package_json, gyp.opts, commands);
  for (let i = commands.length; i !== 0; i--) {
    gyp.todo.unshift(commands[i - 1]);
  }
  process.nextTick(callback);
}
