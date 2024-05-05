'use strict';

module.exports = exports;

const url = require('url');
const fs = require('fs');
const path = require('path');

module.exports.detect = function(opts, config) {
  const to = opts.hosted_path;
  const uri = url.parse(to);
  config.prefix = (!uri.pathname || uri.pathname === '/') ? '' : uri.pathname.replace('/', '');
  if (opts.bucket && opts.region) {
    config.bucket = opts.bucket;
    config.region = opts.region;
    config.endpoint = opts.host;
    config.s3ForcePathStyle = opts.s3ForcePathStyle;
  } else {
    const parts = uri.hostname.split('.s3');
    const bucket = parts[0];
    if (!bucket) {
      return;
    }
    if (!config.bucket) {
      config.bucket = bucket;
    }
    if (!config.region) {
      const region = parts[1].slice(1).split('.')[0];
      if (region === 'amazonaws') {
        config.region = 'us-east-1';
      } else {
        config.region = region;
      }
    }
  }
};

module.exports.get_s3 = function(config) {

  if (process.env.node_pre_gyp_mock_s3) {
    // here we're mocking. node_pre_gyp_mock_s3 is the scratch directory
    // for the mock code.
    const AWSMock = require('mock-aws-s3');
    const os = require('os');

    AWSMock.config.basePath = `${os.tmpdir()}/mock`;

    const s3 = AWSMock.S3();

    // wrapped callback maker. fs calls return code of ENOENT but AWS.S3 returns
    // NotFound.
    const wcb = (fn) => (err, ...args) => {
      if (err && err.code === 'ENOENT') {
        err.code = 'NotFound';
      }
      return fn(err, ...args);
    };

    return {
      listObjects(params, callback) {
        return s3.listObjects(params, wcb(callback));
      },
      headObject(params, callback) {
        return s3.headObject(params, wcb(callback));
      },
      deleteObject(params, callback) {
        return s3.deleteObject(params, wcb(callback));
      },
      putObject(params, callback) {
        return s3.putObject(params, wcb(callback));
      }
    };
  }

  // if not mocking then setup real s3.
  const AWS = require('aws-sdk');

  AWS.config.update(config);
  const s3 = new AWS.S3();

  // need to change if additional options need to be specified.
  return {
    listObjects(params, callback) {
      return s3.listObjects(params, callback);
    },
    headObject(params, callback) {
      return s3.headObject(params, callback);
    },
    deleteObject(params, callback) {
      return s3.deleteObject(params, callback);
    },
    putObject(params, callback) {
      return s3.putObject(params, callback);
    }
  };



};

//
// function to get the mocking control function. if not mocking it returns a no-op.
//
// if mocking it sets up the mock http interceptors that use the mocked s3 file system
// to fulfill reponses.
module.exports.get_mockS3Http = function() {
  let mock_s3 = false;
  if (!process.env.node_pre_gyp_mock_s3) {
    return () => mock_s3;
  }

  const nock = require('nock');
  // the bucket used for testing, as addressed by https.
  const host = 'https://mapbox-node-pre-gyp-public-testing-bucket.s3.us-east-1.amazonaws.com';
  const mockDir = process.env.node_pre_gyp_mock_s3 + '/mapbox-node-pre-gyp-public-testing-bucket';

  // function to setup interceptors. they are "turned off" by setting mock_s3 to false.
  const mock_http = () => {
    // eslint-disable-next-line no-unused-vars
    function get(uri, requestBody) {
      const filepath = path.join(mockDir, uri.replace('%2B', '+'));

      try {
        fs.accessSync(filepath, fs.constants.R_OK);
      } catch (e) {
        return [404, 'not found\n'];
      }

      // the mock s3 functions just write to disk, so just read from it.
      return [200, fs.createReadStream(filepath)];
    }

    // eslint-disable-next-line no-unused-vars
    return nock(host)
      .persist()
      .get(() => mock_s3) // mock any uri for s3 when true
      .reply(get);
  };

  // setup interceptors. they check the mock_s3 flag to determine whether to intercept.
  mock_http(nock, host, mockDir);
  // function to turn matching all requests to s3 on/off.
  const mockS3Http = (action) => {
    const previous = mock_s3;
    if (action === 'off') {
      mock_s3 = false;
    } else if (action === 'on') {
      mock_s3 = true;
    } else if (action !== 'get') {
      throw new Error(`illegal action for setMockHttp ${action}`);
    }
    return previous;
  };

  // call mockS3Http with the argument
  // - 'on' - turn it on
  // - 'off' - turn it off (used by fetch.test.js so it doesn't interfere with redirects)
  // - 'get' - return true or false for 'on' or 'off'
  return mockS3Http;
};



