// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * @fileoverview Mac Script to interact with Xcode. Functionality includes
 * checking if a given project is open in Xcode, starting a debug session for
 * a given project, and stopping a debug session for a given project.
 */

"use strict";

function run(args_array = []) {
	let args;
	try {
		args = new CommandArguments(args_array);
	} catch (e) {
		return new RunJsonResponse(false, `Failed to parse arguments: ${e}`);
	}

	const xcodeResult = getXcode(args);
	if (xcodeResult.error != null) {
		return new RunJsonResponse(false, xcodeResult.error).stringify();
	}
	const xcode = xcodeResult.result;

	if (args.command === "project-opened") {
		const result = getWorkspace(xcode, args);
		return new RunJsonResponse(result.error == null, result.error).stringify();
	} else if (args.command === "debug") {
		const result = debugApp(xcode, args);
		return new RunJsonResponse(result.error == null, result.error, result.result).stringify();
	} else if (args.command === "stop") {
		const result = stopApp(xcode, args);
		return new RunJsonResponse(result.error == null, result.error).stringify();
	} else {
		return new RunJsonResponse(false, "Unknown command").stringify();
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

		this.xcodePath = this.validatedStringArgument("--xcode-path", parsedArguments["--xcode-path"]);
		this.projectPath = this.validatedStringArgument("--project-path", parsedArguments["--project-path"]);
		this.workspacePath = this.validatedStringArgument("--workspace-path", parsedArguments["--workspace-path"]);
		this.targetDestinationId = this.validatedStringArgument("--device-id", parsedArguments["--device-id"]);
		this.targetSchemeName = this.validatedStringArgument("--scheme", parsedArguments["--scheme"]);
		this.skipBuilding = this.validatedBoolArgument("--skip-building", parsedArguments["--skip-building"]);
		this.launchArguments = this.validatedJsonArgument("--launch-args", parsedArguments["--launch-args"]);
		this.closeWindowOnStop = this.validatedBoolArgument("--close-window", parsedArguments["--close-window"]);
		this.promptToSaveBeforeClose = this.validatedBoolArgument("--prompt-to-save", parsedArguments["--prompt-to-save"]);
		this.verbose = this.validatedBoolArgument("--verbose", parsedArguments["--verbose"]);

		if (this.verbose) {
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
		switch (command) {
			case "project-opened":
			case "debug":
			case "stop":
				return command;
			default:
				throw `Unrecognized Command: ${command}`;
		}
	}

	/**
	 * Validates the flag is allowed for the current command.
	 *
	 * @param {!string} flag
	 * @returns {!bool} The validated command.
	 */
	isArgumentAllowed(flag) {
		const allowedArguments = {
			"common": {
				"--xcode-path": true,
				"--project-path": true,
				"--workspace-path": true,
				"--verbose": true,
			},
			"project-opened": {},
			"debug": {
				"--device-id": true,
				"--scheme": true,
				"--skip-building": true,
				"--launch-args": true,
			},
			"stop": {
				"--close-window": true,
				"--prompt-to-save": true,
			},
		}

		if (allowedArguments["common"][flag] === true || allowedArguments[this.command][flag] === true) {
			return true;
		}
		return false;
	}

	/**
	 * Parses the command line arguments into an object.
	 *
	 * @param {!Array<string>} args List of arguments passed from the command line.
	 * @returns {!Object.<string, string>} Object mapping flag to value.
	 * @throws Will throw an error if flag is not recognized.
	 */
	parseArguments(args) {
		const valuesPerFlag = {};
		for (let index = 1; index < args.length; index++) {
			const entry = args[index];
			let flag;
			let value;
			const splitIndex = entry.indexOf("=");
			if (splitIndex === -1) {
				flag = entry;
				value = args[index + 1];

				// If next value in the array is also a flag or the next value
				// is null/undefined, treat the flag like a boolean flag and
				// set the value to "true".
				if ((value != null && value.startsWith("--")) || value == null) {
					value = "true";
				} else {
					index++;
				}
			} else {
				flag = entry.substring(0, splitIndex);
				value = entry.substring(splitIndex + 1, entry.length + 1);
			}
			if (!flag.startsWith("--")) {
				throw `Unrecognized Flag: ${flag}`;
			}

			valuesPerFlag[flag] = value;
		}
		return valuesPerFlag;
	}


	/**
	 * Validates `value` is not null, undefined, or empty. If the flag is not
	 * allowed for the current command, return `null`.
	 *
	 * @param {!string} flag
	 * @param {?string} value
	 * @returns {!string}
	 * @throws Will throw an error if `value` is null, undefined, or empty.
	 */
	validatedStringArgument(flag, value) {
		if (!this.isArgumentAllowed(flag)) {
			return null;
		}
		if (value == null || value === "") {
			throw `Missing value for ${flag}`;
		}
		return value;
	}

	/**
	 * Converts `value` to a boolean. If `value` is null, undefined, or empty,
	 * it will return true. If the flag is not allowed for the current command,
	 * will return `null`.
	 *
	 * @param {?string} value
	 * @returns {?boolean}
	 * @throws Will throw an error if `value` is not empty, null, "true", or "false".
	 */
	validatedBoolArgument(flag, value) {
		if (!this.isArgumentAllowed(flag)) {
			return null;
		}
		if (value == null || value === "") {
			return false;
		}
		if (value !== "true" && value !== "false") {
			throw `Invalid value for ${flag}`;
		}
		return value === "true";
	}

	/**
	 * Validates `value` is not null, undefined, or empty. Parses `value` as
	 * JSON. If the flag is not allowed for the current command, will return `null`.
	 *
	 * @param {!string} flag
	 * @param {?string} value
	 * @returns {!Object}
	 * @throws Will throw an error if the flag is allowed and the value is
	 *     null, undefined, or empty. Will also throw an error if parsing fails.
	 */
	validatedJsonArgument(flag, value) {
		if (!this.isArgumentAllowed(flag)) {
			return null;
		}
		if (value == null || value === "") {
			throw `Missing value for ${flag}`;
		}
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
	 * @param {?string=} error
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
 * @returns {!FunctionResult}
 */
function getXcode(args) {
	try {
		const xcode = Application(args.xcodePath);
		const isXcodeRunning = xcode.running();

		if (!isXcodeRunning) {
			return new FunctionResult(null, "Xcode is not running");
		}

		return new FunctionResult(xcode);
	} catch (e) {
		return new FunctionResult(null, `Failed to get Xcode application: ${e}`);
	}
}

/**
 * Sets active run destination to targeted device. Uses Xcode debug function
 * from Mac Scripting for Xcode to install the app on the device and start a
 * debugging session using the "run" or "run without building" scheme action
 * (depending on `args.skipBuilding`). Waits for the debugging session to start running.
 *
 * @param {!Application} xcode Mac Scripting Application for Xcode
 * @param {!CommandArguments} args
 * @returns {!FunctionResult}
 */
function debugApp(xcode, args) {
	const documentLoadedResult = waitForWorkspaceToLoad(xcode, args);
	if (documentLoadedResult.error != null) {
		return new FunctionResult(null, documentLoadedResult.error);
	}

	const workspaceResult = getWorkspace(xcode, args);
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

		// Wait until app has started up to a max of 10 minutes.
		// Potential statuses include: not yet started/‌running/‌cancelled/‌failed/‌error occurred/‌succeeded.
		const checkFrequencyInSeconds = 0.5;
		const maxWaitInSeconds = 10 * 60; // 10 minutes
		const iterations = maxWaitInSeconds * (1 / checkFrequencyInSeconds);
		const verboseLogInterval = 10 * (1 / checkFrequencyInSeconds);
		for (let i = 0; i < iterations; i++) {
			if (actionResult.status() != "not yet started") {
				break;
			}
			if (args.verbose && i % verboseLogInterval === 0) {
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
 * @param {!WorkspaceDocument} targetWorkspace WorkspaceDocument from Mac Scripting for Xcode
 * @param {!string} deviceId
 * @param {?bool=} verbose
 * @returns {!FunctionResult}
 */
function getTargetDestination(targetWorkspace, deviceId, verbose = false) {
	try {
		let targetDestination;
		for (let runDest of targetWorkspace.runDestinations()) {
			if (runDest.device() != null && verbose) {
				console.log(`Device: ${runDest.device().deviceIdentifier()}`);
			}
			if (runDest.device() != null && runDest.device().deviceIdentifier() === deviceId) {
				targetDestination = runDest;
				break;
			}
		}
		if (targetDestination == null) {
			return new FunctionResult(null, "Unable to find target device. Is it paired, unlocked, connected, correct deployment, symbols done?");
		}

		return new FunctionResult(targetDestination);
	} catch (e) {
		return new FunctionResult(null, `Failed to get target destination: ${e}`);
	}
}

/**
 * Waits for the workspace to load. If the workspace is not loaded or in the
 * process of opening, it will wait up to 10 minutes.
 *
 * @param {!Application} xcode Mac Scripting Application for Xcode
 * @param {!CommandArguments} args
 * @returns {!FunctionResult}
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

			const workspaceResult = getWorkspace(xcode, args, verbose);
			if (workspaceResult.error == null) {
				const document = workspaceResult.result;
				if (document.loaded()) {
					return new FunctionResult(null, null);
				}
			} else if (verbose) {
				console.log(workspaceResult.error);
			}
			delay(checkFrequencyInSeconds);
		}
		return new FunctionResult(null, "Timed out waiting for workspace to load");
	} catch (e) {
		return new FunctionResult(null, `Failed to wait for workspace to load: ${e}`);
	}
}

/**
 * Gets workspace opened in Xcode matching the projectPath or workspacePath
 * from the command line arguments. If workspace is not found, return null with
 * an error.
 *
 * @param {!Application} xcode Mac Scripting Application for Xcode
 * @param {!CommandArguments} args
 * @param {?bool=} verbose
 * @returns {!FunctionResult}
 */
function getWorkspace(xcode, args, verbose = false) {
	const privatePrefix = "/private";

	try {
		const documents = xcode.workspaceDocuments();
		for (let document of documents) {
			const filePath = document.file().toString();
			if (verbose) {
				console.log(`Workspace: ${filePath}`);
			}
			if (filePath === args.projectPath || filePath === args.workspacePath) {
				return new FunctionResult(document);
			}
			// Sometimes when the project is in a temporary directory, it'll be
			// prefixed with `/private` but the args will not. Remove the
			// prefix before matching.
			if (filePath.startsWith(privatePrefix)) {
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
 * @param {!Application} xcode Mac Scripting Application for Xcode
 * @param {!CommandArguments} args
 * @returns {!FunctionResult}
 */
function stopApp(xcode, args) {
	const workspaceResult = getWorkspace(xcode, args);
	if (workspaceResult.error != null) {
		return new FunctionResult(null, workspaceResult.error);
	}
	const targetDocument = workspaceResult.result;

	try {
		targetDocument.stop();

		if (args.closeWindowOnStop) {
			// Wait a couple seconds before closing Xcode, otherwise it'll
			// prompt the user to stop the app.
			delay(2);

			targetDocument.close({
				saving: args.promptToSaveBeforeClose === true ? "ask" : "no",
			});
		}
	} catch (e) {
		return new FunctionResult(null, `Failed to stop app: ${e}`);
	}
	return new FunctionResult(null, null);
}
