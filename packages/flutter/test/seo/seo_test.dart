// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/src/seo/seo_tag.dart';
import 'package:flutter/src/seo/seo_node.dart';
import 'package:flutter/src/seo/seo_widget.dart';
import 'package:flutter/src/seo/seo_link.dart';
import 'package:flutter/src/seo/seo_image.dart';
import 'package:flutter/src/seo/seo_list.dart';
import 'package:flutter/src/seo/seo_head.dart';
import 'package:flutter/src/seo/seo_structured_data.dart';
import 'package:flutter/src/seo/seo_tree.dart';
import 'package:flutter/src/seo/seo_router.dart';

void main() {
  group('SeoTag', () {
    test('htmlTag returns correct tag names', () {
      expect(SeoTag.h1.htmlTag, 'h1');
      expect(SeoTag.h2.htmlTag, 'h2');
      expect(SeoTag.h3.htmlTag, 'h3');
      expect(SeoTag.h4.htmlTag, 'h4');
      expect(SeoTag.h5.htmlTag, 'h5');
      expect(SeoTag.h6.htmlTag, 'h6');
      expect(SeoTag.p.htmlTag, 'p');
      expect(SeoTag.article.htmlTag, 'article');
      expect(SeoTag.nav.htmlTag, 'nav');
      expect(SeoTag.main.htmlTag, 'main');
      expect(SeoTag.section.htmlTag, 'section');
      expect(SeoTag.aside.htmlTag, 'aside');
      expect(SeoTag.header.htmlTag, 'header');
      expect(SeoTag.footer.htmlTag, 'footer');
      expect(SeoTag.div.htmlTag, 'div');
      expect(SeoTag.span.htmlTag, 'span');
      expect(SeoTag.a.htmlTag, 'a');
      expect(SeoTag.img.htmlTag, 'img');
      expect(SeoTag.ul.htmlTag, 'ul');
      expect(SeoTag.ol.htmlTag, 'ol');
      expect(SeoTag.li.htmlTag, 'li');
      expect(SeoTag.strong.htmlTag, 'strong');
      expect(SeoTag.em.htmlTag, 'em');
      expect(SeoTag.blockquote.htmlTag, 'blockquote');
      expect(SeoTag.time.htmlTag, 'time');
      expect(SeoTag.address.htmlTag, 'address');
      expect(SeoTag.figure.htmlTag, 'figure');
      expect(SeoTag.figcaption.htmlTag, 'figcaption');
    });

    test('isVoid identifies void elements', () {
      expect(SeoTag.img.isVoid, isTrue);
      expect(SeoTag.br.isVoid, isTrue);
      expect(SeoTag.hr.isVoid, isTrue);
      expect(SeoTag.p.isVoid, isFalse);
      expect(SeoTag.div.isVoid, isFalse);
      expect(SeoTag.a.isVoid, isFalse);
      expect(SeoTag.span.isVoid, isFalse);
    });

    test('isBlock identifies block elements', () {
      expect(SeoTag.div.isBlock, isTrue);
      expect(SeoTag.p.isBlock, isTrue);
      expect(SeoTag.article.isBlock, isTrue);
      expect(SeoTag.section.isBlock, isTrue);
      expect(SeoTag.main.isBlock, isTrue);
      expect(SeoTag.nav.isBlock, isTrue);
      expect(SeoTag.header.isBlock, isTrue);
      expect(SeoTag.footer.isBlock, isTrue);
      expect(SeoTag.blockquote.isBlock, isTrue);
      expect(SeoTag.ul.isBlock, isTrue);
      expect(SeoTag.ol.isBlock, isTrue);
      expect(SeoTag.li.isBlock, isTrue);
      expect(SeoTag.h1.isBlock, isTrue);
      expect(SeoTag.span.isBlock, isFalse);
      expect(SeoTag.a.isBlock, isFalse);
      expect(SeoTag.strong.isBlock, isFalse);
      expect(SeoTag.em.isBlock, isFalse);
    });

    test('isHeading identifies heading elements', () {
      expect(SeoTag.h1.isHeading, isTrue);
      expect(SeoTag.h2.isHeading, isTrue);
      expect(SeoTag.h3.isHeading, isTrue);
      expect(SeoTag.h4.isHeading, isTrue);
      expect(SeoTag.h5.isHeading, isTrue);
      expect(SeoTag.h6.isHeading, isTrue);
      expect(SeoTag.p.isHeading, isFalse);
      expect(SeoTag.div.isHeading, isFalse);
    });
  });

  group('SeoNode', () {
    test('generates correct HTML for simple element', () {
      const node = SeoNode(
        tag: SeoTag.h1,
        textContent: 'Hello World',
      );
      expect(node.toHtml(), '<h1>Hello World</h1>');
    });

    test('generates HTML with attributes', () {
      const node = SeoNode(
        tag: SeoTag.a,
        attributes: {'href': '/about', 'title': 'About Us'},
        textContent: 'About',
      );
      final html = node.toHtml();
      expect(html, contains('<a'));
      expect(html, contains('href="/about"'));
      expect(html, contains('title="About Us"'));
      expect(html, contains('About</a>'));
    });

    test('generates HTML with children', () {
      const node = SeoNode(
        tag: SeoTag.nav,
        children: [
          SeoNode(tag: SeoTag.a, attributes: {'href': '/'}, textContent: 'Home'),
          SeoNode(tag: SeoTag.a, attributes: {'href': '/about'}, textContent: 'About'),
        ],
      );
      final html = node.toHtml();
      expect(html, contains('<nav>'));
      expect(html, contains('<a href="/">Home</a>'));
      expect(html, contains('<a href="/about">About</a>'));
      expect(html, contains('</nav>'));
    });

    test('escapes HTML entities in text content', () {
      const node = SeoNode(
        tag: SeoTag.p,
        textContent: '<script>alert("xss")</script>',
      );
      final html = node.toHtml();
      expect(html, contains('&lt;script&gt;'));
      expect(html, contains('&quot;xss&quot;'));
      expect(html, contains('&lt;/script&gt;'));
      expect(html, isNot(contains('<script>')));
    });

    test('generates void elements correctly', () {
      const node = SeoNode(
        tag: SeoTag.img,
        attributes: {'src': '/image.jpg', 'alt': 'Test image'},
      );
      final html = node.toHtml();
      expect(html, contains('img'));
      expect(html, contains('src="/image.jpg"'));
      expect(html, contains('alt="Test image"'));
      expect(html, isNot(contains('</img>')));
    });

    test('escapes HTML entities in attributes', () {
      const node = SeoNode(
        tag: SeoTag.a,
        attributes: {'href': '/search?q=test&page=1', 'data-name': "O'Reilly"},
        textContent: 'Search',
      );
      final html = node.toHtml();
      expect(html, contains('&amp;'));
      expect(html, contains('&#39;'));
    });

    test('handles indentation correctly', () {
      const node = SeoNode(
        tag: SeoTag.div,
        textContent: 'Content',
      );
      final html = node.toHtml(indent: 2);
      expect(html, startsWith('    <div>'));
    });

    test('creates link node correctly', () {
      final node = SeoNode.link(
        href: 'https://example.com',
        text: 'Example',
        title: 'Visit Example',
      );
      expect(node.tag, SeoTag.a);
      expect(node.attributes['href'], 'https://example.com');
      expect(node.attributes['title'], 'Visit Example');
      expect(node.textContent, 'Example');
    });

    test('creates image node correctly', () {
      final node = SeoNode.image(
        src: '/image.png',
        alt: 'My Image',
        width: 100,
        height: 200,
      );
      expect(node.tag, SeoTag.img);
      expect(node.attributes['src'], '/image.png');
      expect(node.attributes['alt'], 'My Image');
      expect(node.attributes['width'], '100');
      expect(node.attributes['height'], '200');
    });

    test('creates heading nodes correctly', () {
      final h1 = SeoNode.heading(level: 1, text: 'Title');
      expect(h1.tag, SeoTag.h1);
      expect(h1.textContent, 'Title');

      final h3 = SeoNode.heading(level: 3, text: 'Subtitle');
      expect(h3.tag, SeoTag.h3);
    });
  });

  group('Seo widget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: Seo(
                tag: SeoTag.h1,
                child: const Text('Hello'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('SeoText renders text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoText(
                'Hello SEO',
                tag: SeoTag.h1,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello SEO'), findsOneWidget);
    });

    testWidgets('SeoExclude renders child normally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoExclude(
                child: const Text('Hidden from SEO'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hidden from SEO'), findsOneWidget);
    });

    testWidgets('Seo with attributes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: Seo(
                tag: SeoTag.article,
                attributes: const {'id': 'main-article', 'class': 'content'},
                child: const Text('Article content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Article content'), findsOneWidget);
    });
  });

  group('SeoLink', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoLink(
                href: '/about',
                child: const Text('About'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('handles tap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoLink(
                href: '/about',
                onTap: () => tapped = true,
                child: const Text('About'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('About'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('supports external links', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoLink(
                href: 'https://flutter.dev',
                external: true,
                child: const Text('Flutter'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('supports title attribute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoLink(
                href: '/contact',
                title: 'Contact us page',
                child: const Text('Contact'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Contact'), findsOneWidget);
    });
  });

  group('SeoImage', () {
    testWidgets('SeoImage.asset renders image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoImage.asset(
                'assets/test.png',
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

    testWidgets('SeoImage with figure caption', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoImage.asset(
                'assets/test.png',
                alt: 'Test image',
                caption: 'This is a test image',
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      );

      expect(find.text('This is a test image'), findsOneWidget);
    });
  });

  group('SeoList', () {
    testWidgets('SeoList.unordered renders list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoList.unordered(
                items: const [
                  Text('Item 1'),
                  Text('Item 2'),
                  Text('Item 3'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('SeoList.ordered renders list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoList.ordered(
                items: const [
                  Text('First'),
                  Text('Second'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('SeoNav renders navigation list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoNav(
                ariaLabel: 'Main navigation',
                children: const [
                  Text('Home'),
                  Text('About'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('SeoBreadcrumb renders breadcrumbs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Scaffold(
              body: SeoBreadcrumb(
                items: const [
                  SeoBreadcrumbItem(label: 'Home', href: '/'),
                  SeoBreadcrumbItem(label: 'Products', href: '/products'),
                  SeoBreadcrumbItem(label: 'Widget', isCurrent: true),
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
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: SeoHead(
              title: 'Page Title',
              description: 'Page description',
              child: const Scaffold(
                body: Text('Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('handles robots settings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: SeoHead(
              title: 'Test',
              description: 'Test page',
              robots: const SeoRobots(
                index: false,
                follow: true,
              ),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('SeoStructuredData', () {
    test('SeoSchema.product generates valid JSON-LD', () {
      final schema = SeoSchema.product(
        name: 'Test Product',
        description: 'A test product',
        price: 29.99,
        currency: 'USD',
        availability: SeoAvailability.inStock,
      );

      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'Product');
      expect(schema['name'], 'Test Product');
      expect(schema['description'], 'A test product');
      expect(schema['offers']['price'], '29.99');
      expect(schema['offers']['priceCurrency'], 'USD');
      expect(schema['offers']['availability'], 'https://schema.org/InStock');
    });

    test('SeoSchema.product with rating', () {
      final schema = SeoSchema.product(
        name: 'Rated Product',
        rating: 4.5,
        reviewCount: 127,
      );

      expect(schema['aggregateRating']['@type'], 'AggregateRating');
      expect(schema['aggregateRating']['ratingValue'], '4.5');
      expect(schema['aggregateRating']['reviewCount'], '127');
    });

    test('SeoSchema.article generates valid JSON-LD', () {
      final schema = SeoSchema.article(
        headline: 'Test Article',
        author: 'Test Author',
        datePublished: DateTime(2025, 1, 15),
        description: 'An article about testing',
      );

      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'Article');
      expect(schema['headline'], 'Test Article');
      expect(schema['author']['@type'], 'Person');
      expect(schema['author']['name'], 'Test Author');
      expect(schema['datePublished'], '2025-01-15T00:00:00.000');
      expect(schema['description'], 'An article about testing');
    });

    test('SeoSchema.article with publisher', () {
      final schema = SeoSchema.article(
        headline: 'Published Article',
        publisher: 'News Corp',
        publisherLogo: 'https://example.com/logo.png',
      );

      expect(schema['publisher']['@type'], 'Organization');
      expect(schema['publisher']['name'], 'News Corp');
      expect(schema['publisher']['logo']['@type'], 'ImageObject');
      expect(schema['publisher']['logo']['url'], 'https://example.com/logo.png');
    });

    test('SeoSchema.faqPage generates valid JSON-LD', () {
      final schema = SeoSchema.faqPage(
        questions: [
          const SeoFaqItem(question: 'What is Flutter?', answer: 'A UI toolkit'),
          const SeoFaqItem(question: 'Is it free?', answer: 'Yes, it is open source'),
        ],
      );

      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'FAQPage');
      expect(schema['mainEntity'], hasLength(2));
      expect(schema['mainEntity'][0]['@type'], 'Question');
      expect(schema['mainEntity'][0]['name'], 'What is Flutter?');
      expect(schema['mainEntity'][0]['acceptedAnswer']['@type'], 'Answer');
      expect(schema['mainEntity'][0]['acceptedAnswer']['text'], 'A UI toolkit');
    });

    test('SeoSchema.breadcrumbList generates valid JSON-LD', () {
      final schema = SeoSchema.breadcrumbList(
        items: const [
          SeoBreadcrumb(name: 'Home', url: 'https://example.com'),
          SeoBreadcrumb(name: 'Products', url: 'https://example.com/products'),
        ],
      );

      expect(schema['@type'], 'BreadcrumbList');
      expect(schema['itemListElement'], hasLength(2));
      expect(schema['itemListElement'][0]['position'], 1);
      expect(schema['itemListElement'][0]['name'], 'Home');
      expect(schema['itemListElement'][1]['position'], 2);
    });

    test('SeoSchema.localBusiness generates valid JSON-LD', () {
      final schema = SeoSchema.localBusiness(
        name: 'Test Restaurant',
        telephone: '+1-555-1234',
        priceRange: r'$$',
        address: const SeoAddress(
          streetAddress: '123 Main St',
          addressLocality: 'Anytown',
          postalCode: '12345',
          addressCountry: 'US',
        ),
        geo: const SeoGeo(latitude: 40.7128, longitude: -74.0060),
      );

      expect(schema['@type'], 'LocalBusiness');
      expect(schema['name'], 'Test Restaurant');
      expect(schema['telephone'], '+1-555-1234');
      expect(schema['priceRange'], r'$$');
      expect(schema['address']['@type'], 'PostalAddress');
      expect(schema['address']['streetAddress'], '123 Main St');
      expect(schema['geo']['@type'], 'GeoCoordinates');
      expect(schema['geo']['latitude'], '40.7128');
    });

    test('SeoSchema.event generates valid JSON-LD', () {
      final schema = SeoSchema.event(
        name: 'Flutter Meetup',
        startDate: DateTime(2025, 6, 15, 18, 0),
        location: 'Conference Center',
        status: SeoEventStatus.scheduled,
        attendanceMode: SeoEventAttendanceMode.offline,
      );

      expect(schema['@type'], 'Event');
      expect(schema['name'], 'Flutter Meetup');
      expect(schema['startDate'], contains('2025-06-15'));
      expect(schema['location']['name'], 'Conference Center');
      expect(schema['eventStatus'], 'https://schema.org/EventScheduled');
      expect(schema['eventAttendanceMode'], 'https://schema.org/OfflineEventAttendanceMode');
    });

    test('SeoSchema.website generates valid JSON-LD', () {
      final schema = SeoSchema.website(
        name: 'My Website',
        url: 'https://example.com',
        searchUrlTemplate: 'https://example.com/search?q={search_term_string}',
      );

      expect(schema['@type'], 'WebSite');
      expect(schema['name'], 'My Website');
      expect(schema['url'], 'https://example.com');
      expect(schema['potentialAction']['@type'], 'SearchAction');
    });

    test('SeoSchema.organization generates valid JSON-LD', () {
      final schema = SeoSchema.organization(
        name: 'Acme Corp',
        url: 'https://acme.com',
        logo: 'https://acme.com/logo.png',
        sameAs: ['https://twitter.com/acme', 'https://facebook.com/acme'],
      );

      expect(schema['@type'], 'Organization');
      expect(schema['name'], 'Acme Corp');
      expect(schema['logo'], 'https://acme.com/logo.png');
      expect(schema['sameAs'], hasLength(2));
    });

    testWidgets('widget renders child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: SeoStructuredData(
              data: SeoSchema.product(name: 'Test'),
              child: const Scaffold(body: Text('Product')),
            ),
          ),
        ),
      );

      expect(find.text('Product'), findsOneWidget);
    });
  });

  group('SeoRouter', () {
    test('SeoRoute has correct defaults', () {
      const route = SeoRoute(path: '/about');
      expect(route.path, '/about');
      expect(route.changeFrequency, isNull);
      expect(route.priority, isNull);
      expect(route.lastModified, isNull);
    });

    test('SeoRoute with all options', () {
      final route = SeoRoute(
        path: '/products',
        changeFrequency: SeoChangeFrequency.daily,
        priority: 0.8,
        lastModified: DateTime(2025, 1, 1),
      );
      expect(route.changeFrequency, SeoChangeFrequency.daily);
      expect(route.priority, 0.8);
      expect(route.lastModified, isNotNull);
    });

    test('SeoChangeFrequency values', () {
      expect(SeoChangeFrequency.always.value, 'always');
      expect(SeoChangeFrequency.hourly.value, 'hourly');
      expect(SeoChangeFrequency.daily.value, 'daily');
      expect(SeoChangeFrequency.weekly.value, 'weekly');
      expect(SeoChangeFrequency.monthly.value, 'monthly');
      expect(SeoChangeFrequency.yearly.value, 'yearly');
      expect(SeoChangeFrequency.never.value, 'never');
    });

    test('SeoRouter generates sitemap', () {
      final routes = [
        const SeoRoute(path: '/', priority: 1.0),
        const SeoRoute(path: '/about', priority: 0.5, changeFrequency: SeoChangeFrequency.monthly),
      ];

      final sitemap = SeoRouter.generateSitemap(
        routes: routes,
        baseUrl: 'https://example.com',
      );

      expect(sitemap, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(sitemap, contains('<urlset'));
      expect(sitemap, contains('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'));
      expect(sitemap, contains('<loc>https://example.com/</loc>'));
      expect(sitemap, contains('<priority>1.0</priority>'));
      expect(sitemap, contains('<loc>https://example.com/about</loc>'));
      expect(sitemap, contains('<changefreq>monthly</changefreq>'));
    });

    test('SeoRouter generates robots.txt', () {
      final robots = SeoRouter.generateRobotsTxt(
        sitemapUrl: 'https://example.com/sitemap.xml',
        disallowPaths: ['/admin', '/private'],
        allowPaths: ['/public'],
      );

      expect(robots, contains('User-agent: *'));
      expect(robots, contains('Disallow: /admin'));
      expect(robots, contains('Disallow: /private'));
      expect(robots, contains('Allow: /public'));
      expect(robots, contains('Sitemap: https://example.com/sitemap.xml'));
    });

    test('SeoRouter robots.txt with custom user agents', () {
      final robots = SeoRouter.generateRobotsTxt(
        userAgent: 'Googlebot',
        disallowPaths: ['/no-google'],
        crawlDelay: 10,
      );

      expect(robots, contains('User-agent: Googlebot'));
      expect(robots, contains('Disallow: /no-google'));
      expect(robots, contains('Crawl-delay: 10'));
    });
  });

  group('SeoTree', () {
    testWidgets('SeoTreeRoot provides manager', (tester) async {
      SeoTreeManager? capturedManager;

      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: Builder(
              builder: (context) {
                capturedManager = SeoTree.maybeOf(context);
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      expect(capturedManager, isNotNull);
    });

    testWidgets('SeoTree.of throws without root', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return const Text('Test');
            },
          ),
        ),
      );

      expect(
        () => SeoTree.of(tester.element(find.text('Test'))),
        throwsAssertionError,
      );
    });

    testWidgets('SeoTreeRoot enabled flag', (tester) async {
      SeoTreeManager? manager;

      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            enabled: false,
            child: Builder(
              builder: (context) {
                manager = SeoTree.maybeOf(context);
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      expect(manager, isNotNull);
      expect(manager!.enabled, isFalse);
    });

    test('SeoTreeManager toHtml generates correct structure', () {
      final manager = SeoTreeManager(enabled: true, debugVisible: false);
      expect(manager.toHtml(), contains('<div id="flutter-seo-root"'));
      expect(manager.toHtml(), contains('</div>'));
    });
  });

  group('SeoRobots', () {
    test('default values', () {
      const robots = SeoRobots();
      expect(robots.index, isTrue);
      expect(robots.follow, isTrue);
    });

    test('toContentString with defaults', () {
      const robots = SeoRobots();
      expect(robots.toContentString(), 'index, follow');
    });

    test('toContentString with noindex nofollow', () {
      const robots = SeoRobots(index: false, follow: false);
      expect(robots.toContentString(), 'noindex, nofollow');
    });

    test('toContentString with additional directives', () {
      const robots = SeoRobots(
        index: true,
        follow: true,
        noArchive: true,
        noSnippet: true,
      );
      final content = robots.toContentString();
      expect(content, contains('index'));
      expect(content, contains('follow'));
      expect(content, contains('noarchive'));
      expect(content, contains('nosnippet'));
    });

    test('toContentString with maxSnippet', () {
      const robots = SeoRobots(maxSnippet: 150);
      expect(robots.toContentString(), contains('max-snippet:150'));
    });

    test('toContentString with maxImagePreview', () {
      const robots = SeoRobots(maxImagePreview: 'large');
      expect(robots.toContentString(), contains('max-image-preview:large'));
    });
  });

  group('SeoTwitterCard', () {
    test('values', () {
      expect(SeoTwitterCard.summary.value, 'summary');
      expect(SeoTwitterCard.summaryLargeImage.value, 'summary_large_image');
      expect(SeoTwitterCard.app.value, 'app');
      expect(SeoTwitterCard.player.value, 'player');
    });
  });

  group('Integration', () {
    testWidgets('full page SEO structure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeoTreeRoot(
            child: SeoHead(
              title: 'Test Page',
              description: 'A test page for SEO',
              canonicalUrl: 'https://example.com/',
              ogTitle: 'Test Page OG',
              twitterCard: SeoTwitterCard.summaryLargeImage,
              child: Scaffold(
                body: Column(
                  children: [
                    SeoNav(
                      ariaLabel: 'Main',
                      children: [
                        SeoLink(href: '/', child: const Text('Home')),
                        SeoLink(href: '/about', child: const Text('About')),
                      ],
                    ),
                    Seo(
                      tag: SeoTag.main,
                      child: Column(
                        children: [
                          Seo(
                            tag: SeoTag.h1,
                            child: const Text('Welcome'),
                          ),
                          Seo(
                            tag: SeoTag.p,
                            child: const Text('This is the content.'),
                          ),
                          SeoStructuredData(
                            data: SeoSchema.website(
                              name: 'Test',
                              url: 'https://example.com',
                            ),
                            child: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('This is the content.'), findsOneWidget);
    });
  });
}
