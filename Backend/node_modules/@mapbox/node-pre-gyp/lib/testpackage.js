'use strict';

module.exports = exports = testpackage;

exports.usage = 'Tests that the staged package is valid';

const fs = require('fs');
const path = require('path');
const log = require('npmlog');
const existsAsync = fs.exists || path.exists;
const versioning = require('./util/versioning.js');
const napi = require('./util/napi.js');
const testbinary = require('./testbinary.js');
const tar = require('tar');
const makeDir = require('make-dir');

function testpackage(gyp, argv, callback) {
  const package_json = gyp.package_json;
  const napi_build_version = napi.get_napi_build_version_from_command_args(argv);
  const opts = versioning.evaluate(package_json, gyp.opts, napi_build_version);
  const tarball = opts.staged_tarball;
  existsAsync(tarball, (found) => {
    if (!found) {
      return callback(new Error('Cannot test package because ' + tarball + ' missing: run `node-pre-gyp package` first'));
    }
    const to = opts.module_path;
    function filter_func(entry) {
      log.info('install', 'unpacking [' + entry.path + ']');
    }

    makeDir(to).then(() => {
      tar.extract({
        file: tarball,
        cwd: to,
        strip: 1,
        onentry: filter_func
      }).then(after_extract, callback);
    }).catch((err) => {
      return callback(err);
    });

    function after_extract() {
      testbinary(gyp, argv, (err) => {
        if (err) {
          return callback(err);
        } else {
          console.log('[' + package_json.name + '] Package appears valid');
          return callback();
        }
      });
    }
  });
}
