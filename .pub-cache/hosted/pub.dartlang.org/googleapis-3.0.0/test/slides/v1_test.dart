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

import 'package:googleapis/slides/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAffineTransform = 0;
api.AffineTransform buildAffineTransform() {
  var o = api.AffineTransform();
  buildCounterAffineTransform++;
  if (buildCounterAffineTransform < 3) {
    o.scaleX = 42.0;
    o.scaleY = 42.0;
    o.shearX = 42.0;
    o.shearY = 42.0;
    o.translateX = 42.0;
    o.translateY = 42.0;
    o.unit = 'foo';
  }
  buildCounterAffineTransform--;
  return o;
}

void checkAffineTransform(api.AffineTransform o) {
  buildCounterAffineTransform++;
  if (buildCounterAffineTransform < 3) {
    unittest.expect(
      o.scaleX!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.scaleY!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.shearX!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.shearY!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.translateX!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.translateY!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.unit!,
      unittest.equals('foo'),
    );
  }
  buildCounterAffineTransform--;
}

core.int buildCounterAutoText = 0;
api.AutoText buildAutoText() {
  var o = api.AutoText();
  buildCounterAutoText++;
  if (buildCounterAutoText < 3) {
    o.content = 'foo';
    o.style = buildTextStyle();
    o.type = 'foo';
  }
  buildCounterAutoText--;
  return o;
}

void checkAutoText(api.AutoText o) {
  buildCounterAutoText++;
  if (buildCounterAutoText < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    checkTextStyle(o.style! as api.TextStyle);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAutoText--;
}

core.int buildCounterAutofit = 0;
api.Autofit buildAutofit() {
  var o = api.Autofit();
  buildCounterAutofit++;
  if (buildCounterAutofit < 3) {
    o.autofitType = 'foo';
    o.fontScale = 42.0;
    o.lineSpacingReduction = 42.0;
  }
  buildCounterAutofit--;
  return o;
}

void checkAutofit(api.Autofit o) {
  buildCounterAutofit++;
  if (buildCounterAutofit < 3) {
    unittest.expect(
      o.autofitType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fontScale!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.lineSpacingReduction!,
      unittest.equals(42.0),
    );
  }
  buildCounterAutofit--;
}

core.List<api.Request> buildUnnamed2507() {
  var o = <api.Request>[];
  o.add(buildRequest());
  o.add(buildRequest());
  return o;
}

void checkUnnamed2507(core.List<api.Request> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRequest(o[0] as api.Request);
  checkRequest(o[1] as api.Request);
}

core.int buildCounterBatchUpdatePresentationRequest = 0;
api.BatchUpdatePresentationRequest buildBatchUpdatePresentationRequest() {
  var o = api.BatchUpdatePresentationRequest();
  buildCounterBatchUpdatePresentationRequest++;
  if (buildCounterBatchUpdatePresentationRequest < 3) {
    o.requests = buildUnnamed2507();
    o.writeControl = buildWriteControl();
  }
  buildCounterBatchUpdatePresentationRequest--;
  return o;
}

void checkBatchUpdatePresentationRequest(api.BatchUpdatePresentationRequest o) {
  buildCounterBatchUpdatePresentationRequest++;
  if (buildCounterBatchUpdatePresentationRequest < 3) {
    checkUnnamed2507(o.requests!);
    checkWriteControl(o.writeControl! as api.WriteControl);
  }
  buildCounterBatchUpdatePresentationRequest--;
}

core.List<api.Response> buildUnnamed2508() {
  var o = <api.Response>[];
  o.add(buildResponse());
  o.add(buildResponse());
  return o;
}

void checkUnnamed2508(core.List<api.Response> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResponse(o[0] as api.Response);
  checkResponse(o[1] as api.Response);
}

core.int buildCounterBatchUpdatePresentationResponse = 0;
api.BatchUpdatePresentationResponse buildBatchUpdatePresentationResponse() {
  var o = api.BatchUpdatePresentationResponse();
  buildCounterBatchUpdatePresentationResponse++;
  if (buildCounterBatchUpdatePresentationResponse < 3) {
    o.presentationId = 'foo';
    o.replies = buildUnnamed2508();
    o.writeControl = buildWriteControl();
  }
  buildCounterBatchUpdatePresentationResponse--;
  return o;
}

void checkBatchUpdatePresentationResponse(
    api.BatchUpdatePresentationResponse o) {
  buildCounterBatchUpdatePresentationResponse++;
  if (buildCounterBatchUpdatePresentationResponse < 3) {
    unittest.expect(
      o.presentationId!,
      unittest.equals('foo'),
    );
    checkUnnamed2508(o.replies!);
    checkWriteControl(o.writeControl! as api.WriteControl);
  }
  buildCounterBatchUpdatePresentationResponse--;
}

core.int buildCounterBullet = 0;
api.Bullet buildBullet() {
  var o = api.Bullet();
  buildCounterBullet++;
  if (buildCounterBullet < 3) {
    o.bulletStyle = buildTextStyle();
    o.glyph = 'foo';
    o.listId = 'foo';
    o.nestingLevel = 42;
  }
  buildCounterBullet--;
  return o;
}

void checkBullet(api.Bullet o) {
  buildCounterBullet++;
  if (buildCounterBullet < 3) {
    checkTextStyle(o.bulletStyle! as api.TextStyle);
    unittest.expect(
      o.glyph!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.listId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nestingLevel!,
      unittest.equals(42),
    );
  }
  buildCounterBullet--;
}

core.List<api.ThemeColorPair> buildUnnamed2509() {
  var o = <api.ThemeColorPair>[];
  o.add(buildThemeColorPair());
  o.add(buildThemeColorPair());
  return o;
}

void checkUnnamed2509(core.List<api.ThemeColorPair> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkThemeColorPair(o[0] as api.ThemeColorPair);
  checkThemeColorPair(o[1] as api.ThemeColorPair);
}

core.int buildCounterColorScheme = 0;
api.ColorScheme buildColorScheme() {
  var o = api.ColorScheme();
  buildCounterColorScheme++;
  if (buildCounterColorScheme < 3) {
    o.colors = buildUnnamed2509();
  }
  buildCounterColorScheme--;
  return o;
}

void checkColorScheme(api.ColorScheme o) {
  buildCounterColorScheme++;
  if (buildCounterColorScheme < 3) {
    checkUnnamed2509(o.colors!);
  }
  buildCounterColorScheme--;
}

core.int buildCounterColorStop = 0;
api.ColorStop buildColorStop() {
  var o = api.ColorStop();
  buildCounterColorStop++;
  if (buildCounterColorStop < 3) {
    o.alpha = 42.0;
    o.color = buildOpaqueColor();
    o.position = 42.0;
  }
  buildCounterColorStop--;
  return o;
}

void checkColorStop(api.ColorStop o) {
  buildCounterColorStop++;
  if (buildCounterColorStop < 3) {
    unittest.expect(
      o.alpha!,
      unittest.equals(42.0),
    );
    checkOpaqueColor(o.color! as api.OpaqueColor);
    unittest.expect(
      o.position!,
      unittest.equals(42.0),
    );
  }
  buildCounterColorStop--;
}

core.int buildCounterCreateImageRequest = 0;
api.CreateImageRequest buildCreateImageRequest() {
  var o = api.CreateImageRequest();
  buildCounterCreateImageRequest++;
  if (buildCounterCreateImageRequest < 3) {
    o.elementProperties = buildPageElementProperties();
    o.objectId = 'foo';
    o.url = 'foo';
  }
  buildCounterCreateImageRequest--;
  return o;
}

void checkCreateImageRequest(api.CreateImageRequest o) {
  buildCounterCreateImageRequest++;
  if (buildCounterCreateImageRequest < 3) {
    checkPageElementProperties(
        o.elementProperties! as api.PageElementProperties);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateImageRequest--;
}

core.int buildCounterCreateImageResponse = 0;
api.CreateImageResponse buildCreateImageResponse() {
  var o = api.CreateImageResponse();
  buildCounterCreateImageResponse++;
  if (buildCounterCreateImageResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterCreateImageResponse--;
  return o;
}

void checkCreateImageResponse(api.CreateImageResponse o) {
  buildCounterCreateImageResponse++;
  if (buildCounterCreateImageResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateImageResponse--;
}

core.int buildCounterCreateLineRequest = 0;
api.CreateLineRequest buildCreateLineRequest() {
  var o = api.CreateLineRequest();
  buildCounterCreateLineRequest++;
  if (buildCounterCreateLineRequest < 3) {
    o.category = 'foo';
    o.elementProperties = buildPageElementProperties();
    o.lineCategory = 'foo';
    o.objectId = 'foo';
  }
  buildCounterCreateLineRequest--;
  return o;
}

void checkCreateLineRequest(api.CreateLineRequest o) {
  buildCounterCreateLineRequest++;
  if (buildCounterCreateLineRequest < 3) {
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    checkPageElementProperties(
        o.elementProperties! as api.PageElementProperties);
    unittest.expect(
      o.lineCategory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateLineRequest--;
}

core.int buildCounterCreateLineResponse = 0;
api.CreateLineResponse buildCreateLineResponse() {
  var o = api.CreateLineResponse();
  buildCounterCreateLineResponse++;
  if (buildCounterCreateLineResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterCreateLineResponse--;
  return o;
}

void checkCreateLineResponse(api.CreateLineResponse o) {
  buildCounterCreateLineResponse++;
  if (buildCounterCreateLineResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateLineResponse--;
}

core.int buildCounterCreateParagraphBulletsRequest = 0;
api.CreateParagraphBulletsRequest buildCreateParagraphBulletsRequest() {
  var o = api.CreateParagraphBulletsRequest();
  buildCounterCreateParagraphBulletsRequest++;
  if (buildCounterCreateParagraphBulletsRequest < 3) {
    o.bulletPreset = 'foo';
    o.cellLocation = buildTableCellLocation();
    o.objectId = 'foo';
    o.textRange = buildRange();
  }
  buildCounterCreateParagraphBulletsRequest--;
  return o;
}

void checkCreateParagraphBulletsRequest(api.CreateParagraphBulletsRequest o) {
  buildCounterCreateParagraphBulletsRequest++;
  if (buildCounterCreateParagraphBulletsRequest < 3) {
    unittest.expect(
      o.bulletPreset!,
      unittest.equals('foo'),
    );
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkRange(o.textRange! as api.Range);
  }
  buildCounterCreateParagraphBulletsRequest--;
}

core.int buildCounterCreateShapeRequest = 0;
api.CreateShapeRequest buildCreateShapeRequest() {
  var o = api.CreateShapeRequest();
  buildCounterCreateShapeRequest++;
  if (buildCounterCreateShapeRequest < 3) {
    o.elementProperties = buildPageElementProperties();
    o.objectId = 'foo';
    o.shapeType = 'foo';
  }
  buildCounterCreateShapeRequest--;
  return o;
}

void checkCreateShapeRequest(api.CreateShapeRequest o) {
  buildCounterCreateShapeRequest++;
  if (buildCounterCreateShapeRequest < 3) {
    checkPageElementProperties(
        o.elementProperties! as api.PageElementProperties);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shapeType!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateShapeRequest--;
}

core.int buildCounterCreateShapeResponse = 0;
api.CreateShapeResponse buildCreateShapeResponse() {
  var o = api.CreateShapeResponse();
  buildCounterCreateShapeResponse++;
  if (buildCounterCreateShapeResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterCreateShapeResponse--;
  return o;
}

void checkCreateShapeResponse(api.CreateShapeResponse o) {
  buildCounterCreateShapeResponse++;
  if (buildCounterCreateShapeResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateShapeResponse--;
}

core.int buildCounterCreateSheetsChartRequest = 0;
api.CreateSheetsChartRequest buildCreateSheetsChartRequest() {
  var o = api.CreateSheetsChartRequest();
  buildCounterCreateSheetsChartRequest++;
  if (buildCounterCreateSheetsChartRequest < 3) {
    o.chartId = 42;
    o.elementProperties = buildPageElementProperties();
    o.linkingMode = 'foo';
    o.objectId = 'foo';
    o.spreadsheetId = 'foo';
  }
  buildCounterCreateSheetsChartRequest--;
  return o;
}

void checkCreateSheetsChartRequest(api.CreateSheetsChartRequest o) {
  buildCounterCreateSheetsChartRequest++;
  if (buildCounterCreateSheetsChartRequest < 3) {
    unittest.expect(
      o.chartId!,
      unittest.equals(42),
    );
    checkPageElementProperties(
        o.elementProperties! as api.PageElementProperties);
    unittest.expect(
      o.linkingMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateSheetsChartRequest--;
}

core.int buildCounterCreateSheetsChartResponse = 0;
api.CreateSheetsChartResponse buildCreateSheetsChartResponse() {
  var o = api.CreateSheetsChartResponse();
  buildCounterCreateSheetsChartResponse++;
  if (buildCounterCreateSheetsChartResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterCreateSheetsChartResponse--;
  return o;
}

void checkCreateSheetsChartResponse(api.CreateSheetsChartResponse o) {
  buildCounterCreateSheetsChartResponse++;
  if (buildCounterCreateSheetsChartResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateSheetsChartResponse--;
}

core.List<api.LayoutPlaceholderIdMapping> buildUnnamed2510() {
  var o = <api.LayoutPlaceholderIdMapping>[];
  o.add(buildLayoutPlaceholderIdMapping());
  o.add(buildLayoutPlaceholderIdMapping());
  return o;
}

void checkUnnamed2510(core.List<api.LayoutPlaceholderIdMapping> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLayoutPlaceholderIdMapping(o[0] as api.LayoutPlaceholderIdMapping);
  checkLayoutPlaceholderIdMapping(o[1] as api.LayoutPlaceholderIdMapping);
}

core.int buildCounterCreateSlideRequest = 0;
api.CreateSlideRequest buildCreateSlideRequest() {
  var o = api.CreateSlideRequest();
  buildCounterCreateSlideRequest++;
  if (buildCounterCreateSlideRequest < 3) {
    o.insertionIndex = 42;
    o.objectId = 'foo';
    o.placeholderIdMappings = buildUnnamed2510();
    o.slideLayoutReference = buildLayoutReference();
  }
  buildCounterCreateSlideRequest--;
  return o;
}

void checkCreateSlideRequest(api.CreateSlideRequest o) {
  buildCounterCreateSlideRequest++;
  if (buildCounterCreateSlideRequest < 3) {
    unittest.expect(
      o.insertionIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkUnnamed2510(o.placeholderIdMappings!);
    checkLayoutReference(o.slideLayoutReference! as api.LayoutReference);
  }
  buildCounterCreateSlideRequest--;
}

core.int buildCounterCreateSlideResponse = 0;
api.CreateSlideResponse buildCreateSlideResponse() {
  var o = api.CreateSlideResponse();
  buildCounterCreateSlideResponse++;
  if (buildCounterCreateSlideResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterCreateSlideResponse--;
  return o;
}

void checkCreateSlideResponse(api.CreateSlideResponse o) {
  buildCounterCreateSlideResponse++;
  if (buildCounterCreateSlideResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateSlideResponse--;
}

core.int buildCounterCreateTableRequest = 0;
api.CreateTableRequest buildCreateTableRequest() {
  var o = api.CreateTableRequest();
  buildCounterCreateTableRequest++;
  if (buildCounterCreateTableRequest < 3) {
    o.columns = 42;
    o.elementProperties = buildPageElementProperties();
    o.objectId = 'foo';
    o.rows = 42;
  }
  buildCounterCreateTableRequest--;
  return o;
}

void checkCreateTableRequest(api.CreateTableRequest o) {
  buildCounterCreateTableRequest++;
  if (buildCounterCreateTableRequest < 3) {
    unittest.expect(
      o.columns!,
      unittest.equals(42),
    );
    checkPageElementProperties(
        o.elementProperties! as api.PageElementProperties);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rows!,
      unittest.equals(42),
    );
  }
  buildCounterCreateTableRequest--;
}

core.int buildCounterCreateTableResponse = 0;
api.CreateTableResponse buildCreateTableResponse() {
  var o = api.CreateTableResponse();
  buildCounterCreateTableResponse++;
  if (buildCounterCreateTableResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterCreateTableResponse--;
  return o;
}

void checkCreateTableResponse(api.CreateTableResponse o) {
  buildCounterCreateTableResponse++;
  if (buildCounterCreateTableResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateTableResponse--;
}

core.int buildCounterCreateVideoRequest = 0;
api.CreateVideoRequest buildCreateVideoRequest() {
  var o = api.CreateVideoRequest();
  buildCounterCreateVideoRequest++;
  if (buildCounterCreateVideoRequest < 3) {
    o.elementProperties = buildPageElementProperties();
    o.id = 'foo';
    o.objectId = 'foo';
    o.source = 'foo';
  }
  buildCounterCreateVideoRequest--;
  return o;
}

void checkCreateVideoRequest(api.CreateVideoRequest o) {
  buildCounterCreateVideoRequest++;
  if (buildCounterCreateVideoRequest < 3) {
    checkPageElementProperties(
        o.elementProperties! as api.PageElementProperties);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.source!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateVideoRequest--;
}

core.int buildCounterCreateVideoResponse = 0;
api.CreateVideoResponse buildCreateVideoResponse() {
  var o = api.CreateVideoResponse();
  buildCounterCreateVideoResponse++;
  if (buildCounterCreateVideoResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterCreateVideoResponse--;
  return o;
}

void checkCreateVideoResponse(api.CreateVideoResponse o) {
  buildCounterCreateVideoResponse++;
  if (buildCounterCreateVideoResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateVideoResponse--;
}

core.int buildCounterCropProperties = 0;
api.CropProperties buildCropProperties() {
  var o = api.CropProperties();
  buildCounterCropProperties++;
  if (buildCounterCropProperties < 3) {
    o.angle = 42.0;
    o.bottomOffset = 42.0;
    o.leftOffset = 42.0;
    o.rightOffset = 42.0;
    o.topOffset = 42.0;
  }
  buildCounterCropProperties--;
  return o;
}

void checkCropProperties(api.CropProperties o) {
  buildCounterCropProperties++;
  if (buildCounterCropProperties < 3) {
    unittest.expect(
      o.angle!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.bottomOffset!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.leftOffset!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.rightOffset!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.topOffset!,
      unittest.equals(42.0),
    );
  }
  buildCounterCropProperties--;
}

core.int buildCounterDeleteObjectRequest = 0;
api.DeleteObjectRequest buildDeleteObjectRequest() {
  var o = api.DeleteObjectRequest();
  buildCounterDeleteObjectRequest++;
  if (buildCounterDeleteObjectRequest < 3) {
    o.objectId = 'foo';
  }
  buildCounterDeleteObjectRequest--;
  return o;
}

void checkDeleteObjectRequest(api.DeleteObjectRequest o) {
  buildCounterDeleteObjectRequest++;
  if (buildCounterDeleteObjectRequest < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteObjectRequest--;
}

core.int buildCounterDeleteParagraphBulletsRequest = 0;
api.DeleteParagraphBulletsRequest buildDeleteParagraphBulletsRequest() {
  var o = api.DeleteParagraphBulletsRequest();
  buildCounterDeleteParagraphBulletsRequest++;
  if (buildCounterDeleteParagraphBulletsRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.objectId = 'foo';
    o.textRange = buildRange();
  }
  buildCounterDeleteParagraphBulletsRequest--;
  return o;
}

void checkDeleteParagraphBulletsRequest(api.DeleteParagraphBulletsRequest o) {
  buildCounterDeleteParagraphBulletsRequest++;
  if (buildCounterDeleteParagraphBulletsRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkRange(o.textRange! as api.Range);
  }
  buildCounterDeleteParagraphBulletsRequest--;
}

core.int buildCounterDeleteTableColumnRequest = 0;
api.DeleteTableColumnRequest buildDeleteTableColumnRequest() {
  var o = api.DeleteTableColumnRequest();
  buildCounterDeleteTableColumnRequest++;
  if (buildCounterDeleteTableColumnRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.tableObjectId = 'foo';
  }
  buildCounterDeleteTableColumnRequest--;
  return o;
}

void checkDeleteTableColumnRequest(api.DeleteTableColumnRequest o) {
  buildCounterDeleteTableColumnRequest++;
  if (buildCounterDeleteTableColumnRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.tableObjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteTableColumnRequest--;
}

core.int buildCounterDeleteTableRowRequest = 0;
api.DeleteTableRowRequest buildDeleteTableRowRequest() {
  var o = api.DeleteTableRowRequest();
  buildCounterDeleteTableRowRequest++;
  if (buildCounterDeleteTableRowRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.tableObjectId = 'foo';
  }
  buildCounterDeleteTableRowRequest--;
  return o;
}

void checkDeleteTableRowRequest(api.DeleteTableRowRequest o) {
  buildCounterDeleteTableRowRequest++;
  if (buildCounterDeleteTableRowRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.tableObjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteTableRowRequest--;
}

core.int buildCounterDeleteTextRequest = 0;
api.DeleteTextRequest buildDeleteTextRequest() {
  var o = api.DeleteTextRequest();
  buildCounterDeleteTextRequest++;
  if (buildCounterDeleteTextRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.objectId = 'foo';
    o.textRange = buildRange();
  }
  buildCounterDeleteTextRequest--;
  return o;
}

void checkDeleteTextRequest(api.DeleteTextRequest o) {
  buildCounterDeleteTextRequest++;
  if (buildCounterDeleteTextRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkRange(o.textRange! as api.Range);
  }
  buildCounterDeleteTextRequest--;
}

core.int buildCounterDimension = 0;
api.Dimension buildDimension() {
  var o = api.Dimension();
  buildCounterDimension++;
  if (buildCounterDimension < 3) {
    o.magnitude = 42.0;
    o.unit = 'foo';
  }
  buildCounterDimension--;
  return o;
}

void checkDimension(api.Dimension o) {
  buildCounterDimension++;
  if (buildCounterDimension < 3) {
    unittest.expect(
      o.magnitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.unit!,
      unittest.equals('foo'),
    );
  }
  buildCounterDimension--;
}

core.Map<core.String, core.String> buildUnnamed2511() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2511(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterDuplicateObjectRequest = 0;
api.DuplicateObjectRequest buildDuplicateObjectRequest() {
  var o = api.DuplicateObjectRequest();
  buildCounterDuplicateObjectRequest++;
  if (buildCounterDuplicateObjectRequest < 3) {
    o.objectId = 'foo';
    o.objectIds = buildUnnamed2511();
  }
  buildCounterDuplicateObjectRequest--;
  return o;
}

void checkDuplicateObjectRequest(api.DuplicateObjectRequest o) {
  buildCounterDuplicateObjectRequest++;
  if (buildCounterDuplicateObjectRequest < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkUnnamed2511(o.objectIds!);
  }
  buildCounterDuplicateObjectRequest--;
}

core.int buildCounterDuplicateObjectResponse = 0;
api.DuplicateObjectResponse buildDuplicateObjectResponse() {
  var o = api.DuplicateObjectResponse();
  buildCounterDuplicateObjectResponse++;
  if (buildCounterDuplicateObjectResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterDuplicateObjectResponse--;
  return o;
}

void checkDuplicateObjectResponse(api.DuplicateObjectResponse o) {
  buildCounterDuplicateObjectResponse++;
  if (buildCounterDuplicateObjectResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDuplicateObjectResponse--;
}

core.List<api.PageElement> buildUnnamed2512() {
  var o = <api.PageElement>[];
  o.add(buildPageElement());
  o.add(buildPageElement());
  return o;
}

void checkUnnamed2512(core.List<api.PageElement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPageElement(o[0] as api.PageElement);
  checkPageElement(o[1] as api.PageElement);
}

core.int buildCounterGroup = 0;
api.Group buildGroup() {
  var o = api.Group();
  buildCounterGroup++;
  if (buildCounterGroup < 3) {
    o.children = buildUnnamed2512();
  }
  buildCounterGroup--;
  return o;
}

void checkGroup(api.Group o) {
  buildCounterGroup++;
  if (buildCounterGroup < 3) {
    checkUnnamed2512(o.children!);
  }
  buildCounterGroup--;
}

core.List<core.String> buildUnnamed2513() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2513(core.List<core.String> o) {
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

core.int buildCounterGroupObjectsRequest = 0;
api.GroupObjectsRequest buildGroupObjectsRequest() {
  var o = api.GroupObjectsRequest();
  buildCounterGroupObjectsRequest++;
  if (buildCounterGroupObjectsRequest < 3) {
    o.childrenObjectIds = buildUnnamed2513();
    o.groupObjectId = 'foo';
  }
  buildCounterGroupObjectsRequest--;
  return o;
}

void checkGroupObjectsRequest(api.GroupObjectsRequest o) {
  buildCounterGroupObjectsRequest++;
  if (buildCounterGroupObjectsRequest < 3) {
    checkUnnamed2513(o.childrenObjectIds!);
    unittest.expect(
      o.groupObjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroupObjectsRequest--;
}

core.int buildCounterGroupObjectsResponse = 0;
api.GroupObjectsResponse buildGroupObjectsResponse() {
  var o = api.GroupObjectsResponse();
  buildCounterGroupObjectsResponse++;
  if (buildCounterGroupObjectsResponse < 3) {
    o.objectId = 'foo';
  }
  buildCounterGroupObjectsResponse--;
  return o;
}

void checkGroupObjectsResponse(api.GroupObjectsResponse o) {
  buildCounterGroupObjectsResponse++;
  if (buildCounterGroupObjectsResponse < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroupObjectsResponse--;
}

core.int buildCounterImage = 0;
api.Image buildImage() {
  var o = api.Image();
  buildCounterImage++;
  if (buildCounterImage < 3) {
    o.contentUrl = 'foo';
    o.imageProperties = buildImageProperties();
    o.sourceUrl = 'foo';
  }
  buildCounterImage--;
  return o;
}

void checkImage(api.Image o) {
  buildCounterImage++;
  if (buildCounterImage < 3) {
    unittest.expect(
      o.contentUrl!,
      unittest.equals('foo'),
    );
    checkImageProperties(o.imageProperties! as api.ImageProperties);
    unittest.expect(
      o.sourceUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterImage--;
}

core.int buildCounterImageProperties = 0;
api.ImageProperties buildImageProperties() {
  var o = api.ImageProperties();
  buildCounterImageProperties++;
  if (buildCounterImageProperties < 3) {
    o.brightness = 42.0;
    o.contrast = 42.0;
    o.cropProperties = buildCropProperties();
    o.link = buildLink();
    o.outline = buildOutline();
    o.recolor = buildRecolor();
    o.shadow = buildShadow();
    o.transparency = 42.0;
  }
  buildCounterImageProperties--;
  return o;
}

void checkImageProperties(api.ImageProperties o) {
  buildCounterImageProperties++;
  if (buildCounterImageProperties < 3) {
    unittest.expect(
      o.brightness!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.contrast!,
      unittest.equals(42.0),
    );
    checkCropProperties(o.cropProperties! as api.CropProperties);
    checkLink(o.link! as api.Link);
    checkOutline(o.outline! as api.Outline);
    checkRecolor(o.recolor! as api.Recolor);
    checkShadow(o.shadow! as api.Shadow);
    unittest.expect(
      o.transparency!,
      unittest.equals(42.0),
    );
  }
  buildCounterImageProperties--;
}

core.int buildCounterInsertTableColumnsRequest = 0;
api.InsertTableColumnsRequest buildInsertTableColumnsRequest() {
  var o = api.InsertTableColumnsRequest();
  buildCounterInsertTableColumnsRequest++;
  if (buildCounterInsertTableColumnsRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.insertRight = true;
    o.number = 42;
    o.tableObjectId = 'foo';
  }
  buildCounterInsertTableColumnsRequest--;
  return o;
}

void checkInsertTableColumnsRequest(api.InsertTableColumnsRequest o) {
  buildCounterInsertTableColumnsRequest++;
  if (buildCounterInsertTableColumnsRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(o.insertRight!, unittest.isTrue);
    unittest.expect(
      o.number!,
      unittest.equals(42),
    );
    unittest.expect(
      o.tableObjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterInsertTableColumnsRequest--;
}

core.int buildCounterInsertTableRowsRequest = 0;
api.InsertTableRowsRequest buildInsertTableRowsRequest() {
  var o = api.InsertTableRowsRequest();
  buildCounterInsertTableRowsRequest++;
  if (buildCounterInsertTableRowsRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.insertBelow = true;
    o.number = 42;
    o.tableObjectId = 'foo';
  }
  buildCounterInsertTableRowsRequest--;
  return o;
}

void checkInsertTableRowsRequest(api.InsertTableRowsRequest o) {
  buildCounterInsertTableRowsRequest++;
  if (buildCounterInsertTableRowsRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(o.insertBelow!, unittest.isTrue);
    unittest.expect(
      o.number!,
      unittest.equals(42),
    );
    unittest.expect(
      o.tableObjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterInsertTableRowsRequest--;
}

core.int buildCounterInsertTextRequest = 0;
api.InsertTextRequest buildInsertTextRequest() {
  var o = api.InsertTextRequest();
  buildCounterInsertTextRequest++;
  if (buildCounterInsertTextRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.insertionIndex = 42;
    o.objectId = 'foo';
    o.text = 'foo';
  }
  buildCounterInsertTextRequest--;
  return o;
}

void checkInsertTextRequest(api.InsertTextRequest o) {
  buildCounterInsertTextRequest++;
  if (buildCounterInsertTextRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.insertionIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterInsertTextRequest--;
}

core.int buildCounterLayoutPlaceholderIdMapping = 0;
api.LayoutPlaceholderIdMapping buildLayoutPlaceholderIdMapping() {
  var o = api.LayoutPlaceholderIdMapping();
  buildCounterLayoutPlaceholderIdMapping++;
  if (buildCounterLayoutPlaceholderIdMapping < 3) {
    o.layoutPlaceholder = buildPlaceholder();
    o.layoutPlaceholderObjectId = 'foo';
    o.objectId = 'foo';
  }
  buildCounterLayoutPlaceholderIdMapping--;
  return o;
}

void checkLayoutPlaceholderIdMapping(api.LayoutPlaceholderIdMapping o) {
  buildCounterLayoutPlaceholderIdMapping++;
  if (buildCounterLayoutPlaceholderIdMapping < 3) {
    checkPlaceholder(o.layoutPlaceholder! as api.Placeholder);
    unittest.expect(
      o.layoutPlaceholderObjectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLayoutPlaceholderIdMapping--;
}

core.int buildCounterLayoutProperties = 0;
api.LayoutProperties buildLayoutProperties() {
  var o = api.LayoutProperties();
  buildCounterLayoutProperties++;
  if (buildCounterLayoutProperties < 3) {
    o.displayName = 'foo';
    o.masterObjectId = 'foo';
    o.name = 'foo';
  }
  buildCounterLayoutProperties--;
  return o;
}

void checkLayoutProperties(api.LayoutProperties o) {
  buildCounterLayoutProperties++;
  if (buildCounterLayoutProperties < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.masterObjectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLayoutProperties--;
}

core.int buildCounterLayoutReference = 0;
api.LayoutReference buildLayoutReference() {
  var o = api.LayoutReference();
  buildCounterLayoutReference++;
  if (buildCounterLayoutReference < 3) {
    o.layoutId = 'foo';
    o.predefinedLayout = 'foo';
  }
  buildCounterLayoutReference--;
  return o;
}

void checkLayoutReference(api.LayoutReference o) {
  buildCounterLayoutReference++;
  if (buildCounterLayoutReference < 3) {
    unittest.expect(
      o.layoutId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.predefinedLayout!,
      unittest.equals('foo'),
    );
  }
  buildCounterLayoutReference--;
}

core.int buildCounterLine = 0;
api.Line buildLine() {
  var o = api.Line();
  buildCounterLine++;
  if (buildCounterLine < 3) {
    o.lineCategory = 'foo';
    o.lineProperties = buildLineProperties();
    o.lineType = 'foo';
  }
  buildCounterLine--;
  return o;
}

void checkLine(api.Line o) {
  buildCounterLine++;
  if (buildCounterLine < 3) {
    unittest.expect(
      o.lineCategory!,
      unittest.equals('foo'),
    );
    checkLineProperties(o.lineProperties! as api.LineProperties);
    unittest.expect(
      o.lineType!,
      unittest.equals('foo'),
    );
  }
  buildCounterLine--;
}

core.int buildCounterLineConnection = 0;
api.LineConnection buildLineConnection() {
  var o = api.LineConnection();
  buildCounterLineConnection++;
  if (buildCounterLineConnection < 3) {
    o.connectedObjectId = 'foo';
    o.connectionSiteIndex = 42;
  }
  buildCounterLineConnection--;
  return o;
}

void checkLineConnection(api.LineConnection o) {
  buildCounterLineConnection++;
  if (buildCounterLineConnection < 3) {
    unittest.expect(
      o.connectedObjectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.connectionSiteIndex!,
      unittest.equals(42),
    );
  }
  buildCounterLineConnection--;
}

core.int buildCounterLineFill = 0;
api.LineFill buildLineFill() {
  var o = api.LineFill();
  buildCounterLineFill++;
  if (buildCounterLineFill < 3) {
    o.solidFill = buildSolidFill();
  }
  buildCounterLineFill--;
  return o;
}

void checkLineFill(api.LineFill o) {
  buildCounterLineFill++;
  if (buildCounterLineFill < 3) {
    checkSolidFill(o.solidFill! as api.SolidFill);
  }
  buildCounterLineFill--;
}

core.int buildCounterLineProperties = 0;
api.LineProperties buildLineProperties() {
  var o = api.LineProperties();
  buildCounterLineProperties++;
  if (buildCounterLineProperties < 3) {
    o.dashStyle = 'foo';
    o.endArrow = 'foo';
    o.endConnection = buildLineConnection();
    o.lineFill = buildLineFill();
    o.link = buildLink();
    o.startArrow = 'foo';
    o.startConnection = buildLineConnection();
    o.weight = buildDimension();
  }
  buildCounterLineProperties--;
  return o;
}

void checkLineProperties(api.LineProperties o) {
  buildCounterLineProperties++;
  if (buildCounterLineProperties < 3) {
    unittest.expect(
      o.dashStyle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endArrow!,
      unittest.equals('foo'),
    );
    checkLineConnection(o.endConnection! as api.LineConnection);
    checkLineFill(o.lineFill! as api.LineFill);
    checkLink(o.link! as api.Link);
    unittest.expect(
      o.startArrow!,
      unittest.equals('foo'),
    );
    checkLineConnection(o.startConnection! as api.LineConnection);
    checkDimension(o.weight! as api.Dimension);
  }
  buildCounterLineProperties--;
}

core.int buildCounterLink = 0;
api.Link buildLink() {
  var o = api.Link();
  buildCounterLink++;
  if (buildCounterLink < 3) {
    o.pageObjectId = 'foo';
    o.relativeLink = 'foo';
    o.slideIndex = 42;
    o.url = 'foo';
  }
  buildCounterLink--;
  return o;
}

void checkLink(api.Link o) {
  buildCounterLink++;
  if (buildCounterLink < 3) {
    unittest.expect(
      o.pageObjectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.relativeLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.slideIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterLink--;
}

core.Map<core.String, api.NestingLevel> buildUnnamed2514() {
  var o = <core.String, api.NestingLevel>{};
  o['x'] = buildNestingLevel();
  o['y'] = buildNestingLevel();
  return o;
}

void checkUnnamed2514(core.Map<core.String, api.NestingLevel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNestingLevel(o['x']! as api.NestingLevel);
  checkNestingLevel(o['y']! as api.NestingLevel);
}

core.int buildCounterList = 0;
api.List buildList() {
  var o = api.List();
  buildCounterList++;
  if (buildCounterList < 3) {
    o.listId = 'foo';
    o.nestingLevel = buildUnnamed2514();
  }
  buildCounterList--;
  return o;
}

void checkList(api.List o) {
  buildCounterList++;
  if (buildCounterList < 3) {
    unittest.expect(
      o.listId!,
      unittest.equals('foo'),
    );
    checkUnnamed2514(o.nestingLevel!);
  }
  buildCounterList--;
}

core.int buildCounterMasterProperties = 0;
api.MasterProperties buildMasterProperties() {
  var o = api.MasterProperties();
  buildCounterMasterProperties++;
  if (buildCounterMasterProperties < 3) {
    o.displayName = 'foo';
  }
  buildCounterMasterProperties--;
  return o;
}

void checkMasterProperties(api.MasterProperties o) {
  buildCounterMasterProperties++;
  if (buildCounterMasterProperties < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterMasterProperties--;
}

core.int buildCounterMergeTableCellsRequest = 0;
api.MergeTableCellsRequest buildMergeTableCellsRequest() {
  var o = api.MergeTableCellsRequest();
  buildCounterMergeTableCellsRequest++;
  if (buildCounterMergeTableCellsRequest < 3) {
    o.objectId = 'foo';
    o.tableRange = buildTableRange();
  }
  buildCounterMergeTableCellsRequest--;
  return o;
}

void checkMergeTableCellsRequest(api.MergeTableCellsRequest o) {
  buildCounterMergeTableCellsRequest++;
  if (buildCounterMergeTableCellsRequest < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkTableRange(o.tableRange! as api.TableRange);
  }
  buildCounterMergeTableCellsRequest--;
}

core.int buildCounterNestingLevel = 0;
api.NestingLevel buildNestingLevel() {
  var o = api.NestingLevel();
  buildCounterNestingLevel++;
  if (buildCounterNestingLevel < 3) {
    o.bulletStyle = buildTextStyle();
  }
  buildCounterNestingLevel--;
  return o;
}

void checkNestingLevel(api.NestingLevel o) {
  buildCounterNestingLevel++;
  if (buildCounterNestingLevel < 3) {
    checkTextStyle(o.bulletStyle! as api.TextStyle);
  }
  buildCounterNestingLevel--;
}

core.int buildCounterNotesProperties = 0;
api.NotesProperties buildNotesProperties() {
  var o = api.NotesProperties();
  buildCounterNotesProperties++;
  if (buildCounterNotesProperties < 3) {
    o.speakerNotesObjectId = 'foo';
  }
  buildCounterNotesProperties--;
  return o;
}

void checkNotesProperties(api.NotesProperties o) {
  buildCounterNotesProperties++;
  if (buildCounterNotesProperties < 3) {
    unittest.expect(
      o.speakerNotesObjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterNotesProperties--;
}

core.int buildCounterOpaqueColor = 0;
api.OpaqueColor buildOpaqueColor() {
  var o = api.OpaqueColor();
  buildCounterOpaqueColor++;
  if (buildCounterOpaqueColor < 3) {
    o.rgbColor = buildRgbColor();
    o.themeColor = 'foo';
  }
  buildCounterOpaqueColor--;
  return o;
}

void checkOpaqueColor(api.OpaqueColor o) {
  buildCounterOpaqueColor++;
  if (buildCounterOpaqueColor < 3) {
    checkRgbColor(o.rgbColor! as api.RgbColor);
    unittest.expect(
      o.themeColor!,
      unittest.equals('foo'),
    );
  }
  buildCounterOpaqueColor--;
}

core.int buildCounterOptionalColor = 0;
api.OptionalColor buildOptionalColor() {
  var o = api.OptionalColor();
  buildCounterOptionalColor++;
  if (buildCounterOptionalColor < 3) {
    o.opaqueColor = buildOpaqueColor();
  }
  buildCounterOptionalColor--;
  return o;
}

void checkOptionalColor(api.OptionalColor o) {
  buildCounterOptionalColor++;
  if (buildCounterOptionalColor < 3) {
    checkOpaqueColor(o.opaqueColor! as api.OpaqueColor);
  }
  buildCounterOptionalColor--;
}

core.int buildCounterOutline = 0;
api.Outline buildOutline() {
  var o = api.Outline();
  buildCounterOutline++;
  if (buildCounterOutline < 3) {
    o.dashStyle = 'foo';
    o.outlineFill = buildOutlineFill();
    o.propertyState = 'foo';
    o.weight = buildDimension();
  }
  buildCounterOutline--;
  return o;
}

void checkOutline(api.Outline o) {
  buildCounterOutline++;
  if (buildCounterOutline < 3) {
    unittest.expect(
      o.dashStyle!,
      unittest.equals('foo'),
    );
    checkOutlineFill(o.outlineFill! as api.OutlineFill);
    unittest.expect(
      o.propertyState!,
      unittest.equals('foo'),
    );
    checkDimension(o.weight! as api.Dimension);
  }
  buildCounterOutline--;
}

core.int buildCounterOutlineFill = 0;
api.OutlineFill buildOutlineFill() {
  var o = api.OutlineFill();
  buildCounterOutlineFill++;
  if (buildCounterOutlineFill < 3) {
    o.solidFill = buildSolidFill();
  }
  buildCounterOutlineFill--;
  return o;
}

void checkOutlineFill(api.OutlineFill o) {
  buildCounterOutlineFill++;
  if (buildCounterOutlineFill < 3) {
    checkSolidFill(o.solidFill! as api.SolidFill);
  }
  buildCounterOutlineFill--;
}

core.List<api.PageElement> buildUnnamed2515() {
  var o = <api.PageElement>[];
  o.add(buildPageElement());
  o.add(buildPageElement());
  return o;
}

void checkUnnamed2515(core.List<api.PageElement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPageElement(o[0] as api.PageElement);
  checkPageElement(o[1] as api.PageElement);
}

core.int buildCounterPage = 0;
api.Page buildPage() {
  var o = api.Page();
  buildCounterPage++;
  if (buildCounterPage < 3) {
    o.layoutProperties = buildLayoutProperties();
    o.masterProperties = buildMasterProperties();
    o.notesProperties = buildNotesProperties();
    o.objectId = 'foo';
    o.pageElements = buildUnnamed2515();
    o.pageProperties = buildPageProperties();
    o.pageType = 'foo';
    o.revisionId = 'foo';
    o.slideProperties = buildSlideProperties();
  }
  buildCounterPage--;
  return o;
}

void checkPage(api.Page o) {
  buildCounterPage++;
  if (buildCounterPage < 3) {
    checkLayoutProperties(o.layoutProperties! as api.LayoutProperties);
    checkMasterProperties(o.masterProperties! as api.MasterProperties);
    checkNotesProperties(o.notesProperties! as api.NotesProperties);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkUnnamed2515(o.pageElements!);
    checkPageProperties(o.pageProperties! as api.PageProperties);
    unittest.expect(
      o.pageType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
    checkSlideProperties(o.slideProperties! as api.SlideProperties);
  }
  buildCounterPage--;
}

core.int buildCounterPageBackgroundFill = 0;
api.PageBackgroundFill buildPageBackgroundFill() {
  var o = api.PageBackgroundFill();
  buildCounterPageBackgroundFill++;
  if (buildCounterPageBackgroundFill < 3) {
    o.propertyState = 'foo';
    o.solidFill = buildSolidFill();
    o.stretchedPictureFill = buildStretchedPictureFill();
  }
  buildCounterPageBackgroundFill--;
  return o;
}

void checkPageBackgroundFill(api.PageBackgroundFill o) {
  buildCounterPageBackgroundFill++;
  if (buildCounterPageBackgroundFill < 3) {
    unittest.expect(
      o.propertyState!,
      unittest.equals('foo'),
    );
    checkSolidFill(o.solidFill! as api.SolidFill);
    checkStretchedPictureFill(
        o.stretchedPictureFill! as api.StretchedPictureFill);
  }
  buildCounterPageBackgroundFill--;
}

core.int buildCounterPageElement = 0;
api.PageElement buildPageElement() {
  var o = api.PageElement();
  buildCounterPageElement++;
  if (buildCounterPageElement < 3) {
    o.description = 'foo';
    o.elementGroup = buildGroup();
    o.image = buildImage();
    o.line = buildLine();
    o.objectId = 'foo';
    o.shape = buildShape();
    o.sheetsChart = buildSheetsChart();
    o.size = buildSize();
    o.table = buildTable();
    o.title = 'foo';
    o.transform = buildAffineTransform();
    o.video = buildVideo();
    o.wordArt = buildWordArt();
  }
  buildCounterPageElement--;
  return o;
}

void checkPageElement(api.PageElement o) {
  buildCounterPageElement++;
  if (buildCounterPageElement < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkGroup(o.elementGroup! as api.Group);
    checkImage(o.image! as api.Image);
    checkLine(o.line! as api.Line);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkShape(o.shape! as api.Shape);
    checkSheetsChart(o.sheetsChart! as api.SheetsChart);
    checkSize(o.size! as api.Size);
    checkTable(o.table! as api.Table);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    checkAffineTransform(o.transform! as api.AffineTransform);
    checkVideo(o.video! as api.Video);
    checkWordArt(o.wordArt! as api.WordArt);
  }
  buildCounterPageElement--;
}

core.int buildCounterPageElementProperties = 0;
api.PageElementProperties buildPageElementProperties() {
  var o = api.PageElementProperties();
  buildCounterPageElementProperties++;
  if (buildCounterPageElementProperties < 3) {
    o.pageObjectId = 'foo';
    o.size = buildSize();
    o.transform = buildAffineTransform();
  }
  buildCounterPageElementProperties--;
  return o;
}

void checkPageElementProperties(api.PageElementProperties o) {
  buildCounterPageElementProperties++;
  if (buildCounterPageElementProperties < 3) {
    unittest.expect(
      o.pageObjectId!,
      unittest.equals('foo'),
    );
    checkSize(o.size! as api.Size);
    checkAffineTransform(o.transform! as api.AffineTransform);
  }
  buildCounterPageElementProperties--;
}

core.int buildCounterPageProperties = 0;
api.PageProperties buildPageProperties() {
  var o = api.PageProperties();
  buildCounterPageProperties++;
  if (buildCounterPageProperties < 3) {
    o.colorScheme = buildColorScheme();
    o.pageBackgroundFill = buildPageBackgroundFill();
  }
  buildCounterPageProperties--;
  return o;
}

void checkPageProperties(api.PageProperties o) {
  buildCounterPageProperties++;
  if (buildCounterPageProperties < 3) {
    checkColorScheme(o.colorScheme! as api.ColorScheme);
    checkPageBackgroundFill(o.pageBackgroundFill! as api.PageBackgroundFill);
  }
  buildCounterPageProperties--;
}

core.int buildCounterParagraphMarker = 0;
api.ParagraphMarker buildParagraphMarker() {
  var o = api.ParagraphMarker();
  buildCounterParagraphMarker++;
  if (buildCounterParagraphMarker < 3) {
    o.bullet = buildBullet();
    o.style = buildParagraphStyle();
  }
  buildCounterParagraphMarker--;
  return o;
}

void checkParagraphMarker(api.ParagraphMarker o) {
  buildCounterParagraphMarker++;
  if (buildCounterParagraphMarker < 3) {
    checkBullet(o.bullet! as api.Bullet);
    checkParagraphStyle(o.style! as api.ParagraphStyle);
  }
  buildCounterParagraphMarker--;
}

core.int buildCounterParagraphStyle = 0;
api.ParagraphStyle buildParagraphStyle() {
  var o = api.ParagraphStyle();
  buildCounterParagraphStyle++;
  if (buildCounterParagraphStyle < 3) {
    o.alignment = 'foo';
    o.direction = 'foo';
    o.indentEnd = buildDimension();
    o.indentFirstLine = buildDimension();
    o.indentStart = buildDimension();
    o.lineSpacing = 42.0;
    o.spaceAbove = buildDimension();
    o.spaceBelow = buildDimension();
    o.spacingMode = 'foo';
  }
  buildCounterParagraphStyle--;
  return o;
}

void checkParagraphStyle(api.ParagraphStyle o) {
  buildCounterParagraphStyle++;
  if (buildCounterParagraphStyle < 3) {
    unittest.expect(
      o.alignment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.direction!,
      unittest.equals('foo'),
    );
    checkDimension(o.indentEnd! as api.Dimension);
    checkDimension(o.indentFirstLine! as api.Dimension);
    checkDimension(o.indentStart! as api.Dimension);
    unittest.expect(
      o.lineSpacing!,
      unittest.equals(42.0),
    );
    checkDimension(o.spaceAbove! as api.Dimension);
    checkDimension(o.spaceBelow! as api.Dimension);
    unittest.expect(
      o.spacingMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterParagraphStyle--;
}

core.int buildCounterPlaceholder = 0;
api.Placeholder buildPlaceholder() {
  var o = api.Placeholder();
  buildCounterPlaceholder++;
  if (buildCounterPlaceholder < 3) {
    o.index = 42;
    o.parentObjectId = 'foo';
    o.type = 'foo';
  }
  buildCounterPlaceholder--;
  return o;
}

void checkPlaceholder(api.Placeholder o) {
  buildCounterPlaceholder++;
  if (buildCounterPlaceholder < 3) {
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.parentObjectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaceholder--;
}

core.List<api.Page> buildUnnamed2516() {
  var o = <api.Page>[];
  o.add(buildPage());
  o.add(buildPage());
  return o;
}

void checkUnnamed2516(core.List<api.Page> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPage(o[0] as api.Page);
  checkPage(o[1] as api.Page);
}

core.List<api.Page> buildUnnamed2517() {
  var o = <api.Page>[];
  o.add(buildPage());
  o.add(buildPage());
  return o;
}

void checkUnnamed2517(core.List<api.Page> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPage(o[0] as api.Page);
  checkPage(o[1] as api.Page);
}

core.List<api.Page> buildUnnamed2518() {
  var o = <api.Page>[];
  o.add(buildPage());
  o.add(buildPage());
  return o;
}

void checkUnnamed2518(core.List<api.Page> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPage(o[0] as api.Page);
  checkPage(o[1] as api.Page);
}

core.int buildCounterPresentation = 0;
api.Presentation buildPresentation() {
  var o = api.Presentation();
  buildCounterPresentation++;
  if (buildCounterPresentation < 3) {
    o.layouts = buildUnnamed2516();
    o.locale = 'foo';
    o.masters = buildUnnamed2517();
    o.notesMaster = buildPage();
    o.pageSize = buildSize();
    o.presentationId = 'foo';
    o.revisionId = 'foo';
    o.slides = buildUnnamed2518();
    o.title = 'foo';
  }
  buildCounterPresentation--;
  return o;
}

void checkPresentation(api.Presentation o) {
  buildCounterPresentation++;
  if (buildCounterPresentation < 3) {
    checkUnnamed2516(o.layouts!);
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    checkUnnamed2517(o.masters!);
    checkPage(o.notesMaster! as api.Page);
    checkSize(o.pageSize! as api.Size);
    unittest.expect(
      o.presentationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
    checkUnnamed2518(o.slides!);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterPresentation--;
}

core.int buildCounterRange = 0;
api.Range buildRange() {
  var o = api.Range();
  buildCounterRange++;
  if (buildCounterRange < 3) {
    o.endIndex = 42;
    o.startIndex = 42;
    o.type = 'foo';
  }
  buildCounterRange--;
  return o;
}

void checkRange(api.Range o) {
  buildCounterRange++;
  if (buildCounterRange < 3) {
    unittest.expect(
      o.endIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterRange--;
}

core.List<api.ColorStop> buildUnnamed2519() {
  var o = <api.ColorStop>[];
  o.add(buildColorStop());
  o.add(buildColorStop());
  return o;
}

void checkUnnamed2519(core.List<api.ColorStop> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkColorStop(o[0] as api.ColorStop);
  checkColorStop(o[1] as api.ColorStop);
}

core.int buildCounterRecolor = 0;
api.Recolor buildRecolor() {
  var o = api.Recolor();
  buildCounterRecolor++;
  if (buildCounterRecolor < 3) {
    o.name = 'foo';
    o.recolorStops = buildUnnamed2519();
  }
  buildCounterRecolor--;
  return o;
}

void checkRecolor(api.Recolor o) {
  buildCounterRecolor++;
  if (buildCounterRecolor < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2519(o.recolorStops!);
  }
  buildCounterRecolor--;
}

core.int buildCounterRefreshSheetsChartRequest = 0;
api.RefreshSheetsChartRequest buildRefreshSheetsChartRequest() {
  var o = api.RefreshSheetsChartRequest();
  buildCounterRefreshSheetsChartRequest++;
  if (buildCounterRefreshSheetsChartRequest < 3) {
    o.objectId = 'foo';
  }
  buildCounterRefreshSheetsChartRequest--;
  return o;
}

void checkRefreshSheetsChartRequest(api.RefreshSheetsChartRequest o) {
  buildCounterRefreshSheetsChartRequest++;
  if (buildCounterRefreshSheetsChartRequest < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRefreshSheetsChartRequest--;
}

core.List<core.String> buildUnnamed2520() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2520(core.List<core.String> o) {
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

core.int buildCounterReplaceAllShapesWithImageRequest = 0;
api.ReplaceAllShapesWithImageRequest buildReplaceAllShapesWithImageRequest() {
  var o = api.ReplaceAllShapesWithImageRequest();
  buildCounterReplaceAllShapesWithImageRequest++;
  if (buildCounterReplaceAllShapesWithImageRequest < 3) {
    o.containsText = buildSubstringMatchCriteria();
    o.imageReplaceMethod = 'foo';
    o.imageUrl = 'foo';
    o.pageObjectIds = buildUnnamed2520();
    o.replaceMethod = 'foo';
  }
  buildCounterReplaceAllShapesWithImageRequest--;
  return o;
}

void checkReplaceAllShapesWithImageRequest(
    api.ReplaceAllShapesWithImageRequest o) {
  buildCounterReplaceAllShapesWithImageRequest++;
  if (buildCounterReplaceAllShapesWithImageRequest < 3) {
    checkSubstringMatchCriteria(o.containsText! as api.SubstringMatchCriteria);
    unittest.expect(
      o.imageReplaceMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.imageUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed2520(o.pageObjectIds!);
    unittest.expect(
      o.replaceMethod!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplaceAllShapesWithImageRequest--;
}

core.int buildCounterReplaceAllShapesWithImageResponse = 0;
api.ReplaceAllShapesWithImageResponse buildReplaceAllShapesWithImageResponse() {
  var o = api.ReplaceAllShapesWithImageResponse();
  buildCounterReplaceAllShapesWithImageResponse++;
  if (buildCounterReplaceAllShapesWithImageResponse < 3) {
    o.occurrencesChanged = 42;
  }
  buildCounterReplaceAllShapesWithImageResponse--;
  return o;
}

void checkReplaceAllShapesWithImageResponse(
    api.ReplaceAllShapesWithImageResponse o) {
  buildCounterReplaceAllShapesWithImageResponse++;
  if (buildCounterReplaceAllShapesWithImageResponse < 3) {
    unittest.expect(
      o.occurrencesChanged!,
      unittest.equals(42),
    );
  }
  buildCounterReplaceAllShapesWithImageResponse--;
}

core.List<core.String> buildUnnamed2521() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2521(core.List<core.String> o) {
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

core.int buildCounterReplaceAllShapesWithSheetsChartRequest = 0;
api.ReplaceAllShapesWithSheetsChartRequest
    buildReplaceAllShapesWithSheetsChartRequest() {
  var o = api.ReplaceAllShapesWithSheetsChartRequest();
  buildCounterReplaceAllShapesWithSheetsChartRequest++;
  if (buildCounterReplaceAllShapesWithSheetsChartRequest < 3) {
    o.chartId = 42;
    o.containsText = buildSubstringMatchCriteria();
    o.linkingMode = 'foo';
    o.pageObjectIds = buildUnnamed2521();
    o.spreadsheetId = 'foo';
  }
  buildCounterReplaceAllShapesWithSheetsChartRequest--;
  return o;
}

void checkReplaceAllShapesWithSheetsChartRequest(
    api.ReplaceAllShapesWithSheetsChartRequest o) {
  buildCounterReplaceAllShapesWithSheetsChartRequest++;
  if (buildCounterReplaceAllShapesWithSheetsChartRequest < 3) {
    unittest.expect(
      o.chartId!,
      unittest.equals(42),
    );
    checkSubstringMatchCriteria(o.containsText! as api.SubstringMatchCriteria);
    unittest.expect(
      o.linkingMode!,
      unittest.equals('foo'),
    );
    checkUnnamed2521(o.pageObjectIds!);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplaceAllShapesWithSheetsChartRequest--;
}

core.int buildCounterReplaceAllShapesWithSheetsChartResponse = 0;
api.ReplaceAllShapesWithSheetsChartResponse
    buildReplaceAllShapesWithSheetsChartResponse() {
  var o = api.ReplaceAllShapesWithSheetsChartResponse();
  buildCounterReplaceAllShapesWithSheetsChartResponse++;
  if (buildCounterReplaceAllShapesWithSheetsChartResponse < 3) {
    o.occurrencesChanged = 42;
  }
  buildCounterReplaceAllShapesWithSheetsChartResponse--;
  return o;
}

void checkReplaceAllShapesWithSheetsChartResponse(
    api.ReplaceAllShapesWithSheetsChartResponse o) {
  buildCounterReplaceAllShapesWithSheetsChartResponse++;
  if (buildCounterReplaceAllShapesWithSheetsChartResponse < 3) {
    unittest.expect(
      o.occurrencesChanged!,
      unittest.equals(42),
    );
  }
  buildCounterReplaceAllShapesWithSheetsChartResponse--;
}

core.List<core.String> buildUnnamed2522() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2522(core.List<core.String> o) {
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

core.int buildCounterReplaceAllTextRequest = 0;
api.ReplaceAllTextRequest buildReplaceAllTextRequest() {
  var o = api.ReplaceAllTextRequest();
  buildCounterReplaceAllTextRequest++;
  if (buildCounterReplaceAllTextRequest < 3) {
    o.containsText = buildSubstringMatchCriteria();
    o.pageObjectIds = buildUnnamed2522();
    o.replaceText = 'foo';
  }
  buildCounterReplaceAllTextRequest--;
  return o;
}

void checkReplaceAllTextRequest(api.ReplaceAllTextRequest o) {
  buildCounterReplaceAllTextRequest++;
  if (buildCounterReplaceAllTextRequest < 3) {
    checkSubstringMatchCriteria(o.containsText! as api.SubstringMatchCriteria);
    checkUnnamed2522(o.pageObjectIds!);
    unittest.expect(
      o.replaceText!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplaceAllTextRequest--;
}

core.int buildCounterReplaceAllTextResponse = 0;
api.ReplaceAllTextResponse buildReplaceAllTextResponse() {
  var o = api.ReplaceAllTextResponse();
  buildCounterReplaceAllTextResponse++;
  if (buildCounterReplaceAllTextResponse < 3) {
    o.occurrencesChanged = 42;
  }
  buildCounterReplaceAllTextResponse--;
  return o;
}

void checkReplaceAllTextResponse(api.ReplaceAllTextResponse o) {
  buildCounterReplaceAllTextResponse++;
  if (buildCounterReplaceAllTextResponse < 3) {
    unittest.expect(
      o.occurrencesChanged!,
      unittest.equals(42),
    );
  }
  buildCounterReplaceAllTextResponse--;
}

core.int buildCounterReplaceImageRequest = 0;
api.ReplaceImageRequest buildReplaceImageRequest() {
  var o = api.ReplaceImageRequest();
  buildCounterReplaceImageRequest++;
  if (buildCounterReplaceImageRequest < 3) {
    o.imageObjectId = 'foo';
    o.imageReplaceMethod = 'foo';
    o.url = 'foo';
  }
  buildCounterReplaceImageRequest--;
  return o;
}

void checkReplaceImageRequest(api.ReplaceImageRequest o) {
  buildCounterReplaceImageRequest++;
  if (buildCounterReplaceImageRequest < 3) {
    unittest.expect(
      o.imageObjectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.imageReplaceMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplaceImageRequest--;
}

core.int buildCounterRequest = 0;
api.Request buildRequest() {
  var o = api.Request();
  buildCounterRequest++;
  if (buildCounterRequest < 3) {
    o.createImage = buildCreateImageRequest();
    o.createLine = buildCreateLineRequest();
    o.createParagraphBullets = buildCreateParagraphBulletsRequest();
    o.createShape = buildCreateShapeRequest();
    o.createSheetsChart = buildCreateSheetsChartRequest();
    o.createSlide = buildCreateSlideRequest();
    o.createTable = buildCreateTableRequest();
    o.createVideo = buildCreateVideoRequest();
    o.deleteObject = buildDeleteObjectRequest();
    o.deleteParagraphBullets = buildDeleteParagraphBulletsRequest();
    o.deleteTableColumn = buildDeleteTableColumnRequest();
    o.deleteTableRow = buildDeleteTableRowRequest();
    o.deleteText = buildDeleteTextRequest();
    o.duplicateObject = buildDuplicateObjectRequest();
    o.groupObjects = buildGroupObjectsRequest();
    o.insertTableColumns = buildInsertTableColumnsRequest();
    o.insertTableRows = buildInsertTableRowsRequest();
    o.insertText = buildInsertTextRequest();
    o.mergeTableCells = buildMergeTableCellsRequest();
    o.refreshSheetsChart = buildRefreshSheetsChartRequest();
    o.replaceAllShapesWithImage = buildReplaceAllShapesWithImageRequest();
    o.replaceAllShapesWithSheetsChart =
        buildReplaceAllShapesWithSheetsChartRequest();
    o.replaceAllText = buildReplaceAllTextRequest();
    o.replaceImage = buildReplaceImageRequest();
    o.rerouteLine = buildRerouteLineRequest();
    o.ungroupObjects = buildUngroupObjectsRequest();
    o.unmergeTableCells = buildUnmergeTableCellsRequest();
    o.updateImageProperties = buildUpdateImagePropertiesRequest();
    o.updateLineCategory = buildUpdateLineCategoryRequest();
    o.updateLineProperties = buildUpdateLinePropertiesRequest();
    o.updatePageElementAltText = buildUpdatePageElementAltTextRequest();
    o.updatePageElementTransform = buildUpdatePageElementTransformRequest();
    o.updatePageElementsZOrder = buildUpdatePageElementsZOrderRequest();
    o.updatePageProperties = buildUpdatePagePropertiesRequest();
    o.updateParagraphStyle = buildUpdateParagraphStyleRequest();
    o.updateShapeProperties = buildUpdateShapePropertiesRequest();
    o.updateSlidesPosition = buildUpdateSlidesPositionRequest();
    o.updateTableBorderProperties = buildUpdateTableBorderPropertiesRequest();
    o.updateTableCellProperties = buildUpdateTableCellPropertiesRequest();
    o.updateTableColumnProperties = buildUpdateTableColumnPropertiesRequest();
    o.updateTableRowProperties = buildUpdateTableRowPropertiesRequest();
    o.updateTextStyle = buildUpdateTextStyleRequest();
    o.updateVideoProperties = buildUpdateVideoPropertiesRequest();
  }
  buildCounterRequest--;
  return o;
}

void checkRequest(api.Request o) {
  buildCounterRequest++;
  if (buildCounterRequest < 3) {
    checkCreateImageRequest(o.createImage! as api.CreateImageRequest);
    checkCreateLineRequest(o.createLine! as api.CreateLineRequest);
    checkCreateParagraphBulletsRequest(
        o.createParagraphBullets! as api.CreateParagraphBulletsRequest);
    checkCreateShapeRequest(o.createShape! as api.CreateShapeRequest);
    checkCreateSheetsChartRequest(
        o.createSheetsChart! as api.CreateSheetsChartRequest);
    checkCreateSlideRequest(o.createSlide! as api.CreateSlideRequest);
    checkCreateTableRequest(o.createTable! as api.CreateTableRequest);
    checkCreateVideoRequest(o.createVideo! as api.CreateVideoRequest);
    checkDeleteObjectRequest(o.deleteObject! as api.DeleteObjectRequest);
    checkDeleteParagraphBulletsRequest(
        o.deleteParagraphBullets! as api.DeleteParagraphBulletsRequest);
    checkDeleteTableColumnRequest(
        o.deleteTableColumn! as api.DeleteTableColumnRequest);
    checkDeleteTableRowRequest(o.deleteTableRow! as api.DeleteTableRowRequest);
    checkDeleteTextRequest(o.deleteText! as api.DeleteTextRequest);
    checkDuplicateObjectRequest(
        o.duplicateObject! as api.DuplicateObjectRequest);
    checkGroupObjectsRequest(o.groupObjects! as api.GroupObjectsRequest);
    checkInsertTableColumnsRequest(
        o.insertTableColumns! as api.InsertTableColumnsRequest);
    checkInsertTableRowsRequest(
        o.insertTableRows! as api.InsertTableRowsRequest);
    checkInsertTextRequest(o.insertText! as api.InsertTextRequest);
    checkMergeTableCellsRequest(
        o.mergeTableCells! as api.MergeTableCellsRequest);
    checkRefreshSheetsChartRequest(
        o.refreshSheetsChart! as api.RefreshSheetsChartRequest);
    checkReplaceAllShapesWithImageRequest(
        o.replaceAllShapesWithImage! as api.ReplaceAllShapesWithImageRequest);
    checkReplaceAllShapesWithSheetsChartRequest(
        o.replaceAllShapesWithSheetsChart!
            as api.ReplaceAllShapesWithSheetsChartRequest);
    checkReplaceAllTextRequest(o.replaceAllText! as api.ReplaceAllTextRequest);
    checkReplaceImageRequest(o.replaceImage! as api.ReplaceImageRequest);
    checkRerouteLineRequest(o.rerouteLine! as api.RerouteLineRequest);
    checkUngroupObjectsRequest(o.ungroupObjects! as api.UngroupObjectsRequest);
    checkUnmergeTableCellsRequest(
        o.unmergeTableCells! as api.UnmergeTableCellsRequest);
    checkUpdateImagePropertiesRequest(
        o.updateImageProperties! as api.UpdateImagePropertiesRequest);
    checkUpdateLineCategoryRequest(
        o.updateLineCategory! as api.UpdateLineCategoryRequest);
    checkUpdateLinePropertiesRequest(
        o.updateLineProperties! as api.UpdateLinePropertiesRequest);
    checkUpdatePageElementAltTextRequest(
        o.updatePageElementAltText! as api.UpdatePageElementAltTextRequest);
    checkUpdatePageElementTransformRequest(
        o.updatePageElementTransform! as api.UpdatePageElementTransformRequest);
    checkUpdatePageElementsZOrderRequest(
        o.updatePageElementsZOrder! as api.UpdatePageElementsZOrderRequest);
    checkUpdatePagePropertiesRequest(
        o.updatePageProperties! as api.UpdatePagePropertiesRequest);
    checkUpdateParagraphStyleRequest(
        o.updateParagraphStyle! as api.UpdateParagraphStyleRequest);
    checkUpdateShapePropertiesRequest(
        o.updateShapeProperties! as api.UpdateShapePropertiesRequest);
    checkUpdateSlidesPositionRequest(
        o.updateSlidesPosition! as api.UpdateSlidesPositionRequest);
    checkUpdateTableBorderPropertiesRequest(o.updateTableBorderProperties!
        as api.UpdateTableBorderPropertiesRequest);
    checkUpdateTableCellPropertiesRequest(
        o.updateTableCellProperties! as api.UpdateTableCellPropertiesRequest);
    checkUpdateTableColumnPropertiesRequest(o.updateTableColumnProperties!
        as api.UpdateTableColumnPropertiesRequest);
    checkUpdateTableRowPropertiesRequest(
        o.updateTableRowProperties! as api.UpdateTableRowPropertiesRequest);
    checkUpdateTextStyleRequest(
        o.updateTextStyle! as api.UpdateTextStyleRequest);
    checkUpdateVideoPropertiesRequest(
        o.updateVideoProperties! as api.UpdateVideoPropertiesRequest);
  }
  buildCounterRequest--;
}

core.int buildCounterRerouteLineRequest = 0;
api.RerouteLineRequest buildRerouteLineRequest() {
  var o = api.RerouteLineRequest();
  buildCounterRerouteLineRequest++;
  if (buildCounterRerouteLineRequest < 3) {
    o.objectId = 'foo';
  }
  buildCounterRerouteLineRequest--;
  return o;
}

void checkRerouteLineRequest(api.RerouteLineRequest o) {
  buildCounterRerouteLineRequest++;
  if (buildCounterRerouteLineRequest < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRerouteLineRequest--;
}

core.int buildCounterResponse = 0;
api.Response buildResponse() {
  var o = api.Response();
  buildCounterResponse++;
  if (buildCounterResponse < 3) {
    o.createImage = buildCreateImageResponse();
    o.createLine = buildCreateLineResponse();
    o.createShape = buildCreateShapeResponse();
    o.createSheetsChart = buildCreateSheetsChartResponse();
    o.createSlide = buildCreateSlideResponse();
    o.createTable = buildCreateTableResponse();
    o.createVideo = buildCreateVideoResponse();
    o.duplicateObject = buildDuplicateObjectResponse();
    o.groupObjects = buildGroupObjectsResponse();
    o.replaceAllShapesWithImage = buildReplaceAllShapesWithImageResponse();
    o.replaceAllShapesWithSheetsChart =
        buildReplaceAllShapesWithSheetsChartResponse();
    o.replaceAllText = buildReplaceAllTextResponse();
  }
  buildCounterResponse--;
  return o;
}

void checkResponse(api.Response o) {
  buildCounterResponse++;
  if (buildCounterResponse < 3) {
    checkCreateImageResponse(o.createImage! as api.CreateImageResponse);
    checkCreateLineResponse(o.createLine! as api.CreateLineResponse);
    checkCreateShapeResponse(o.createShape! as api.CreateShapeResponse);
    checkCreateSheetsChartResponse(
        o.createSheetsChart! as api.CreateSheetsChartResponse);
    checkCreateSlideResponse(o.createSlide! as api.CreateSlideResponse);
    checkCreateTableResponse(o.createTable! as api.CreateTableResponse);
    checkCreateVideoResponse(o.createVideo! as api.CreateVideoResponse);
    checkDuplicateObjectResponse(
        o.duplicateObject! as api.DuplicateObjectResponse);
    checkGroupObjectsResponse(o.groupObjects! as api.GroupObjectsResponse);
    checkReplaceAllShapesWithImageResponse(
        o.replaceAllShapesWithImage! as api.ReplaceAllShapesWithImageResponse);
    checkReplaceAllShapesWithSheetsChartResponse(
        o.replaceAllShapesWithSheetsChart!
            as api.ReplaceAllShapesWithSheetsChartResponse);
    checkReplaceAllTextResponse(
        o.replaceAllText! as api.ReplaceAllTextResponse);
  }
  buildCounterResponse--;
}

core.int buildCounterRgbColor = 0;
api.RgbColor buildRgbColor() {
  var o = api.RgbColor();
  buildCounterRgbColor++;
  if (buildCounterRgbColor < 3) {
    o.blue = 42.0;
    o.green = 42.0;
    o.red = 42.0;
  }
  buildCounterRgbColor--;
  return o;
}

void checkRgbColor(api.RgbColor o) {
  buildCounterRgbColor++;
  if (buildCounterRgbColor < 3) {
    unittest.expect(
      o.blue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.green!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.red!,
      unittest.equals(42.0),
    );
  }
  buildCounterRgbColor--;
}

core.int buildCounterShadow = 0;
api.Shadow buildShadow() {
  var o = api.Shadow();
  buildCounterShadow++;
  if (buildCounterShadow < 3) {
    o.alignment = 'foo';
    o.alpha = 42.0;
    o.blurRadius = buildDimension();
    o.color = buildOpaqueColor();
    o.propertyState = 'foo';
    o.rotateWithShape = true;
    o.transform = buildAffineTransform();
    o.type = 'foo';
  }
  buildCounterShadow--;
  return o;
}

void checkShadow(api.Shadow o) {
  buildCounterShadow++;
  if (buildCounterShadow < 3) {
    unittest.expect(
      o.alignment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.alpha!,
      unittest.equals(42.0),
    );
    checkDimension(o.blurRadius! as api.Dimension);
    checkOpaqueColor(o.color! as api.OpaqueColor);
    unittest.expect(
      o.propertyState!,
      unittest.equals('foo'),
    );
    unittest.expect(o.rotateWithShape!, unittest.isTrue);
    checkAffineTransform(o.transform! as api.AffineTransform);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterShadow--;
}

core.int buildCounterShape = 0;
api.Shape buildShape() {
  var o = api.Shape();
  buildCounterShape++;
  if (buildCounterShape < 3) {
    o.placeholder = buildPlaceholder();
    o.shapeProperties = buildShapeProperties();
    o.shapeType = 'foo';
    o.text = buildTextContent();
  }
  buildCounterShape--;
  return o;
}

void checkShape(api.Shape o) {
  buildCounterShape++;
  if (buildCounterShape < 3) {
    checkPlaceholder(o.placeholder! as api.Placeholder);
    checkShapeProperties(o.shapeProperties! as api.ShapeProperties);
    unittest.expect(
      o.shapeType!,
      unittest.equals('foo'),
    );
    checkTextContent(o.text! as api.TextContent);
  }
  buildCounterShape--;
}

core.int buildCounterShapeBackgroundFill = 0;
api.ShapeBackgroundFill buildShapeBackgroundFill() {
  var o = api.ShapeBackgroundFill();
  buildCounterShapeBackgroundFill++;
  if (buildCounterShapeBackgroundFill < 3) {
    o.propertyState = 'foo';
    o.solidFill = buildSolidFill();
  }
  buildCounterShapeBackgroundFill--;
  return o;
}

void checkShapeBackgroundFill(api.ShapeBackgroundFill o) {
  buildCounterShapeBackgroundFill++;
  if (buildCounterShapeBackgroundFill < 3) {
    unittest.expect(
      o.propertyState!,
      unittest.equals('foo'),
    );
    checkSolidFill(o.solidFill! as api.SolidFill);
  }
  buildCounterShapeBackgroundFill--;
}

core.int buildCounterShapeProperties = 0;
api.ShapeProperties buildShapeProperties() {
  var o = api.ShapeProperties();
  buildCounterShapeProperties++;
  if (buildCounterShapeProperties < 3) {
    o.autofit = buildAutofit();
    o.contentAlignment = 'foo';
    o.link = buildLink();
    o.outline = buildOutline();
    o.shadow = buildShadow();
    o.shapeBackgroundFill = buildShapeBackgroundFill();
  }
  buildCounterShapeProperties--;
  return o;
}

void checkShapeProperties(api.ShapeProperties o) {
  buildCounterShapeProperties++;
  if (buildCounterShapeProperties < 3) {
    checkAutofit(o.autofit! as api.Autofit);
    unittest.expect(
      o.contentAlignment!,
      unittest.equals('foo'),
    );
    checkLink(o.link! as api.Link);
    checkOutline(o.outline! as api.Outline);
    checkShadow(o.shadow! as api.Shadow);
    checkShapeBackgroundFill(o.shapeBackgroundFill! as api.ShapeBackgroundFill);
  }
  buildCounterShapeProperties--;
}

core.int buildCounterSheetsChart = 0;
api.SheetsChart buildSheetsChart() {
  var o = api.SheetsChart();
  buildCounterSheetsChart++;
  if (buildCounterSheetsChart < 3) {
    o.chartId = 42;
    o.contentUrl = 'foo';
    o.sheetsChartProperties = buildSheetsChartProperties();
    o.spreadsheetId = 'foo';
  }
  buildCounterSheetsChart--;
  return o;
}

void checkSheetsChart(api.SheetsChart o) {
  buildCounterSheetsChart++;
  if (buildCounterSheetsChart < 3) {
    unittest.expect(
      o.chartId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.contentUrl!,
      unittest.equals('foo'),
    );
    checkSheetsChartProperties(
        o.sheetsChartProperties! as api.SheetsChartProperties);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSheetsChart--;
}

core.int buildCounterSheetsChartProperties = 0;
api.SheetsChartProperties buildSheetsChartProperties() {
  var o = api.SheetsChartProperties();
  buildCounterSheetsChartProperties++;
  if (buildCounterSheetsChartProperties < 3) {
    o.chartImageProperties = buildImageProperties();
  }
  buildCounterSheetsChartProperties--;
  return o;
}

void checkSheetsChartProperties(api.SheetsChartProperties o) {
  buildCounterSheetsChartProperties++;
  if (buildCounterSheetsChartProperties < 3) {
    checkImageProperties(o.chartImageProperties! as api.ImageProperties);
  }
  buildCounterSheetsChartProperties--;
}

core.int buildCounterSize = 0;
api.Size buildSize() {
  var o = api.Size();
  buildCounterSize++;
  if (buildCounterSize < 3) {
    o.height = buildDimension();
    o.width = buildDimension();
  }
  buildCounterSize--;
  return o;
}

void checkSize(api.Size o) {
  buildCounterSize++;
  if (buildCounterSize < 3) {
    checkDimension(o.height! as api.Dimension);
    checkDimension(o.width! as api.Dimension);
  }
  buildCounterSize--;
}

core.int buildCounterSlideProperties = 0;
api.SlideProperties buildSlideProperties() {
  var o = api.SlideProperties();
  buildCounterSlideProperties++;
  if (buildCounterSlideProperties < 3) {
    o.layoutObjectId = 'foo';
    o.masterObjectId = 'foo';
    o.notesPage = buildPage();
  }
  buildCounterSlideProperties--;
  return o;
}

void checkSlideProperties(api.SlideProperties o) {
  buildCounterSlideProperties++;
  if (buildCounterSlideProperties < 3) {
    unittest.expect(
      o.layoutObjectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.masterObjectId!,
      unittest.equals('foo'),
    );
    checkPage(o.notesPage! as api.Page);
  }
  buildCounterSlideProperties--;
}

core.int buildCounterSolidFill = 0;
api.SolidFill buildSolidFill() {
  var o = api.SolidFill();
  buildCounterSolidFill++;
  if (buildCounterSolidFill < 3) {
    o.alpha = 42.0;
    o.color = buildOpaqueColor();
  }
  buildCounterSolidFill--;
  return o;
}

void checkSolidFill(api.SolidFill o) {
  buildCounterSolidFill++;
  if (buildCounterSolidFill < 3) {
    unittest.expect(
      o.alpha!,
      unittest.equals(42.0),
    );
    checkOpaqueColor(o.color! as api.OpaqueColor);
  }
  buildCounterSolidFill--;
}

core.int buildCounterStretchedPictureFill = 0;
api.StretchedPictureFill buildStretchedPictureFill() {
  var o = api.StretchedPictureFill();
  buildCounterStretchedPictureFill++;
  if (buildCounterStretchedPictureFill < 3) {
    o.contentUrl = 'foo';
    o.size = buildSize();
  }
  buildCounterStretchedPictureFill--;
  return o;
}

void checkStretchedPictureFill(api.StretchedPictureFill o) {
  buildCounterStretchedPictureFill++;
  if (buildCounterStretchedPictureFill < 3) {
    unittest.expect(
      o.contentUrl!,
      unittest.equals('foo'),
    );
    checkSize(o.size! as api.Size);
  }
  buildCounterStretchedPictureFill--;
}

core.int buildCounterSubstringMatchCriteria = 0;
api.SubstringMatchCriteria buildSubstringMatchCriteria() {
  var o = api.SubstringMatchCriteria();
  buildCounterSubstringMatchCriteria++;
  if (buildCounterSubstringMatchCriteria < 3) {
    o.matchCase = true;
    o.text = 'foo';
  }
  buildCounterSubstringMatchCriteria--;
  return o;
}

void checkSubstringMatchCriteria(api.SubstringMatchCriteria o) {
  buildCounterSubstringMatchCriteria++;
  if (buildCounterSubstringMatchCriteria < 3) {
    unittest.expect(o.matchCase!, unittest.isTrue);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubstringMatchCriteria--;
}

core.List<api.TableBorderRow> buildUnnamed2523() {
  var o = <api.TableBorderRow>[];
  o.add(buildTableBorderRow());
  o.add(buildTableBorderRow());
  return o;
}

void checkUnnamed2523(core.List<api.TableBorderRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableBorderRow(o[0] as api.TableBorderRow);
  checkTableBorderRow(o[1] as api.TableBorderRow);
}

core.List<api.TableColumnProperties> buildUnnamed2524() {
  var o = <api.TableColumnProperties>[];
  o.add(buildTableColumnProperties());
  o.add(buildTableColumnProperties());
  return o;
}

void checkUnnamed2524(core.List<api.TableColumnProperties> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableColumnProperties(o[0] as api.TableColumnProperties);
  checkTableColumnProperties(o[1] as api.TableColumnProperties);
}

core.List<api.TableRow> buildUnnamed2525() {
  var o = <api.TableRow>[];
  o.add(buildTableRow());
  o.add(buildTableRow());
  return o;
}

void checkUnnamed2525(core.List<api.TableRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableRow(o[0] as api.TableRow);
  checkTableRow(o[1] as api.TableRow);
}

core.List<api.TableBorderRow> buildUnnamed2526() {
  var o = <api.TableBorderRow>[];
  o.add(buildTableBorderRow());
  o.add(buildTableBorderRow());
  return o;
}

void checkUnnamed2526(core.List<api.TableBorderRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableBorderRow(o[0] as api.TableBorderRow);
  checkTableBorderRow(o[1] as api.TableBorderRow);
}

core.int buildCounterTable = 0;
api.Table buildTable() {
  var o = api.Table();
  buildCounterTable++;
  if (buildCounterTable < 3) {
    o.columns = 42;
    o.horizontalBorderRows = buildUnnamed2523();
    o.rows = 42;
    o.tableColumns = buildUnnamed2524();
    o.tableRows = buildUnnamed2525();
    o.verticalBorderRows = buildUnnamed2526();
  }
  buildCounterTable--;
  return o;
}

void checkTable(api.Table o) {
  buildCounterTable++;
  if (buildCounterTable < 3) {
    unittest.expect(
      o.columns!,
      unittest.equals(42),
    );
    checkUnnamed2523(o.horizontalBorderRows!);
    unittest.expect(
      o.rows!,
      unittest.equals(42),
    );
    checkUnnamed2524(o.tableColumns!);
    checkUnnamed2525(o.tableRows!);
    checkUnnamed2526(o.verticalBorderRows!);
  }
  buildCounterTable--;
}

core.int buildCounterTableBorderCell = 0;
api.TableBorderCell buildTableBorderCell() {
  var o = api.TableBorderCell();
  buildCounterTableBorderCell++;
  if (buildCounterTableBorderCell < 3) {
    o.location = buildTableCellLocation();
    o.tableBorderProperties = buildTableBorderProperties();
  }
  buildCounterTableBorderCell--;
  return o;
}

void checkTableBorderCell(api.TableBorderCell o) {
  buildCounterTableBorderCell++;
  if (buildCounterTableBorderCell < 3) {
    checkTableCellLocation(o.location! as api.TableCellLocation);
    checkTableBorderProperties(
        o.tableBorderProperties! as api.TableBorderProperties);
  }
  buildCounterTableBorderCell--;
}

core.int buildCounterTableBorderFill = 0;
api.TableBorderFill buildTableBorderFill() {
  var o = api.TableBorderFill();
  buildCounterTableBorderFill++;
  if (buildCounterTableBorderFill < 3) {
    o.solidFill = buildSolidFill();
  }
  buildCounterTableBorderFill--;
  return o;
}

void checkTableBorderFill(api.TableBorderFill o) {
  buildCounterTableBorderFill++;
  if (buildCounterTableBorderFill < 3) {
    checkSolidFill(o.solidFill! as api.SolidFill);
  }
  buildCounterTableBorderFill--;
}

core.int buildCounterTableBorderProperties = 0;
api.TableBorderProperties buildTableBorderProperties() {
  var o = api.TableBorderProperties();
  buildCounterTableBorderProperties++;
  if (buildCounterTableBorderProperties < 3) {
    o.dashStyle = 'foo';
    o.tableBorderFill = buildTableBorderFill();
    o.weight = buildDimension();
  }
  buildCounterTableBorderProperties--;
  return o;
}

void checkTableBorderProperties(api.TableBorderProperties o) {
  buildCounterTableBorderProperties++;
  if (buildCounterTableBorderProperties < 3) {
    unittest.expect(
      o.dashStyle!,
      unittest.equals('foo'),
    );
    checkTableBorderFill(o.tableBorderFill! as api.TableBorderFill);
    checkDimension(o.weight! as api.Dimension);
  }
  buildCounterTableBorderProperties--;
}

core.List<api.TableBorderCell> buildUnnamed2527() {
  var o = <api.TableBorderCell>[];
  o.add(buildTableBorderCell());
  o.add(buildTableBorderCell());
  return o;
}

void checkUnnamed2527(core.List<api.TableBorderCell> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableBorderCell(o[0] as api.TableBorderCell);
  checkTableBorderCell(o[1] as api.TableBorderCell);
}

core.int buildCounterTableBorderRow = 0;
api.TableBorderRow buildTableBorderRow() {
  var o = api.TableBorderRow();
  buildCounterTableBorderRow++;
  if (buildCounterTableBorderRow < 3) {
    o.tableBorderCells = buildUnnamed2527();
  }
  buildCounterTableBorderRow--;
  return o;
}

void checkTableBorderRow(api.TableBorderRow o) {
  buildCounterTableBorderRow++;
  if (buildCounterTableBorderRow < 3) {
    checkUnnamed2527(o.tableBorderCells!);
  }
  buildCounterTableBorderRow--;
}

core.int buildCounterTableCell = 0;
api.TableCell buildTableCell() {
  var o = api.TableCell();
  buildCounterTableCell++;
  if (buildCounterTableCell < 3) {
    o.columnSpan = 42;
    o.location = buildTableCellLocation();
    o.rowSpan = 42;
    o.tableCellProperties = buildTableCellProperties();
    o.text = buildTextContent();
  }
  buildCounterTableCell--;
  return o;
}

void checkTableCell(api.TableCell o) {
  buildCounterTableCell++;
  if (buildCounterTableCell < 3) {
    unittest.expect(
      o.columnSpan!,
      unittest.equals(42),
    );
    checkTableCellLocation(o.location! as api.TableCellLocation);
    unittest.expect(
      o.rowSpan!,
      unittest.equals(42),
    );
    checkTableCellProperties(o.tableCellProperties! as api.TableCellProperties);
    checkTextContent(o.text! as api.TextContent);
  }
  buildCounterTableCell--;
}

core.int buildCounterTableCellBackgroundFill = 0;
api.TableCellBackgroundFill buildTableCellBackgroundFill() {
  var o = api.TableCellBackgroundFill();
  buildCounterTableCellBackgroundFill++;
  if (buildCounterTableCellBackgroundFill < 3) {
    o.propertyState = 'foo';
    o.solidFill = buildSolidFill();
  }
  buildCounterTableCellBackgroundFill--;
  return o;
}

void checkTableCellBackgroundFill(api.TableCellBackgroundFill o) {
  buildCounterTableCellBackgroundFill++;
  if (buildCounterTableCellBackgroundFill < 3) {
    unittest.expect(
      o.propertyState!,
      unittest.equals('foo'),
    );
    checkSolidFill(o.solidFill! as api.SolidFill);
  }
  buildCounterTableCellBackgroundFill--;
}

core.int buildCounterTableCellLocation = 0;
api.TableCellLocation buildTableCellLocation() {
  var o = api.TableCellLocation();
  buildCounterTableCellLocation++;
  if (buildCounterTableCellLocation < 3) {
    o.columnIndex = 42;
    o.rowIndex = 42;
  }
  buildCounterTableCellLocation--;
  return o;
}

void checkTableCellLocation(api.TableCellLocation o) {
  buildCounterTableCellLocation++;
  if (buildCounterTableCellLocation < 3) {
    unittest.expect(
      o.columnIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rowIndex!,
      unittest.equals(42),
    );
  }
  buildCounterTableCellLocation--;
}

core.int buildCounterTableCellProperties = 0;
api.TableCellProperties buildTableCellProperties() {
  var o = api.TableCellProperties();
  buildCounterTableCellProperties++;
  if (buildCounterTableCellProperties < 3) {
    o.contentAlignment = 'foo';
    o.tableCellBackgroundFill = buildTableCellBackgroundFill();
  }
  buildCounterTableCellProperties--;
  return o;
}

void checkTableCellProperties(api.TableCellProperties o) {
  buildCounterTableCellProperties++;
  if (buildCounterTableCellProperties < 3) {
    unittest.expect(
      o.contentAlignment!,
      unittest.equals('foo'),
    );
    checkTableCellBackgroundFill(
        o.tableCellBackgroundFill! as api.TableCellBackgroundFill);
  }
  buildCounterTableCellProperties--;
}

core.int buildCounterTableColumnProperties = 0;
api.TableColumnProperties buildTableColumnProperties() {
  var o = api.TableColumnProperties();
  buildCounterTableColumnProperties++;
  if (buildCounterTableColumnProperties < 3) {
    o.columnWidth = buildDimension();
  }
  buildCounterTableColumnProperties--;
  return o;
}

void checkTableColumnProperties(api.TableColumnProperties o) {
  buildCounterTableColumnProperties++;
  if (buildCounterTableColumnProperties < 3) {
    checkDimension(o.columnWidth! as api.Dimension);
  }
  buildCounterTableColumnProperties--;
}

core.int buildCounterTableRange = 0;
api.TableRange buildTableRange() {
  var o = api.TableRange();
  buildCounterTableRange++;
  if (buildCounterTableRange < 3) {
    o.columnSpan = 42;
    o.location = buildTableCellLocation();
    o.rowSpan = 42;
  }
  buildCounterTableRange--;
  return o;
}

void checkTableRange(api.TableRange o) {
  buildCounterTableRange++;
  if (buildCounterTableRange < 3) {
    unittest.expect(
      o.columnSpan!,
      unittest.equals(42),
    );
    checkTableCellLocation(o.location! as api.TableCellLocation);
    unittest.expect(
      o.rowSpan!,
      unittest.equals(42),
    );
  }
  buildCounterTableRange--;
}

core.List<api.TableCell> buildUnnamed2528() {
  var o = <api.TableCell>[];
  o.add(buildTableCell());
  o.add(buildTableCell());
  return o;
}

void checkUnnamed2528(core.List<api.TableCell> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableCell(o[0] as api.TableCell);
  checkTableCell(o[1] as api.TableCell);
}

core.int buildCounterTableRow = 0;
api.TableRow buildTableRow() {
  var o = api.TableRow();
  buildCounterTableRow++;
  if (buildCounterTableRow < 3) {
    o.rowHeight = buildDimension();
    o.tableCells = buildUnnamed2528();
    o.tableRowProperties = buildTableRowProperties();
  }
  buildCounterTableRow--;
  return o;
}

void checkTableRow(api.TableRow o) {
  buildCounterTableRow++;
  if (buildCounterTableRow < 3) {
    checkDimension(o.rowHeight! as api.Dimension);
    checkUnnamed2528(o.tableCells!);
    checkTableRowProperties(o.tableRowProperties! as api.TableRowProperties);
  }
  buildCounterTableRow--;
}

core.int buildCounterTableRowProperties = 0;
api.TableRowProperties buildTableRowProperties() {
  var o = api.TableRowProperties();
  buildCounterTableRowProperties++;
  if (buildCounterTableRowProperties < 3) {
    o.minRowHeight = buildDimension();
  }
  buildCounterTableRowProperties--;
  return o;
}

void checkTableRowProperties(api.TableRowProperties o) {
  buildCounterTableRowProperties++;
  if (buildCounterTableRowProperties < 3) {
    checkDimension(o.minRowHeight! as api.Dimension);
  }
  buildCounterTableRowProperties--;
}

core.Map<core.String, api.List> buildUnnamed2529() {
  var o = <core.String, api.List>{};
  o['x'] = buildList();
  o['y'] = buildList();
  return o;
}

void checkUnnamed2529(core.Map<core.String, api.List> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkList(o['x']! as api.List);
  checkList(o['y']! as api.List);
}

core.List<api.TextElement> buildUnnamed2530() {
  var o = <api.TextElement>[];
  o.add(buildTextElement());
  o.add(buildTextElement());
  return o;
}

void checkUnnamed2530(core.List<api.TextElement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTextElement(o[0] as api.TextElement);
  checkTextElement(o[1] as api.TextElement);
}

core.int buildCounterTextContent = 0;
api.TextContent buildTextContent() {
  var o = api.TextContent();
  buildCounterTextContent++;
  if (buildCounterTextContent < 3) {
    o.lists = buildUnnamed2529();
    o.textElements = buildUnnamed2530();
  }
  buildCounterTextContent--;
  return o;
}

void checkTextContent(api.TextContent o) {
  buildCounterTextContent++;
  if (buildCounterTextContent < 3) {
    checkUnnamed2529(o.lists!);
    checkUnnamed2530(o.textElements!);
  }
  buildCounterTextContent--;
}

core.int buildCounterTextElement = 0;
api.TextElement buildTextElement() {
  var o = api.TextElement();
  buildCounterTextElement++;
  if (buildCounterTextElement < 3) {
    o.autoText = buildAutoText();
    o.endIndex = 42;
    o.paragraphMarker = buildParagraphMarker();
    o.startIndex = 42;
    o.textRun = buildTextRun();
  }
  buildCounterTextElement--;
  return o;
}

void checkTextElement(api.TextElement o) {
  buildCounterTextElement++;
  if (buildCounterTextElement < 3) {
    checkAutoText(o.autoText! as api.AutoText);
    unittest.expect(
      o.endIndex!,
      unittest.equals(42),
    );
    checkParagraphMarker(o.paragraphMarker! as api.ParagraphMarker);
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    checkTextRun(o.textRun! as api.TextRun);
  }
  buildCounterTextElement--;
}

core.int buildCounterTextRun = 0;
api.TextRun buildTextRun() {
  var o = api.TextRun();
  buildCounterTextRun++;
  if (buildCounterTextRun < 3) {
    o.content = 'foo';
    o.style = buildTextStyle();
  }
  buildCounterTextRun--;
  return o;
}

void checkTextRun(api.TextRun o) {
  buildCounterTextRun++;
  if (buildCounterTextRun < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    checkTextStyle(o.style! as api.TextStyle);
  }
  buildCounterTextRun--;
}

core.int buildCounterTextStyle = 0;
api.TextStyle buildTextStyle() {
  var o = api.TextStyle();
  buildCounterTextStyle++;
  if (buildCounterTextStyle < 3) {
    o.backgroundColor = buildOptionalColor();
    o.baselineOffset = 'foo';
    o.bold = true;
    o.fontFamily = 'foo';
    o.fontSize = buildDimension();
    o.foregroundColor = buildOptionalColor();
    o.italic = true;
    o.link = buildLink();
    o.smallCaps = true;
    o.strikethrough = true;
    o.underline = true;
    o.weightedFontFamily = buildWeightedFontFamily();
  }
  buildCounterTextStyle--;
  return o;
}

void checkTextStyle(api.TextStyle o) {
  buildCounterTextStyle++;
  if (buildCounterTextStyle < 3) {
    checkOptionalColor(o.backgroundColor! as api.OptionalColor);
    unittest.expect(
      o.baselineOffset!,
      unittest.equals('foo'),
    );
    unittest.expect(o.bold!, unittest.isTrue);
    unittest.expect(
      o.fontFamily!,
      unittest.equals('foo'),
    );
    checkDimension(o.fontSize! as api.Dimension);
    checkOptionalColor(o.foregroundColor! as api.OptionalColor);
    unittest.expect(o.italic!, unittest.isTrue);
    checkLink(o.link! as api.Link);
    unittest.expect(o.smallCaps!, unittest.isTrue);
    unittest.expect(o.strikethrough!, unittest.isTrue);
    unittest.expect(o.underline!, unittest.isTrue);
    checkWeightedFontFamily(o.weightedFontFamily! as api.WeightedFontFamily);
  }
  buildCounterTextStyle--;
}

core.int buildCounterThemeColorPair = 0;
api.ThemeColorPair buildThemeColorPair() {
  var o = api.ThemeColorPair();
  buildCounterThemeColorPair++;
  if (buildCounterThemeColorPair < 3) {
    o.color = buildRgbColor();
    o.type = 'foo';
  }
  buildCounterThemeColorPair--;
  return o;
}

void checkThemeColorPair(api.ThemeColorPair o) {
  buildCounterThemeColorPair++;
  if (buildCounterThemeColorPair < 3) {
    checkRgbColor(o.color! as api.RgbColor);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterThemeColorPair--;
}

core.int buildCounterThumbnail = 0;
api.Thumbnail buildThumbnail() {
  var o = api.Thumbnail();
  buildCounterThumbnail++;
  if (buildCounterThumbnail < 3) {
    o.contentUrl = 'foo';
    o.height = 42;
    o.width = 42;
  }
  buildCounterThumbnail--;
  return o;
}

void checkThumbnail(api.Thumbnail o) {
  buildCounterThumbnail++;
  if (buildCounterThumbnail < 3) {
    unittest.expect(
      o.contentUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.height!,
      unittest.equals(42),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterThumbnail--;
}

core.List<core.String> buildUnnamed2531() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2531(core.List<core.String> o) {
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

core.int buildCounterUngroupObjectsRequest = 0;
api.UngroupObjectsRequest buildUngroupObjectsRequest() {
  var o = api.UngroupObjectsRequest();
  buildCounterUngroupObjectsRequest++;
  if (buildCounterUngroupObjectsRequest < 3) {
    o.objectIds = buildUnnamed2531();
  }
  buildCounterUngroupObjectsRequest--;
  return o;
}

void checkUngroupObjectsRequest(api.UngroupObjectsRequest o) {
  buildCounterUngroupObjectsRequest++;
  if (buildCounterUngroupObjectsRequest < 3) {
    checkUnnamed2531(o.objectIds!);
  }
  buildCounterUngroupObjectsRequest--;
}

core.int buildCounterUnmergeTableCellsRequest = 0;
api.UnmergeTableCellsRequest buildUnmergeTableCellsRequest() {
  var o = api.UnmergeTableCellsRequest();
  buildCounterUnmergeTableCellsRequest++;
  if (buildCounterUnmergeTableCellsRequest < 3) {
    o.objectId = 'foo';
    o.tableRange = buildTableRange();
  }
  buildCounterUnmergeTableCellsRequest--;
  return o;
}

void checkUnmergeTableCellsRequest(api.UnmergeTableCellsRequest o) {
  buildCounterUnmergeTableCellsRequest++;
  if (buildCounterUnmergeTableCellsRequest < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkTableRange(o.tableRange! as api.TableRange);
  }
  buildCounterUnmergeTableCellsRequest--;
}

core.int buildCounterUpdateImagePropertiesRequest = 0;
api.UpdateImagePropertiesRequest buildUpdateImagePropertiesRequest() {
  var o = api.UpdateImagePropertiesRequest();
  buildCounterUpdateImagePropertiesRequest++;
  if (buildCounterUpdateImagePropertiesRequest < 3) {
    o.fields = 'foo';
    o.imageProperties = buildImageProperties();
    o.objectId = 'foo';
  }
  buildCounterUpdateImagePropertiesRequest--;
  return o;
}

void checkUpdateImagePropertiesRequest(api.UpdateImagePropertiesRequest o) {
  buildCounterUpdateImagePropertiesRequest++;
  if (buildCounterUpdateImagePropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkImageProperties(o.imageProperties! as api.ImageProperties);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateImagePropertiesRequest--;
}

core.int buildCounterUpdateLineCategoryRequest = 0;
api.UpdateLineCategoryRequest buildUpdateLineCategoryRequest() {
  var o = api.UpdateLineCategoryRequest();
  buildCounterUpdateLineCategoryRequest++;
  if (buildCounterUpdateLineCategoryRequest < 3) {
    o.lineCategory = 'foo';
    o.objectId = 'foo';
  }
  buildCounterUpdateLineCategoryRequest--;
  return o;
}

void checkUpdateLineCategoryRequest(api.UpdateLineCategoryRequest o) {
  buildCounterUpdateLineCategoryRequest++;
  if (buildCounterUpdateLineCategoryRequest < 3) {
    unittest.expect(
      o.lineCategory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateLineCategoryRequest--;
}

core.int buildCounterUpdateLinePropertiesRequest = 0;
api.UpdateLinePropertiesRequest buildUpdateLinePropertiesRequest() {
  var o = api.UpdateLinePropertiesRequest();
  buildCounterUpdateLinePropertiesRequest++;
  if (buildCounterUpdateLinePropertiesRequest < 3) {
    o.fields = 'foo';
    o.lineProperties = buildLineProperties();
    o.objectId = 'foo';
  }
  buildCounterUpdateLinePropertiesRequest--;
  return o;
}

void checkUpdateLinePropertiesRequest(api.UpdateLinePropertiesRequest o) {
  buildCounterUpdateLinePropertiesRequest++;
  if (buildCounterUpdateLinePropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkLineProperties(o.lineProperties! as api.LineProperties);
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateLinePropertiesRequest--;
}

core.int buildCounterUpdatePageElementAltTextRequest = 0;
api.UpdatePageElementAltTextRequest buildUpdatePageElementAltTextRequest() {
  var o = api.UpdatePageElementAltTextRequest();
  buildCounterUpdatePageElementAltTextRequest++;
  if (buildCounterUpdatePageElementAltTextRequest < 3) {
    o.description = 'foo';
    o.objectId = 'foo';
    o.title = 'foo';
  }
  buildCounterUpdatePageElementAltTextRequest--;
  return o;
}

void checkUpdatePageElementAltTextRequest(
    api.UpdatePageElementAltTextRequest o) {
  buildCounterUpdatePageElementAltTextRequest++;
  if (buildCounterUpdatePageElementAltTextRequest < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdatePageElementAltTextRequest--;
}

core.int buildCounterUpdatePageElementTransformRequest = 0;
api.UpdatePageElementTransformRequest buildUpdatePageElementTransformRequest() {
  var o = api.UpdatePageElementTransformRequest();
  buildCounterUpdatePageElementTransformRequest++;
  if (buildCounterUpdatePageElementTransformRequest < 3) {
    o.applyMode = 'foo';
    o.objectId = 'foo';
    o.transform = buildAffineTransform();
  }
  buildCounterUpdatePageElementTransformRequest--;
  return o;
}

void checkUpdatePageElementTransformRequest(
    api.UpdatePageElementTransformRequest o) {
  buildCounterUpdatePageElementTransformRequest++;
  if (buildCounterUpdatePageElementTransformRequest < 3) {
    unittest.expect(
      o.applyMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkAffineTransform(o.transform! as api.AffineTransform);
  }
  buildCounterUpdatePageElementTransformRequest--;
}

core.List<core.String> buildUnnamed2532() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2532(core.List<core.String> o) {
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

core.int buildCounterUpdatePageElementsZOrderRequest = 0;
api.UpdatePageElementsZOrderRequest buildUpdatePageElementsZOrderRequest() {
  var o = api.UpdatePageElementsZOrderRequest();
  buildCounterUpdatePageElementsZOrderRequest++;
  if (buildCounterUpdatePageElementsZOrderRequest < 3) {
    o.operation = 'foo';
    o.pageElementObjectIds = buildUnnamed2532();
  }
  buildCounterUpdatePageElementsZOrderRequest--;
  return o;
}

void checkUpdatePageElementsZOrderRequest(
    api.UpdatePageElementsZOrderRequest o) {
  buildCounterUpdatePageElementsZOrderRequest++;
  if (buildCounterUpdatePageElementsZOrderRequest < 3) {
    unittest.expect(
      o.operation!,
      unittest.equals('foo'),
    );
    checkUnnamed2532(o.pageElementObjectIds!);
  }
  buildCounterUpdatePageElementsZOrderRequest--;
}

core.int buildCounterUpdatePagePropertiesRequest = 0;
api.UpdatePagePropertiesRequest buildUpdatePagePropertiesRequest() {
  var o = api.UpdatePagePropertiesRequest();
  buildCounterUpdatePagePropertiesRequest++;
  if (buildCounterUpdatePagePropertiesRequest < 3) {
    o.fields = 'foo';
    o.objectId = 'foo';
    o.pageProperties = buildPageProperties();
  }
  buildCounterUpdatePagePropertiesRequest--;
  return o;
}

void checkUpdatePagePropertiesRequest(api.UpdatePagePropertiesRequest o) {
  buildCounterUpdatePagePropertiesRequest++;
  if (buildCounterUpdatePagePropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkPageProperties(o.pageProperties! as api.PageProperties);
  }
  buildCounterUpdatePagePropertiesRequest--;
}

core.int buildCounterUpdateParagraphStyleRequest = 0;
api.UpdateParagraphStyleRequest buildUpdateParagraphStyleRequest() {
  var o = api.UpdateParagraphStyleRequest();
  buildCounterUpdateParagraphStyleRequest++;
  if (buildCounterUpdateParagraphStyleRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.fields = 'foo';
    o.objectId = 'foo';
    o.style = buildParagraphStyle();
    o.textRange = buildRange();
  }
  buildCounterUpdateParagraphStyleRequest--;
  return o;
}

void checkUpdateParagraphStyleRequest(api.UpdateParagraphStyleRequest o) {
  buildCounterUpdateParagraphStyleRequest++;
  if (buildCounterUpdateParagraphStyleRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkParagraphStyle(o.style! as api.ParagraphStyle);
    checkRange(o.textRange! as api.Range);
  }
  buildCounterUpdateParagraphStyleRequest--;
}

core.int buildCounterUpdateShapePropertiesRequest = 0;
api.UpdateShapePropertiesRequest buildUpdateShapePropertiesRequest() {
  var o = api.UpdateShapePropertiesRequest();
  buildCounterUpdateShapePropertiesRequest++;
  if (buildCounterUpdateShapePropertiesRequest < 3) {
    o.fields = 'foo';
    o.objectId = 'foo';
    o.shapeProperties = buildShapeProperties();
  }
  buildCounterUpdateShapePropertiesRequest--;
  return o;
}

void checkUpdateShapePropertiesRequest(api.UpdateShapePropertiesRequest o) {
  buildCounterUpdateShapePropertiesRequest++;
  if (buildCounterUpdateShapePropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkShapeProperties(o.shapeProperties! as api.ShapeProperties);
  }
  buildCounterUpdateShapePropertiesRequest--;
}

core.List<core.String> buildUnnamed2533() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2533(core.List<core.String> o) {
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

core.int buildCounterUpdateSlidesPositionRequest = 0;
api.UpdateSlidesPositionRequest buildUpdateSlidesPositionRequest() {
  var o = api.UpdateSlidesPositionRequest();
  buildCounterUpdateSlidesPositionRequest++;
  if (buildCounterUpdateSlidesPositionRequest < 3) {
    o.insertionIndex = 42;
    o.slideObjectIds = buildUnnamed2533();
  }
  buildCounterUpdateSlidesPositionRequest--;
  return o;
}

void checkUpdateSlidesPositionRequest(api.UpdateSlidesPositionRequest o) {
  buildCounterUpdateSlidesPositionRequest++;
  if (buildCounterUpdateSlidesPositionRequest < 3) {
    unittest.expect(
      o.insertionIndex!,
      unittest.equals(42),
    );
    checkUnnamed2533(o.slideObjectIds!);
  }
  buildCounterUpdateSlidesPositionRequest--;
}

core.int buildCounterUpdateTableBorderPropertiesRequest = 0;
api.UpdateTableBorderPropertiesRequest
    buildUpdateTableBorderPropertiesRequest() {
  var o = api.UpdateTableBorderPropertiesRequest();
  buildCounterUpdateTableBorderPropertiesRequest++;
  if (buildCounterUpdateTableBorderPropertiesRequest < 3) {
    o.borderPosition = 'foo';
    o.fields = 'foo';
    o.objectId = 'foo';
    o.tableBorderProperties = buildTableBorderProperties();
    o.tableRange = buildTableRange();
  }
  buildCounterUpdateTableBorderPropertiesRequest--;
  return o;
}

void checkUpdateTableBorderPropertiesRequest(
    api.UpdateTableBorderPropertiesRequest o) {
  buildCounterUpdateTableBorderPropertiesRequest++;
  if (buildCounterUpdateTableBorderPropertiesRequest < 3) {
    unittest.expect(
      o.borderPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkTableBorderProperties(
        o.tableBorderProperties! as api.TableBorderProperties);
    checkTableRange(o.tableRange! as api.TableRange);
  }
  buildCounterUpdateTableBorderPropertiesRequest--;
}

core.int buildCounterUpdateTableCellPropertiesRequest = 0;
api.UpdateTableCellPropertiesRequest buildUpdateTableCellPropertiesRequest() {
  var o = api.UpdateTableCellPropertiesRequest();
  buildCounterUpdateTableCellPropertiesRequest++;
  if (buildCounterUpdateTableCellPropertiesRequest < 3) {
    o.fields = 'foo';
    o.objectId = 'foo';
    o.tableCellProperties = buildTableCellProperties();
    o.tableRange = buildTableRange();
  }
  buildCounterUpdateTableCellPropertiesRequest--;
  return o;
}

void checkUpdateTableCellPropertiesRequest(
    api.UpdateTableCellPropertiesRequest o) {
  buildCounterUpdateTableCellPropertiesRequest++;
  if (buildCounterUpdateTableCellPropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkTableCellProperties(o.tableCellProperties! as api.TableCellProperties);
    checkTableRange(o.tableRange! as api.TableRange);
  }
  buildCounterUpdateTableCellPropertiesRequest--;
}

core.List<core.int> buildUnnamed2534() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2534(core.List<core.int> o) {
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

core.int buildCounterUpdateTableColumnPropertiesRequest = 0;
api.UpdateTableColumnPropertiesRequest
    buildUpdateTableColumnPropertiesRequest() {
  var o = api.UpdateTableColumnPropertiesRequest();
  buildCounterUpdateTableColumnPropertiesRequest++;
  if (buildCounterUpdateTableColumnPropertiesRequest < 3) {
    o.columnIndices = buildUnnamed2534();
    o.fields = 'foo';
    o.objectId = 'foo';
    o.tableColumnProperties = buildTableColumnProperties();
  }
  buildCounterUpdateTableColumnPropertiesRequest--;
  return o;
}

void checkUpdateTableColumnPropertiesRequest(
    api.UpdateTableColumnPropertiesRequest o) {
  buildCounterUpdateTableColumnPropertiesRequest++;
  if (buildCounterUpdateTableColumnPropertiesRequest < 3) {
    checkUnnamed2534(o.columnIndices!);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkTableColumnProperties(
        o.tableColumnProperties! as api.TableColumnProperties);
  }
  buildCounterUpdateTableColumnPropertiesRequest--;
}

core.List<core.int> buildUnnamed2535() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2535(core.List<core.int> o) {
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

core.int buildCounterUpdateTableRowPropertiesRequest = 0;
api.UpdateTableRowPropertiesRequest buildUpdateTableRowPropertiesRequest() {
  var o = api.UpdateTableRowPropertiesRequest();
  buildCounterUpdateTableRowPropertiesRequest++;
  if (buildCounterUpdateTableRowPropertiesRequest < 3) {
    o.fields = 'foo';
    o.objectId = 'foo';
    o.rowIndices = buildUnnamed2535();
    o.tableRowProperties = buildTableRowProperties();
  }
  buildCounterUpdateTableRowPropertiesRequest--;
  return o;
}

void checkUpdateTableRowPropertiesRequest(
    api.UpdateTableRowPropertiesRequest o) {
  buildCounterUpdateTableRowPropertiesRequest++;
  if (buildCounterUpdateTableRowPropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkUnnamed2535(o.rowIndices!);
    checkTableRowProperties(o.tableRowProperties! as api.TableRowProperties);
  }
  buildCounterUpdateTableRowPropertiesRequest--;
}

core.int buildCounterUpdateTextStyleRequest = 0;
api.UpdateTextStyleRequest buildUpdateTextStyleRequest() {
  var o = api.UpdateTextStyleRequest();
  buildCounterUpdateTextStyleRequest++;
  if (buildCounterUpdateTextStyleRequest < 3) {
    o.cellLocation = buildTableCellLocation();
    o.fields = 'foo';
    o.objectId = 'foo';
    o.style = buildTextStyle();
    o.textRange = buildRange();
  }
  buildCounterUpdateTextStyleRequest--;
  return o;
}

void checkUpdateTextStyleRequest(api.UpdateTextStyleRequest o) {
  buildCounterUpdateTextStyleRequest++;
  if (buildCounterUpdateTextStyleRequest < 3) {
    checkTableCellLocation(o.cellLocation! as api.TableCellLocation);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkTextStyle(o.style! as api.TextStyle);
    checkRange(o.textRange! as api.Range);
  }
  buildCounterUpdateTextStyleRequest--;
}

core.int buildCounterUpdateVideoPropertiesRequest = 0;
api.UpdateVideoPropertiesRequest buildUpdateVideoPropertiesRequest() {
  var o = api.UpdateVideoPropertiesRequest();
  buildCounterUpdateVideoPropertiesRequest++;
  if (buildCounterUpdateVideoPropertiesRequest < 3) {
    o.fields = 'foo';
    o.objectId = 'foo';
    o.videoProperties = buildVideoProperties();
  }
  buildCounterUpdateVideoPropertiesRequest--;
  return o;
}

void checkUpdateVideoPropertiesRequest(api.UpdateVideoPropertiesRequest o) {
  buildCounterUpdateVideoPropertiesRequest++;
  if (buildCounterUpdateVideoPropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
    checkVideoProperties(o.videoProperties! as api.VideoProperties);
  }
  buildCounterUpdateVideoPropertiesRequest--;
}

core.int buildCounterVideo = 0;
api.Video buildVideo() {
  var o = api.Video();
  buildCounterVideo++;
  if (buildCounterVideo < 3) {
    o.id = 'foo';
    o.source = 'foo';
    o.url = 'foo';
    o.videoProperties = buildVideoProperties();
  }
  buildCounterVideo--;
  return o;
}

void checkVideo(api.Video o) {
  buildCounterVideo++;
  if (buildCounterVideo < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.source!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
    checkVideoProperties(o.videoProperties! as api.VideoProperties);
  }
  buildCounterVideo--;
}

core.int buildCounterVideoProperties = 0;
api.VideoProperties buildVideoProperties() {
  var o = api.VideoProperties();
  buildCounterVideoProperties++;
  if (buildCounterVideoProperties < 3) {
    o.autoPlay = true;
    o.end = 42;
    o.mute = true;
    o.outline = buildOutline();
    o.start = 42;
  }
  buildCounterVideoProperties--;
  return o;
}

void checkVideoProperties(api.VideoProperties o) {
  buildCounterVideoProperties++;
  if (buildCounterVideoProperties < 3) {
    unittest.expect(o.autoPlay!, unittest.isTrue);
    unittest.expect(
      o.end!,
      unittest.equals(42),
    );
    unittest.expect(o.mute!, unittest.isTrue);
    checkOutline(o.outline! as api.Outline);
    unittest.expect(
      o.start!,
      unittest.equals(42),
    );
  }
  buildCounterVideoProperties--;
}

core.int buildCounterWeightedFontFamily = 0;
api.WeightedFontFamily buildWeightedFontFamily() {
  var o = api.WeightedFontFamily();
  buildCounterWeightedFontFamily++;
  if (buildCounterWeightedFontFamily < 3) {
    o.fontFamily = 'foo';
    o.weight = 42;
  }
  buildCounterWeightedFontFamily--;
  return o;
}

void checkWeightedFontFamily(api.WeightedFontFamily o) {
  buildCounterWeightedFontFamily++;
  if (buildCounterWeightedFontFamily < 3) {
    unittest.expect(
      o.fontFamily!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.weight!,
      unittest.equals(42),
    );
  }
  buildCounterWeightedFontFamily--;
}

core.int buildCounterWordArt = 0;
api.WordArt buildWordArt() {
  var o = api.WordArt();
  buildCounterWordArt++;
  if (buildCounterWordArt < 3) {
    o.renderedText = 'foo';
  }
  buildCounterWordArt--;
  return o;
}

void checkWordArt(api.WordArt o) {
  buildCounterWordArt++;
  if (buildCounterWordArt < 3) {
    unittest.expect(
      o.renderedText!,
      unittest.equals('foo'),
    );
  }
  buildCounterWordArt--;
}

core.int buildCounterWriteControl = 0;
api.WriteControl buildWriteControl() {
  var o = api.WriteControl();
  buildCounterWriteControl++;
  if (buildCounterWriteControl < 3) {
    o.requiredRevisionId = 'foo';
  }
  buildCounterWriteControl--;
  return o;
}

void checkWriteControl(api.WriteControl o) {
  buildCounterWriteControl++;
  if (buildCounterWriteControl < 3) {
    unittest.expect(
      o.requiredRevisionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterWriteControl--;
}

void main() {
  unittest.group('obj-schema-AffineTransform', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAffineTransform();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AffineTransform.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAffineTransform(od as api.AffineTransform);
    });
  });

  unittest.group('obj-schema-AutoText', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutoText();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AutoText.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAutoText(od as api.AutoText);
    });
  });

  unittest.group('obj-schema-Autofit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutofit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Autofit.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAutofit(od as api.Autofit);
    });
  });

  unittest.group('obj-schema-BatchUpdatePresentationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdatePresentationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdatePresentationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdatePresentationRequest(
          od as api.BatchUpdatePresentationRequest);
    });
  });

  unittest.group('obj-schema-BatchUpdatePresentationResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdatePresentationResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdatePresentationResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdatePresentationResponse(
          od as api.BatchUpdatePresentationResponse);
    });
  });

  unittest.group('obj-schema-Bullet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBullet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Bullet.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBullet(od as api.Bullet);
    });
  });

  unittest.group('obj-schema-ColorScheme', () {
    unittest.test('to-json--from-json', () async {
      var o = buildColorScheme();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ColorScheme.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkColorScheme(od as api.ColorScheme);
    });
  });

  unittest.group('obj-schema-ColorStop', () {
    unittest.test('to-json--from-json', () async {
      var o = buildColorStop();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ColorStop.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkColorStop(od as api.ColorStop);
    });
  });

  unittest.group('obj-schema-CreateImageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateImageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateImageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateImageRequest(od as api.CreateImageRequest);
    });
  });

  unittest.group('obj-schema-CreateImageResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateImageResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateImageResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateImageResponse(od as api.CreateImageResponse);
    });
  });

  unittest.group('obj-schema-CreateLineRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateLineRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateLineRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateLineRequest(od as api.CreateLineRequest);
    });
  });

  unittest.group('obj-schema-CreateLineResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateLineResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateLineResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateLineResponse(od as api.CreateLineResponse);
    });
  });

  unittest.group('obj-schema-CreateParagraphBulletsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateParagraphBulletsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateParagraphBulletsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateParagraphBulletsRequest(
          od as api.CreateParagraphBulletsRequest);
    });
  });

  unittest.group('obj-schema-CreateShapeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateShapeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateShapeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateShapeRequest(od as api.CreateShapeRequest);
    });
  });

  unittest.group('obj-schema-CreateShapeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateShapeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateShapeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateShapeResponse(od as api.CreateShapeResponse);
    });
  });

  unittest.group('obj-schema-CreateSheetsChartRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateSheetsChartRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateSheetsChartRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateSheetsChartRequest(od as api.CreateSheetsChartRequest);
    });
  });

  unittest.group('obj-schema-CreateSheetsChartResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateSheetsChartResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateSheetsChartResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateSheetsChartResponse(od as api.CreateSheetsChartResponse);
    });
  });

  unittest.group('obj-schema-CreateSlideRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateSlideRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateSlideRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateSlideRequest(od as api.CreateSlideRequest);
    });
  });

  unittest.group('obj-schema-CreateSlideResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateSlideResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateSlideResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateSlideResponse(od as api.CreateSlideResponse);
    });
  });

  unittest.group('obj-schema-CreateTableRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateTableRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateTableRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateTableRequest(od as api.CreateTableRequest);
    });
  });

  unittest.group('obj-schema-CreateTableResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateTableResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateTableResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateTableResponse(od as api.CreateTableResponse);
    });
  });

  unittest.group('obj-schema-CreateVideoRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateVideoRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateVideoRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateVideoRequest(od as api.CreateVideoRequest);
    });
  });

  unittest.group('obj-schema-CreateVideoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateVideoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateVideoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateVideoResponse(od as api.CreateVideoResponse);
    });
  });

  unittest.group('obj-schema-CropProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCropProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CropProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCropProperties(od as api.CropProperties);
    });
  });

  unittest.group('obj-schema-DeleteObjectRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteObjectRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteObjectRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteObjectRequest(od as api.DeleteObjectRequest);
    });
  });

  unittest.group('obj-schema-DeleteParagraphBulletsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteParagraphBulletsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteParagraphBulletsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteParagraphBulletsRequest(
          od as api.DeleteParagraphBulletsRequest);
    });
  });

  unittest.group('obj-schema-DeleteTableColumnRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteTableColumnRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteTableColumnRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteTableColumnRequest(od as api.DeleteTableColumnRequest);
    });
  });

  unittest.group('obj-schema-DeleteTableRowRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteTableRowRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteTableRowRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteTableRowRequest(od as api.DeleteTableRowRequest);
    });
  });

  unittest.group('obj-schema-DeleteTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteTextRequest(od as api.DeleteTextRequest);
    });
  });

  unittest.group('obj-schema-Dimension', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimension();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Dimension.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDimension(od as api.Dimension);
    });
  });

  unittest.group('obj-schema-DuplicateObjectRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDuplicateObjectRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DuplicateObjectRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDuplicateObjectRequest(od as api.DuplicateObjectRequest);
    });
  });

  unittest.group('obj-schema-DuplicateObjectResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDuplicateObjectResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DuplicateObjectResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDuplicateObjectResponse(od as api.DuplicateObjectResponse);
    });
  });

  unittest.group('obj-schema-Group', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Group.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGroup(od as api.Group);
    });
  });

  unittest.group('obj-schema-GroupObjectsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupObjectsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupObjectsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupObjectsRequest(od as api.GroupObjectsRequest);
    });
  });

  unittest.group('obj-schema-GroupObjectsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupObjectsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupObjectsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupObjectsResponse(od as api.GroupObjectsResponse);
    });
  });

  unittest.group('obj-schema-Image', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Image.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImage(od as api.Image);
    });
  });

  unittest.group('obj-schema-ImageProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImageProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImageProperties(od as api.ImageProperties);
    });
  });

  unittest.group('obj-schema-InsertTableColumnsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertTableColumnsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertTableColumnsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertTableColumnsRequest(od as api.InsertTableColumnsRequest);
    });
  });

  unittest.group('obj-schema-InsertTableRowsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertTableRowsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertTableRowsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertTableRowsRequest(od as api.InsertTableRowsRequest);
    });
  });

  unittest.group('obj-schema-InsertTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertTextRequest(od as api.InsertTextRequest);
    });
  });

  unittest.group('obj-schema-LayoutPlaceholderIdMapping', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLayoutPlaceholderIdMapping();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LayoutPlaceholderIdMapping.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLayoutPlaceholderIdMapping(od as api.LayoutPlaceholderIdMapping);
    });
  });

  unittest.group('obj-schema-LayoutProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLayoutProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LayoutProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLayoutProperties(od as api.LayoutProperties);
    });
  });

  unittest.group('obj-schema-LayoutReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLayoutReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LayoutReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLayoutReference(od as api.LayoutReference);
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

  unittest.group('obj-schema-LineConnection', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLineConnection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LineConnection.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLineConnection(od as api.LineConnection);
    });
  });

  unittest.group('obj-schema-LineFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLineFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LineFill.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLineFill(od as api.LineFill);
    });
  });

  unittest.group('obj-schema-LineProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLineProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LineProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLineProperties(od as api.LineProperties);
    });
  });

  unittest.group('obj-schema-Link', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Link.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLink(od as api.Link);
    });
  });

  unittest.group('obj-schema-List', () {
    unittest.test('to-json--from-json', () async {
      var o = buildList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.List.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkList(od as api.List);
    });
  });

  unittest.group('obj-schema-MasterProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMasterProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MasterProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMasterProperties(od as api.MasterProperties);
    });
  });

  unittest.group('obj-schema-MergeTableCellsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMergeTableCellsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MergeTableCellsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMergeTableCellsRequest(od as api.MergeTableCellsRequest);
    });
  });

  unittest.group('obj-schema-NestingLevel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNestingLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NestingLevel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNestingLevel(od as api.NestingLevel);
    });
  });

  unittest.group('obj-schema-NotesProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotesProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotesProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotesProperties(od as api.NotesProperties);
    });
  });

  unittest.group('obj-schema-OpaqueColor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOpaqueColor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OpaqueColor.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOpaqueColor(od as api.OpaqueColor);
    });
  });

  unittest.group('obj-schema-OptionalColor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOptionalColor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OptionalColor.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOptionalColor(od as api.OptionalColor);
    });
  });

  unittest.group('obj-schema-Outline', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOutline();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Outline.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOutline(od as api.Outline);
    });
  });

  unittest.group('obj-schema-OutlineFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOutlineFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OutlineFill.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOutlineFill(od as api.OutlineFill);
    });
  });

  unittest.group('obj-schema-Page', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Page.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPage(od as api.Page);
    });
  });

  unittest.group('obj-schema-PageBackgroundFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPageBackgroundFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PageBackgroundFill.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPageBackgroundFill(od as api.PageBackgroundFill);
    });
  });

  unittest.group('obj-schema-PageElement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPageElement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PageElement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPageElement(od as api.PageElement);
    });
  });

  unittest.group('obj-schema-PageElementProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPageElementProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PageElementProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPageElementProperties(od as api.PageElementProperties);
    });
  });

  unittest.group('obj-schema-PageProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPageProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PageProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPageProperties(od as api.PageProperties);
    });
  });

  unittest.group('obj-schema-ParagraphMarker', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParagraphMarker();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ParagraphMarker.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkParagraphMarker(od as api.ParagraphMarker);
    });
  });

  unittest.group('obj-schema-ParagraphStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParagraphStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ParagraphStyle.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkParagraphStyle(od as api.ParagraphStyle);
    });
  });

  unittest.group('obj-schema-Placeholder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaceholder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Placeholder.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaceholder(od as api.Placeholder);
    });
  });

  unittest.group('obj-schema-Presentation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPresentation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Presentation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPresentation(od as api.Presentation);
    });
  });

  unittest.group('obj-schema-Range', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Range.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRange(od as api.Range);
    });
  });

  unittest.group('obj-schema-Recolor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecolor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Recolor.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRecolor(od as api.Recolor);
    });
  });

  unittest.group('obj-schema-RefreshSheetsChartRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRefreshSheetsChartRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RefreshSheetsChartRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRefreshSheetsChartRequest(od as api.RefreshSheetsChartRequest);
    });
  });

  unittest.group('obj-schema-ReplaceAllShapesWithImageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceAllShapesWithImageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceAllShapesWithImageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceAllShapesWithImageRequest(
          od as api.ReplaceAllShapesWithImageRequest);
    });
  });

  unittest.group('obj-schema-ReplaceAllShapesWithImageResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceAllShapesWithImageResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceAllShapesWithImageResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceAllShapesWithImageResponse(
          od as api.ReplaceAllShapesWithImageResponse);
    });
  });

  unittest.group('obj-schema-ReplaceAllShapesWithSheetsChartRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceAllShapesWithSheetsChartRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceAllShapesWithSheetsChartRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceAllShapesWithSheetsChartRequest(
          od as api.ReplaceAllShapesWithSheetsChartRequest);
    });
  });

  unittest.group('obj-schema-ReplaceAllShapesWithSheetsChartResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceAllShapesWithSheetsChartResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceAllShapesWithSheetsChartResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceAllShapesWithSheetsChartResponse(
          od as api.ReplaceAllShapesWithSheetsChartResponse);
    });
  });

  unittest.group('obj-schema-ReplaceAllTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceAllTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceAllTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceAllTextRequest(od as api.ReplaceAllTextRequest);
    });
  });

  unittest.group('obj-schema-ReplaceAllTextResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceAllTextResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceAllTextResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceAllTextResponse(od as api.ReplaceAllTextResponse);
    });
  });

  unittest.group('obj-schema-ReplaceImageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceImageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceImageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceImageRequest(od as api.ReplaceImageRequest);
    });
  });

  unittest.group('obj-schema-Request', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Request.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRequest(od as api.Request);
    });
  });

  unittest.group('obj-schema-RerouteLineRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRerouteLineRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RerouteLineRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRerouteLineRequest(od as api.RerouteLineRequest);
    });
  });

  unittest.group('obj-schema-Response', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Response.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResponse(od as api.Response);
    });
  });

  unittest.group('obj-schema-RgbColor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRgbColor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RgbColor.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRgbColor(od as api.RgbColor);
    });
  });

  unittest.group('obj-schema-Shadow', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShadow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Shadow.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkShadow(od as api.Shadow);
    });
  });

  unittest.group('obj-schema-Shape', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShape();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Shape.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkShape(od as api.Shape);
    });
  });

  unittest.group('obj-schema-ShapeBackgroundFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShapeBackgroundFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ShapeBackgroundFill.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkShapeBackgroundFill(od as api.ShapeBackgroundFill);
    });
  });

  unittest.group('obj-schema-ShapeProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShapeProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ShapeProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkShapeProperties(od as api.ShapeProperties);
    });
  });

  unittest.group('obj-schema-SheetsChart', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSheetsChart();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SheetsChart.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSheetsChart(od as api.SheetsChart);
    });
  });

  unittest.group('obj-schema-SheetsChartProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSheetsChartProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SheetsChartProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSheetsChartProperties(od as api.SheetsChartProperties);
    });
  });

  unittest.group('obj-schema-Size', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSize();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Size.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSize(od as api.Size);
    });
  });

  unittest.group('obj-schema-SlideProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSlideProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SlideProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSlideProperties(od as api.SlideProperties);
    });
  });

  unittest.group('obj-schema-SolidFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSolidFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SolidFill.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSolidFill(od as api.SolidFill);
    });
  });

  unittest.group('obj-schema-StretchedPictureFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStretchedPictureFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StretchedPictureFill.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStretchedPictureFill(od as api.StretchedPictureFill);
    });
  });

  unittest.group('obj-schema-SubstringMatchCriteria', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubstringMatchCriteria();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubstringMatchCriteria.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubstringMatchCriteria(od as api.SubstringMatchCriteria);
    });
  });

  unittest.group('obj-schema-Table', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Table.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTable(od as api.Table);
    });
  });

  unittest.group('obj-schema-TableBorderCell', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableBorderCell();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableBorderCell.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableBorderCell(od as api.TableBorderCell);
    });
  });

  unittest.group('obj-schema-TableBorderFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableBorderFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableBorderFill.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableBorderFill(od as api.TableBorderFill);
    });
  });

  unittest.group('obj-schema-TableBorderProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableBorderProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableBorderProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableBorderProperties(od as api.TableBorderProperties);
    });
  });

  unittest.group('obj-schema-TableBorderRow', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableBorderRow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableBorderRow.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableBorderRow(od as api.TableBorderRow);
    });
  });

  unittest.group('obj-schema-TableCell', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableCell();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TableCell.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTableCell(od as api.TableCell);
    });
  });

  unittest.group('obj-schema-TableCellBackgroundFill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableCellBackgroundFill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableCellBackgroundFill.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableCellBackgroundFill(od as api.TableCellBackgroundFill);
    });
  });

  unittest.group('obj-schema-TableCellLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableCellLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableCellLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableCellLocation(od as api.TableCellLocation);
    });
  });

  unittest.group('obj-schema-TableCellProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableCellProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableCellProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableCellProperties(od as api.TableCellProperties);
    });
  });

  unittest.group('obj-schema-TableColumnProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableColumnProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableColumnProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableColumnProperties(od as api.TableColumnProperties);
    });
  });

  unittest.group('obj-schema-TableRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TableRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTableRange(od as api.TableRange);
    });
  });

  unittest.group('obj-schema-TableRow', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableRow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TableRow.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTableRow(od as api.TableRow);
    });
  });

  unittest.group('obj-schema-TableRowProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableRowProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableRowProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableRowProperties(od as api.TableRowProperties);
    });
  });

  unittest.group('obj-schema-TextContent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextContent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextContent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextContent(od as api.TextContent);
    });
  });

  unittest.group('obj-schema-TextElement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextElement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextElement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextElement(od as api.TextElement);
    });
  });

  unittest.group('obj-schema-TextRun', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextRun();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TextRun.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTextRun(od as api.TextRun);
    });
  });

  unittest.group('obj-schema-TextStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TextStyle.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTextStyle(od as api.TextStyle);
    });
  });

  unittest.group('obj-schema-ThemeColorPair', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThemeColorPair();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThemeColorPair.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThemeColorPair(od as api.ThemeColorPair);
    });
  });

  unittest.group('obj-schema-Thumbnail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThumbnail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Thumbnail.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkThumbnail(od as api.Thumbnail);
    });
  });

  unittest.group('obj-schema-UngroupObjectsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUngroupObjectsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UngroupObjectsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUngroupObjectsRequest(od as api.UngroupObjectsRequest);
    });
  });

  unittest.group('obj-schema-UnmergeTableCellsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnmergeTableCellsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnmergeTableCellsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnmergeTableCellsRequest(od as api.UnmergeTableCellsRequest);
    });
  });

  unittest.group('obj-schema-UpdateImagePropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateImagePropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateImagePropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateImagePropertiesRequest(od as api.UpdateImagePropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateLineCategoryRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateLineCategoryRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateLineCategoryRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateLineCategoryRequest(od as api.UpdateLineCategoryRequest);
    });
  });

  unittest.group('obj-schema-UpdateLinePropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateLinePropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateLinePropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateLinePropertiesRequest(od as api.UpdateLinePropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdatePageElementAltTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdatePageElementAltTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdatePageElementAltTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdatePageElementAltTextRequest(
          od as api.UpdatePageElementAltTextRequest);
    });
  });

  unittest.group('obj-schema-UpdatePageElementTransformRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdatePageElementTransformRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdatePageElementTransformRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdatePageElementTransformRequest(
          od as api.UpdatePageElementTransformRequest);
    });
  });

  unittest.group('obj-schema-UpdatePageElementsZOrderRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdatePageElementsZOrderRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdatePageElementsZOrderRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdatePageElementsZOrderRequest(
          od as api.UpdatePageElementsZOrderRequest);
    });
  });

  unittest.group('obj-schema-UpdatePagePropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdatePagePropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdatePagePropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdatePagePropertiesRequest(od as api.UpdatePagePropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateParagraphStyleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateParagraphStyleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateParagraphStyleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateParagraphStyleRequest(od as api.UpdateParagraphStyleRequest);
    });
  });

  unittest.group('obj-schema-UpdateShapePropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateShapePropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateShapePropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateShapePropertiesRequest(od as api.UpdateShapePropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateSlidesPositionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateSlidesPositionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateSlidesPositionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateSlidesPositionRequest(od as api.UpdateSlidesPositionRequest);
    });
  });

  unittest.group('obj-schema-UpdateTableBorderPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTableBorderPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTableBorderPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTableBorderPropertiesRequest(
          od as api.UpdateTableBorderPropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateTableCellPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTableCellPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTableCellPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTableCellPropertiesRequest(
          od as api.UpdateTableCellPropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateTableColumnPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTableColumnPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTableColumnPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTableColumnPropertiesRequest(
          od as api.UpdateTableColumnPropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateTableRowPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTableRowPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTableRowPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTableRowPropertiesRequest(
          od as api.UpdateTableRowPropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateTextStyleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTextStyleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTextStyleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTextStyleRequest(od as api.UpdateTextStyleRequest);
    });
  });

  unittest.group('obj-schema-UpdateVideoPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateVideoPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateVideoPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateVideoPropertiesRequest(od as api.UpdateVideoPropertiesRequest);
    });
  });

  unittest.group('obj-schema-Video', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Video.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVideo(od as api.Video);
    });
  });

  unittest.group('obj-schema-VideoProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoProperties(od as api.VideoProperties);
    });
  });

  unittest.group('obj-schema-WeightedFontFamily', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWeightedFontFamily();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WeightedFontFamily.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWeightedFontFamily(od as api.WeightedFontFamily);
    });
  });

  unittest.group('obj-schema-WordArt', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWordArt();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.WordArt.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkWordArt(od as api.WordArt);
    });
  });

  unittest.group('obj-schema-WriteControl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWriteControl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WriteControl.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWriteControl(od as api.WriteControl);
    });
  });

  unittest.group('resource-PresentationsResource', () {
    unittest.test('method--batchUpdate', () async {
      var mock = HttpServerMock();
      var res = api.SlidesApi(mock).presentations;
      var arg_request = buildBatchUpdatePresentationRequest();
      var arg_presentationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchUpdatePresentationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchUpdatePresentationRequest(
            obj as api.BatchUpdatePresentationRequest);

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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v1/presentations/"),
        );
        pathOffset += 17;
        index = path.indexOf(':batchUpdate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_presentationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals(":batchUpdate"),
        );
        pathOffset += 12;

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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchUpdatePresentationResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchUpdate(arg_request, arg_presentationId,
          $fields: arg_$fields);
      checkBatchUpdatePresentationResponse(
          response as api.BatchUpdatePresentationResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SlidesApi(mock).presentations;
      var arg_request = buildPresentation();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Presentation.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPresentation(obj as api.Presentation);

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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/presentations"),
        );
        pathOffset += 16;

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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPresentation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkPresentation(response as api.Presentation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SlidesApi(mock).presentations;
      var arg_presentationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v1/presentations/"),
        );
        pathOffset += 17;
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPresentation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_presentationId, $fields: arg_$fields);
      checkPresentation(response as api.Presentation);
    });
  });

  unittest.group('resource-PresentationsPagesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SlidesApi(mock).presentations.pages;
      var arg_presentationId = 'foo';
      var arg_pageObjectId = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v1/presentations/"),
        );
        pathOffset += 17;
        index = path.indexOf('/pages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_presentationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/pages/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_pageObjectId'),
        );

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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_presentationId, arg_pageObjectId,
          $fields: arg_$fields);
      checkPage(response as api.Page);
    });

    unittest.test('method--getThumbnail', () async {
      var mock = HttpServerMock();
      var res = api.SlidesApi(mock).presentations.pages;
      var arg_presentationId = 'foo';
      var arg_pageObjectId = 'foo';
      var arg_thumbnailProperties_mimeType = 'foo';
      var arg_thumbnailProperties_thumbnailSize = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v1/presentations/"),
        );
        pathOffset += 17;
        index = path.indexOf('/pages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_presentationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/pages/"),
        );
        pathOffset += 7;
        index = path.indexOf('/thumbnail', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_pageObjectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/thumbnail"),
        );
        pathOffset += 10;

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
          queryMap["thumbnailProperties.mimeType"]!.first,
          unittest.equals(arg_thumbnailProperties_mimeType),
        );
        unittest.expect(
          queryMap["thumbnailProperties.thumbnailSize"]!.first,
          unittest.equals(arg_thumbnailProperties_thumbnailSize),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildThumbnail());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getThumbnail(
          arg_presentationId, arg_pageObjectId,
          thumbnailProperties_mimeType: arg_thumbnailProperties_mimeType,
          thumbnailProperties_thumbnailSize:
              arg_thumbnailProperties_thumbnailSize,
          $fields: arg_$fields);
      checkThumbnail(response as api.Thumbnail);
    });
  });
}
