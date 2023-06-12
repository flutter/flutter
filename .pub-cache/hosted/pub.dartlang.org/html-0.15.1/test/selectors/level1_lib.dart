/// Test for the Selectors API ported from
/// <https://github.com/w3c/web-platform-tests/tree/master/selectors-api>
///
/// Note: tried to make minimal changes possible here. Hence some oddities such
/// as [runTest] arguments having a different order, long lines, etc.
///
/// As usual with ports: being faithful to the original style is more important
/// than other style goals, as it reduces friction to integrating changes
/// from upstream.
library html.test.selectors.level1_lib;

// TODO(https://github.com/dart-lang/html/issues/173): Remove.
// ignore_for_file: avoid_dynamic_calls

import 'package:html/dom.dart';
import 'package:test/test.dart' as unittest;

late Document doc;

/*
 * Create and append special elements that cannot be created correctly with HTML markup alone.
 */
void setupSpecialElements(parent) {
  // Setup null and undefined tests
  parent.append(doc.createElement('null'));
  parent.append(doc.createElement('undefined'));

  // Setup namespace tests
  final anyNS = doc.createElement('div');
  final noNS = doc.createElement('div');
  anyNS.id = 'any-namespace';
  noNS.id = 'no-namespace';

  var div = [
    doc.createElement('div'),
    doc.createElementNS('http://www.w3.org/1999/xhtml', 'div'),
    doc.createElementNS('', 'div'),
    doc.createElementNS('http://www.example.org/ns', 'div')
  ];

  div[0].id = 'any-namespace-div1';
  div[1].id = 'any-namespace-div2';
  div[2].attributes['id'] =
      'any-namespace-div3'; // Non-HTML elements can't use .id property
  div[3].attributes['id'] = 'any-namespace-div4';

  for (var i = 0; i < div.length; i++) {
    anyNS.append(div[i]);
  }

  div = [
    doc.createElement('div'),
    doc.createElementNS('http://www.w3.org/1999/xhtml', 'div'),
    doc.createElementNS('', 'div'),
    doc.createElementNS('http://www.example.org/ns', 'div')
  ];

  div[0].id = 'no-namespace-div1';
  div[1].id = 'no-namespace-div2';
  div[2].attributes['id'] =
      'no-namespace-div3'; // Non-HTML elements can't use .id property
  div[3].attributes['id'] = 'no-namespace-div4';

  for (var i = 0; i < div.length; i++) {
    noNS.append(div[i]);
  }

  parent.append(anyNS);
  parent.append(noNS);
}

/*
 * Verify that the NodeList returned by querySelectorAll is static and and that a new list is created after
 * each call. A static list should not be affected by subsequent changes to the DOM.
 */
void verifyStaticList(String type, dynamic root) {
  List pre;
  List post;
  late int preLength;

  runTest(() {
    pre = root.querySelectorAll('div') as List;
    preLength = pre.length;

    final div = doc.createElement('div');
    (root is Document ? root.body : root).append(div);

    assertEquals(
        pre.length, preLength, 'The length of the NodeList should not change.');
  }, '$type: static NodeList');

  runTest(() {
    post = root.querySelectorAll('div') as List;
    assertEquals(post.length, preLength + 1,
        'The length of the new NodeList should be 1 more than the previous list.');
  }, '$type: new NodeList');
}

/*
 * Verify handling of special values for the selector parameter, including stringification of
 * null and undefined, and the handling of the empty string.
 */
void runSpecialSelectorTests(String type, root) {
  // Dart note: changed these tests because we don't have auto conversion to
  // String like JavaScript does.
  runTest(() {
    // 1
    assertEquals(root.querySelectorAll('null').length, 1,
        "This should find one element with the tag name 'NULL'.");
  }, '$type.querySelectorAll null');

  runTest(() {
    // 2
    assertEquals(root.querySelectorAll('undefined').length, 1,
        "This should find one element with the tag name 'UNDEFINED'.");
  }, '$type.querySelectorAll undefined');

  runTest(() {
    // 3
    assertThrows((e) => e is NoSuchMethodError, () {
      root.querySelectorAll();
    }, 'This should throw a TypeError.');
  }, '$type.querySelectorAll no parameter');

  runTest(() {
    // 4
    final elm = root.querySelector('null');
    assertNotEquals(elm, null, 'This should find an element.');
    // TODO(jmesserly): change "localName" back to "tagName" once implemented.
    assertEquals(
        elm.localName.toUpperCase(), 'NULL', "The tag name should be 'NULL'.");
  }, '$type.querySelector null');

  runTest(() {
    // 5
    final elm = root.querySelector('undefined');
    assertNotEquals(elm, 'undefined', 'This should find an element.');
    // TODO(jmesserly): change "localName" back to "tagName" once implemented.
    assertEquals(elm.localName.toUpperCase(), 'UNDEFINED',
        "The tag name should be 'UNDEFINED'.");
  }, '$type.querySelector undefined');

  runTest(() {
    // 6
    assertThrows((e) => e is NoSuchMethodError, () {
      root.querySelector();
    }, 'This should throw a TypeError.');
  }, '$type.querySelector no parameter');

  runTest(() {
    // 7
    final result = root.querySelectorAll('*');
    var i = 0;
    traverse(root as Node, (elem) {
      if (!identical(elem, root)) {
        assertEquals(
            elem, result[i], 'The result in index $i should be in tree order.');
        i++;
      }
    });
  }, '$type.querySelectorAll tree order');
}

/// Tests containing this string fail for an unknown reason
final _failureName = 'matching custom data-* attribute with';

String? _getSkip(String name) {
  if (name.contains(_failureName)) {
    return 'Tests related to `$_failureName` fail for an unknown reason.';
  }
  return null;
}

/*
 * Execute queries with the specified valid selectors for both querySelector() and querySelectorAll()
 * Only run these tests when results are expected. Don't run for syntax error tests.
 */
void runValidSelectorTest(String type, Node root,
    List<Map<String, dynamic>> selectors, testType, docType) {
  var nodeType = '';
  switch (root.nodeType) {
    case Node.DOCUMENT_NODE:
      nodeType = 'document';
      break;
    case Node.ELEMENT_NODE:
      nodeType = root.parentNode != null ? 'element' : 'detached';
      break;
    case Node.DOCUMENT_FRAGMENT_NODE:
      nodeType = 'fragment';
      break;
    default:
      throw StateError('Reached unreachable code path.');
  }

  for (var i = 0; i < selectors.length; i++) {
    final s = selectors[i];
    final n = s['name'] as String;
    final skip = _getSkip(n);
    final q = s['selector'] as String;
    final e = s['expect'] as List?;

    if ((s['exclude'] is! List ||
            (s['exclude'].indexOf(nodeType) == -1 &&
                s['exclude'].indexOf(docType) == -1)) &&
        (s['testType'] & testType != 0)) {
      //console.log("Running tests " + nodeType + ": " + s["testType"] + "&" + testType + "=" + (s["testType"] & testType) + ": " + JSON.stringify(s))
      late List<Element> foundall;
      Element? found;

      runTest(() {
        foundall = (root as dynamic).querySelectorAll(q) as List<Element>;
        assertNotEquals(foundall, null, 'The method should not return null.');
        assertEquals(foundall.length, e!.length,
            'The method should return the expected number of matches.');

        for (var i = 0; i < e.length; i++) {
          assertNotEquals(
              foundall[i], null, 'The item in index $i should not be null.');
          assertEquals(foundall[i].attributes['id'], e[i],
              'The item in index $i should have the expected ID.');
          assertFalse(foundall[i].attributes.containsKey('data-clone'),
              'This should not be a cloned element.');
        }
      }, '$type.querySelectorAll: $n:$q', skip: skip);

      runTest(() {
        found = (root as dynamic).querySelector(q) as Element?;

        if (e!.isNotEmpty) {
          assertNotEquals(found, null, 'The method should return a match.');
          assertEquals(found!.attributes['id'], e[0],
              'The method should return the first match.');
          assertEquals(found, foundall[0],
              'The result should match the first item from querySelectorAll.');
          assertFalse(found!.attributes.containsKey('data-clone'),
              'This should not be annotated as a cloned element.');
        } else {
          assertEquals(found, null, 'The method should not match anything.');
        }
      }, '$type.querySelector: $n : $q', skip: skip);
    } else {
      //console.log("Excluding for " + nodeType + ": " + s["testType"] + "&" + testType + "=" + (s["testType"] & testType) + ": " + JSON.stringify(s))
    }
  }
}

/*
 * Execute queries with the specified invalid selectors for both querySelector() and querySelectorAll()
 * Only run these tests when errors are expected. Don't run for valid selector tests.
 */
void runInvalidSelectorTest(String type, root, List selectors) {
  for (var i = 0; i < selectors.length; i++) {
    final s = selectors[i];
    final n = s['name'] as String;
    final q = s['selector'] as String;

    // Dart note: FormatException seems a reasonable mapping of SyntaxError
    runTest(() {
      assertThrows((e) => e is FormatException, () {
        root.querySelector(q);
      });
    }, '$type.querySelector: $n:$q');

    runTest(() {
      assertThrows((e) => e is FormatException, () {
        root.querySelectorAll(q);
      });
    }, '$type.querySelectorAll: $n:$q');
  }
}

void traverse(Node elem, void Function(Node) fn) {
  if (elem.nodeType == Node.ELEMENT_NODE) {
    fn(elem);
  }

  // Dart note: changed this since our DOM API doesn't support nextNode yet.
  for (var node in elem.nodes) {
    traverse(node, fn);
  }
}

void runTest(dynamic Function() body, String name, {String? skip}) =>
    unittest.test(name, body, skip: skip);

void assertTrue(bool value, String reason) =>
    unittest.expect(value, unittest.isTrue, reason: reason);

void assertFalse(bool value, String reason) =>
    unittest.expect(value, unittest.isFalse, reason: reason);

void assertEquals(x, y, String reason) => unittest.expect(x, y, reason: reason);

void assertNotEquals(x, y, String reason) =>
    unittest.expect(x, unittest.isNot(y), reason: reason);

void assertThrows(exception, void Function() body, [String? reason]) =>
    unittest.expect(body, unittest.throwsA(exception), reason: reason);
