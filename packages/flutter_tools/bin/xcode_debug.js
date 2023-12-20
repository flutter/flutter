// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * @fileoverview OSA Script to interact with Xcode. Functionality includes
 * checking if a given project is open in Xcode, starting a debug session for
 * a given project, and stopping a debug session for a given project.
 */

'use strict';

/**
 * OSA Script `run` handler that is called when the script is run. When ran
 * with `osascript`, arguments are passed from the command line to the direct
 * parameter of the `run` handler as a list of strings.
 *
 * @param {?Array<string>=} args_array
 * @returns {!RunJsonResponse} The validated command.
 */
function run(args_array = []) {
  let args;
  try {
    args = new CommandArguments(args_array);
  } catch (e) {
    return new RunJsonResponse(false, `Failed to parse arguments: ${e}`).stringify();
  }

  const xcodeResult = getXcode(args);
  if (xcodeResult.error != null) {
    return new RunJsonResponse(false, xcodeResult.error).stringify();
  }
  const xcode = xcodeResult.result;

  if (args.command === 'check-workspace-opened') {
    const result = getWorkspaceDocument(xcode, args);
    return new RunJsonResponse(result.error == null, result.error).stringify();
  } else if (args.command === 'debug') {
    const result = debugApp(xcode, args);
    return new RunJsonResponse(result.error == null, result.error, result.result).stringify();
  } else if (args.command === 'stop') {
    const result = stopApp(xcode, args);
    return new RunJsonResponse(result.error == null, result.error).stringify();
  } else {
    return new RunJsonResponse(false, 'Unknown command').stringify();
  }
}

/**
 * Parsed and validated arguments passed from the command line.
 */
class CommandArguments {
  /**
   *
   * @param {!Array<string>} args List of arguments passed from the command line.
   */
  constructor(args) {
    this.command = this.validatedCommand(args[0]);

    const parsedArguments = this.parseArguments(args);

    this.xcodePath = this.validatedStringArgument('--xcode-path', parsedArguments['--xcode-path']);
    this.projectPath = this.validatedStringArgument('--project-path', parsedArguments['--project-path']);
    this.projectName = this.validatedStringArgument('--project-name', parsedArguments['--project-name']);
    this.expectedConfigurationBuildDir = this.validatedStringArgument(
      '--expected-configuration-build-dir',
      parsedArguments['--expected-configuration-build-dir'],
    );
    this.workspacePath = this.validatedStringArgument('--workspace-path', parsedArguments['--workspace-path']);
    this.targetDestinationId = this.validatedStringArgument('--device-id', parsedArguments['--device-id']);
    this.targetSchemeName = this.validatedStringArgument('--scheme', parsedArguments['--scheme']);
    this.skipBuilding = this.validatedBoolArgument('--skip-building', parsedArguments['--skip-building']);
    this.launchArguments = this.validatedJsonArgument('--launch-args', parsedArguments['--launch-args']);
    this.closeWindowOnStop = this.validatedBoolArgument('--close-window', parsedArguments['--close-window']);
    this.promptToSaveBeforeClose = this.validatedBoolArgument('--prompt-to-save', parsedArguments['--prompt-to-save']);
    this.verbose = this.validatedBoolArgument('--verbose', parsedArguments['--verbose']);

    if (this.verbose === true) {
      console.log(JSON.stringify(this));
    }
  }

  /**
   * Validates the command is available.
   *
   * @param {?string} command
   * @returns {!string} The validated command.
   * @throws Will throw an error if command is not recognized.
   */
  validatedCommand(command) {
    const allowedCommands = ['check-workspace-opened', 'debug', 'stop'];
    if (allowedCommands.includes(command) === false) {
      throw `Unrecognized Command: ${command}`;
    }

    return command;
  }

  /**
   * Returns map of commands to map of allowed arguments. For each command, if
   * an argument flag is a key, than that flag is allowed for that command. If
   * the value for the key is true, then it is required for the command.
   *
   * @returns {!string} Map of commands to allowed and optionally required
   *     arguments.
   */
  argumentSettings() {
    return {
      'check-workspace-opened': {
        '--xcode-path': true,
        '--project-path': true,
        '--workspace-path': true,
        '--verbose': false,
      },
      'debug': {
        '--xcode-path': true,
        '--project-path': true,
        '--workspace-path': true,
        '--project-name': true,
        '--expected-configuration-build-dir': false,
        '--device-id': true,
        '--scheme': true,
        '--skip-building': true,
        '--launch-args': true,
        '--verbose': false,
      },
      'stop': {
        '--xcode-path': true,
        '--project-path': true,
        '--workspace-path': true,
        '--close-window': true,
        '--prompt-to-save': true,
        '--verbose': false,
      },
    };
  }

  /**
   * Validates the flag is allowed for the current command.
   *
   * @param {!string} flag
   * @param {?string} value
   * @returns {!bool}
   * @throws Will throw an error if the flag is not allowed for the current
   *     command and the value is not null, undefined, or empty.
   */
  isArgumentAllowed(flag, value) {
    const isAllowed = this.argumentSettings()[this.command].hasOwnProperty(flag);
    if (isAllowed === false && (value != null && value !== '')) {
      throw `The flag ${flag} is not allowed for the command ${this.command}.`;
    }
    return isAllowed;
  }

  /**
   * Validates required flag has a value.
   *
   * @param {!string} flag
   * @param {?string} value
   * @throws Will throw an error if the flag is required for the current
   *     command and the value is not null, undefined, or empty.
   */
  validateRequiredArgument(flag, value) {
    const isRequired = this.argumentSettings()[this.command][flag] === true;
    if (isRequired === true && (value == null || value === '')) {
      throw `Missing value for ${flag}`;
    }
  }

  /**
   * Parses the command line arguments into an object.
   *
   * @param {!Array<string>} args List of arguments passed from the command line.
   * @returns {!Object.<string, string>} Object mapping flag to value.
   * @throws Will throw an error if flag does not begin with '--'.
   */
  parseArguments(args) {
    const valuesPerFlag = {};
    for (let index = 1; index < args.length; index++) {
      const entry = args[index];
      let flag;
      let value;
      const splitIndex = entry.indexOf('=');
      if (splitIndex === -1) {
        flag = entry;
        value = args[index + 1];

        // If the flag is allowed for the command, and the next value in the
        // array is null/undefined or also a flag, treat the flag like a boolean
        // flag and set the value to 'true'.
        if (this.isArgumentAllowed(flag) && (value == null || value.startsWith('--'))) {
          value = 'true';
        } else {
          index++;
        }
      } else {
        flag = entry.substring(0, splitIndex);
        value = entry.substring(splitIndex + 1, entry.length + 1);
      }
      if (flag.startsWith('--') === false) {
        throw `Unrecognized Flag: ${flag}`;
      }

      valuesPerFlag[flag] = value;
    }
    return valuesPerFlag;
  }


  /**
   * Validates the flag is allowed and `value` is valid. If the flag is not
   * allowed for the current command, return `null`.
   *
   * @param {!string} flag
   * @param {?string} value
   * @returns {!string}
   * @throws Will throw an error if the flag is allowed and `value` is null,
   *     undefined, or empty.
   */
  validatedStringArgument(flag, value) {
    if (this.isArgumentAllowed(flag, value) === false) {
      return null;
    }
    this.validateRequiredArgument(flag, value);
    return value;
  }

  /**
   * Validates the flag is allowed, validates `value` is valid, and converts
   * `value` to a boolean. A `value` of null, undefined, or empty, it will
   * return true. If the flag is not allowed for the current command, will
   * return `null`.
   *
<<<<<<< HEAD
=======
   * @param {!string} flag
>>>>>>> 78666c8dc57e9f7548ca9f8dd0740fbf0c658dc9
   * @param {?string} value
   * @returns {?boolean}
   * @throws Will throw an error if the flag is allowed and `value` is not
   *     null, undefined, empty, 'true', or 'false'.
   */
  validatedBoolArgument(flag, value) {
    if (this.isArgumentAllowed(flag, value) === false) {
      return null;
    }
    if (value == null || value === '') {
      return false;
    }
    if (value !== 'true' && value !== 'false') {
      throw `Invalid value for ${flag}`;
    }
    return value === 'true';
  }

  /**
   * Validates the flag is allowed, `value` is valid, and parses `value` as JSON.
   * If the flag is not allowed for the current command, will return `null`.
   *
   * @param {!string} flag
   * @param {?string} value
   * @returns {!Object}
   * @throws Will throw an error if the flag is allowed and the value is
   *     null, undefined, or empty. Will also throw an error if parsing fails.
   */
  validatedJsonArgument(flag, value) {
    if (this.isArgumentAllowed(flag, value) === false) {
      return null;
    }
    this.validateRequiredArgument(flag, value);
    try {
      return JSON.parse(value);
    } catch (e) {
      throw `Error parsing ${flag}: ${e}`;
    }
  }
}

/**
 * Response to return in `run` function.
 */
class RunJsonResponse {
  /**
   *
   * @param {!bool} success Whether the command was successful.
   * @param {?string=} errorMessage Defaults to null.
   * @param {?DebugResult=} debugResult Curated results from Xcode's debug
   *     function. Defaults to null.
   */
  constructor(success, errorMessage = null, debugResult = null) {
    this.status = success;
    this.errorMessage = errorMessage;
    this.debugResult = debugResult;
  }

  /**
   * Converts this object to a JSON string.
   *
   * @returns {!string}
   * @throws Throws an error if conversion fails.
   */
  stringify() {
    return JSON.stringify(this);
  }
}

/**
 * Utility class to return a result along with a potential error.
 */
class FunctionResult {
  /**
   *
   * @param {?Object} result
   * @param {?string=} error Defaults to null.
   */
  constructor(result, error = null) {
    this.result = result;
    this.error = error;
  }
}

/**
 * Curated results from Xcode's debug function. Mirrors parts of
 * `scheme action result` from Xcode's Script Editor dictionary.
 */
class DebugResult {
  /**
   *
   * @param {!Object} result
   */
  constructor(result) {
    this.completed = result.completed();
    this.status = result.status();
    this.errorMessage = result.errorMessage();
  }
}

/**
 * Get the Xcode application from the given path. Since macs can have multiple
 * Xcode version, we use the path to target the specific Xcode application.
 * If the Xcode app is not running, return null with an error.
 *
 * @param {!CommandArguments} args
 * @returns {!FunctionResult} Return either an `Application` (Mac Scripting class)
 *     or null as the `result`.
 */
function getXcode(args) {
  try {
    const xcode = Application(args.xcodePath);
    const isXcodeRunning = xcode.running();

    if (isXcodeRunning === false) {
      return new FunctionResult(null, 'Xcode is not running');
    }

    return new FunctionResult(xcode);
  } catch (e) {
    return new FunctionResult(null, `Failed to get Xcode application: ${e}`);
  }
}

/**
 * After setting the active run destination to the targeted device, uses Xcode
 * debug function from Mac Scripting for Xcode to install the app on the device
 * and start a debugging session using the 'run' or 'run without building' scheme
 * action (depending on `args.skipBuilding`). Waits for the debugging session
 * to start running.
 *
 * @param {!Application} xcode An `Application` (Mac Scripting class) for Xcode.
 * @param {!CommandArguments} args
 * @returns {!FunctionResult} Return either a `DebugResult` or null as the `result`.
 */
function debugApp(xcode, args) {
  const workspaceResult = waitForWorkspaceToLoad(xcode, args);
  if (workspaceResult.error != null) {
    return new FunctionResult(null, workspaceResult.error);
  }
  const targetWorkspace = workspaceResult.result;

  const destinationResult = getTargetDestination(
    targetWorkspace,
    args.targetDestinationId,
    args.verbose,
  );
  if (destinationResult.error != null) {
    return new FunctionResult(null, destinationResult.error)
  }

  // If expectedConfigurationBuildDir is available, ensure that it matches the
  // build settings.
  if (args.expectedConfigurationBuildDir != null && args.expectedConfigurationBuildDir !== '') {
    const updateResult = waitForConfigurationBuildDirToUpdate(targetWorkspace, args);
    if (updateResult.error != null) {
      return new FunctionResult(null, updateResult.error);
    }
  }

  try {
    // Documentation from the Xcode Script Editor dictionary indicates that the
    // `debug` function has a parameter called `runDestinationSpecifier` which
    // is used to specify which device to debug the app on. It also states that
    // it should be the same as the xcodebuild -destination specifier. It also
    // states that if not specified, the `activeRunDestination` is used instead.
    //
    // Experimentation has shown that the `runDestinationSpecifier` does not work.
    // It will always use the `activeRunDestination`. To mitigate this, we set
    // the `activeRunDestination` to the targeted device prior to starting the debug.
    targetWorkspace.activeRunDestination = destinationResult.result;

    const actionResult = targetWorkspace.debug({
      scheme: args.targetSchemeName,
      skipBuilding: args.skipBuilding,
      commandLineArguments: args.launchArguments,
    });

    // Wait until scheme action has started up to a max of 10 minutes.
    // This does not wait for app to install, launch, or start debug session.
    // Potential statuses include: not yet started/‌running/‌cancelled/‌failed/‌error occurred/‌succeeded.
    const checkFrequencyInSeconds = 0.5;
    const maxWaitInSeconds = 10 * 60; // 10 minutes
    const iterations = maxWaitInSeconds * (1 / checkFrequencyInSeconds);
    const verboseLogInterval = 10 * (1 / checkFrequencyInSeconds);
    for (let i = 0; i < iterations; i++) {
      if (actionResult.status() !== 'not yet started') {
        break;
      }
      if (args.verbose === true && i % verboseLogInterval === 0) {
        console.log(`Action result status: ${actionResult.status()}`);
      }
      delay(checkFrequencyInSeconds);
    }

    return new FunctionResult(new DebugResult(actionResult));
  } catch (e) {
    return new FunctionResult(null, `Failed to start debugging session: ${e}`);
  }
}

/**
 * Iterates through available run destinations looking for one with a matching
 * `deviceId`. If device is not found, return null with an error.
 *
 * @param {!WorkspaceDocument} targetWorkspace A `WorkspaceDocument` (Xcode Mac
 *     Scripting class).
 * @param {!string} deviceId
 * @param {?bool=} verbose Defaults to false.
 * @returns {!FunctionResult} Return either a `RunDestination` (Xcode Mac
 *     Scripting class) or null as the `result`.
 */
function getTargetDestination(targetWorkspace, deviceId, verbose = false) {
  try {
    for (let destination of targetWorkspace.runDestinations()) {
      const device = destination.device();
      if (verbose === true && device != null) {
        console.log(`Device: ${device.name()} (${device.deviceIdentifier()})`);
      }
      if (device != null && device.deviceIdentifier() === deviceId) {
        return new FunctionResult(destination);
      }
    }
    return new FunctionResult(
      null,
      'Unable to find target device. Ensure that the device is paired, ' +
      'unlocked, connected, and has an iOS version at least as high as the ' +
      'Minimum Deployment.',
    );
  } catch (e) {
    return new FunctionResult(null, `Failed to get target destination: ${e}`);
  }
}

/**
 * Waits for the workspace to load. If the workspace is not loaded or in the
 * process of opening, it will wait up to 10 minutes.
 *
 * @param {!Application} xcode An `Application` (Mac Scripting class) for Xcode.
 * @param {!CommandArguments} args
 * @returns {!FunctionResult} Return either a `WorkspaceDocument` (Xcode Mac
 *     Scripting class) or null as the `result`.
 */
function waitForWorkspaceToLoad(xcode, args) {
  try {
    const checkFrequencyInSeconds = 0.5;
    const maxWaitInSeconds = 10 * 60; // 10 minutes
    const verboseLogInterval = 10 * (1 / checkFrequencyInSeconds);
    const iterations = maxWaitInSeconds * (1 / checkFrequencyInSeconds);
    for (let i = 0; i < iterations; i++) {
      // Every 10 seconds, print the list of workspaces if verbose
      const verbose = args.verbose && i % verboseLogInterval === 0;

      const workspaceResult = getWorkspaceDocument(xcode, args, verbose);
      if (workspaceResult.error == null) {
        const document = workspaceResult.result;
        if (document.loaded() === true) {
          return new FunctionResult(document, null);
        }
      } else if (verbose === true) {
        console.log(workspaceResult.error);
      }
      delay(checkFrequencyInSeconds);
    }
    return new FunctionResult(null, 'Timed out waiting for workspace to load');
  } catch (e) {
    return new FunctionResult(null, `Failed to wait for workspace to load: ${e}`);
  }
}

/**
 * Gets workspace opened in Xcode matching the projectPath or workspacePath
 * from the command line arguments. If workspace is not found, return null with
 * an error.
 *
 * @param {!Application} xcode An `Application` (Mac Scripting class) for Xcode.
 * @param {!CommandArguments} args
 * @param {?bool=} verbose Defaults to false.
 * @returns {!FunctionResult} Return either a `WorkspaceDocument` (Xcode Mac
 *     Scripting class) or null as the `result`.
 */
function getWorkspaceDocument(xcode, args, verbose = false) {
  const privatePrefix = '/private';

  try {
    const documents = xcode.workspaceDocuments();
    for (let document of documents) {
      const filePath = document.file().toString();
      if (verbose === true) {
        console.log(`Workspace: ${filePath}`);
      }
      if (filePath === args.projectPath || filePath === args.workspacePath) {
        return new FunctionResult(document);
      }
      // Sometimes when the project is in a temporary directory, it'll be
      // prefixed with `/private` but the args will not. Remove the
      // prefix before matching.
      if (filePath.startsWith(privatePrefix) === true) {
        const filePathWithoutPrefix = filePath.slice(privatePrefix.length);
        if (filePathWithoutPrefix === args.projectPath || filePathWithoutPrefix === args.workspacePath) {
          return new FunctionResult(document);
        }
      }
    }
  } catch (e) {
    return new FunctionResult(null, `Failed to get workspace: ${e}`);
  }
  return new FunctionResult(null, `Failed to get workspace.`);
}

/**
 * Stops all debug sessions in the target workspace.
 *
 * @param {!Application} xcode An `Application` (Mac Scripting class) for Xcode.
 * @param {!CommandArguments} args
 * @returns {!FunctionResult} Always returns null as the `result`.
 */
function stopApp(xcode, args) {
  const workspaceResult = getWorkspaceDocument(xcode, args);
  if (workspaceResult.error != null) {
    return new FunctionResult(null, workspaceResult.error);
  }
  const targetDocument = workspaceResult.result;

  try {
    targetDocument.stop();

    if (args.closeWindowOnStop === true) {
      // Wait a couple seconds before closing Xcode, otherwise it'll prompt the
      // user to stop the app.
      delay(2);

      targetDocument.close({
        saving: args.promptToSaveBeforeClose === true ? 'ask' : 'no',
      });
    }
  } catch (e) {
    return new FunctionResult(null, `Failed to stop app: ${e}`);
  }
  return new FunctionResult(null, null);
}

/**
 * Gets resolved build setting for CONFIGURATION_BUILD_DIR and waits until its
 * value matches the `--expected-configuration-build-dir` argument. Waits up to
 * 2 minutes.
 *
 * @param {!WorkspaceDocument} targetWorkspace A `WorkspaceDocument` (Xcode Mac
 *     Scripting class).
 * @param {!CommandArguments} args
 * @returns {!FunctionResult} Always returns null as the `result`.
 */
function waitForConfigurationBuildDirToUpdate(targetWorkspace, args) {
  // Get the project
  let project;
  try {
    project = targetWorkspace.projects().find(x => x.name() == args.projectName);
  } catch (e) {
    return new FunctionResult(null, `Failed to find project ${args.projectName}: ${e}`);
  }
  if (project == null) {
    return new FunctionResult(null, `Failed to find project ${args.projectName}.`);
  }

  // Get the target
  let target;
  try {
    // The target is probably named the same as the project, but if not, just use the first.
    const targets = project.targets();
    target = targets.find(x => x.name() == args.projectName);
    if (target == null && targets.length > 0) {
      target = targets[0];
      if (args.verbose) {
        console.log(`Failed to find target named ${args.projectName}, picking first target: ${target.name()}.`);
      }
    }
  } catch (e) {
    return new FunctionResult(null, `Failed to find target: ${e}`);
  }
  if (target == null) {
    return new FunctionResult(null, `Failed to find target.`);
  }

  try {
    // Use the first build configuration (Debug). Any should do since they all
    // include Generated.xcconfig.
    const buildConfig = target.buildConfigurations()[0];
    const buildSettings = buildConfig.resolvedBuildSettings().reverse();

    // CONFIGURATION_BUILD_DIR is often at (reverse) index 225 for Xcode
    // projects, so check there first. If it's not there, search the build
    // settings (which can be a little slow).
    const defaultIndex = 225;
    let configurationBuildDirSettings;
    if (buildSettings[defaultIndex] != null && buildSettings[defaultIndex].name() === 'CONFIGURATION_BUILD_DIR') {
      configurationBuildDirSettings = buildSettings[defaultIndex];
    } else {
      configurationBuildDirSettings = buildSettings.find(x => x.name() === 'CONFIGURATION_BUILD_DIR');
    }

    if (configurationBuildDirSettings == null) {
      // This should not happen, even if it's not set by Flutter, there should
      // always be a resolved build setting for CONFIGURATION_BUILD_DIR.
      return new FunctionResult(null, `Unable to find CONFIGURATION_BUILD_DIR.`);
    }

    // Wait up to 2 minutes for the CONFIGURATION_BUILD_DIR to update to the
    // expected value.
    const checkFrequencyInSeconds = 0.5;
    const maxWaitInSeconds = 2 * 60; // 2 minutes
    const verboseLogInterval = 10 * (1 / checkFrequencyInSeconds);
    const iterations = maxWaitInSeconds * (1 / checkFrequencyInSeconds);
    for (let i = 0; i < iterations; i++) {
      const verbose = args.verbose && i % verboseLogInterval === 0;

      const configurationBuildDir = configurationBuildDirSettings.value();
      if (configurationBuildDir === args.expectedConfigurationBuildDir) {
        console.log(`CONFIGURATION_BUILD_DIR: ${configurationBuildDir}`);
        return new FunctionResult(null, null);
      }
      if (verbose) {
        console.log(`Current CONFIGURATION_BUILD_DIR: ${configurationBuildDir} while expecting ${args.expectedConfigurationBuildDir}`);
      }
      delay(checkFrequencyInSeconds);
    }
    return new FunctionResult(null, 'Timed out waiting for CONFIGURATION_BUILD_DIR to update.');
  } catch (e) {
    return new FunctionResult(null, `Failed to get CONFIGURATION_BUILD_DIR: ${e}`);
  }
}
