import '../base/io.dart';
import '../doctor_validator.dart';

const String kCoreProcessPattern = r'Topaz OFD\\Warsaw\\core.exe';

class TopazOfdValidator extends DoctorValidator {
  const TopazOfdValidator({required this.processLister}) : super('Topaz OFD');

  final ProcessLister processLister;

  @override
  Future<ValidationResult> validate() async {
    final String tasks = await processLister.getProcessesWithPath('core');
    final RegExp pattern = RegExp(kCoreProcessPattern, multiLine: true, caseSensitive: false);
    final bool matches = pattern.hasMatch(tasks);
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

class ProcessLister {
  Future<String> getProcessesWithPath(String? filter) async {
    final String argument = filter == null ? 'Get-Process $filter | Format-List Path' : 'Get-Process | Format-List Path';
    final ProcessResult taskResult = await Process.run('powershell', <String>['-command', argument]);
    return taskResult.stdout as String;
  }
}
