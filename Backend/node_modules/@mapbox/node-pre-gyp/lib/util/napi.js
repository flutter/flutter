'use strict';

const fs = require('fs');

module.exports = exports;

const versionArray = process.version
  .substr(1)
  .replace(/-.*$/, '')
  .split('.')
  .map((item) => {
    return +item;
  });

const napi_multiple_commands = [
  'build',
  'clean',
  'configure',
  'package',
  'publish',
  'reveal',
  'testbinary',
  'testpackage',
  'unpublish'
];

const napi_build_version_tag = 'napi_build_version=';

module.exports.get_napi_version = function() {
  // returns the non-zero numeric napi version or undefined if napi is not supported.
  // correctly supporting target requires an updated cross-walk
  let version = process.versions.napi; // can be undefined
  if (!version) { // this code should never need to be updated
    if (versionArray[0] === 9 && versionArray[1] >= 3) version = 2; // 9.3.0+
    else if (versionArray[0] === 8) version = 1; // 8.0.0+
  }
  return version;
};

module.exports.get_napi_version_as_string = function(target) {
  // returns the napi version as a string or an empty string if napi is not supported.
  const version = module.exports.get_napi_version(target);
  return version ? '' + version : '';
};

module.exports.validate_package_json = function(package_json, opts) { // throws Error

  const binary = package_json.binary;
  const module_path_ok = pathOK(binary.module_path);
  const remote_path_ok = pathOK(binary.remote_path);
  const package_name_ok = pathOK(binary.package_name);
  const napi_build_versions = module.exports.get_napi_build_versions(package_json, opts, true);
  const napi_build_versions_raw = module.exports.get_napi_build_versions_raw(package_json);

  if (napi_build_versions) {
    napi_build_versions.forEach((napi_build_version)=> {
      if (!(parseInt(napi_build_version, 10) === napi_build_version && napi_build_version > 0)) {
        throw new Error('All values specified in napi_versions must be positive integers.');
      }
    });
  }

  if (napi_build_versions && (!module_path_ok || (!remote_path_ok && !package_name_ok))) {
    throw new Error('When napi_versions is specified; module_path and either remote_path or ' +
			"package_name must contain the substitution string '{napi_build_version}`.");
  }

  if ((module_path_ok || remote_path_ok || package_name_ok) && !napi_build_versions_raw) {
    throw new Error("When the substitution string '{napi_build_version}` is specified in " +
			'module_path, remote_path, or package_name; napi_versions must also be specified.');
  }

  if (napi_build_versions && !module.exports.get_best_napi_build_version(package_json, opts) &&
	module.exports.build_napi_only(package_json)) {
    throw new Error(
      'The Node-API version of this Node instance is ' + module.exports.get_napi_version(opts ? opts.target : undefined) + '. ' +
			'This module supports Node-API version(s) ' + module.exports.get_napi_build_versions_raw(package_json) + '. ' +
			'This Node instance cannot run this module.');
  }

  if (napi_build_versions_raw && !napi_build_versions && module.exports.build_napi_only(package_json)) {
    throw new Error(
      'The Node-API version of this Node instance is ' + module.exports.get_napi_version(opts ? opts.target : undefined) + '. ' +
			'This module supports Node-API version(s) ' + module.exports.get_napi_build_versions_raw(package_json) + '. ' +
			'This Node instance cannot run this module.');
  }

};

function pathOK(path) {
  return path && (path.indexOf('{napi_build_version}') !== -1 || path.indexOf('{node_napi_label}') !== -1);
}

module.exports.expand_commands = function(package_json, opts, commands) {
  const expanded_commands = [];
  const napi_build_versions = module.exports.get_napi_build_versions(package_json, opts);
  commands.forEach((command)=> {
    if (napi_build_versions && command.name === 'install') {
      const napi_build_version = module.exports.get_best_napi_build_version(package_json, opts);
      const args = napi_build_version ? [napi_build_version_tag + napi_build_version] : [];
      expanded_commands.push({ name: command.name, args: args });
    } else if (napi_build_versions && napi_multiple_commands.indexOf(command.name) !== -1) {
      napi_build_versions.forEach((napi_build_version)=> {
        const args = command.args.slice();
        args.push(napi_build_version_tag + napi_build_version);
        expanded_commands.push({ name: command.name, args: args });
      });
    } else {
      expanded_commands.push(command);
    }
  });
  return expanded_commands;
};

module.exports.get_napi_build_versions = function(package_json, opts, warnings) { // opts may be undefined
  const log = require('npmlog');
  let napi_build_versions = [];
  const supported_napi_version = module.exports.get_napi_version(opts ? opts.target : undefined);
  // remove duplicates, verify each napi version can actaully be built
  if (package_json.binary && package_json.binary.napi_versions) {
    package_json.binary.napi_versions.forEach((napi_version) => {
      const duplicated = napi_build_versions.indexOf(napi_version) !== -1;
      if (!duplicated && supported_napi_version && napi_version <= supported_napi_version) {
        napi_build_versions.push(napi_version);
      } else if (warnings && !duplicated && supported_napi_version) {
        log.info('This Node instance does not support builds for Node-API version', napi_version);
      }
    });
  }
  if (opts && opts['build-latest-napi-version-only']) {
    let latest_version = 0;
    napi_build_versions.forEach((napi_version) => {
      if (napi_version > latest_version) latest_version = napi_version;
    });
    napi_build_versions = latest_version ? [latest_version] : [];
  }
  return napi_build_versions.length ? napi_build_versions : undefined;
};

module.exports.get_napi_build_versions_raw = function(package_json) {
  const napi_build_versions = [];
  // remove duplicates
  if (package_json.binary && package_json.binary.napi_versions) {
    package_json.binary.napi_versions.forEach((napi_version) => {
      if (napi_build_versions.indexOf(napi_version) === -1) {
        napi_build_versions.push(napi_version);
      }
    });
  }
  return napi_build_versions.length ? napi_build_versions : undefined;
};

module.exports.get_command_arg = function(napi_build_version) {
  return napi_build_version_tag + napi_build_version;
};

module.exports.get_napi_build_version_from_command_args = function(command_args) {
  for (let i = 0; i < command_args.length; i++) {
    const arg = command_args[i];
    if (arg.indexOf(napi_build_version_tag) === 0) {
      return parseInt(arg.substr(napi_build_version_tag.length), 10);
    }
  }
  return undefined;
};

module.exports.swap_build_dir_out = function(napi_build_version) {
  if (napi_build_version) {
    const rm = require('rimraf');
    rm.sync(module.exports.get_build_dir(napi_build_version));
    fs.renameSync('build', module.exports.get_build_dir(napi_build_version));
  }
};

module.exports.swap_build_dir_in = function(napi_build_version) {
  if (napi_build_version) {
    const rm = require('rimraf');
    rm.sync('build');
    fs.renameSync(module.exports.get_build_dir(napi_build_version), 'build');
  }
};

module.exports.get_build_dir = function(napi_build_version) {
  return 'build-tmp-napi-v' + napi_build_version;
};

module.exports.get_best_napi_build_version = function(package_json, opts) {
  let best_napi_build_version = 0;
  const napi_build_versions = module.exports.get_napi_build_versions(package_json, opts);
  if (napi_build_versions) {
    const our_napi_version = module.exports.get_napi_version(opts ? opts.target : undefined);
    napi_build_versions.forEach((napi_build_version)=> {
      if (napi_build_version > best_napi_build_version &&
				napi_build_version <= our_napi_version) {
        best_napi_build_version = napi_build_version;
      }
    });
  }
  return best_napi_build_version === 0 ? undefined : best_napi_build_version;
};

module.exports.build_napi_only = function(package_json) {
  return package_json.binary && package_json.binary.package_name &&
	package_json.binary.package_name.indexOf('{node_napi_label}') === -1;
};
