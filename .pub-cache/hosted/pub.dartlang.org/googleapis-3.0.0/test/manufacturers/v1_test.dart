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

import 'package:googleapis/manufacturers/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Image> buildUnnamed2094() {
  var o = <api.Image>[];
  o.add(buildImage());
  o.add(buildImage());
  return o;
}

void checkUnnamed2094(core.List<api.Image> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImage(o[0] as api.Image);
  checkImage(o[1] as api.Image);
}

core.List<core.String> buildUnnamed2095() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2095(core.List<core.String> o) {
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

core.List<api.FeatureDescription> buildUnnamed2096() {
  var o = <api.FeatureDescription>[];
  o.add(buildFeatureDescription());
  o.add(buildFeatureDescription());
  return o;
}

void checkUnnamed2096(core.List<api.FeatureDescription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFeatureDescription(o[0] as api.FeatureDescription);
  checkFeatureDescription(o[1] as api.FeatureDescription);
}

core.List<core.String> buildUnnamed2097() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2097(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2098() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2098(core.List<core.String> o) {
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

core.List<api.ProductDetail> buildUnnamed2099() {
  var o = <api.ProductDetail>[];
  o.add(buildProductDetail());
  o.add(buildProductDetail());
  return o;
}

void checkUnnamed2099(core.List<api.ProductDetail> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProductDetail(o[0] as api.ProductDetail);
  checkProductDetail(o[1] as api.ProductDetail);
}

core.List<core.String> buildUnnamed2100() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2100(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2101() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2101(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2102() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2102(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2103() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2103(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2104() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2104(core.List<core.String> o) {
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

core.int buildCounterAttributes = 0;
api.Attributes buildAttributes() {
  var o = api.Attributes();
  buildCounterAttributes++;
  if (buildCounterAttributes < 3) {
    o.additionalImageLink = buildUnnamed2094();
    o.ageGroup = 'foo';
    o.brand = 'foo';
    o.capacity = buildCapacity();
    o.color = 'foo';
    o.count = buildCount();
    o.description = 'foo';
    o.disclosureDate = 'foo';
    o.excludedDestination = buildUnnamed2095();
    o.featureDescription = buildUnnamed2096();
    o.flavor = 'foo';
    o.format = 'foo';
    o.gender = 'foo';
    o.gtin = buildUnnamed2097();
    o.imageLink = buildImage();
    o.includedDestination = buildUnnamed2098();
    o.itemGroupId = 'foo';
    o.material = 'foo';
    o.mpn = 'foo';
    o.pattern = 'foo';
    o.productDetail = buildUnnamed2099();
    o.productHighlight = buildUnnamed2100();
    o.productLine = 'foo';
    o.productName = 'foo';
    o.productPageUrl = 'foo';
    o.productType = buildUnnamed2101();
    o.releaseDate = 'foo';
    o.richProductContent = buildUnnamed2102();
    o.scent = 'foo';
    o.size = 'foo';
    o.sizeSystem = 'foo';
    o.sizeType = buildUnnamed2103();
    o.suggestedRetailPrice = buildPrice();
    o.targetClientId = 'foo';
    o.theme = 'foo';
    o.title = 'foo';
    o.videoLink = buildUnnamed2104();
  }
  buildCounterAttributes--;
  return o;
}

void checkAttributes(api.Attributes o) {
  buildCounterAttributes++;
  if (buildCounterAttributes < 3) {
    checkUnnamed2094(o.additionalImageLink!);
    unittest.expect(
      o.ageGroup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.brand!,
      unittest.equals('foo'),
    );
    checkCapacity(o.capacity! as api.Capacity);
    unittest.expect(
      o.color!,
      unittest.equals('foo'),
    );
    checkCount(o.count! as api.Count);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.disclosureDate!,
      unittest.equals('foo'),
    );
    checkUnnamed2095(o.excludedDestination!);
    checkUnnamed2096(o.featureDescription!);
    unittest.expect(
      o.flavor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gender!,
      unittest.equals('foo'),
    );
    checkUnnamed2097(o.gtin!);
    checkImage(o.imageLink! as api.Image);
    checkUnnamed2098(o.includedDestination!);
    unittest.expect(
      o.itemGroupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.material!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mpn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pattern!,
      unittest.equals('foo'),
    );
    checkUnnamed2099(o.productDetail!);
    checkUnnamed2100(o.productHighlight!);
    unittest.expect(
      o.productLine!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productPageUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed2101(o.productType!);
    unittest.expect(
      o.releaseDate!,
      unittest.equals('foo'),
    );
    checkUnnamed2102(o.richProductContent!);
    unittest.expect(
      o.scent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sizeSystem!,
      unittest.equals('foo'),
    );
    checkUnnamed2103(o.sizeType!);
    checkPrice(o.suggestedRetailPrice! as api.Price);
    unittest.expect(
      o.targetClientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.theme!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    checkUnnamed2104(o.videoLink!);
  }
  buildCounterAttributes--;
}

core.int buildCounterCapacity = 0;
api.Capacity buildCapacity() {
  var o = api.Capacity();
  buildCounterCapacity++;
  if (buildCounterCapacity < 3) {
    o.unit = 'foo';
    o.value = 'foo';
  }
  buildCounterCapacity--;
  return o;
}

void checkCapacity(api.Capacity o) {
  buildCounterCapacity++;
  if (buildCounterCapacity < 3) {
    unittest.expect(
      o.unit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterCapacity--;
}

core.int buildCounterCount = 0;
api.Count buildCount() {
  var o = api.Count();
  buildCounterCount++;
  if (buildCounterCount < 3) {
    o.unit = 'foo';
    o.value = 'foo';
  }
  buildCounterCount--;
  return o;
}

void checkCount(api.Count o) {
  buildCounterCount++;
  if (buildCounterCount < 3) {
    unittest.expect(
      o.unit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterCount--;
}

core.int buildCounterDestinationStatus = 0;
api.DestinationStatus buildDestinationStatus() {
  var o = api.DestinationStatus();
  buildCounterDestinationStatus++;
  if (buildCounterDestinationStatus < 3) {
    o.destination = 'foo';
    o.status = 'foo';
  }
  buildCounterDestinationStatus--;
  return o;
}

void checkDestinationStatus(api.DestinationStatus o) {
  buildCounterDestinationStatus++;
  if (buildCounterDestinationStatus < 3) {
    unittest.expect(
      o.destination!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterDestinationStatus--;
}

core.int buildCounterEmpty = 0;
api.Empty buildEmpty() {
  var o = api.Empty();
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
  return o;
}

void checkEmpty(api.Empty o) {
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
}

core.int buildCounterFeatureDescription = 0;
api.FeatureDescription buildFeatureDescription() {
  var o = api.FeatureDescription();
  buildCounterFeatureDescription++;
  if (buildCounterFeatureDescription < 3) {
    o.headline = 'foo';
    o.image = buildImage();
    o.text = 'foo';
  }
  buildCounterFeatureDescription--;
  return o;
}

void checkFeatureDescription(api.FeatureDescription o) {
  buildCounterFeatureDescription++;
  if (buildCounterFeatureDescription < 3) {
    unittest.expect(
      o.headline!,
      unittest.equals('foo'),
    );
    checkImage(o.image! as api.Image);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterFeatureDescription--;
}

core.int buildCounterImage = 0;
api.Image buildImage() {
  var o = api.Image();
  buildCounterImage++;
  if (buildCounterImage < 3) {
    o.imageUrl = 'foo';
    o.status = 'foo';
    o.type = 'foo';
  }
  buildCounterImage--;
  return o;
}

void checkImage(api.Image o) {
  buildCounterImage++;
  if (buildCounterImage < 3) {
    unittest.expect(
      o.imageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterImage--;
}

core.int buildCounterIssue = 0;
api.Issue buildIssue() {
  var o = api.Issue();
  buildCounterIssue++;
  if (buildCounterIssue < 3) {
    o.attribute = 'foo';
    o.description = 'foo';
    o.destination = 'foo';
    o.resolution = 'foo';
    o.severity = 'foo';
    o.timestamp = 'foo';
    o.title = 'foo';
    o.type = 'foo';
  }
  buildCounterIssue--;
  return o;
}

void checkIssue(api.Issue o) {
  buildCounterIssue++;
  if (buildCounterIssue < 3) {
    unittest.expect(
      o.attribute!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destination!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resolution!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterIssue--;
}

core.List<api.Product> buildUnnamed2105() {
  var o = <api.Product>[];
  o.add(buildProduct());
  o.add(buildProduct());
  return o;
}

void checkUnnamed2105(core.List<api.Product> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProduct(o[0] as api.Product);
  checkProduct(o[1] as api.Product);
}

core.int buildCounterListProductsResponse = 0;
api.ListProductsResponse buildListProductsResponse() {
  var o = api.ListProductsResponse();
  buildCounterListProductsResponse++;
  if (buildCounterListProductsResponse < 3) {
    o.nextPageToken = 'foo';
    o.products = buildUnnamed2105();
  }
  buildCounterListProductsResponse--;
  return o;
}

void checkListProductsResponse(api.ListProductsResponse o) {
  buildCounterListProductsResponse++;
  if (buildCounterListProductsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2105(o.products!);
  }
  buildCounterListProductsResponse--;
}

core.int buildCounterPrice = 0;
api.Price buildPrice() {
  var o = api.Price();
  buildCounterPrice++;
  if (buildCounterPrice < 3) {
    o.amount = 'foo';
    o.currency = 'foo';
  }
  buildCounterPrice--;
  return o;
}

void checkPrice(api.Price o) {
  buildCounterPrice++;
  if (buildCounterPrice < 3) {
    unittest.expect(
      o.amount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currency!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrice--;
}

core.List<api.DestinationStatus> buildUnnamed2106() {
  var o = <api.DestinationStatus>[];
  o.add(buildDestinationStatus());
  o.add(buildDestinationStatus());
  return o;
}

void checkUnnamed2106(core.List<api.DestinationStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDestinationStatus(o[0] as api.DestinationStatus);
  checkDestinationStatus(o[1] as api.DestinationStatus);
}

core.List<api.Issue> buildUnnamed2107() {
  var o = <api.Issue>[];
  o.add(buildIssue());
  o.add(buildIssue());
  return o;
}

void checkUnnamed2107(core.List<api.Issue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIssue(o[0] as api.Issue);
  checkIssue(o[1] as api.Issue);
}

core.int buildCounterProduct = 0;
api.Product buildProduct() {
  var o = api.Product();
  buildCounterProduct++;
  if (buildCounterProduct < 3) {
    o.attributes = buildAttributes();
    o.contentLanguage = 'foo';
    o.destinationStatuses = buildUnnamed2106();
    o.issues = buildUnnamed2107();
    o.name = 'foo';
    o.parent = 'foo';
    o.productId = 'foo';
    o.targetCountry = 'foo';
  }
  buildCounterProduct--;
  return o;
}

void checkProduct(api.Product o) {
  buildCounterProduct++;
  if (buildCounterProduct < 3) {
    checkAttributes(o.attributes! as api.Attributes);
    unittest.expect(
      o.contentLanguage!,
      unittest.equals('foo'),
    );
    checkUnnamed2106(o.destinationStatuses!);
    checkUnnamed2107(o.issues!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetCountry!,
      unittest.equals('foo'),
    );
  }
  buildCounterProduct--;
}

core.int buildCounterProductDetail = 0;
api.ProductDetail buildProductDetail() {
  var o = api.ProductDetail();
  buildCounterProductDetail++;
  if (buildCounterProductDetail < 3) {
    o.attributeName = 'foo';
    o.attributeValue = 'foo';
    o.sectionName = 'foo';
  }
  buildCounterProductDetail--;
  return o;
}

void checkProductDetail(api.ProductDetail o) {
  buildCounterProductDetail++;
  if (buildCounterProductDetail < 3) {
    unittest.expect(
      o.attributeName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.attributeValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sectionName!,
      unittest.equals('foo'),
    );
  }
  buildCounterProductDetail--;
}

core.List<core.String> buildUnnamed2108() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2108(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2109() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2109(core.List<core.String> o) {
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
  unittest.group('obj-schema-Attributes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttributes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Attributes.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAttributes(od as api.Attributes);
    });
  });

  unittest.group('obj-schema-Capacity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCapacity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Capacity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCapacity(od as api.Capacity);
    });
  });

  unittest.group('obj-schema-Count', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Count.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCount(od as api.Count);
    });
  });

  unittest.group('obj-schema-DestinationStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDestinationStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DestinationStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDestinationStatus(od as api.DestinationStatus);
    });
  });

  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-FeatureDescription', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatureDescription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeatureDescription.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeatureDescription(od as api.FeatureDescription);
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

  unittest.group('obj-schema-Issue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIssue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Issue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIssue(od as api.Issue);
    });
  });

  unittest.group('obj-schema-ListProductsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListProductsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListProductsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListProductsResponse(od as api.ListProductsResponse);
    });
  });

  unittest.group('obj-schema-Price', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Price.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPrice(od as api.Price);
    });
  });

  unittest.group('obj-schema-Product', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProduct();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Product.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProduct(od as api.Product);
    });
  });

  unittest.group('obj-schema-ProductDetail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProductDetail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProductDetail.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProductDetail(od as api.ProductDetail);
    });
  });

  unittest.group('resource-AccountsProductsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ManufacturerCenterApi(mock).accounts.products;
      var arg_parent = 'foo';
      var arg_name = 'foo';
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_parent, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ManufacturerCenterApi(mock).accounts.products;
      var arg_parent = 'foo';
      var arg_name = 'foo';
      var arg_include = buildUnnamed2108();
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
          queryMap["include"]!,
          unittest.equals(arg_include),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildProduct());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_parent, arg_name,
          include: arg_include, $fields: arg_$fields);
      checkProduct(response as api.Product);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ManufacturerCenterApi(mock).accounts.products;
      var arg_parent = 'foo';
      var arg_include = buildUnnamed2109();
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          queryMap["include"]!,
          unittest.equals(arg_include),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListProductsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          include: arg_include,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListProductsResponse(response as api.ListProductsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.ManufacturerCenterApi(mock).accounts.products;
      var arg_request = buildAttributes();
      var arg_parent = 'foo';
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Attributes.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAttributes(obj as api.Attributes);

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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_parent, arg_name,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });
  });
}
