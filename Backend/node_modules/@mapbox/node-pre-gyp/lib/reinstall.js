'use strict';

module.exports = exports = rebuild;

exports.usage = 'Runs "clean" and "install" at once';

const napi = require('./util/napi.js');

function rebuild(gyp, argv, callback) {
  const package_json = gyp.package_json;
  let installArgs = [];
  const napi_build_version = napi.get_best_napi_build_version(package_json, gyp.opts);
  if (napi_build_version != null) installArgs = [napi.get_command_arg(napi_build_version)];
  gyp.todo.unshift(
    { name: 'clean', args: [] },
    { name: 'install', args: installArgs }
  );
  process.nextTick(callback);
}
