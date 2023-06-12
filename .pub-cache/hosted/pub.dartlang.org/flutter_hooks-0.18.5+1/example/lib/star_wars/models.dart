// ignore_for_file: public_member_api_docs

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:meta/meta.dart';

part 'models.g.dart';

/// json serializer to build models
@SerializersFor([
  PlanetPageModel,
  PlanetModel,
])
final Serializers serializers =
    (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

@immutable
abstract class PlanetPageModel
    implements Built<PlanetPageModel, PlanetPageModelBuilder> {
  factory PlanetPageModel([
    void Function(PlanetPageModelBuilder) updates,
  ]) = _$PlanetPageModel;

  const PlanetPageModel._();

  static Serializer<PlanetPageModel> get serializer =>
      _$planetPageModelSerializer;

  @nullable
  String get next;

  @nullable
  String get previous;

  BuiltList<PlanetModel> get results;
}

@immutable
abstract class PlanetModel implements Built<PlanetModel, PlanetModelBuilder> {
  factory PlanetModel([
    void Function(PlanetModelBuilder) updates,
  ]) = _$PlanetModel;

  const PlanetModel._();

  static Serializer<PlanetModel> get serializer => _$planetModelSerializer;

  String get name;
}
