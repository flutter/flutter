import 'dart:convert' show jsonDecode;

import 'package:file/file.dart';
import 'package:meta/meta.dart' show required;

const String kStateFileName = '.flutter_conductor_state.json';

class State {
  State._({
    @required this.candidateBranch,
    @required this.releaseChannel,
  })  : assert(candidateBranch != null),
        assert(releaseChannel != null);

  /// Instantiate state from persistent file.
  factory State.fromFile(File file) {
    final String serializedState = file.readAsStringSync();
    final Map<String, dynamic> json =
        jsonDecode(serializedState) as Map<String, dynamic>;
    return State._(
      candidateBranch: json['candidateBranch'] as String,
      releaseChannel: json['releaseChannel'] as String,
    );
  }

  final String releaseChannel;
  final String candidateBranch;
}
