'use strict';

module.exports = exports;

const fs = require('fs');
const path = require('path');
const win = process.platform === 'win32';
const existsSync = fs.existsSync || path.existsSync;
const cp = require('child_process');

// try to build up the complete path to node-gyp
/* priority:
  - node-gyp on ENV:npm_config_node_gyp (https://github.com/npm/npm/pull/4887)
  - node-gyp on NODE_PATH
  - node-gyp inside npm on NODE_PATH (ignore on iojs)
  - node-gyp inside npm beside node exe
*/
function which_node_gyp() {
  let node_gyp_bin;
  if (process.env.npm_config_node_gyp) {
    try {
      node_gyp_bin = process.env.npm_config_node_gyp;
      if (existsSync(node_gyp_bin)) {
        return node_gyp_bin;
      }
    } catch (err) {
      // do nothing
    }
  }
  try {
    const node_gyp_main = require.resolve('node-gyp'); // eslint-disable-line node/no-missing-require
    node_gyp_bin = path.join(path.dirname(
      path.dirname(node_gyp_main)),
    'bin/node-gyp.js');
    if (existsSync(node_gyp_bin)) {
      return node_gyp_bin;
    }
  } catch (err) {
    // do nothing
  }
  if (process.execPath.indexOf('iojs') === -1) {
    try {
      const npm_main = require.resolve('npm'); // eslint-disable-line node/no-missing-require
      node_gyp_bin = path.join(path.dirname(
        path.dirname(npm_main)),
      'node_modules/node-gyp/bin/node-gyp.js');
      if (existsSync(node_gyp_bin)) {
        return node_gyp_bin;
      }
    } catch (err) {
      // do nothing
    }
  }
  const npm_base = path.join(path.dirname(
    path.dirname(process.execPath)),
  'lib/node_modules/npm/');
  node_gyp_bin = path.join(npm_base, 'node_modules/node-gyp/bin/node-gyp.js');
  if (existsSync(node_gyp_bin)) {
    return node_gyp_bin;
  }
}

module.exports.run_gyp = function(args, opts, callback) {
  let shell_cmd = '';
  const cmd_args = [];
  if (opts.runtime && opts.runtime === 'node-webkit') {
    shell_cmd = 'nw-gyp';
    if (win) shell_cmd += '.cmd';
  } else {
    const node_gyp_path = which_node_gyp();
    if (node_gyp_path) {
      shell_cmd = process.execPath;
      cmd_args.push(node_gyp_path);
    } else {
      shell_cmd = 'node-gyp';
      if (win) shell_cmd += '.cmd';
    }
  }
  const final_args = cmd_args.concat(args);
  const cmd = cp.spawn(shell_cmd, final_args, { cwd: undefined, env: process.env, stdio: [0, 1, 2] });
  cmd.on('error', (err) => {
    if (err) {
      return callback(new Error("Failed to execute '" + shell_cmd + ' ' + final_args.join(' ') + "' (" + err + ')'));
    }
    callback(null, opts);
  });
  cmd.on('close', (code) => {
    if (code && code !== 0) {
      return callback(new Error("Failed to execute '" + shell_cmd + ' ' + final_args.join(' ') + "' (" + code + ')'));
    }
    callback(null, opts);
  });
};
