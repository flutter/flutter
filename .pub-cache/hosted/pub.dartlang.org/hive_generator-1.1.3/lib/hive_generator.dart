import 'package:build/build.dart';
import 'package:hive_generator/src/type_adapter_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder getBuilder(BuilderOptions options) =>
    SharedPartBuilder([TypeAdapterGenerator()], 'hive_generator');
