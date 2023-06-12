/// Test for the Selectors API ported from
/// <https://github.com/w3c/web-platform-tests/tree/master/selectors-api>
library html.test.selectors.selectors;

// Bit-mapped flags to indicate which tests the selector is suitable for
final testQsaBaseline =
    0x01; // querySelector() and querySelectorAll() baseline tests
final testQsaAdditional =
    0x02; // querySelector() and querySelectorAll() additional tests
final testFindBaseline =
    0x04; // find() and findAll() baseline tests, may be unsuitable for querySelector[All]
final testFindAdditional =
    0x08; // find() and findAll() additional tests, may be unsuitable for querySelector[All]
final testMatchBaseline = 0x10; // matches() baseline tests
var testMatchAdditional = 0x20; // matches() additional tests

/*
 * All of these invalid selectors should result in a SyntaxError being thrown by the APIs.
 *
 *   name:     A descriptive name of the selector being tested
 *   selector: The selector to test
 */
final invalidSelectors = [
  {'name': 'Empty String', 'selector': ''},
  {'name': 'Invalid character', 'selector': '['},
  {'name': 'Invalid character', 'selector': ']'},
  {'name': 'Invalid character', 'selector': '('},
  {'name': 'Invalid character', 'selector': ')'},
  {'name': 'Invalid character', 'selector': '{'},
  {'name': 'Invalid character', 'selector': '}'},
  {'name': 'Invalid character', 'selector': '<'},
  {'name': 'Invalid character', 'selector': '>'},
  {'name': 'Invalid ID', 'selector': '#'},
  {'name': 'Invalid group of selectors', 'selector': 'div,'},
  {'name': 'Invalid class', 'selector': '.'},
  {'name': 'Invalid class', 'selector': '.5cm'},
  {'name': 'Invalid class', 'selector': '..test'},
  {'name': 'Invalid class', 'selector': '.foo..quux'},
  {'name': 'Invalid class', 'selector': '.bar.'},
  {'name': 'Invalid combinator', 'selector': 'div & address, p'},
  {'name': 'Invalid combinator', 'selector': 'div >> address, p'},
  {'name': 'Invalid combinator', 'selector': 'div ++ address, p'},
  {'name': 'Invalid combinator', 'selector': 'div ~~ address, p'},
  {'name': 'Invalid [att=value] selector', 'selector': '[*=test]'},
  {'name': 'Invalid [att=value] selector', 'selector': '[*|*=test]'},
  {
    'name': 'Invalid [att=value] selector',
    'selector': '[class= space unquoted ]'
  },
  {'name': 'Unknown pseudo-class', 'selector': 'div:example'},
  {'name': 'Unknown pseudo-class', 'selector': ':example'},
  {'name': 'Unknown pseudo-element', 'selector': 'div::example'},
  {'name': 'Unknown pseudo-element', 'selector': '::example'},
  {'name': 'Invalid pseudo-element', 'selector': ':::before'},
  {'name': 'Undeclared namespace', 'selector': 'ns|div'},
  {'name': 'Undeclared namespace', 'selector': ':not(ns|div)'},
  {'name': 'Invalid namespace', 'selector': '^|div'},
  {'name': 'Invalid namespace', 'selector': '\$|div'}
];

/*
 * All of these should be valid selectors, expected to match zero or more elements in the document.
 * None should throw any errors.
 *
 *   name:     A descriptive name of the selector being tested
 *   selector: The selector to test
 *   'expect':   A list of IDs of the elements expected to be matched. List must be given in tree order.
 *   'exclude':  An array of contexts to exclude from testing. The valid values are:
 *             ["document", "element", "fragment", "detached", "html", "xhtml"]
 *             The "html" and "xhtml" values represent the type of document being queried. These are useful
 *             for tests that are affected by differences between HTML and XML, such as case sensitivity.
 *   'level':    An integer indicating the CSS or Selectors level in which the selector being tested was introduced.
 *   'testType': A bit-mapped flag indicating the type of test.
 *
 * Note: Interactive pseudo-classes (:active :hover and :focus) have not been tested in this test suite.
 */
var validSelectors = [
  // Type Selector
  {
    'name': 'Type selector, matching html element',
    'selector': 'html',
    'expect': ['html'],
    'exclude': ['element', 'fragment', 'detached'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Type selector, matching html element',
    'selector': 'html',
    'expect': [] /*no matches*/,
    'exclude': ['document'],
    'level': 1,
    'testType': testQsaBaseline
  },
  {
    'name': 'Type selector, matching body element',
    'selector': 'body',
    'expect': ['body'],
    'exclude': ['element', 'fragment', 'detached'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Type selector, matching body element',
    'selector': 'body',
    'expect': [] /*no matches*/,
    'exclude': ['document'],
    'level': 1,
    'testType': testQsaBaseline
  },

  // Universal Selector
  // Testing "*" for entire an entire context node is handled separately.
  {
    'name':
        'Universal selector, matching all children of element with specified ID',
    'selector': '#universal>*',
    'expect': [
      'universal-p1',
      'universal-hr1',
      'universal-pre1',
      'universal-p2',
      'universal-address1'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Universal selector, matching all grandchildren of element with specified ID',
    'selector': '#universal>*>*',
    'expect': [
      'universal-code1',
      'universal-span1',
      'universal-a1',
      'universal-code2'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Universal selector, matching all children of empty element with specified ID',
    'selector': '#empty>*',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Universal selector, matching all descendants of element with specified ID',
    'selector': '#universal *',
    'expect': [
      'universal-p1',
      'universal-code1',
      'universal-hr1',
      'universal-pre1',
      'universal-span1',
      'universal-p2',
      'universal-a1',
      'universal-address1',
      'universal-code2',
      'universal-a2'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // Attribute Selectors
  // - presence                  [att]
  {
    'name': 'Attribute presence selector, matching align attribute with value',
    'selector': '.attr-presence-div1[align]',
    'expect': ['attr-presence-div1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute presence selector, matching align attribute with empty value',
    'selector': '.attr-presence-div2[align]',
    'expect': ['attr-presence-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute presence selector, matching title attribute, case insensitivity',
    'selector': '#attr-presence [TiTlE]',
    'expect': ['attr-presence-a1', 'attr-presence-span1'],
    'exclude': ['xhtml'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute presence selector, not matching title attribute, case sensitivity',
    'selector': '#attr-presence [TiTlE]',
    'expect': [],
    'exclude': ['html'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Attribute presence selector, matching custom data-* attribute',
    'selector': '[data-attr-presence]',
    'expect': ['attr-presence-pre1', 'attr-presence-blockquote1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute presence selector, not matching attribute with similar name',
    'selector': '.attr-presence-div3[align], .attr-presence-div4[align]',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute presence selector, matching attribute with non-ASCII characters',
    'selector': 'ul[data-中文]',
    'expect': ['attr-presence-ul1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute presence selector, not matching default option without selected attribute',
    'selector': '#attr-presence-select1 option[selected]',
    'expect': [] /* no matches */,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute presence selector, matching option with selected attribute',
    'selector': '#attr-presence-select2 option[selected]',
    'expect': ['attr-presence-select2-option4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute presence selector, matching multiple options with selected attributes',
    'selector': '#attr-presence-select3 option[selected]',
    'expect': [
      'attr-presence-select3-option2',
      'attr-presence-select3-option3'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // - value                     [att=val]
  {
    'name': 'Attribute value selector, matching align attribute with value',
    'selector': '#attr-value [align="center"]',
    'expect': ['attr-value-div1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute value selector, matching align attribute with empty value',
    'selector': '#attr-value [align=""]',
    'expect': ['attr-value-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute value selector, not matching align attribute with partial value',
    'selector': '#attr-value [align="c"]',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute value selector, not matching align attribute with incorrect value',
    'selector': '#attr-value [align="centera"]',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute value selector, matching custom data-* attribute with unicode escaped value',
    'selector': '[data-attr-value="\\e9"]',
    'expect': ['attr-value-div3'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute value selector, matching custom data-* attribute with escaped character',
    'selector': '[data-attr-value_foo="\\e9"]',
    'expect': ['attr-value-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute value selector with single-quoted value, matching multiple inputs with type attributes',
    'selector':
        "#attr-value input[type='hidden'],#attr-value input[type='radio']",
    'expect': [
      'attr-value-input3',
      'attr-value-input4',
      'attr-value-input6',
      'attr-value-input8',
      'attr-value-input9'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute value selector with double-quoted value, matching multiple inputs with type attributes',
    'selector':
        "#attr-value input[type=\"hidden\"],#attr-value input[type='radio']",
    'expect': [
      'attr-value-input3',
      'attr-value-input4',
      'attr-value-input6',
      'attr-value-input8',
      'attr-value-input9'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute value selector with unquoted value, matching multiple inputs with type attributes',
    'selector': '#attr-value input[type=hidden],#attr-value input[type=radio]',
    'expect': [
      'attr-value-input3',
      'attr-value-input4',
      'attr-value-input6',
      'attr-value-input8',
      'attr-value-input9'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute value selector, matching attribute with value using non-ASCII characters',
    'selector': '[data-attr-value=中文]',
    'expect': ['attr-value-div5'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // - whitespace-separated list [att~=val]
  {
    'name':
        'Attribute whitespace-separated list selector, matching class attribute with value',
    'selector': '#attr-whitespace [class~="div1"]',
    'expect': ['attr-whitespace-div1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector, not matching class attribute with empty value',
    'selector': '#attr-whitespace [class~=""]',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector, not matching class attribute with partial value',
    'selector': '[data-attr-whitespace~="div"]',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector, matching custom data-* attribute with unicode escaped value',
    'selector': '[data-attr-whitespace~="\\0000e9"]',
    'expect': ['attr-whitespace-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector, matching custom data-* attribute with escaped character',
    'selector': '[data-attr-whitespace_foo~="\\e9"]',
    'expect': ['attr-whitespace-div5'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector with single-quoted value, matching multiple links with rel attributes',
    'selector':
        "#attr-whitespace a[rel~='bookmark'],  #attr-whitespace a[rel~='nofollow']",
    'expect': [
      'attr-whitespace-a1',
      'attr-whitespace-a2',
      'attr-whitespace-a3',
      'attr-whitespace-a5',
      'attr-whitespace-a7'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector with double-quoted value, matching multiple links with rel attributes',
    'selector':
        "#attr-whitespace a[rel~=\"bookmark\"],#attr-whitespace a[rel~='nofollow']",
    'expect': [
      'attr-whitespace-a1',
      'attr-whitespace-a2',
      'attr-whitespace-a3',
      'attr-whitespace-a5',
      'attr-whitespace-a7'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector with unquoted value, matching multiple links with rel attributes',
    'selector':
        '#attr-whitespace a[rel~=bookmark],    #attr-whitespace a[rel~=nofollow]',
    'expect': [
      'attr-whitespace-a1',
      'attr-whitespace-a2',
      'attr-whitespace-a3',
      'attr-whitespace-a5',
      'attr-whitespace-a7'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector with double-quoted value, not matching value with space',
    'selector': '#attr-whitespace a[rel~="book mark"]',
    'expect': [] /* no matches */,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute whitespace-separated list selector, matching title attribute with value using non-ASCII characters',
    'selector': '#attr-whitespace [title~=中文]',
    'expect': ['attr-whitespace-p1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // - hyphen-separated list     [att|=val]
  {
    'name':
        'Attribute hyphen-separated list selector, not matching unspecified lang attribute',
    'selector': '#attr-hyphen-div1[lang|="en"]',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Attribute hyphen-separated list selector, matching lang attribute with exact value',
    'selector': '#attr-hyphen-div2[lang|="fr"]',
    'expect': ['attr-hyphen-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute hyphen-separated list selector, matching lang attribute with partial value',
    'selector': '#attr-hyphen-div3[lang|="en"]',
    'expect': ['attr-hyphen-div3'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Attribute hyphen-separated list selector, not matching incorrect value',
    'selector': '#attr-hyphen-div4[lang|="es-AR"]',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },

  // - substring begins-with     [att^=val] (Level 3)
  {
    'name':
        'Attribute begins with selector, matching href attributes beginning with specified substring',
    'selector': '#attr-begins a[href^="http://www"]',
    'expect': ['attr-begins-a1', 'attr-begins-a3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute begins with selector, matching lang attributes beginning with specified substring, ',
    'selector': '#attr-begins [lang^="en-"]',
    'expect': ['attr-begins-div2', 'attr-begins-div4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute begins with selector, not matching class attribute not beginning with specified substring',
    'selector': '#attr-begins [class^=apple]',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },
  {
    'name':
        'Attribute begins with selector with single-quoted value, matching class attribute beginning with specified substring',
    'selector': "#attr-begins [class^=' apple']",
    'expect': ['attr-begins-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute begins with selector with double-quoted value, matching class attribute beginning with specified substring',
    'selector': '#attr-begins [class^=" apple"]',
    'expect': ['attr-begins-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute begins with selector with unquoted value, not matching class attribute not beginning with specified substring',
    'selector': '#attr-begins [class^= apple]',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },

  // - substring ends-with       [att\$=val] (Level 3)
  {
    'name':
        'Attribute ends with selector, matching href attributes ending with specified substring',
    'selector': '#attr-ends a[href\$=".org"]',
    'expect': ['attr-ends-a1', 'attr-ends-a3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute ends with selector, matching lang attributes ending with specified substring, ',
    'selector': '#attr-ends [lang\$="-CH"]',
    'expect': ['attr-ends-div2', 'attr-ends-div4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute ends with selector, not matching class attribute not ending with specified substring',
    'selector': '#attr-ends [class\$=apple]',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },
  {
    'name':
        'Attribute ends with selector with single-quoted value, matching class attribute ending with specified substring',
    'selector': "#attr-ends [class\$='apple ']",
    'expect': ['attr-ends-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute ends with selector with double-quoted value, matching class attribute ending with specified substring',
    'selector': '#attr-ends [class\$="apple "]',
    'expect': ['attr-ends-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute ends with selector with unquoted value, not matching class attribute not ending with specified substring',
    'selector': '#attr-ends [class\$=apple ]',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },

  // - substring contains        [att*=val] (Level 3)
  {
    'name':
        'Attribute contains selector, matching href attributes beginning with specified substring',
    'selector': '#attr-contains a[href*="http://www"]',
    'expect': ['attr-contains-a1', 'attr-contains-a3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector, matching href attributes ending with specified substring',
    'selector': '#attr-contains a[href*=".org"]',
    'expect': ['attr-contains-a1', 'attr-contains-a2'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector, matching href attributes containing specified substring',
    'selector': '#attr-contains a[href*=".example."]',
    'expect': ['attr-contains-a1', 'attr-contains-a3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector, matching lang attributes beginning with specified substring, ',
    'selector': '#attr-contains [lang*="en-"]',
    'expect': ['attr-contains-div2', 'attr-contains-div6'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector, matching lang attributes ending with specified substring, ',
    'selector': '#attr-contains [lang*="-CH"]',
    'expect': ['attr-contains-div3', 'attr-contains-div5'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with single-quoted value, matching class attribute beginning with specified substring',
    'selector': "#attr-contains [class*=' apple']",
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with single-quoted value, matching class attribute ending with specified substring',
    'selector': "#attr-contains [class*='orange ']",
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with single-quoted value, matching class attribute containing specified substring',
    'selector': "#attr-contains [class*='ple banana ora']",
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with double-quoted value, matching class attribute beginning with specified substring',
    'selector': '#attr-contains [class*=" apple"]',
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with double-quoted value, matching class attribute ending with specified substring',
    'selector': '#attr-contains [class*="orange "]',
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with double-quoted value, matching class attribute containing specified substring',
    'selector': '#attr-contains [class*="ple banana ora"]',
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with unquoted value, matching class attribute beginning with specified substring',
    'selector': '#attr-contains [class*= apple]',
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with unquoted value, matching class attribute ending with specified substring',
    'selector': '#attr-contains [class*=orange ]',
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'Attribute contains selector with unquoted value, matching class attribute containing specified substring',
    'selector': '#attr-contains [class*= banana ]',
    'expect': ['attr-contains-p1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // Pseudo-classes
  // - :root                 (Level 3)
  {
    'name': ':root pseudo-class selector, matching document root element',
    'selector': ':root',
    'expect': ['html'],
    'exclude': ['element', 'fragment', 'detached'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': ':root pseudo-class selector, not matching document root element',
    'selector': ':root',
    'expect': [] /*no matches*/,
    'exclude': ['document'],
    'level': 3,
    'testType': testQsaAdditional
  },

  // - :nth-child(n)         (Level 3)
  {
    'name': ':nth-child selector, matching the third child element',
    'selector': '#pseudo-nth-table1 :nth-child(3)',
    'expect': [
      'pseudo-nth-td3',
      'pseudo-nth-td9',
      'pseudo-nth-tr3',
      'pseudo-nth-td15'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': ':nth-child selector, matching every third child element',
    'selector': '#pseudo-nth li:nth-child(3n)',
    'expect': [
      'pseudo-nth-li3',
      'pseudo-nth-li6',
      'pseudo-nth-li9',
      'pseudo-nth-li12'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-child selector, matching every second child element, starting from the fourth',
    'selector': '#pseudo-nth li:nth-child(2n+4)',
    'expect': [
      'pseudo-nth-li4',
      'pseudo-nth-li6',
      'pseudo-nth-li8',
      'pseudo-nth-li10',
      'pseudo-nth-li12'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-child selector, matching every fourth child element, starting from the third',
    'selector': '#pseudo-nth-p1 :nth-child(4n-1)',
    'expect': ['pseudo-nth-em2', 'pseudo-nth-span3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :nth-last-child       (Level 3)
  {
    'name': ':nth-last-child selector, matching the third last child element',
    'selector': '#pseudo-nth-table1 :nth-last-child(3)',
    'expect': [
      'pseudo-nth-tr1',
      'pseudo-nth-td4',
      'pseudo-nth-td10',
      'pseudo-nth-td16'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-last-child selector, matching every third child element from the end',
    'selector': '#pseudo-nth li:nth-last-child(3n)',
    'expect': [
      'pseudo-nth-li1',
      'pseudo-nth-li4',
      'pseudo-nth-li7',
      'pseudo-nth-li10'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-last-child selector, matching every second child element from the end, starting from the fourth last',
    'selector': '#pseudo-nth li:nth-last-child(2n+4)',
    'expect': [
      'pseudo-nth-li1',
      'pseudo-nth-li3',
      'pseudo-nth-li5',
      'pseudo-nth-li7',
      'pseudo-nth-li9'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-last-child selector, matching every fourth element from the end, starting from the third last',
    'selector': '#pseudo-nth-p1 :nth-last-child(4n-1)',
    'expect': ['pseudo-nth-span2', 'pseudo-nth-span4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :nth-of-type(n)       (Level 3)
  {
    'name': ':nth-of-type selector, matching the third em element',
    'selector': '#pseudo-nth-p1 em:nth-of-type(3)',
    'expect': ['pseudo-nth-em3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-of-type selector, matching every second element of their type',
    'selector': '#pseudo-nth-p1 :nth-of-type(2n)',
    'expect': [
      'pseudo-nth-em2',
      'pseudo-nth-span2',
      'pseudo-nth-span4',
      'pseudo-nth-strong2',
      'pseudo-nth-em4'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-of-type selector, matching every second elemetn of their type, starting from the first',
    'selector': '#pseudo-nth-p1 span:nth-of-type(2n-1)',
    'expect': ['pseudo-nth-span1', 'pseudo-nth-span3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :nth-last-of-type(n)  (Level 3)
  {
    'name': ':nth-last-of-type selector, matching the thrid last em element',
    'selector': '#pseudo-nth-p1 em:nth-last-of-type(3)',
    'expect': ['pseudo-nth-em2'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-last-of-type selector, matching every second last element of their type',
    'selector': '#pseudo-nth-p1 :nth-last-of-type(2n)',
    'expect': [
      'pseudo-nth-span1',
      'pseudo-nth-em1',
      'pseudo-nth-strong1',
      'pseudo-nth-em3',
      'pseudo-nth-span3'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':nth-last-of-type selector, matching every second last element of their type, starting from the last',
    'selector': '#pseudo-nth-p1 span:nth-last-of-type(2n-1)',
    'expect': ['pseudo-nth-span2', 'pseudo-nth-span4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :first-of-type        (Level 3)
  {
    'name': ':first-of-type selector, matching the first em element',
    'selector': '#pseudo-nth-p1 em:first-of-type',
    'expect': ['pseudo-nth-em1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':first-of-type selector, matching the first of every type of element',
    'selector': '#pseudo-nth-p1 :first-of-type',
    'expect': ['pseudo-nth-span1', 'pseudo-nth-em1', 'pseudo-nth-strong1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':first-of-type selector, matching the first td element in each table row',
    'selector': '#pseudo-nth-table1 tr :first-of-type',
    'expect': ['pseudo-nth-td1', 'pseudo-nth-td7', 'pseudo-nth-td13'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :last-of-type         (Level 3)
  {
    'name': ':last-of-type selector, matching the last em elemnet',
    'selector': '#pseudo-nth-p1 em:last-of-type',
    'expect': ['pseudo-nth-em4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':last-of-type selector, matching the last of every type of element',
    'selector': '#pseudo-nth-p1 :last-of-type',
    'expect': ['pseudo-nth-span4', 'pseudo-nth-strong2', 'pseudo-nth-em4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':last-of-type selector, matching the last td element in each table row',
    'selector': '#pseudo-nth-table1 tr :last-of-type',
    'expect': ['pseudo-nth-td6', 'pseudo-nth-td12', 'pseudo-nth-td18'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :first-child
  {
    'name':
        ':first-child pseudo-class selector, matching first child div element',
    'selector': '#pseudo-first-child div:first-child',
    'expect': ['pseudo-first-child-div1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        ":first-child pseudo-class selector, doesn't match non-first-child elements",
    'selector':
        '.pseudo-first-child-div2:first-child, .pseudo-first-child-div3:first-child',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        ':first-child pseudo-class selector, matching first-child of multiple elements',
    'selector': '#pseudo-first-child span:first-child',
    'expect': [
      'pseudo-first-child-span1',
      'pseudo-first-child-span3',
      'pseudo-first-child-span5'
    ],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // - :last-child           (Level 3)
  {
    'name':
        ':last-child pseudo-class selector, matching last child div element',
    'selector': '#pseudo-last-child div:last-child',
    'expect': ['pseudo-last-child-div3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ":last-child pseudo-class selector, doesn't match non-last-child elements",
    'selector':
        '.pseudo-last-child-div1:last-child, .pseudo-last-child-div2:first-child',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },
  {
    'name':
        ':last-child pseudo-class selector, matching first-child of multiple elements',
    'selector': '#pseudo-last-child span:last-child',
    'expect': [
      'pseudo-last-child-span2',
      'pseudo-last-child-span4',
      'pseudo-last-child-span6'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :only-child           (Level 3)
  {
    'name':
        ':pseudo-only-child pseudo-class selector, matching all only-child elements',
    'selector': '#pseudo-only :only-child',
    'expect': ['pseudo-only-span1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':pseudo-only-child pseudo-class selector, matching only-child em elements',
    'selector': '#pseudo-only em:only-child',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },

  // - :only-of-type         (Level 3)
  {
    'name':
        ':pseudo-only-of-type pseudo-class selector, matching all elements with no siblings of the same type',
    'selector': '#pseudo-only :only-of-type',
    'expect': ['pseudo-only-span1', 'pseudo-only-em1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        ':pseudo-only-of-type pseudo-class selector, matching em elements with no siblings of the same type',
    'selector': '#pseudo-only em:only-of-type',
    'expect': ['pseudo-only-em1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :empty                (Level 3)
  {
    'name': ':empty pseudo-class selector, matching empty p elements',
    'selector': '#pseudo-empty p:empty',
    'expect': ['pseudo-empty-p1', 'pseudo-empty-p2'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': ':empty pseudo-class selector, matching all empty elements',
    'selector': '#pseudo-empty :empty',
    'expect': ['pseudo-empty-p1', 'pseudo-empty-p2', 'pseudo-empty-span1'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :link and :visited
  // Implementations may treat all visited links as unvisited, so these cannot be tested separately.
  // The only guarantee is that ":link,:visited" matches the set of all visited and unvisited links and that they are individually mutually exclusive sets.
  {
    'name':
        ':link and :visited pseudo-class selectors, matching a and area elements with href attributes',
    'selector': '#pseudo-link :link, #pseudo-link :visited',
    'expect': ['pseudo-link-a1', 'pseudo-link-a2', 'pseudo-link-area1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        ':link and :visited pseudo-class selectors, matching link elements with href attributes',
    'selector': '#head :link, #head :visited',
    'expect': ['pseudo-link-link1', 'pseudo-link-link2'],
    'exclude': ['element', 'fragment', 'detached'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        ':link and :visited pseudo-class selectors, not matching link elements with href attributes',
    'selector': '#head :link, #head :visited',
    'expect': [] /*no matches*/,
    'exclude': ['document'],
    'level': 1,
    'testType': testQsaBaseline
  },
  {
    'name':
        ':link and :visited pseudo-class selectors, chained, mutually exclusive pseudo-classes match nothing',
    'selector': ':link:visited',
    'expect': [] /*no matches*/,
    'exclude': ['document'],
    'level': 1,
    'testType': testQsaBaseline
  },

  // - :target               (Level 3)
  {
    'name':
        ':target pseudo-class selector, matching the element referenced by the URL fragment identifier',
    'selector': ':target',
    'expect': [] /*no matches*/,
    'exclude': ['document', 'element'],
    'level': 3,
    'testType': testQsaAdditional
  },
  {
    'name':
        ':target pseudo-class selector, matching the element referenced by the URL fragment identifier',
    'selector': ':target',
    'expect': ['target'],
    'exclude': ['fragment', 'detached'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :lang()
  {
    'name': ':lang pseudo-class selector, matching inherited language',
    'selector': '#pseudo-lang-div1:lang(en)',
    'expect': ['pseudo-lang-div1'],
    'exclude': ['detached', 'fragment'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        ':lang pseudo-class selector, not matching element with no inherited language',
    'selector': '#pseudo-lang-div1:lang(en)',
    'expect': [] /*no matches*/,
    'exclude': ['document', 'element'],
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        ':lang pseudo-class selector, matching specified language with exact value',
    'selector': '#pseudo-lang-div2:lang(fr)',
    'expect': ['pseudo-lang-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        ':lang pseudo-class selector, matching specified language with partial value',
    'selector': '#pseudo-lang-div3:lang(en)',
    'expect': ['pseudo-lang-div3'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': ':lang pseudo-class selector, not matching incorrect language',
    'selector': '#pseudo-lang-div4:lang(es-AR)',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },

  // - :enabled              (Level 3)
  {
    'name':
        ':enabled pseudo-class selector, matching all enabled form controls',
    'selector': '#pseudo-ui :enabled',
    'expect': [
      'pseudo-ui-input1',
      'pseudo-ui-input2',
      'pseudo-ui-input3',
      'pseudo-ui-input4',
      'pseudo-ui-input5',
      'pseudo-ui-input6',
      'pseudo-ui-input7',
      'pseudo-ui-input8',
      'pseudo-ui-input9',
      'pseudo-ui-textarea1',
      'pseudo-ui-button1'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :disabled             (Level 3)
  {
    'name':
        ':enabled pseudo-class selector, matching all disabled form controls',
    'selector': '#pseudo-ui :disabled',
    'expect': [
      'pseudo-ui-input10',
      'pseudo-ui-input11',
      'pseudo-ui-input12',
      'pseudo-ui-input13',
      'pseudo-ui-input14',
      'pseudo-ui-input15',
      'pseudo-ui-input16',
      'pseudo-ui-input17',
      'pseudo-ui-input18',
      'pseudo-ui-textarea2',
      'pseudo-ui-button2'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :checked              (Level 3)
  {
    'name':
        ':checked pseudo-class selector, matching checked radio buttons and checkboxes',
    'selector': '#pseudo-ui :checked',
    'expect': [
      'pseudo-ui-input4',
      'pseudo-ui-input6',
      'pseudo-ui-input13',
      'pseudo-ui-input15'
    ],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // - :not(s)               (Level 3)
  {
    'name': ':not pseudo-class selector, matching ',
    'selector': '#not>:not(div)',
    'expect': ['not-p1', 'not-p2', 'not-p3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': ':not pseudo-class selector, matching ',
    'selector': '#not * :not(:first-child)',
    'expect': ['not-em1', 'not-em2', 'not-em3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': ':not pseudo-class selector, matching nothing',
    'selector': ':not(*)',
    'expect': [] /* no matches */,
    'level': 3,
    'testType': testQsaAdditional
  },
  {
    'name': ':not pseudo-class selector, matching nothing',
    'selector': ':not(*|*)',
    'expect': [] /* no matches */,
    'level': 3,
    'testType': testQsaAdditional
  },

  // Pseudo-elements
  // - ::first-line
  {
    'name':
        ':first-line pseudo-element (one-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element:first-line',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        '::first-line pseudo-element (two-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element::first-line',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },

  // - ::first-letter
  {
    'name':
        ':first-letter pseudo-element (one-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element:first-letter',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        '::first-letter pseudo-element (two-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element::first-letter',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },

  // - ::before
  {
    'name':
        ':before pseudo-element (one-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element:before',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        '::before pseudo-element (two-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element::before',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },

  // - ::after
  {
    'name':
        ':after pseudo-element (one-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element:after',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        '::after pseudo-element (two-colon syntax) selector, not matching any elements',
    'selector': '#pseudo-element::after',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },

  // Class Selectors
  {
    'name': 'Class selector, matching element with specified class',
    'selector': '.class-p',
    'expect': ['class-p1', 'class-p2', 'class-p3'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Class selector, chained, matching only elements with all specified classes',
    'selector': '#class .apple.orange.banana',
    'expect': [
      'class-div1',
      'class-div2',
      'class-p4',
      'class-div3',
      'class-p6',
      'class-div4'
    ],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Class Selector, chained, with type selector',
    'selector': 'div.apple.banana.orange',
    'expect': ['class-div1', 'class-div2', 'class-div3', 'class-div4'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  // Caution: If copying and pasting the folowing non-ASCII classes, ensure unicode normalisation is not performed in the process.
  {
    'name':
        'Class selector, matching element with class value using non-ASCII characters',
    'selector': '.台北Táiběi',
    'expect': ['class-span1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Class selector, matching multiple elements with class value using non-ASCII characters',
    'selector': '.台北',
    'expect': ['class-span1', 'class-span2'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Class selector, chained, matching element with multiple class values using non-ASCII characters',
    'selector': '.台北Táiběi.台北',
    'expect': ['class-span1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Class selector, matching element with class with escaped character',
    'selector': '.foo\\:bar',
    'expect': ['class-span3'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Class selector, matching element with class with escaped character',
    'selector': '.test\\.foo\\[5\\]bar',
    'expect': ['class-span4'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // ID Selectors
  {
    'name': 'ID selector, matching element with specified id',
    'selector': '#id #id-div1',
    'expect': ['id-div1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'ID selector, chained, matching element with specified id',
    'selector': '#id-div1, #id-div1',
    'expect': ['id-div1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'ID selector, chained, matching element with specified id',
    'selector': '#id-div1, #id-div2',
    'expect': ['id-div1', 'id-div2'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'ID Selector, chained, with type selector',
    'selector': 'div#id-div1, div#id-div2',
    'expect': ['id-div1', 'id-div2'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'ID selector, not matching non-existent descendant',
    'selector': '#id #none',
    'expect': [] /*no matches*/,
    'level': 1,
    'testType': testQsaBaseline
  },
  {
    'name': 'ID selector, not matching non-existent ancestor',
    'selector': '#none #id-div1',
    'expect': [] /*no matches*/,
    'level': 1,
    'testType': testQsaBaseline
  },
  {
    'name': 'ID selector, matching multiple elements with duplicate id',
    'selector': '#id-li-duplicate',
    'expect': [
      'id-li-duplicate',
      'id-li-duplicate',
      'id-li-duplicate',
      'id-li-duplicate'
    ],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // Caution: If copying and pasting the folowing non-ASCII IDs, ensure unicode normalisation is not performed in the process.
  {
    'name': 'ID selector, matching id value using non-ASCII characters',
    'selector': '#台北Táiběi',
    'expect': ['台北Táiběi'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'ID selector, matching id value using non-ASCII characters',
    'selector': '#台北',
    'expect': ['台北'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'ID selector, matching id values using non-ASCII characters',
    'selector': '#台北Táiběi, #台北',
    'expect': ['台北Táiběi', '台北'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // XXX runMatchesTest() in level2-lib.js can't handle this because obtaining the expected nodes requires escaping characters when generating the selector from 'expect' values
  {
    'name': 'ID selector, matching element with id with escaped character',
    'selector': '#\\#foo\\:bar',
    'expect': ['#foo:bar'],
    'level': 1,
    'testType': testQsaBaseline
  },
  {
    'name': 'ID selector, matching element with id with escaped character',
    'selector': '#test\\.foo\\[5\\]bar',
    'expect': ['test.foo[5]bar'],
    'level': 1,
    'testType': testQsaBaseline
  },

  // Namespaces
  // XXX runMatchesTest() in level2-lib.js can't handle these because non-HTML elements don't have a recognised id
  {
    'name': 'Namespace selector, matching element with any namespace',
    'selector': '#any-namespace *|div',
    'expect': [
      'any-namespace-div1',
      'any-namespace-div2',
      'any-namespace-div3',
      'any-namespace-div4'
    ],
    'level': 3,
    'testType': testQsaBaseline
  },
  {
    'name': 'Namespace selector, matching div elements in no namespace only',
    'selector': '#no-namespace |div',
    'expect': ['no-namespace-div3'],
    'level': 3,
    'testType': testQsaBaseline
  },
  {
    'name': 'Namespace selector, matching any elements in no namespace only',
    'selector': '#no-namespace |*',
    'expect': ['no-namespace-div3'],
    'level': 3,
    'testType': testQsaBaseline
  },

  // Combinators
  // - Descendant combinator ' '
  {
    'name':
        'Descendant combinator, matching element that is a descendant of an element with id',
    'selector': '#descendant div',
    'expect': [
      'descendant-div1',
      'descendant-div2',
      'descendant-div3',
      'descendant-div4'
    ],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Descendant combinator, matching element with id that is a descendant of an element',
    'selector': 'body #descendant-div1',
    'expect': ['descendant-div1'],
    'exclude': ['detached', 'fragment'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Descendant combinator, matching element with id that is a descendant of an element',
    'selector': 'div #descendant-div1',
    'expect': ['descendant-div1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Descendant combinator, matching element with id that is a descendant of an element with id',
    'selector': '#descendant #descendant-div2',
    'expect': ['descendant-div2'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Descendant combinator, matching element with class that is a descendant of an element with id',
    'selector': '#descendant .descendant-div2',
    'expect': ['descendant-div2'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Descendant combinator, matching element with class that is a descendant of an element with class',
    'selector': '.descendant-div1 .descendant-div3',
    'expect': ['descendant-div3'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Descendant combinator, not matching element with id that is not a descendant of an element with id',
    'selector': '#descendant-div1 #descendant-div4',
    'expect': [] /*no matches*/,
    'level': 1,
    'testType': testQsaBaseline
  },
  {
    'name': 'Descendant combinator, whitespace characters',
    'selector': '#descendant\t\r\n#descendant-div2',
    'expect': ['descendant-div2'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // - Child combinator '>'
  {
    'name':
        'Child combinator, matching element that is a child of an element with id',
    'selector': '#child>div',
    'expect': ['child-div1', 'child-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Child combinator, matching element with id that is a child of an element',
    'selector': 'div>#child-div1',
    'expect': ['child-div1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Child combinator, matching element with id that is a child of an element with id',
    'selector': '#child>#child-div1',
    'expect': ['child-div1'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Child combinator, matching element with id that is a child of an element with class',
    'selector': '#child-div1>.child-div2',
    'expect': ['child-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Child combinator, matching element with class that is a child of an element with class',
    'selector': '.child-div1>.child-div2',
    'expect': ['child-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Child combinator, not matching element with id that is not a child of an element with id',
    'selector': '#child>#child-div3',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Child combinator, not matching element with id that is not a child of an element with class',
    'selector': '#child-div1>.child-div3',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name':
        'Child combinator, not matching element with class that is not a child of an element with class',
    'selector': '.child-div1>.child-div3',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name': 'Child combinator, surrounded by whitespace',
    'selector': '#child-div1\t\r\n>\t\r\n#child-div2',
    'expect': ['child-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Child combinator, whitespace after',
    'selector': '#child-div1>\t\r\n#child-div2',
    'expect': ['child-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Child combinator, whitespace before',
    'selector': '#child-div1\t\r\n>#child-div2',
    'expect': ['child-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Child combinator, no whitespace',
    'selector': '#child-div1>#child-div2',
    'expect': ['child-div2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // - Adjacent sibling combinator '+'
  {
    'name':
        'Adjacent sibling combinator, matching element that is an adjacent sibling of an element with id',
    'selector': '#adjacent-div2+div',
    'expect': ['adjacent-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Adjacent sibling combinator, matching element with id that is an adjacent sibling of an element',
    'selector': 'div+#adjacent-div4',
    'expect': ['adjacent-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Adjacent sibling combinator, matching element with id that is an adjacent sibling of an element with id',
    'selector': '#adjacent-div2+#adjacent-div4',
    'expect': ['adjacent-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Adjacent sibling combinator, matching element with class that is an adjacent sibling of an element with id',
    'selector': '#adjacent-div2+.adjacent-div4',
    'expect': ['adjacent-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Adjacent sibling combinator, matching element with class that is an adjacent sibling of an element with class',
    'selector': '.adjacent-div2+.adjacent-div4',
    'expect': ['adjacent-div4'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Adjacent sibling combinator, matching p element that is an adjacent sibling of a div element',
    'selector': '#adjacent div+p',
    'expect': ['adjacent-p2'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name':
        'Adjacent sibling combinator, not matching element with id that is not an adjacent sibling of an element with id',
    'selector': '#adjacent-div2+#adjacent-p2, #adjacent-div2+#adjacent-div1',
    'expect': [] /*no matches*/,
    'level': 2,
    'testType': testQsaBaseline
  },
  {
    'name': 'Adjacent sibling combinator, surrounded by whitespace',
    'selector': '#adjacent-p2\t\r\n+\t\r\n#adjacent-p3',
    'expect': ['adjacent-p3'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Adjacent sibling combinator, whitespace after',
    'selector': '#adjacent-p2+\t\r\n#adjacent-p3',
    'expect': ['adjacent-p3'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Adjacent sibling combinator, whitespace before',
    'selector': '#adjacent-p2\t\r\n+#adjacent-p3',
    'expect': ['adjacent-p3'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Adjacent sibling combinator, no whitespace',
    'selector': '#adjacent-p2+#adjacent-p3',
    'expect': ['adjacent-p3'],
    'level': 2,
    'testType': testQsaBaseline | testMatchBaseline
  },

  // - General sibling combinator ~ (Level 3)
  {
    'name':
        'General sibling combinator, matching element that is a sibling of an element with id',
    'selector': '#sibling-div2~div',
    'expect': ['sibling-div4', 'sibling-div6'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'General sibling combinator, matching element with id that is a sibling of an element',
    'selector': 'div~#sibling-div4',
    'expect': ['sibling-div4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'General sibling combinator, matching element with id that is a sibling of an element with id',
    'selector': '#sibling-div2~#sibling-div4',
    'expect': ['sibling-div4'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'General sibling combinator, matching element with class that is a sibling of an element with id',
    'selector': '#sibling-div2~.sibling-div',
    'expect': ['sibling-div4', 'sibling-div6'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'General sibling combinator, matching p element that is a sibling of a div element',
    'selector': '#sibling div~p',
    'expect': ['sibling-p2', 'sibling-p3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name':
        'General sibling combinator, not matching element with id that is not a sibling after a p element',
    'selector': '#sibling>p~div',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },
  {
    'name':
        'General sibling combinator, not matching element with id that is not a sibling after an element with id',
    'selector': '#sibling-div2~#sibling-div3, #sibling-div2~#sibling-div1',
    'expect': [] /*no matches*/,
    'level': 3,
    'testType': testQsaAdditional
  },
  {
    'name': 'General sibling combinator, surrounded by whitespace',
    'selector': '#sibling-p2\t\r\n~\t\r\n#sibling-p3',
    'expect': ['sibling-p3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': 'General sibling combinator, whitespace after',
    'selector': '#sibling-p2~\t\r\n#sibling-p3',
    'expect': ['sibling-p3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': 'General sibling combinator, whitespace before',
    'selector': '#sibling-p2\t\r\n~#sibling-p3',
    'expect': ['sibling-p3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },
  {
    'name': 'General sibling combinator, no whitespace',
    'selector': '#sibling-p2~#sibling-p3',
    'expect': ['sibling-p3'],
    'level': 3,
    'testType': testQsaAdditional | testMatchBaseline
  },

  // Group of selectors (comma)
  {
    'name': 'Syntax, group of selectors separator, surrounded by whitespace',
    'selector': '#group em\t\r \n,\t\r \n#group strong',
    'expect': ['group-em1', 'group-strong1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Syntax, group of selectors separator, whitespace after',
    'selector': '#group em,\t\r\n#group strong',
    'expect': ['group-em1', 'group-strong1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Syntax, group of selectors separator, whitespace before',
    'selector': '#group em\t\r\n,#group strong',
    'expect': ['group-em1', 'group-strong1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
  {
    'name': 'Syntax, group of selectors separator, no whitespace',
    'selector': '#group em,#group strong',
    'expect': ['group-em1', 'group-strong1'],
    'level': 1,
    'testType': testQsaBaseline | testMatchBaseline
  },
];
