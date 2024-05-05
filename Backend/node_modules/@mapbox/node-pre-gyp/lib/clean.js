'use strict';

module.exports = exports = clean;

exports.usage = 'Removes the entire folder containing the compiled .node module';

const rm = require('rimraf');
const exists = require('fs').exists || require('path').exists;
const versioning = require('./util/versioning.js');
const napi = require('./util/napi.js');
const path = require('path');

function clean(gyp, argv, callback) {
  const package_json = gyp.package_json;
  const napi_build_version = napi.get_napi_build_version_from_command_args(argv);
  const opts = versioning.evaluate(package_json, gyp.opts, napi_build_version);
  const to_delete = opts.module_path;
  if (!to_delete) {
    return callback(new Error('module_path is empty, refusing to delete'));
  } else if (path.normalize(to_delete) === path.normalize(process.cwd())) {
    return callback(new Error('module_path is not set, refusing to delete'));
  } else {
    exists(to_delete, (found) => {
      if (found) {
        if (!gyp.opts.silent_clean) console.log('[' + package_json.name + '] Removing "%s"', to_delete);
        return rm(to_delete, callback);
      }
      return callback();
    });
  }
}
