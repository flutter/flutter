import 'package:platform/platform.dart';

import './proto/conductor_state.pb.dart' as pb;
import './stdio.dart' show Stdio;

const String kStateFileName = '.flutter_conductor_state.json';

String defaultStateFilePath(Platform platform) {
  assert(platform.environment['HOME'] != null);
  return <String>[
    platform.environment['HOME'],
    kStateFileName,
  ].join(platform.pathSeparator);
}

void presentState(Stdio stdio, pb.ConductorState state) {
  stdio.printStatus('Flutter Conductor Status\n');
  stdio.printStatus('Release channel: ${state.releaseChannel}');
  stdio.printStatus('');
  stdio.printStatus(
      'Release started at: ${DateTime.fromMillisecondsSinceEpoch(state.createdDate.toInt())}');
  stdio.printStatus(
      'Last updated at: ${DateTime.fromMillisecondsSinceEpoch(state.lastUpdatedDate.toInt())}');
  stdio.printStatus('');
  stdio.printStatus('Engine Repo');
  stdio.printStatus('\tCandidate branch: ${state.engine.candidateBranch}');
  stdio.printStatus('\tPrevious git HEAD: ${state.engine.previousGitHead}');
  stdio.printStatus('\tPath to checkout: ${state.engine.checkoutPath}');
  stdio.printStatus('Framework Repo');
  stdio.printStatus('\tCandidate branch: ${state.framework.candidateBranch}');
  stdio.printStatus('\tPrevious git HEAD: ${state.framework.previousGitHead}');
  stdio.printStatus('\tPath to checkout: ${state.framework.checkoutPath}');
}
