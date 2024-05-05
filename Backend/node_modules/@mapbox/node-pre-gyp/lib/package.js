'use strict';

module.exports = exports = _package;

exports.usage = 'Packs binary (and enclosing directory) into locally staged tarball';

const fs = require('fs');
const path = require('path');
const log = require('npmlog');
const versioning = require('./util/versioning.js');
const napi = require('./util/napi.js');
const existsAsync = fs.exists || path.exists;
const makeDir = require('make-dir');
const tar = require('tar');

function readdirSync(dir) {
  let list = [];
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    const stats = fs.lstatSync(path.join(dir, file));
    if (stats.isDirectory()) {
      list = list.concat(readdirSync(path.join(dir, file)));
    } else {
      list.push(path.join(dir, file));
    }
  });
  return list;
}

function _package(gyp, argv, callback) {
  const package_json = gyp.package_json;
  const napi_build_version = napi.get_napi_build_version_from_command_args(argv);
  const opts = versioning.evaluate(package_json, gyp.opts, napi_build_version);
  const from = opts.module_path;
  const binary_module = path.join(from, opts.module_name + '.node');
  existsAsync(binary_module, (found) => {
    if (!found) {
      return callback(new Error('Cannot package because ' + binary_module + ' missing: run `node-pre-gyp rebuild` first'));
    }
    const tarball = opts.staged_tarball;
    const filter_func = function(entry) {
      const basename = path.basename(entry);
      if (basename.length && basename[0] !== '.') {
        console.log('packing ' + entry);
        return true;
      } else {
        console.log('skipping ' + entry);
      }
      return false;
    };
    makeDir(path.dirname(tarball)).then(() => {
      let files = readdirSync(from);
      const base = path.basename(from);
      files = files.map((file) => {
        return path.join(base, path.relative(from, file));
      });
      tar.create({
        portable: false,
        gzip: true,
        filter: filter_func,
        file: tarball,
        cwd: path.dirname(from)
      }, files, (err2) => {
        if (err2)  console.error('[' + package_json.name + '] ' + err2.message);
        else log.info('package', 'Binary staged at "' + tarball + '"');
        return callback(err2);
      });
    }).catch((err) => {
      return callback(err);
    });
  });
}
