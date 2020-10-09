import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_driver/src/common/find.dart';
import 'package:flutter_driver/src/common/message.dart';

import 'stub_command.dart';

class StubCommandExtension extends CommandExtension {
  @override
  Future<Result> call(Command command) async {
    return const StubCommandResult('stub response');
  }

  @override
  String get commandKind => 'StubCommand';

  @override
  Command deserialize(Map<String, String> params, DeserializeFinderFactory finderFactory) {
    return StubCommand.deserialize(params, finderFactory);
  }
}
