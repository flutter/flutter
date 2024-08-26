import 'base/utils.dart';

enum FfiLanguageOptions implements CliEnum {

  C,
  Cpp;

  @override
  String get cliName => snakeCase(name);

  @override
  String get helpText => switch(this){
    FfiLanguageOptions.C => 'Specify that you want to generate an FFI example in the C language',
    FfiLanguageOptions.Cpp => 'Specify that you want to generate an FFI example in C++',
  };

}
