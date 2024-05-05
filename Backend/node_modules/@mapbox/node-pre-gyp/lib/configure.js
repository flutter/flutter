'use strict';

module.exports = exports = configure;

exports.usage = 'Attempts to configure node-gyp or nw-gyp build';

const napi = require('./util/napi.js');
const compile = require('./util/compile.js');
const handle_gyp_opts = require('./util/handle_gyp_opts.js');

function configure(gyp, argv, callback) {
  handle_gyp_opts(gyp, argv, (err, result) => {
    let final_args = result.gyp.concat(result.pre);
    // pull select node-gyp configure options out of the npm environ
    const known_gyp_args = ['dist-url', 'python', 'nodedir', 'msvs_version'];
    known_gyp_args.forEach((key) => {
      const val = gyp.opts[key] || gyp.opts[key.replace('-', '_')];
      if (val) {
        final_args.push('--' + key + '=' + val);
      }
    });
    // --ensure=false tell node-gyp to re-install node development headers
    // but it is only respected by node-gyp install, so we have to call install
    // as a separate step if the user passes it
    if (gyp.opts.ensure === false) {
      const install_args = final_args.concat(['install', '--ensure=false']);
      compile.run_gyp(install_args, result.opts, (err2) => {
        if (err2) return callback(err2);
        if (result.unparsed.length > 0) {
          final_args = final_args.
            concat(['--']).
            concat(result.unparsed);
        }
        compile.run_gyp(['configure'].concat(final_args), result.opts, (err3) => {
          return callback(err3);
        });
      });
    } else {
      if (result.unparsed.length > 0) {
        final_args = final_args.
          concat(['--']).
          concat(result.unparsed);
      }
      compile.run_gyp(['configure'].concat(final_args), result.opts, (err4) => {
        if (!err4 && result.opts.napi_build_version) {
          napi.swap_build_dir_out(result.opts.napi_build_version);
        }
        return callback(err4);
      });
    }
  });
}
