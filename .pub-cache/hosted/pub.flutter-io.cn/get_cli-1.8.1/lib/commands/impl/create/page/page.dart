import 'dart:io';

import 'package:cli_dialog/cli_dialog.dart';
import 'package:recase/recase.dart';

import '../../../../common/menu/menu.dart';
import '../../../../common/utils/logger/log_utils.dart';
import '../../../../common/utils/pubspec/pubspec_utils.dart';
import '../../../../core/generator.dart';
import '../../../../core/internationalization.dart';
import '../../../../core/locales.g.dart';
import '../../../../core/structure.dart';
import '../../../../functions/create/create_single_file.dart';
import '../../../../functions/routes/get_add_route.dart';
import '../../../../samples/impl/get_binding.dart';
import '../../../../samples/impl/get_controller.dart';
import '../../../../samples/impl/get_view.dart';
import '../../../interface/command.dart';

/// The command create a Binding and Controller page and view
class CreatePageCommand extends Command {
  @override
  String get commandName => 'page';

  @override
  List<String> get alias => ['module', '-p', '-m'];
  @override
  Future<void> execute() async {
    var isProject = false;
    if (GetCli.arguments[0] == 'create' || GetCli.arguments[0] == '-c') {
      isProject = GetCli.arguments[1].split(':').first == 'project';
    }
    var name = this.name;
    if (name.isEmpty || isProject) {
      name = 'home';
    }
    checkForAlreadyExists(name);
  }

  @override
  String? get hint => LocaleKeys.hint_create_page.tr;

  void checkForAlreadyExists(String? name) {
    var newFileModel =
        Structure.model(name, 'page', true, on: onCommand, folderName: name);
    var pathSplit = Structure.safeSplitPath(newFileModel.path!);

    pathSplit.removeLast();
    var path = pathSplit.join('/');
    path = Structure.replaceAsExpected(path: path);
    if (Directory(path).existsSync()) {
      final menu = Menu(
        [
          LocaleKeys.options_yes.tr,
          LocaleKeys.options_no.tr,
          LocaleKeys.options_rename.tr,
        ],
        title:
            Translation(LocaleKeys.ask_existing_page.trArgs([name])).toString(),
      );
      final result = menu.choose();
      if (result.index == 0) {
        _writeFiles(path, name!, overwrite: true);
      } else if (result.index == 2) {
        final dialog = CLI_Dialog();
        dialog.addQuestion(LocaleKeys.ask_new_page_name.tr, 'name');
        name = dialog.ask()['name'] as String?;

        checkForAlreadyExists(name!.trim().snakeCase);
      }
    } else {
      Directory(path).createSync(recursive: true);
      _writeFiles(path, name!, overwrite: false);
    }
  }

  void _writeFiles(String path, String name, {bool overwrite = false}) {
    var isServer = PubspecUtils.isServerProject;
    var extraFolder = PubspecUtils.extraFolder ?? true;
    var controllerFile = handleFileCreate(
      name,
      'controller',
      path,
      extraFolder,
      ControllerSample(
        '',
        name,
        isServer,
        overwrite: overwrite,
      ),
      'controllers',
    );
    var controllerDir = Structure.pathToDirImport(controllerFile.path);
    var viewFile = handleFileCreate(
      name,
      'view',
      path,
      extraFolder,
      GetViewSample(
        '',
        '${name.pascalCase}View',
        '${name.pascalCase}Controller',
        controllerDir,
        isServer,
        overwrite: overwrite,
      ),
      'views',
    );
    var bindingFile = handleFileCreate(
      name,
      'binding',
      path,
      extraFolder,
      BindingSample(
        '',
        name,
        '${name.pascalCase}Binding',
        controllerDir,
        isServer,
        overwrite: overwrite,
      ),
      'bindings',
    );

    addRoute(
      name,
      Structure.pathToDirImport(bindingFile.path),
      Structure.pathToDirImport(viewFile.path),
    );
    LogService.success(LocaleKeys.sucess_page_create.trArgs([name.pascalCase]));
  }

  @override
  String get codeSample => 'get create page:product';

  @override
  int get maxParameters => 0;
}
