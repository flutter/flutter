
import 'package:flutter_tool_api/extension.dart';
import 'package:flutter_tool_api/doctor.dart';

class FlutterMacOSExtension extends ToolExtension {
  @override
  String get name => 'flutter_tool_macos';

  @override
  final MacOSDoctor doctorDomain = MacOSDoctor();
}

class MacOSDoctor extends DoctorDomain {
  @override
  Future<ValidationResult> diagnose(Map<String, Object> arguments) async {
    return ValidationResult(
      name: 'flutter_tools_macos',
      messages: <ValidationMessage>[
        ValidationMessage(
          'lkjadskljasdfljkasdkljasdkljasdklj',
        )
      ]
    );
  }
}
