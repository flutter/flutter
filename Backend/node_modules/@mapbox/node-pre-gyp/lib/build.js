'use strict';

module.exports = exports = build;

exports.usage = 'Attempts to compile the module by dispatching to node-gyp or nw-gyp';

const napi = require('./util/napi.js');
const compile = require('./util/compile.js');
const handle_gyp_opts = require('./util/handle_gyp_opts.js');
const configure = require('./configure.js');

function do_build(gyp, argv, callback) {
  handle_gyp_opts(gyp, argv, (err, result) => {
    let final_args = ['build'].concat(result.gyp).concat(result.pre);
    if (result.unparsed.length > 0) {
      final_args = final_args.
        concat(['--']).
        concat(result.unparsed);
    }
    if (!err && result.opts.napi_build_version) {
      napi.swap_build_dir_in(result.opts.napi_build_version);
    }
    compile.run_gyp(final_args, result.opts, (err2) => {
      if (result.opts.napi_build_version) {
        napi.swap_build_dir_out(result.opts.napi_build_version);
      }
      return callback(err2);
    });
  });
}

function build(gyp, argv, callback) {

  // Form up commands to pass to node-gyp:
  // We map `node-pre-gyp build` to `node-gyp configure build` so that we do not
  // trigger a clean and therefore do not pay the penalty of a full recompile
  if (argv.length && (argv.indexOf('rebuild') > -1)) {
    argv.shift(); // remove `rebuild`
    // here we map `node-pre-gyp rebuild` to `node-gyp rebuild` which internally means
    // "clean + configure + build" and triggers a full recompile
    compile.run_gyp(['clean'], {}, (err3) => {
      if (err3) return callback(err3);
      configure(gyp, argv, (err4) => {
        if (err4) return callback(err4);
        return do_build(gyp, argv, callback);
      });
    });
  } else {
    return do_build(gyp, argv, callback);
  }
}
