import '../base/io.dart';
import '../doctor_validator.dart';

const String kCoreProcessPattern = r'Topaz OFD\\Warsaw\\core.exe';

class TopazOfdValidator extends DoctorValidator {
  const TopazOfdValidator() : super('Topaz OFD');

  @override
  Future<ValidationResult> validate() async {
    final ProcessResult tasksResult = await Process.run('powershell', ['-command', 'Get-Process core | Format-List Path']);
    String tasks = tasksResult.stdout as String;
    final RegExp pattern = RegExp(kCoreProcessPattern, multiLine: true, caseSensitive: false);
    final bool matches = pattern.hasMatch(tasks);
    tasks = '$tasks: $kCoreProcessPattern: $matches';
    if (matches) {
      return const ValidationResult(
        ValidationType.partial,
        <ValidationMessage>[
          ValidationMessage.hint('The Topaz OFD Security Module process has been found running. If you are unable to build, you will need to disable it.'),
        ],
        statusInfo: 'Topaz OFD may be running');
    } else {
      return const ValidationResult(
        ValidationType.success,
        <ValidationMessage>[]);
    }
  }
}
