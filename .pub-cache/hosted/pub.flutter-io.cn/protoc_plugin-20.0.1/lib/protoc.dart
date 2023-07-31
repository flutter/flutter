import 'dart:convert';

import 'package:dart_style/dart_style.dart';
import 'package:protobuf/protobuf.dart';

import 'const_generator.dart' show writeJsonConst;
import 'indenting_writer.dart';
import 'mixins.dart';
import 'names.dart';
import 'src/code_generator.dart';
import 'src/generated/dart_options.pb.dart';
import 'src/generated/descriptor.pb.dart';
import 'src/generated/plugin.pb.dart';
import 'src/linker.dart';
import 'src/options.dart';
import 'src/output_config.dart';
import 'src/shared.dart';
import 'string_escape.dart';

export 'src/code_generator.dart';

part 'src/base_type.dart';
part 'src/client_generator.dart';
part 'src/enum_generator.dart';
part 'src/extension_generator.dart';
part 'src/file_generator.dart';
part 'src/grpc_generator.dart';
part 'src/message_generator.dart';
part 'src/protobuf_field.dart';
part 'src/service_generator.dart';
part 'src/well_known_types.dart';
