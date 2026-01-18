// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/src/seo/seo_head.dart';
import 'package:flutter/src/seo/seo_image.dart';
import 'package:flutter/src/seo/seo_link.dart';
import 'package:flutter/src/seo/seo_list.dart';
import 'package:flutter/src/seo/seo_node.dart';
import 'package:flutter/src/seo/seo_router.dart';
import 'package:flutter/src/seo/seo_structured_data.dart';
import 'package:flutter/src/seo/seo_tag.dart';
import 'package:flutter/src/seo/seo_tree.dart';
import 'package:flutter/src/seo/seo_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeoTag', () {
    test('htmlTag returns correct tag names', () {
      expect(SeoTag.h1.htmlTag, 'h1');
      expect(SeoTag.h2.htmlTag, 'h2');
      expect(SeoTag.h3.htmlTag, 'h3');
      expect(SeoTag.p.htmlTag, 'p');
      expect(SeoTag.article.htmlTag, 'article');
      expect(SeoTag.nav.htmlTag, 'nav');
      expect(SeoTag.a.htmlTag, 'a');
      expect(SeoTag.img.htmlTag, 'img');
      expect(SeoTag.ul.htmlTag, 'ul');
      expect(SeoTag.ol.htmlTag, 'ol');
      expect(SeoTag.li.htmlTag, 'li');
    });

    test('tagName is an alias for htmlTag', () {
      expect(SeoTag.h1.tagName, SeoTag.h1.htmlTag);
      expect(SeoTag.p.tagName, SeoTag.p.htmlTag);
    });

    test('isVoid identifies void elements', () {
      expect(SeoTag.img.isVoid, isTrue);
      expect(SeoTag.br.isVoid, isTrue);
      expect(SeoTag.hr.isVoid, isTrue);
      expect(SeoTag.p.isVoid, isFalse);
      expect(SeoTag.div.isVoid, isFalse);
    });

    test('isVoidElement is an alias for isVoid', () {
      expect(SeoTag.img.isVoidElement, SeoTag.img.isVoid);
      expect(SeoTag.p.isVoidElement, SeoTag.p.isVoid);
    });

    test('isBlock identifies block elements', () {
      expect(SeoTag.div.isBlock, isTrue);
      expect(SeoTag.p.isBlock, isTrue);
      expect(SeoTag.article.isBlock, isTrue);
      expect(SeoTag.h1.isBlock, isTrue);
      expect(SeoTag.span.isBlock, isFalse);
      expect(SeoTag.a.isBlock, isFalse);
    });

    test('isBlockElement is an alias for isBlock', () {
      expect(SeoTag.div.isBlockElement, SeoTag.div.isBlock);
      expect(SeoTag.span.isBlockElement, SeoTag.span.isBlock);
    });

    test('isHeading identifies heading elements', () {
      expect(SeoTag.h1.isHeading, isTrue);
      expect(SeoTag.h2.isHeading, isTrue);
      expect(SeoTag.h6.isHeading, isTrue);
      expect(SeoTag.p.isHeading, isFalse);
    });

    test('headingLevel returns correct level', () {
      expect(SeoTag.h1.headingLevel, 1);
      expect(SeoTag.h2.headingLevel, 2);
      expect(SeoTag.h6.headingLevel, 6);
      expect(SeoTag.p.headingLevel, isNull);
    });
  });

  group('SeoNode', () {
    test('creates node with text', () {
      const node = SeoNode(tag: SeoTag.h1, text: 'Hello World');
      expect(node.tag, SeoTag.h1);
      expect(node.text, 'Hello World');
      expect(node.textContent, 'Hello World');
    });

    test('creates node with textContent parameter', () {
      const node = SeoNode(tag: SeoTag.p, textContent: 'Paragraph');
      expect(node.text, 'Paragraph');
      expect(node.textContent, 'Paragraph');
    });

    test('generates correct HTML for simple element', () {
      const node = SeoNode(tag: SeoTag.h1, text: 'Hello World');
      expect(node.toHtml(), contains('<h1>'));
      expect(node.toHtml(), contains('Hello World'));
      expect(node.toHtml(), contains('</h1>'));
    });

    test('generates HTML with attributes', () {
      const node = SeoNode(
        tag: SeoTag.a,
        attributes: <String, String>{'href': '/about', 'title': 'About Us'},
        text: 'About',
      );
      final html = node.toHtml();
      expect(html, contains('<a'));
      expect(html, contains('href="/about"'));
      expect(html, contains('title="About Us"'));
      expect(html, contains('</a>'));
    });

    test('generates HTML with children', () {
      const node = SeoNode(
        tag: SeoTag.nav,
        children: <SeoNode>[
          SeoNode(tag: SeoTag.a, attributes: <String, String>{'href': '/'}, text: 'Home'),
          SeoNode(tag: SeoTag.a, attributes: <String, String>{'href': '/about'}, text: 'About'),
        ],
      );
      final html = node.toHtml();
      expect(html, contains('<nav>'));
      expect(html, contains('</nav>'));
    });

    test('escapes HTML entities in text content', () {
      const node = SeoNode(tag: SeoTag.p, text: '<script>alert("xss")</script>');
      final html = node.toHtml();
      expect(html, contains('&lt;script&gt;'));
      expect(html, isNot(contains('<script>')));
    });

    test('generates void elements correctly', () {
      const node = SeoNode(
        tag: SeoTag.img,
        attributes: <String, String>{'src': '/image.jpg', 'alt': 'Test image'},
      );
      final html = node.toHtml();
      expect(html, contains('img'));
      expect(html, contains('src="/image.jpg"'));
      expect(html, contains('alt="Test image"'));
      expect(html, isNot(contains('</img>')));
    });

    test('SeoNode.link creates link node', () {
      final node = SeoNode.link(
        href: 'https://example.com',
        text: 'Example',
        title: 'Visit Example',
      );
      expect(node.tag, SeoTag.a);
      expect(node.attributes['href'], 'https://example.com');
      expect(node.attributes['title'], 'Visit Example');
      expect(node.text, 'Example');
    });

    test('SeoNode.image creates image node', () {
      final node = SeoNode.image(src: '/image.png', alt: 'My Image', width: 100, height: 200);
      expect(node.tag, SeoTag.img);
      expect(node.attributes['src'], '/image.png');
      expect(node.attributes['alt'], 'My Image');
      expect(node.attributes['width'], '100');
      expect(node.attributes['height'], '200');
    });

    test('SeoNode.paragraph creates paragraph node', () {
      const node = SeoNode.paragraph(text: 'Hello paragraph');
      expect(node.tag, SeoTag.p);
      expect(node.text, 'Hello paragraph');
    });

    test('SeoNode.list creates list node', () {
      final node = SeoNode.list(items: <String>['One', 'Two', 'Three']);
      expect(node.tag, SeoTag.ul);
      expect(node.children.length, 3);
      expect(node.children[0].tag, SeoTag.li);
      expect(node.children[0].text, 'One');
    });

    test('SeoNode.list creates ordered list when specified', () {
      final node = SeoNode.list(items: <String>['First', 'Second'], ordered: true);
      expect(node.tag, SeoTag.ol);
    });

    test('copyWith creates modified copy', () {
      const original = SeoNode(tag: SeoTag.h1, text: 'Original');
      final copy = original.copyWith(text: 'Modified');
      expect(copy.tag, SeoTag.h1);
      expect(copy.text, 'Modified');
      expect(original.text, 'Original');
    });

    test('hasContent returns true when node has text', () {
      const node = SeoNode(tag: SeoTag.p, text: 'Hello');
      expect(node.hasContent, isTrue);
    });

    test('hasContent returns true when node has children', () {
      const node = SeoNode(
        tag: SeoTag.div,
        children: <SeoNode>[SeoNode(tag: SeoTag.p, text: 'Child')],
      );
      expect(node.hasContent, isTrue);
    });

    test('hasContent returns false when node is empty', () {
      const node = SeoNode(tag: SeoTag.div);
      expect(node.hasContent, isFalse);
    });
  });

  group('Seo widget', () {
    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: Seo(tag: SeoTag.h1, child: Text('Hello')),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('SeoText renders text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(body: SeoText('Hello SEO', tag: SeoTag.h1)),
          ),
        ),
      );

      expect(find.text('Hello SEO'), findsOneWidget);
    });

    testWidgets('SeoExclude renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(body: SeoExclude(child: Text('Hidden from SEO'))),
          ),
        ),
      );

      expect(find.text('Hidden from SEO'), findsOneWidget);
    });
  });

  group('SeoLink', () {
    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoLink(href: '/about', child: Text('About')),
            ),
          ),
        ),
      );

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoLink(href: '/about', onTap: () => tapped = true, child: const Text('About')),
            ),
          ),
        ),
      );

      await tester.tap(find.text('About'));
      expect(tapped, isTrue);
    });
  });

  group('SeoImage', () {
    testWidgets('SeoImage.network renders image', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoImage.network(
                'https://example.com/image.jpg',
                alt: 'Test image',
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('SeoList', () {
    testWidgets('renders items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoList(items: <Widget>[Text('Item 1'), Text('Item 2'), Text('Item 3')]),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('SeoNav renders navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(body: SeoNav(children: <Widget>[Text('Home'), Text('About')])),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('SeoBreadcrumbs renders breadcrumbs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoBreadcrumbs(
                items: <SeoBreadcrumbItem>[
                  SeoBreadcrumbItem(label: 'Home', href: '/'),
                  SeoBreadcrumbItem(label: 'Products', href: '/products'),
                  SeoBreadcrumbItem(label: 'Widget'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Widget'), findsOneWidget);
    });
  });

  group('SeoHead', () {
    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: SeoHead(
              title: 'Page Title',
              description: 'Page description',
              child: Scaffold(body: Text('Content')),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('SeoHead with robots', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeoTreeRoot(
            child: SeoHead(
              title: 'Test',
              description: 'Test page',
              robots: SeoRobots.noindexFollow,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('SeoSchema', () {
    test('website generates correct schema', () {
      final schema = SeoSchema.website(name: 'My Website', url: 'https://example.com');
      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'WebSite');
      expect(schema['name'], 'My Website');
      expect(schema['url'], 'https://example.com');
    });

    test('organization generates correct schema', () {
      final schema = SeoSchema.organization(name: 'My Organization', url: 'https://example.com');
      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'Organization');
      expect(schema['name'], 'My Organization');
    });

    test('article generates correct schema', () {
      final schema = SeoSchema.article(
        headline: 'Test Article',
        author: 'John Doe',
        datePublished: DateTime(2024, 1, 1),
      );
      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'Article');
      expect(schema['headline'], 'Test Article');
      expect((schema['author'] as Map<String, dynamic>)['name'], 'John Doe');
    });

    test('product generates correct schema', () {
      final schema = SeoSchema.product(name: 'Test Product', price: 29.99, currency: 'USD');
      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'Product');
      expect(schema['name'], 'Test Product');
      expect((schema['offers'] as Map<String, dynamic>)['price'], '29.99');
      expect((schema['offers'] as Map<String, dynamic>)['priceCurrency'], 'USD');
    });

    test('faqPage generates correct schema', () {
      final schema = SeoSchema.faqPage(
        questions: <SeoFaqItem>[
          const SeoFaqItem(question: 'What is Flutter?', answer: 'A UI toolkit.'),
          const SeoFaqItem(question: 'Is Flutter free?', answer: 'Yes.'),
        ],
      );
      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'FAQPage');
      expect((schema['mainEntity'] as List<dynamic>).length, 2);
    });

    test('breadcrumbList generates correct schema', () {
      final schema = SeoSchema.breadcrumbList(
        items: <SeoBreadcrumb>[
          const SeoBreadcrumb(name: 'Home', url: 'https://example.com/'),
          const SeoBreadcrumb(name: 'Products', url: 'https://example.com/products'),
        ],
      );
      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'BreadcrumbList');
      expect((schema['itemListElement'] as List<dynamic>).length, 2);
    });
  });

  group('SeoRobots', () {
    test('default constructor creates index/follow', () {
      expect(SeoRobots.indexFollow.index, isTrue);
      expect(SeoRobots.indexFollow.follow, isTrue);
    });

    test('named constants work correctly', () {
      expect(SeoRobots.indexFollow.index, isTrue);
      expect(SeoRobots.indexFollow.follow, isTrue);
      expect(SeoRobots.noindexFollow.index, isFalse);
      expect(SeoRobots.noindexFollow.follow, isTrue);
      expect(SeoRobots.indexNofollow.index, isTrue);
      expect(SeoRobots.indexNofollow.follow, isFalse);
      expect(SeoRobots.noindexNofollow.index, isFalse);
      expect(SeoRobots.noindexNofollow.follow, isFalse);
    });

    test('toContentString generates correct content', () {
      final content = SeoRobots.indexFollow.toContentString();
      expect(content, contains('index'));
      expect(content, contains('follow'));
    });
  });

  group('SeoRouter', () {
    test('generateSitemap creates valid XML', () async {
      const router = SeoRouter(
        baseUrl: 'https://example.com',
        routes: <SeoRoute>[
          SeoRoute(path: '/'),
          SeoRoute(path: '/about'),
          SeoRoute(path: '/contact'),
        ],
      );
      final sitemap = await router.generateSitemap();
      expect(sitemap, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(sitemap, contains('<urlset'));
      expect(sitemap, contains('<loc>https://example.com/</loc>'));
      expect(sitemap, contains('<loc>https://example.com/about</loc>'));
    });

    test('generateRobotsTxt creates valid robots.txt', () {
      const router = SeoRouter(baseUrl: 'https://example.com', routes: <SeoRoute>[]);
      final robotsTxt = router.generateRobotsTxt();
      expect(robotsTxt, contains('User-agent:'));
      expect(robotsTxt, contains('Sitemap: https://example.com/sitemap.xml'));
    });
  });

  group('SeoTreeRoot', () {
    testWidgets('provides SeoTreeManager to descendants', (WidgetTester tester) async {
      SeoTreeManager? manager;
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Builder(
              builder: (BuildContext context) {
                manager = SeoTree.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(manager, isNotNull);
    });
  });

  group('SeoTwitterCard', () {
    test('enum values exist', () {
      expect(SeoTwitterCard.summary, isNotNull);
      expect(SeoTwitterCard.summaryLargeImage, isNotNull);
      expect(SeoTwitterCard.app, isNotNull);
      expect(SeoTwitterCard.player, isNotNull);
    });
  });

  group('SeoChangeFrequency', () {
    test('enum values exist', () {
      expect(SeoChangeFrequency.always, isNotNull);
      expect(SeoChangeFrequency.hourly, isNotNull);
      expect(SeoChangeFrequency.daily, isNotNull);
      expect(SeoChangeFrequency.weekly, isNotNull);
      expect(SeoChangeFrequency.monthly, isNotNull);
      expect(SeoChangeFrequency.yearly, isNotNull);
      expect(SeoChangeFrequency.never, isNotNull);
    });
  });
}
