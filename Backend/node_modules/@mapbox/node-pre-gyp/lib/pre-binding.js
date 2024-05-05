'use strict';

const npg = require('..');
const versioning = require('../lib/util/versioning.js');
const napi = require('../lib/util/napi.js');
const existsSync = require('fs').existsSync || require('path').existsSync;
const path = require('path');

module.exports = exports;

exports.usage = 'Finds the require path for the node-pre-gyp installed module';

exports.validate = function(package_json, opts) {
  versioning.validate_config(package_json, opts);
};

exports.find = function(package_json_path, opts) {
  if (!existsSync(package_json_path)) {
    throw new Error(package_json_path + 'does not exist');
  }
  const prog = new npg.Run({ package_json_path, argv: process.argv });
  prog.setBinaryHostProperty();
  const package_json = prog.package_json;

  versioning.validate_config(package_json, opts);
  let napi_build_version;
  if (napi.get_napi_build_versions(package_json, opts)) {
    napi_build_version = napi.get_best_napi_build_version(package_json, opts);
  }
  opts = opts || {};
  if (!opts.module_root) opts.module_root = path.dirname(package_json_path);
  const meta = versioning.evaluate(package_json, opts, napi_build_version);
  return meta.module;
};
