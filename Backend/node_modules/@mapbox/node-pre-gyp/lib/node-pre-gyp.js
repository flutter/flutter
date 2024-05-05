'use strict';

/**
 * Module exports.
 */

module.exports = exports;

/**
 * Module dependencies.
 */

// load mocking control function for accessing s3 via https. the function is a noop always returning
// false if not mocking.
exports.mockS3Http = require('./util/s3_setup').get_mockS3Http();
exports.mockS3Http('on');
const mocking = exports.mockS3Http('get');


const fs = require('fs');
const path = require('path');
const nopt = require('nopt');
const log = require('npmlog');
log.disableProgress();
const napi = require('./util/napi.js');

const EE = require('events').EventEmitter;
const inherits = require('util').inherits;
const cli_commands = [
  'clean',
  'install',
  'reinstall',
  'build',
  'rebuild',
  'package',
  'testpackage',
  'publish',
  'unpublish',
  'info',
  'testbinary',
  'reveal',
  'configure'
];
const aliases = {};

// differentiate node-pre-gyp's logs from npm's
log.heading = 'node-pre-gyp';

if (mocking) {
  log.warn(`mocking s3 to ${process.env.node_pre_gyp_mock_s3}`);
}

// this is a getter to avoid circular reference warnings with node v14.
Object.defineProperty(exports, 'find', {
  get: function() {
    return require('./pre-binding').find;
  },
  enumerable: true
});

// in the following, "my_module" is using node-pre-gyp to
// prebuild and install pre-built binaries. "main_module"
// is using "my_module".
//
// "bin/node-pre-gyp" invokes Run() without a path. the
// expectation is that the working directory is the package
// root "my_module". this is true because in all cases npm is
// executing a script in the context of "my_module".
//
// "pre-binding.find()" is executed by "my_module" but in the
// context of "main_module". this is because "main_module" is
// executing and requires "my_module" which is then executing
// "pre-binding.find()" via "node-pre-gyp.find()", so the working
// directory is that of "main_module".
//
// that's why "find()" must pass the path to package.json.
//
function Run({ package_json_path = './package.json', argv }) {
  this.package_json_path = package_json_path;
  this.commands = {};

  const self = this;
  cli_commands.forEach((command) => {
    self.commands[command] = function(argvx, callback) {
      log.verbose('command', command, argvx);
      return require('./' + command)(self, argvx, callback);
    };
  });

  this.parseArgv(argv);

  // this is set to true after the binary.host property was set to
  // either staging_host or production_host.
  this.binaryHostSet = false;
}
inherits(Run, EE);
exports.Run = Run;
const proto = Run.prototype;

/**
 * Export the contents of the package.json.
 */

proto.package = require('../package.json');

/**
 * nopt configuration definitions
 */

proto.configDefs = {
  help: Boolean,     // everywhere
  arch: String,      // 'configure'
  debug: Boolean,    // 'build'
  directory: String, // bin
  proxy: String,     // 'install'
  loglevel: String  // everywhere
};

/**
 * nopt shorthands
 */

proto.shorthands = {
  release: '--no-debug',
  C: '--directory',
  debug: '--debug',
  j: '--jobs',
  silent: '--loglevel=silent',
  silly: '--loglevel=silly',
  verbose: '--loglevel=verbose'
};

/**
 * expose the command aliases for the bin file to use.
 */

proto.aliases = aliases;

/**
 * Parses the given argv array and sets the 'opts', 'argv',
 * 'command', and 'package_json' properties.
 */

proto.parseArgv = function parseOpts(argv) {
  this.opts = nopt(this.configDefs, this.shorthands, argv);
  this.argv = this.opts.argv.remain.slice();
  const commands = this.todo = [];

  // create a copy of the argv array with aliases mapped
  argv = this.argv.map((arg) => {
    // is this an alias?
    if (arg in this.aliases) {
      arg = this.aliases[arg];
    }
    return arg;
  });

  // process the mapped args into "command" objects ("name" and "args" props)
  argv.slice().forEach((arg) => {
    if (arg in this.commands) {
      const args = argv.splice(0, argv.indexOf(arg));
      argv.shift();
      if (commands.length > 0) {
        commands[commands.length - 1].args = args;
      }
      commands.push({ name: arg, args: [] });
    }
  });
  if (commands.length > 0) {
    commands[commands.length - 1].args = argv.splice(0);
  }


  // if a directory was specified package.json is assumed to be relative
  // to it.
  let package_json_path = this.package_json_path;
  if (this.opts.directory) {
    package_json_path = path.join(this.opts.directory, package_json_path);
  }

  this.package_json = JSON.parse(fs.readFileSync(package_json_path));

  // expand commands entries for multiple napi builds
  this.todo = napi.expand_commands(this.package_json, this.opts, commands);

  // support for inheriting config env variables from npm
  const npm_config_prefix = 'npm_config_';
  Object.keys(process.env).forEach((name) => {
    if (name.indexOf(npm_config_prefix) !== 0) return;
    const val = process.env[name];
    if (name === npm_config_prefix + 'loglevel') {
      log.level = val;
    } else {
      // add the user-defined options to the config
      name = name.substring(npm_config_prefix.length);
      // avoid npm argv clobber already present args
      // which avoids problem of 'npm test' calling
      // script that runs unique npm install commands
      if (name === 'argv') {
        if (this.opts.argv &&
             this.opts.argv.remain &&
             this.opts.argv.remain.length) {
          // do nothing
        } else {
          this.opts[name] = val;
        }
      } else {
        this.opts[name] = val;
      }
    }
  });

  if (this.opts.loglevel) {
    log.level = this.opts.loglevel;
  }
  log.resume();
};

/**
 * allow the binary.host property to be set at execution time.
 *
 * for this to take effect requires all the following to be true.
 * - binary is a property in package.json
 * - binary.host is falsey
 * - binary.staging_host is not empty
 * - binary.production_host is not empty
 *
 * if any of the previous checks fail then the function returns an empty string
 * and makes no changes to package.json's binary property.
 *
 *
 * if command is "publish" then the default is set to "binary.staging_host"
 * if command is not "publish" the the default is set to "binary.production_host"
 *
 * if the command-line option '--s3_host' is set to "staging" or "production" then
 * "binary.host" is set to the specified "staging_host" or "production_host". if
 * '--s3_host' is any other value an exception is thrown.
 *
 * if '--s3_host' is not present then "binary.host" is set to the default as above.
 *
 * this strategy was chosen so that any command other than "publish" or "unpublish" uses "production"
 * as the default without requiring any command-line options but that "publish" and "unpublish" require
 * '--s3_host production_host' to be specified in order to *really* publish (or unpublish). publishing
 * to staging can be done freely without worrying about disturbing any production releases.
 */
proto.setBinaryHostProperty = function(command) {
  if (this.binaryHostSet) {
    return this.package_json.binary.host;
  }
  const p = this.package_json;
  // don't set anything if host is present. it must be left blank to trigger this.
  if (!p || !p.binary || p.binary.host) {
    return '';
  }
  // and both staging and production must be present. errors will be reported later.
  if (!p.binary.staging_host || !p.binary.production_host) {
    return '';
  }
  let target = 'production_host';
  if (command === 'publish' || command === 'unpublish') {
    target = 'staging_host';
  }
  // the environment variable has priority over the default or the command line. if
  // either the env var or the command line option are invalid throw an error.
  const npg_s3_host = process.env.node_pre_gyp_s3_host;
  if (npg_s3_host === 'staging' || npg_s3_host === 'production') {
    target = `${npg_s3_host}_host`;
  } else if (this.opts['s3_host'] === 'staging' || this.opts['s3_host'] === 'production') {
    target = `${this.opts['s3_host']}_host`;
  } else if (this.opts['s3_host'] || npg_s3_host) {
    throw new Error(`invalid s3_host ${this.opts['s3_host'] || npg_s3_host}`);
  }

  p.binary.host = p.binary[target];
  this.binaryHostSet = true;

  return p.binary.host;
};

/**
 * Returns the usage instructions for node-pre-gyp.
 */

proto.usage = function usage() {
  const str = [
    '',
    '  Usage: node-pre-gyp <command> [options]',
    '',
    '  where <command> is one of:',
    cli_commands.map((c) => {
      return '    - ' + c + ' - ' + require('./' + c).usage;
    }).join('\n'),
    '',
    'node-pre-gyp@' + this.version + '  ' + path.resolve(__dirname, '..'),
    'node@' + process.versions.node
  ].join('\n');
  return str;
};

/**
 * Version number getter.
 */

Object.defineProperty(proto, 'version', {
  get: function() {
    return this.package.version;
  },
  enumerable: true
});
