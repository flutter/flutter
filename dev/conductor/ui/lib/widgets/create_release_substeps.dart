// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:conductor_core/conductor_core.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../logic/helper_functions.dart';
import 'common/tooltip.dart';

const FileSystem fileSystem = LocalFileSystem();
const ProcessManager processManager = LocalProcessManager();
const Platform platform = LocalPlatform();
final Stdio stdio = VerboseStdio(
  stdout: io.stdout,
  stderr: io.stderr,
  stdin: io.stdin,
);

/// Displays all substeps related to the 1st step.
///
/// Uses input fields and dropdowns to capture all the parameters of the conductor start command.
class CreateReleaseSubsteps extends StatefulWidget {
  const CreateReleaseSubsteps({
    Key? key,
    required this.nextStep,
    this.startContext,
  }) : super(key: key);

  final VoidCallback nextStep;
  final StartContext? startContext;

  @override
  State<CreateReleaseSubsteps> createState() => CreateReleaseSubstepsState();

  static const List<String> substepTitles = <String>[
    'Candidate Branch',
    'Release Channel',
    'Framework Mirror',
    'Engine Mirror',
    'Engine Cherrypicks (if necessary)',
    'Framework Cherrypicks (if necessary)',
    'Dart Revision (if necessary)',
    'Increment',
  ];
}

class CreateReleaseSubstepsState extends State<CreateReleaseSubsteps> {
  @visibleForTesting
  late Map<String, String?> releaseData = <String, String?>{};

  Object? _error;
  bool _isLoading = false;

  /// Function that initializes and executes the equivalent of `conductor start` CLI command.
  ///
  /// Exceptions and errors can be thrown by this function and needed to be caught by the outer block.
  Future<void> runStartContext(
      {required FileSystem fileSystem,
      required ProcessManager processManager,
      required Platform platform,
      required Stdio stdio}) async {
    final Checkouts checkouts = Checkouts(
      fileSystem: fileSystem,
      parentDirectory: localFlutterRoot.parent,
      platform: platform,
      processManager: processManager,
      stdio: stdio,
    );
    final String stateFilePath = defaultStateFilePath(platform);
    final File stateFile = fileSystem.file(stateFilePath);

    /// Data captured by the input forms and dropdowns are transformed to conform the formats of StartContext.
    final StartContext startContext = widget.startContext ??
        StartContext(
          candidateBranch: releaseData[CreateReleaseSubsteps.substepTitles[0]] ?? '',
          releaseChannel: releaseData[CreateReleaseSubsteps.substepTitles[1]] ?? '',
          frameworkMirror: releaseData[CreateReleaseSubsteps.substepTitles[2]] ?? '',
          engineMirror: releaseData[CreateReleaseSubsteps.substepTitles[3]] ?? '',
          engineCherrypickRevisions: cherrypickStringtoArray(releaseData[CreateReleaseSubsteps.substepTitles[4]]),
          frameworkCherrypickRevisions: cherrypickStringtoArray(releaseData[CreateReleaseSubsteps.substepTitles[5]]),
          dartRevision: releaseData[CreateReleaseSubsteps.substepTitles[6]] == ''
              ? null
              : releaseData[CreateReleaseSubsteps.substepTitles[6]],
          incrementLetter: releaseData[CreateReleaseSubsteps.substepTitles[7]] ?? '',
          checkouts: checkouts,
          engineUpstream: EngineRepository.defaultUpstream,
          flutterRoot: localFlutterRoot,
          frameworkUpstream: FrameworkRepository.defaultUpstream,
          processManager: processManager,
          stateFile: stateFile,
          stdio: stdio,
        );
    await startContext.run();
  }

  /// Updates the corresponding [field] in [releaseData] with [data].
  void setReleaseData(String field, String data) {
    setState(() {
      releaseData = <String, String?>{
        ...releaseData,
        field: data,
      };
    });
  }

  /// Updates [_error] with what the conductor throws.
  void setError(Object? errorThrown) {
    setState(() {
      _error = errorThrown;
    });
  }

  /// Method to modify the state [_isLoading].
  void setIsLoading(bool result) {
    setState(() {
      _isLoading = result;
    });
  }

  /// Presents the error object in a string.
  String presentError(Object? error) {
    final StringBuffer buffer = StringBuffer();
    if (error is ConductorException) {
      buffer.writeln('Conductor Exception: $error');
      return buffer.toString();
    } else {
      buffer.writeln('Error: $error');
      return buffer.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InputAsSubstep(
          index: 0,
          setReleaseData: setReleaseData,
          hintText: 'The candidate branch the release will be based on.',
        ),
        DropdownAsSubstep(
          index: 1,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['dev', 'beta', 'stable'],
        ),
        InputAsSubstep(
          index: 2,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Framework repository mirror.",
        ),
        InputAsSubstep(
          index: 3,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Engine repository mirror.",
        ),
        InputAsSubstep(
          index: 4,
          setReleaseData: setReleaseData,
          hintText: 'Engine cherrypick hashes to be applied. Multiple hashes delimited by a comma, no spaces.',
        ),
        InputAsSubstep(
          index: 5,
          setReleaseData: setReleaseData,
          hintText: 'Framework cherrypick hashes to be applied. Multiple hashes delimited by a comma, no spaces.',
        ),
        InputAsSubstep(
          index: 6,
          setReleaseData: setReleaseData,
          hintText: 'New Dart revision to cherrypick.',
        ),
        DropdownAsSubstep(
          index: 7,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['y', 'z', 'm', 'n'],
        ),
        const SizedBox(height: 20.0),
        if (_error != null)
          Center(
            child: SelectableText(
              presentError(_error),
              style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              key: const Key('step1continue'),
              onPressed: _isLoading
                  ? null // if the release initialization is loading, disable this button
                  : () async {
                      setError(null);
                      try {
                        setIsLoading(true);
                        await runStartContext(
                            fileSystem: fileSystem, processManager: processManager, platform: platform, stdio: stdio);
                        // ignore: avoid_catches_without_on_clauses
                      } catch (error) {
                        setError(error);
                      } finally {
                        setIsLoading(false);
                      }
                      if (_error == null) {
                        widget.nextStep();
                      }
                    },
              child: const Text('Continue'),
            ),
            const SizedBox(width: 30.0),
            if (_isLoading)
              const CircularProgressIndicator(
                semanticsLabel: 'Linear progress indicator',
              ),
          ],
        ),
      ],
    );
  }
}

typedef SetReleaseData = void Function(String name, String data);

/// Captures the input values and updates the corresponding field in [releaseData].
class InputAsSubstep extends StatelessWidget {
  const InputAsSubstep({
    Key? key,
    required this.index,
    required this.setReleaseData,
    this.hintText,
  }) : super(key: key);

  final int index;
  final SetReleaseData setReleaseData;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key(CreateReleaseSubsteps.substepTitles[index]),
      decoration: InputDecoration(
        labelText: CreateReleaseSubsteps.substepTitles[index],
        hintText: hintText,
      ),
      onChanged: (String data) {
        setReleaseData(CreateReleaseSubsteps.substepTitles[index], data);
      },
    );
  }
}

/// Captures the chosen option and updates the corresponding field in [releaseData].
class DropdownAsSubstep extends StatelessWidget {
  const DropdownAsSubstep({
    Key? key,
    required this.index,
    required this.releaseData,
    required this.setReleaseData,
    required this.options,
  }) : super(key: key);

  final int index;
  final Map<String, String?> releaseData;
  final SetReleaseData setReleaseData;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          CreateReleaseSubsteps.substepTitles[index],
          style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[700]),
        ),
        // Only add a tooltip for the increment dropdown
        if (index == 7)
          const Padding(
            padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
            child: InfoTooltip(
              tooltipName: 'ReleaseIncrement',
              // m: has one less space than the other lines, because otherwise,
              // it would display on the app one more space than the other lines
              tooltipMessage: '''
m:   Indicates a standard dev release.
n:    Indicates a hotfix to a dev or beta release.
y:    Indicates the first dev release after a beta release.
z:    Indicates a hotfix to a stable release.''',
            ),
          ),
        const SizedBox(width: 20.0),
        DropdownButton<String>(
          hint: const Text('-'), // Dropdown initially displays the hint when no option is selected.
          key: Key(CreateReleaseSubsteps.substepTitles[index]),
          value: releaseData[CreateReleaseSubsteps.substepTitles[index]],
          icon: const Icon(Icons.arrow_downward),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setReleaseData(CreateReleaseSubsteps.substepTitles[index], newValue!);
          },
        ),
      ],
    );
  }
}
