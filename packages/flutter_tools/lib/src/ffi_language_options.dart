import 'package:vm_snapshot_analysis/name.dart';

import 'base/utils.dart';

enum FfiLanguageOptions implements CliEnum {

  C,
  Cpp,
  Go,
  Rust,
  Swift;

  @override
  String get cliName => snakeCase(name);

  @override
  String get helpText => switch(this){
    FfiLanguageOptions.C => 'Specify that you want to generate an FFI example in the C language',
    FfiLanguageOptions.Rust => 'Specify that you want to generate an FFI example in Rustlang',
    FfiLanguageOptions.Cpp => 'Specify that you want to generate an FFI example in C++',
    FfiLanguageOptions.Swift  => 'Specify that you want to generate an FFi example in Rust',
    FfiLanguageOptions.Go => 'Specify that you want to generate an FFi example in Go'
  };

}
