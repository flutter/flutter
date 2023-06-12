/// Test for the Selectors API ported from
/// <https://github.com/w3c/web-platform-tests/tree/master/selectors-api>
///
/// Note, unlike the original we don't operate in-browser on a DOM loaded into
/// an iframe, but instead operate over a parsed DOM.

@TestOn('vm')
library html.test.selectors.level1_baseline_test;

import 'dart:io';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support.dart';
import 'level1_lib.dart';
import 'selectors.dart';

Future<Document> testContentDocument() async {
  final testPath =
      p.join(await testDirectory, 'selectors', 'level1-content.html');
  return parse(File(testPath).readAsStringSync());
}

var testType = testQsaBaseline; // Only run baseline tests.
var docType = 'html'; // Only run tests suitable for HTML

void main() async {
  /*
   * This test suite tests Selectors API methods in 4 different contexts:
   * 1. Document node
   * 2. In-document Element node
   * 3. Detached Element node (an element with no parent, not in the document)
   * 4. Document Fragment node
   *
   * For each context, the following tests are run:
   *
   * The interface check tests ensure that each type of node exposes the Selectors API methods
   *
   * The special selector tests verify the result of passing special values for the selector parameter,
   * to ensure that the correct WebIDL processing is performed, such as stringification of null and
   * undefined and missing parameter. The universal selector is also tested here, rather than with the
   * rest of ordinary selectors for practical reasons.
   *
   * The static list verification tests ensure that the node lists returned by the method remain unchanged
   * due to subsequent document modication, and that a new list is generated each time the method is
   * invoked based on the current state of the document.
   *
   * The invalid selector tests ensure that SyntaxError is thrown for invalid forms of selectors
   *
   * The valid selector tests check the result from querying many different types of selectors, with a
   * list of expected elements. This checks that querySelector() always returns the first result from
   * querySelectorAll(), and that all matching elements are correctly returned in tree-order. The tests
   * can be limited by specifying the test types to run, using the testType variable. The constants for this
   * can be found in selectors.js.
   *
   * All the selectors tested for both the valid and invalid selector tests are found in selectors.js.
   * See comments in that file for documentation of the format used.
   *
   * The level1-lib.js file contains all the common test functions for running each of the aforementioned tests
   */

  // Prepare the nodes for testing
  //doc = frame.contentDocument;                 // Document Node tests
  doc = await testContentDocument();

  final element = doc.getElementById('root')!; // In-document Element Node tests

  //Setup the namespace tests
  setupSpecialElements(element);

  final outOfScope = element
      .clone(true); // Append this to the body before running the in-document
  // Element tests, but after running the Document tests. This
  // tests that no elements that are not descendants of element
  // are selected.

  traverse(outOfScope, (elem) {
    // Annotate each element as being a clone; used for verifying
    elem.attributes['data-clone'] =
        ''; // that none of these elements ever match.
  });

  final detached = element.clone(true); // Detached Element Node tests

  final fragment = doc.createDocumentFragment(); // Fragment Node tests
  fragment.append(element.clone(true));

  // Setup Tests
  runSpecialSelectorTests('Document', doc);
  runSpecialSelectorTests('Detached Element', detached);
  runSpecialSelectorTests('Fragment', fragment);
  runSpecialSelectorTests('In-document Element', element);

  verifyStaticList('Document', doc);
  verifyStaticList('Detached Element', detached);
  verifyStaticList('Fragment', fragment);
  verifyStaticList('In-document Element', element);

  // TODO(jmesserly): fix negative tests
  //runInvalidSelectorTest('Document', doc, invalidSelectors);
  //runInvalidSelectorTest('Detached Element', detached, invalidSelectors);
  //runInvalidSelectorTest('Fragment', fragment, invalidSelectors);
  //runInvalidSelectorTest('In-document Element', element, invalidSelectors);

  runValidSelectorTest('Document', doc, validSelectors, testType, docType);
  runValidSelectorTest(
      'Detached Element', detached, validSelectors, testType, docType);
  runValidSelectorTest('Fragment', fragment, validSelectors, testType, docType);

  group('out of scope', () {
    setUp(() {
      doc.body!.append(outOfScope); // Append before in-document Element tests.
      // None of these elements should match
    });
    tearDown(outOfScope.remove);
    runValidSelectorTest(
        'In-document Element', element, validSelectors, testType, docType);
  });
}
