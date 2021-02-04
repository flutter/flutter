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
  stdio.printStatus('\nFlutter Conductor Status\n');
  stdio.printStatus('Release channel:\t\t${state.releaseChannel}\n');
  stdio.printStatus('Engine Repo');
  stdio.printStatus('\tCandidate branch${state.engine.candidateBranch}');
  stdio.printStatus('Framework Repo');
  stdio.printStatus('\tCandidate branch${state.framework.candidateBranch}');
}
