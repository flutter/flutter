// ignore_for_file: avoid_returning_null
// ignore_for_file: camel_case_types
// ignore_for_file: cascade_invocations
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: unnecessary_string_interpolations
// ignore_for_file: unused_local_variable

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:googleapis/vectortile/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.int> buildUnnamed1637() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1637(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.int> buildUnnamed1638() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1638(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.int> buildUnnamed1639() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1639(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterArea = 0;
api.Area buildArea() {
  var o = api.Area();
  buildCounterArea++;
  if (buildCounterArea < 3) {
    o.basemapZOrder = buildBasemapZOrder();
    o.hasExternalEdges = true;
    o.internalEdges = buildUnnamed1637();
    o.loopBreaks = buildUnnamed1638();
    o.triangleIndices = buildUnnamed1639();
    o.type = 'foo';
    o.vertexOffsets = buildVertex2DList();
    o.zOrder = 42;
  }
  buildCounterArea--;
  return o;
}

void checkArea(api.Area o) {
  buildCounterArea++;
  if (buildCounterArea < 3) {
    checkBasemapZOrder(o.basemapZOrder! as api.BasemapZOrder);
    unittest.expect(o.hasExternalEdges!, unittest.isTrue);
    checkUnnamed1637(o.internalEdges!);
    checkUnnamed1638(o.loopBreaks!);
    checkUnnamed1639(o.triangleIndices!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkVertex2DList(o.vertexOffsets! as api.Vertex2DList);
    unittest.expect(
      o.zOrder!,
      unittest.equals(42),
    );
  }
  buildCounterArea--;
}

core.int buildCounterBasemapZOrder = 0;
api.BasemapZOrder buildBasemapZOrder() {
  var o = api.BasemapZOrder();
  buildCounterBasemapZOrder++;
  if (buildCounterBasemapZOrder < 3) {
    o.zGrade = 42;
    o.zPlane = 42;
    o.zWithinGrade = 42;
  }
  buildCounterBasemapZOrder--;
  return o;
}

void checkBasemapZOrder(api.BasemapZOrder o) {
  buildCounterBasemapZOrder++;
  if (buildCounterBasemapZOrder < 3) {
    unittest.expect(
      o.zGrade!,
      unittest.equals(42),
    );
    unittest.expect(
      o.zPlane!,
      unittest.equals(42),
    );
    unittest.expect(
      o.zWithinGrade!,
      unittest.equals(42),
    );
  }
  buildCounterBasemapZOrder--;
}

core.int buildCounterExtrudedArea = 0;
api.ExtrudedArea buildExtrudedArea() {
  var o = api.ExtrudedArea();
  buildCounterExtrudedArea++;
  if (buildCounterExtrudedArea < 3) {
    o.area = buildArea();
    o.maxZ = 42;
    o.minZ = 42;
  }
  buildCounterExtrudedArea--;
  return o;
}

void checkExtrudedArea(api.ExtrudedArea o) {
  buildCounterExtrudedArea++;
  if (buildCounterExtrudedArea < 3) {
    checkArea(o.area! as api.Area);
    unittest.expect(
      o.maxZ!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minZ!,
      unittest.equals(42),
    );
  }
  buildCounterExtrudedArea--;
}

core.List<api.Relation> buildUnnamed1640() {
  var o = <api.Relation>[];
  o.add(buildRelation());
  o.add(buildRelation());
  return o;
}

void checkUnnamed1640(core.List<api.Relation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRelation(o[0] as api.Relation);
  checkRelation(o[1] as api.Relation);
}

core.int buildCounterFeature = 0;
api.Feature buildFeature() {
  var o = api.Feature();
  buildCounterFeature++;
  if (buildCounterFeature < 3) {
    o.displayName = 'foo';
    o.geometry = buildGeometry();
    o.placeId = 'foo';
    o.relations = buildUnnamed1640();
    o.segmentInfo = buildSegmentInfo();
    o.type = 'foo';
  }
  buildCounterFeature--;
  return o;
}

void checkFeature(api.Feature o) {
  buildCounterFeature++;
  if (buildCounterFeature < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkGeometry(o.geometry! as api.Geometry);
    unittest.expect(
      o.placeId!,
      unittest.equals('foo'),
    );
    checkUnnamed1640(o.relations!);
    checkSegmentInfo(o.segmentInfo! as api.SegmentInfo);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterFeature--;
}

core.List<api.Feature> buildUnnamed1641() {
  var o = <api.Feature>[];
  o.add(buildFeature());
  o.add(buildFeature());
  return o;
}

void checkUnnamed1641(core.List<api.Feature> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFeature(o[0] as api.Feature);
  checkFeature(o[1] as api.Feature);
}

core.List<api.ProviderInfo> buildUnnamed1642() {
  var o = <api.ProviderInfo>[];
  o.add(buildProviderInfo());
  o.add(buildProviderInfo());
  return o;
}

void checkUnnamed1642(core.List<api.ProviderInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProviderInfo(o[0] as api.ProviderInfo);
  checkProviderInfo(o[1] as api.ProviderInfo);
}

core.int buildCounterFeatureTile = 0;
api.FeatureTile buildFeatureTile() {
  var o = api.FeatureTile();
  buildCounterFeatureTile++;
  if (buildCounterFeatureTile < 3) {
    o.coordinates = buildTileCoordinates();
    o.features = buildUnnamed1641();
    o.name = 'foo';
    o.providers = buildUnnamed1642();
    o.status = 'foo';
    o.versionId = 'foo';
  }
  buildCounterFeatureTile--;
  return o;
}

void checkFeatureTile(api.FeatureTile o) {
  buildCounterFeatureTile++;
  if (buildCounterFeatureTile < 3) {
    checkTileCoordinates(o.coordinates! as api.TileCoordinates);
    checkUnnamed1641(o.features!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed1642(o.providers!);
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterFeatureTile--;
}

core.List<api.Row> buildUnnamed1643() {
  var o = <api.Row>[];
  o.add(buildRow());
  o.add(buildRow());
  return o;
}

void checkUnnamed1643(core.List<api.Row> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRow(o[0] as api.Row);
  checkRow(o[1] as api.Row);
}

core.int buildCounterFirstDerivativeElevationGrid = 0;
api.FirstDerivativeElevationGrid buildFirstDerivativeElevationGrid() {
  var o = api.FirstDerivativeElevationGrid();
  buildCounterFirstDerivativeElevationGrid++;
  if (buildCounterFirstDerivativeElevationGrid < 3) {
    o.altitudeMultiplier = 42.0;
    o.rows = buildUnnamed1643();
  }
  buildCounterFirstDerivativeElevationGrid--;
  return o;
}

void checkFirstDerivativeElevationGrid(api.FirstDerivativeElevationGrid o) {
  buildCounterFirstDerivativeElevationGrid++;
  if (buildCounterFirstDerivativeElevationGrid < 3) {
    unittest.expect(
      o.altitudeMultiplier!,
      unittest.equals(42.0),
    );
    checkUnnamed1643(o.rows!);
  }
  buildCounterFirstDerivativeElevationGrid--;
}

core.List<api.Area> buildUnnamed1644() {
  var o = <api.Area>[];
  o.add(buildArea());
  o.add(buildArea());
  return o;
}

void checkUnnamed1644(core.List<api.Area> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkArea(o[0] as api.Area);
  checkArea(o[1] as api.Area);
}

core.List<api.ExtrudedArea> buildUnnamed1645() {
  var o = <api.ExtrudedArea>[];
  o.add(buildExtrudedArea());
  o.add(buildExtrudedArea());
  return o;
}

void checkUnnamed1645(core.List<api.ExtrudedArea> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExtrudedArea(o[0] as api.ExtrudedArea);
  checkExtrudedArea(o[1] as api.ExtrudedArea);
}

core.List<api.Line> buildUnnamed1646() {
  var o = <api.Line>[];
  o.add(buildLine());
  o.add(buildLine());
  return o;
}

void checkUnnamed1646(core.List<api.Line> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLine(o[0] as api.Line);
  checkLine(o[1] as api.Line);
}

core.List<api.ModeledVolume> buildUnnamed1647() {
  var o = <api.ModeledVolume>[];
  o.add(buildModeledVolume());
  o.add(buildModeledVolume());
  return o;
}

void checkUnnamed1647(core.List<api.ModeledVolume> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkModeledVolume(o[0] as api.ModeledVolume);
  checkModeledVolume(o[1] as api.ModeledVolume);
}

core.int buildCounterGeometry = 0;
api.Geometry buildGeometry() {
  var o = api.Geometry();
  buildCounterGeometry++;
  if (buildCounterGeometry < 3) {
    o.areas = buildUnnamed1644();
    o.extrudedAreas = buildUnnamed1645();
    o.lines = buildUnnamed1646();
    o.modeledVolumes = buildUnnamed1647();
  }
  buildCounterGeometry--;
  return o;
}

void checkGeometry(api.Geometry o) {
  buildCounterGeometry++;
  if (buildCounterGeometry < 3) {
    checkUnnamed1644(o.areas!);
    checkUnnamed1645(o.extrudedAreas!);
    checkUnnamed1646(o.lines!);
    checkUnnamed1647(o.modeledVolumes!);
  }
  buildCounterGeometry--;
}

core.int buildCounterLine = 0;
api.Line buildLine() {
  var o = api.Line();
  buildCounterLine++;
  if (buildCounterLine < 3) {
    o.basemapZOrder = buildBasemapZOrder();
    o.vertexOffsets = buildVertex2DList();
    o.zOrder = 42;
  }
  buildCounterLine--;
  return o;
}

void checkLine(api.Line o) {
  buildCounterLine++;
  if (buildCounterLine < 3) {
    checkBasemapZOrder(o.basemapZOrder! as api.BasemapZOrder);
    checkVertex2DList(o.vertexOffsets! as api.Vertex2DList);
    unittest.expect(
      o.zOrder!,
      unittest.equals(42),
    );
  }
  buildCounterLine--;
}

core.List<api.TriangleStrip> buildUnnamed1648() {
  var o = <api.TriangleStrip>[];
  o.add(buildTriangleStrip());
  o.add(buildTriangleStrip());
  return o;
}

void checkUnnamed1648(core.List<api.TriangleStrip> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTriangleStrip(o[0] as api.TriangleStrip);
  checkTriangleStrip(o[1] as api.TriangleStrip);
}

core.int buildCounterModeledVolume = 0;
api.ModeledVolume buildModeledVolume() {
  var o = api.ModeledVolume();
  buildCounterModeledVolume++;
  if (buildCounterModeledVolume < 3) {
    o.strips = buildUnnamed1648();
    o.vertexOffsets = buildVertex3DList();
  }
  buildCounterModeledVolume--;
  return o;
}

void checkModeledVolume(api.ModeledVolume o) {
  buildCounterModeledVolume++;
  if (buildCounterModeledVolume < 3) {
    checkUnnamed1648(o.strips!);
    checkVertex3DList(o.vertexOffsets! as api.Vertex3DList);
  }
  buildCounterModeledVolume--;
}

core.int buildCounterProviderInfo = 0;
api.ProviderInfo buildProviderInfo() {
  var o = api.ProviderInfo();
  buildCounterProviderInfo++;
  if (buildCounterProviderInfo < 3) {
    o.description = 'foo';
  }
  buildCounterProviderInfo--;
  return o;
}

void checkProviderInfo(api.ProviderInfo o) {
  buildCounterProviderInfo++;
  if (buildCounterProviderInfo < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
  }
  buildCounterProviderInfo--;
}

core.int buildCounterRelation = 0;
api.Relation buildRelation() {
  var o = api.Relation();
  buildCounterRelation++;
  if (buildCounterRelation < 3) {
    o.relatedFeatureIndex = 42;
    o.relationType = 'foo';
  }
  buildCounterRelation--;
  return o;
}

void checkRelation(api.Relation o) {
  buildCounterRelation++;
  if (buildCounterRelation < 3) {
    unittest.expect(
      o.relatedFeatureIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.relationType!,
      unittest.equals('foo'),
    );
  }
  buildCounterRelation--;
}

core.int buildCounterRoadInfo = 0;
api.RoadInfo buildRoadInfo() {
  var o = api.RoadInfo();
  buildCounterRoadInfo++;
  if (buildCounterRoadInfo < 3) {
    o.isPrivate = true;
  }
  buildCounterRoadInfo--;
  return o;
}

void checkRoadInfo(api.RoadInfo o) {
  buildCounterRoadInfo++;
  if (buildCounterRoadInfo < 3) {
    unittest.expect(o.isPrivate!, unittest.isTrue);
  }
  buildCounterRoadInfo--;
}

core.List<core.int> buildUnnamed1649() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1649(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterRow = 0;
api.Row buildRow() {
  var o = api.Row();
  buildCounterRow++;
  if (buildCounterRow < 3) {
    o.altitudeDiffs = buildUnnamed1649();
  }
  buildCounterRow--;
  return o;
}

void checkRow(api.Row o) {
  buildCounterRow++;
  if (buildCounterRow < 3) {
    checkUnnamed1649(o.altitudeDiffs!);
  }
  buildCounterRow--;
}

core.int buildCounterSecondDerivativeElevationGrid = 0;
api.SecondDerivativeElevationGrid buildSecondDerivativeElevationGrid() {
  var o = api.SecondDerivativeElevationGrid();
  buildCounterSecondDerivativeElevationGrid++;
  if (buildCounterSecondDerivativeElevationGrid < 3) {
    o.altitudeMultiplier = 42.0;
    o.columnCount = 42;
    o.encodedData = 'foo';
    o.rowCount = 42;
  }
  buildCounterSecondDerivativeElevationGrid--;
  return o;
}

void checkSecondDerivativeElevationGrid(api.SecondDerivativeElevationGrid o) {
  buildCounterSecondDerivativeElevationGrid++;
  if (buildCounterSecondDerivativeElevationGrid < 3) {
    unittest.expect(
      o.altitudeMultiplier!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.columnCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.encodedData!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rowCount!,
      unittest.equals(42),
    );
  }
  buildCounterSecondDerivativeElevationGrid--;
}

core.int buildCounterSegmentInfo = 0;
api.SegmentInfo buildSegmentInfo() {
  var o = api.SegmentInfo();
  buildCounterSegmentInfo++;
  if (buildCounterSegmentInfo < 3) {
    o.roadInfo = buildRoadInfo();
  }
  buildCounterSegmentInfo--;
  return o;
}

void checkSegmentInfo(api.SegmentInfo o) {
  buildCounterSegmentInfo++;
  if (buildCounterSegmentInfo < 3) {
    checkRoadInfo(o.roadInfo! as api.RoadInfo);
  }
  buildCounterSegmentInfo--;
}

core.int buildCounterTerrainTile = 0;
api.TerrainTile buildTerrainTile() {
  var o = api.TerrainTile();
  buildCounterTerrainTile++;
  if (buildCounterTerrainTile < 3) {
    o.coordinates = buildTileCoordinates();
    o.firstDerivative = buildFirstDerivativeElevationGrid();
    o.name = 'foo';
    o.secondDerivative = buildSecondDerivativeElevationGrid();
  }
  buildCounterTerrainTile--;
  return o;
}

void checkTerrainTile(api.TerrainTile o) {
  buildCounterTerrainTile++;
  if (buildCounterTerrainTile < 3) {
    checkTileCoordinates(o.coordinates! as api.TileCoordinates);
    checkFirstDerivativeElevationGrid(
        o.firstDerivative! as api.FirstDerivativeElevationGrid);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkSecondDerivativeElevationGrid(
        o.secondDerivative! as api.SecondDerivativeElevationGrid);
  }
  buildCounterTerrainTile--;
}

core.int buildCounterTileCoordinates = 0;
api.TileCoordinates buildTileCoordinates() {
  var o = api.TileCoordinates();
  buildCounterTileCoordinates++;
  if (buildCounterTileCoordinates < 3) {
    o.x = 42;
    o.y = 42;
    o.zoom = 42;
  }
  buildCounterTileCoordinates--;
  return o;
}

void checkTileCoordinates(api.TileCoordinates o) {
  buildCounterTileCoordinates++;
  if (buildCounterTileCoordinates < 3) {
    unittest.expect(
      o.x!,
      unittest.equals(42),
    );
    unittest.expect(
      o.y!,
      unittest.equals(42),
    );
    unittest.expect(
      o.zoom!,
      unittest.equals(42),
    );
  }
  buildCounterTileCoordinates--;
}

core.List<core.int> buildUnnamed1650() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1650(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterTriangleStrip = 0;
api.TriangleStrip buildTriangleStrip() {
  var o = api.TriangleStrip();
  buildCounterTriangleStrip++;
  if (buildCounterTriangleStrip < 3) {
    o.vertexIndices = buildUnnamed1650();
  }
  buildCounterTriangleStrip--;
  return o;
}

void checkTriangleStrip(api.TriangleStrip o) {
  buildCounterTriangleStrip++;
  if (buildCounterTriangleStrip < 3) {
    checkUnnamed1650(o.vertexIndices!);
  }
  buildCounterTriangleStrip--;
}

core.List<core.int> buildUnnamed1651() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1651(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.int> buildUnnamed1652() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1652(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterVertex2DList = 0;
api.Vertex2DList buildVertex2DList() {
  var o = api.Vertex2DList();
  buildCounterVertex2DList++;
  if (buildCounterVertex2DList < 3) {
    o.xOffsets = buildUnnamed1651();
    o.yOffsets = buildUnnamed1652();
  }
  buildCounterVertex2DList--;
  return o;
}

void checkVertex2DList(api.Vertex2DList o) {
  buildCounterVertex2DList++;
  if (buildCounterVertex2DList < 3) {
    checkUnnamed1651(o.xOffsets!);
    checkUnnamed1652(o.yOffsets!);
  }
  buildCounterVertex2DList--;
}

core.List<core.int> buildUnnamed1653() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1653(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.int> buildUnnamed1654() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1654(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.int> buildUnnamed1655() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1655(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterVertex3DList = 0;
api.Vertex3DList buildVertex3DList() {
  var o = api.Vertex3DList();
  buildCounterVertex3DList++;
  if (buildCounterVertex3DList < 3) {
    o.xOffsets = buildUnnamed1653();
    o.yOffsets = buildUnnamed1654();
    o.zOffsets = buildUnnamed1655();
  }
  buildCounterVertex3DList--;
  return o;
}

void checkVertex3DList(api.Vertex3DList o) {
  buildCounterVertex3DList++;
  if (buildCounterVertex3DList < 3) {
    checkUnnamed1653(o.xOffsets!);
    checkUnnamed1654(o.yOffsets!);
    checkUnnamed1655(o.zOffsets!);
  }
  buildCounterVertex3DList--;
}

core.List<core.String> buildUnnamed1656() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1656(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

void main() {
  unittest.group('obj-schema-Area', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArea();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Area.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkArea(od as api.Area);
    });
  });

  unittest.group('obj-schema-BasemapZOrder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasemapZOrder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasemapZOrder.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasemapZOrder(od as api.BasemapZOrder);
    });
  });

  unittest.group('obj-schema-ExtrudedArea', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExtrudedArea();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExtrudedArea.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExtrudedArea(od as api.ExtrudedArea);
    });
  });

  unittest.group('obj-schema-Feature', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeature();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Feature.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFeature(od as api.Feature);
    });
  });

  unittest.group('obj-schema-FeatureTile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatureTile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeatureTile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeatureTile(od as api.FeatureTile);
    });
  });

  unittest.group('obj-schema-FirstDerivativeElevationGrid', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFirstDerivativeElevationGrid();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FirstDerivativeElevationGrid.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFirstDerivativeElevationGrid(od as api.FirstDerivativeElevationGrid);
    });
  });

  unittest.group('obj-schema-Geometry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGeometry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Geometry.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGeometry(od as api.Geometry);
    });
  });

  unittest.group('obj-schema-Line', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLine();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Line.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLine(od as api.Line);
    });
  });

  unittest.group('obj-schema-ModeledVolume', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModeledVolume();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModeledVolume.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModeledVolume(od as api.ModeledVolume);
    });
  });

  unittest.group('obj-schema-ProviderInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProviderInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProviderInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProviderInfo(od as api.ProviderInfo);
    });
  });

  unittest.group('obj-schema-Relation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRelation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Relation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRelation(od as api.Relation);
    });
  });

  unittest.group('obj-schema-RoadInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoadInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RoadInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRoadInfo(od as api.RoadInfo);
    });
  });

  unittest.group('obj-schema-Row', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Row.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRow(od as api.Row);
    });
  });

  unittest.group('obj-schema-SecondDerivativeElevationGrid', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecondDerivativeElevationGrid();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SecondDerivativeElevationGrid.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSecondDerivativeElevationGrid(
          od as api.SecondDerivativeElevationGrid);
    });
  });

  unittest.group('obj-schema-SegmentInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegmentInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SegmentInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSegmentInfo(od as api.SegmentInfo);
    });
  });

  unittest.group('obj-schema-TerrainTile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTerrainTile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TerrainTile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTerrainTile(od as api.TerrainTile);
    });
  });

  unittest.group('obj-schema-TileCoordinates', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTileCoordinates();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TileCoordinates.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTileCoordinates(od as api.TileCoordinates);
    });
  });

  unittest.group('obj-schema-TriangleStrip', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTriangleStrip();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TriangleStrip.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTriangleStrip(od as api.TriangleStrip);
    });
  });

  unittest.group('obj-schema-Vertex2DList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVertex2DList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Vertex2DList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVertex2DList(od as api.Vertex2DList);
    });
  });

  unittest.group('obj-schema-Vertex3DList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVertex3DList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Vertex3DList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVertex3DList(od as api.Vertex3DList);
    });
  });

  unittest.group('resource-FeaturetilesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SemanticTileApi(mock).featuretiles;
      var arg_name = 'foo';
      var arg_alwaysIncludeBuildingFootprints = true;
      var arg_clientInfo_apiClient = 'foo';
      var arg_clientInfo_applicationId = 'foo';
      var arg_clientInfo_applicationVersion = 'foo';
      var arg_clientInfo_deviceModel = 'foo';
      var arg_clientInfo_operatingSystem = 'foo';
      var arg_clientInfo_platform = 'foo';
      var arg_clientInfo_userId = 'foo';
      var arg_clientTileVersionId = 'foo';
      var arg_enableDetailedHighwayTypes = true;
      var arg_enableFeatureNames = true;
      var arg_enableModeledVolumes = true;
      var arg_enablePoliticalFeatures = true;
      var arg_enablePrivateRoads = true;
      var arg_enableUnclippedBuildings = true;
      var arg_languageCode = 'foo';
      var arg_regionCode = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["alwaysIncludeBuildingFootprints"]!.first,
          unittest.equals("$arg_alwaysIncludeBuildingFootprints"),
        );
        unittest.expect(
          queryMap["clientInfo.apiClient"]!.first,
          unittest.equals(arg_clientInfo_apiClient),
        );
        unittest.expect(
          queryMap["clientInfo.applicationId"]!.first,
          unittest.equals(arg_clientInfo_applicationId),
        );
        unittest.expect(
          queryMap["clientInfo.applicationVersion"]!.first,
          unittest.equals(arg_clientInfo_applicationVersion),
        );
        unittest.expect(
          queryMap["clientInfo.deviceModel"]!.first,
          unittest.equals(arg_clientInfo_deviceModel),
        );
        unittest.expect(
          queryMap["clientInfo.operatingSystem"]!.first,
          unittest.equals(arg_clientInfo_operatingSystem),
        );
        unittest.expect(
          queryMap["clientInfo.platform"]!.first,
          unittest.equals(arg_clientInfo_platform),
        );
        unittest.expect(
          queryMap["clientInfo.userId"]!.first,
          unittest.equals(arg_clientInfo_userId),
        );
        unittest.expect(
          queryMap["clientTileVersionId"]!.first,
          unittest.equals(arg_clientTileVersionId),
        );
        unittest.expect(
          queryMap["enableDetailedHighwayTypes"]!.first,
          unittest.equals("$arg_enableDetailedHighwayTypes"),
        );
        unittest.expect(
          queryMap["enableFeatureNames"]!.first,
          unittest.equals("$arg_enableFeatureNames"),
        );
        unittest.expect(
          queryMap["enableModeledVolumes"]!.first,
          unittest.equals("$arg_enableModeledVolumes"),
        );
        unittest.expect(
          queryMap["enablePoliticalFeatures"]!.first,
          unittest.equals("$arg_enablePoliticalFeatures"),
        );
        unittest.expect(
          queryMap["enablePrivateRoads"]!.first,
          unittest.equals("$arg_enablePrivateRoads"),
        );
        unittest.expect(
          queryMap["enableUnclippedBuildings"]!.first,
          unittest.equals("$arg_enableUnclippedBuildings"),
        );
        unittest.expect(
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          queryMap["regionCode"]!.first,
          unittest.equals(arg_regionCode),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFeatureTile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          alwaysIncludeBuildingFootprints: arg_alwaysIncludeBuildingFootprints,
          clientInfo_apiClient: arg_clientInfo_apiClient,
          clientInfo_applicationId: arg_clientInfo_applicationId,
          clientInfo_applicationVersion: arg_clientInfo_applicationVersion,
          clientInfo_deviceModel: arg_clientInfo_deviceModel,
          clientInfo_operatingSystem: arg_clientInfo_operatingSystem,
          clientInfo_platform: arg_clientInfo_platform,
          clientInfo_userId: arg_clientInfo_userId,
          clientTileVersionId: arg_clientTileVersionId,
          enableDetailedHighwayTypes: arg_enableDetailedHighwayTypes,
          enableFeatureNames: arg_enableFeatureNames,
          enableModeledVolumes: arg_enableModeledVolumes,
          enablePoliticalFeatures: arg_enablePoliticalFeatures,
          enablePrivateRoads: arg_enablePrivateRoads,
          enableUnclippedBuildings: arg_enableUnclippedBuildings,
          languageCode: arg_languageCode,
          regionCode: arg_regionCode,
          $fields: arg_$fields);
      checkFeatureTile(response as api.FeatureTile);
    });
  });

  unittest.group('resource-TerraintilesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SemanticTileApi(mock).terraintiles;
      var arg_name = 'foo';
      var arg_altitudePrecisionCentimeters = 42;
      var arg_clientInfo_apiClient = 'foo';
      var arg_clientInfo_applicationId = 'foo';
      var arg_clientInfo_applicationVersion = 'foo';
      var arg_clientInfo_deviceModel = 'foo';
      var arg_clientInfo_operatingSystem = 'foo';
      var arg_clientInfo_platform = 'foo';
      var arg_clientInfo_userId = 'foo';
      var arg_maxElevationResolutionCells = 42;
      var arg_minElevationResolutionCells = 42;
      var arg_terrainFormats = buildUnnamed1656();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          core.int.parse(queryMap["altitudePrecisionCentimeters"]!.first),
          unittest.equals(arg_altitudePrecisionCentimeters),
        );
        unittest.expect(
          queryMap["clientInfo.apiClient"]!.first,
          unittest.equals(arg_clientInfo_apiClient),
        );
        unittest.expect(
          queryMap["clientInfo.applicationId"]!.first,
          unittest.equals(arg_clientInfo_applicationId),
        );
        unittest.expect(
          queryMap["clientInfo.applicationVersion"]!.first,
          unittest.equals(arg_clientInfo_applicationVersion),
        );
        unittest.expect(
          queryMap["clientInfo.deviceModel"]!.first,
          unittest.equals(arg_clientInfo_deviceModel),
        );
        unittest.expect(
          queryMap["clientInfo.operatingSystem"]!.first,
          unittest.equals(arg_clientInfo_operatingSystem),
        );
        unittest.expect(
          queryMap["clientInfo.platform"]!.first,
          unittest.equals(arg_clientInfo_platform),
        );
        unittest.expect(
          queryMap["clientInfo.userId"]!.first,
          unittest.equals(arg_clientInfo_userId),
        );
        unittest.expect(
          core.int.parse(queryMap["maxElevationResolutionCells"]!.first),
          unittest.equals(arg_maxElevationResolutionCells),
        );
        unittest.expect(
          core.int.parse(queryMap["minElevationResolutionCells"]!.first),
          unittest.equals(arg_minElevationResolutionCells),
        );
        unittest.expect(
          queryMap["terrainFormats"]!,
          unittest.equals(arg_terrainFormats),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTerrainTile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          altitudePrecisionCentimeters: arg_altitudePrecisionCentimeters,
          clientInfo_apiClient: arg_clientInfo_apiClient,
          clientInfo_applicationId: arg_clientInfo_applicationId,
          clientInfo_applicationVersion: arg_clientInfo_applicationVersion,
          clientInfo_deviceModel: arg_clientInfo_deviceModel,
          clientInfo_operatingSystem: arg_clientInfo_operatingSystem,
          clientInfo_platform: arg_clientInfo_platform,
          clientInfo_userId: arg_clientInfo_userId,
          maxElevationResolutionCells: arg_maxElevationResolutionCells,
          minElevationResolutionCells: arg_minElevationResolutionCells,
          terrainFormats: arg_terrainFormats,
          $fields: arg_$fields);
      checkTerrainTile(response as api.TerrainTile);
    });
  });
}
