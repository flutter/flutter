import '../../../../core/internationalization.dart';
import '../../../../core/locales.g.dart';
import '../../../../functions/create/create_single_file.dart';
import '../../../../samples/impl/get_provider.dart';
import '../../../interface/command.dart';

class CreateProviderCommand extends Command {
  @override
  String get commandName => 'provider';
  @override
  Future<void> execute() async {
    var name = this.name;
    handleFileCreate(name, 'provider', onCommand, onCommand.isNotEmpty,
        ProviderSample(name), onCommand.isNotEmpty ? 'providers' : '');
  }

  @override
  String? get hint => Translation(LocaleKeys.hint_create_provider).tr;

  @override
  String get codeSample => 'get create provider:user on data';

  @override
  int get maxParameters => 0;
}
