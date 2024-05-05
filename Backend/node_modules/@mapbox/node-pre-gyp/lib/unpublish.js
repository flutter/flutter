'use strict';

module.exports = exports = unpublish;

exports.usage = 'Unpublishes pre-built binary (requires aws-sdk)';

const log = require('npmlog');
const versioning = require('./util/versioning.js');
const napi = require('./util/napi.js');
const s3_setup = require('./util/s3_setup.js');
const url = require('url');

function unpublish(gyp, argv, callback) {
  const package_json = gyp.package_json;
  const napi_build_version = napi.get_napi_build_version_from_command_args(argv);
  const opts = versioning.evaluate(package_json, gyp.opts, napi_build_version);
  const config = {};
  s3_setup.detect(opts, config);
  const s3 = s3_setup.get_s3(config);
  const key_name = url.resolve(config.prefix, opts.package_name);
  const s3_opts = {
    Bucket: config.bucket,
    Key: key_name
  };
  s3.headObject(s3_opts, (err, meta) => {
    if (err && err.code === 'NotFound') {
      console.log('[' + package_json.name + '] Not found: https://' + s3_opts.Bucket + '.s3.amazonaws.com/' + s3_opts.Key);
      return callback();
    } else if (err) {
      return callback(err);
    } else {
      log.info('unpublish', JSON.stringify(meta));
      s3.deleteObject(s3_opts, (err2, resp) => {
        if (err2) return callback(err2);
        log.info(JSON.stringify(resp));
        console.log('[' + package_json.name + '] Success: removed https://' + s3_opts.Bucket + '.s3.amazonaws.com/' + s3_opts.Key);
        return callback();
      });
    }
  });
}
