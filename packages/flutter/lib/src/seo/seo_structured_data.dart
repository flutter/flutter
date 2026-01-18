// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'seo_tree.dart';

/// A widget that injects JSON-LD structured data for rich search results.
///
/// Structured data helps search engines understand your content and can
/// enable rich snippets in search results (ratings, prices, availability, etc.).
///
/// ## Product Example
///
/// ```dart
/// SeoStructuredData(
///   data: SeoSchema.product(
///     name: 'Running Shoes',
///     description: 'Lightweight running shoes for marathon training.',
///     image: 'https://example.com/shoes.jpg',
///     price: 129.99,
///     currency: 'USD',
///     availability: SeoAvailability.inStock,
///     rating: 4.5,
///     reviewCount: 127,
///   ),
///   child: ProductPage(),
/// )
/// ```
///
/// ## Article Example
///
/// ```dart
/// SeoStructuredData(
///   data: SeoSchema.article(
///     headline: 'How to Train for a Marathon',
///     author: 'Jane Smith',
///     datePublished: DateTime(2025, 1, 15),
///     image: 'https://example.com/marathon.jpg',
///   ),
///   child: ArticlePage(),
/// )
/// ```
///
/// ## FAQ Example
///
/// ```dart
/// SeoStructuredData(
///   data: SeoSchema.faqPage(
///     questions: [
///       SeoFaqItem(
///         question: 'How do I return an item?',
///         answer: 'You can return items within 30 days of purchase.',
///       ),
///       SeoFaqItem(
///         question: 'What payment methods do you accept?',
///         answer: 'We accept credit cards, PayPal, and Apple Pay.',
///       ),
///     ],
///   ),
///   child: FaqPage(),
/// )
/// ```
///
/// {@category SEO}
class SeoStructuredData extends StatefulWidget {
  /// Creates a structured data widget with raw JSON-LD data.
  const SeoStructuredData({super.key, required this.data, required this.child});

  /// The JSON-LD structured data.
  ///
  /// This should be a valid schema.org object. Use the [SeoSchema] helpers
  /// to construct common types, or provide your own Map.
  final Map<String, dynamic> data;

  /// The content widget.
  final Widget child;

  @override
  State<SeoStructuredData> createState() => _SeoStructuredDataState();
}

class _SeoStructuredDataState extends State<SeoStructuredData> {
  String? _scriptId;

  @override
  void initState() {
    super.initState();
    _injectStructuredData();
  }

  @override
  void didUpdateWidget(SeoStructuredData oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapEquals(widget.data, oldWidget.data)) {
      _updateStructuredData();
    }
  }

  @override
  void dispose() {
    _removeStructuredData();
    super.dispose();
  }

  void _injectStructuredData() {
    // Get the SEO tree manager from context
    final seoTree = SeoTree.maybeOf(context);
    if (seoTree == null || !seoTree.isSupported) {
      return;
    }

    // Generate unique ID for this script element
    _scriptId = 'seo-ld-${widget.hashCode}';

    // Convert data to JSON and inject via the tree manager
    final jsonString = jsonEncode(widget.data);
    seoTree.addStructuredData(_scriptId!, jsonString);
  }

  void _updateStructuredData() {
    _removeStructuredData();
    _injectStructuredData();
  }

  void _removeStructuredData() {
    if (_scriptId == null) {
      return;
    }

    final seoTree = SeoTree.maybeOf(context);
    if (seoTree == null || !seoTree.isSupported) {
      return;
    }

    seoTree.removeStructuredData(_scriptId!);
    _scriptId = null;
  }

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    return jsonEncode(a) == jsonEncode(b);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Helper class for building schema.org structured data.
class SeoSchema {
  SeoSchema._();

  /// Creates a Product schema.
  ///
  /// See: https://schema.org/Product
  static Map<String, dynamic> product({
    required String name,
    String? description,
    String? image,
    String? sku,
    String? brand,
    double? price,
    String currency = 'USD',
    SeoAvailability? availability,
    double? rating,
    int? reviewCount,
    String? url,
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'Product',
      'name': name,
      if (description != null) 'description': description,
      if (image != null) 'image': image,
      if (sku != null) 'sku': sku,
      if (brand != null) 'brand': {'@type': 'Brand', 'name': brand},
      if (price != null)
        'offers': {
          '@type': 'Offer',
          'price': price.toString(),
          'priceCurrency': currency,
          if (availability != null) 'availability': availability.schemaUrl,
          if (url != null) 'url': url,
        },
      if (rating != null && reviewCount != null)
        'aggregateRating': {
          '@type': 'AggregateRating',
          'ratingValue': rating.toString(),
          'reviewCount': reviewCount.toString(),
        },
    };
  }

  /// Creates an Article schema.
  ///
  /// See: https://schema.org/Article
  static Map<String, dynamic> article({
    required String headline,
    String? author,
    DateTime? datePublished,
    DateTime? dateModified,
    String? image,
    String? description,
    String? publisher,
    String? publisherLogo,
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'Article',
      'headline': headline,
      if (author != null) 'author': {'@type': 'Person', 'name': author},
      if (datePublished != null) 'datePublished': datePublished.toIso8601String(),
      if (dateModified != null) 'dateModified': dateModified.toIso8601String(),
      if (image != null) 'image': image,
      if (description != null) 'description': description,
      if (publisher != null)
        'publisher': {
          '@type': 'Organization',
          'name': publisher,
          if (publisherLogo != null) 'logo': {'@type': 'ImageObject', 'url': publisherLogo},
        },
    };
  }

  /// Creates a BreadcrumbList schema.
  ///
  /// See: https://schema.org/BreadcrumbList
  static Map<String, dynamic> breadcrumbList({required List<SeoBreadcrumb> items}) {
    return {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      'itemListElement': items.asMap().entries.map((entry) {
        return {
          '@type': 'ListItem',
          'position': entry.key + 1,
          'name': entry.value.name,
          'item': entry.value.url,
        };
      }).toList(),
    };
  }

  /// Creates a FAQPage schema.
  ///
  /// See: https://schema.org/FAQPage
  static Map<String, dynamic> faqPage({required List<SeoFaqItem> questions}) {
    return {
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      'mainEntity': questions.map((q) {
        return {
          '@type': 'Question',
          'name': q.question,
          'acceptedAnswer': {'@type': 'Answer', 'text': q.answer},
        };
      }).toList(),
    };
  }

  /// Creates a LocalBusiness schema.
  ///
  /// See: https://schema.org/LocalBusiness
  static Map<String, dynamic> localBusiness({
    required String name,
    String? description,
    String? image,
    String? telephone,
    String? email,
    String? url,
    SeoAddress? address,
    SeoGeo? geo,
    List<SeoOpeningHours>? openingHours,
    double? rating,
    int? reviewCount,
    String? priceRange,
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      'name': name,
      if (description != null) 'description': description,
      if (image != null) 'image': image,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (url != null) 'url': url,
      if (address != null) 'address': address.toJson(),
      if (geo != null) 'geo': geo.toJson(),
      if (openingHours != null)
        'openingHoursSpecification': openingHours.map((h) => h.toJson()).toList(),
      if (rating != null && reviewCount != null)
        'aggregateRating': {
          '@type': 'AggregateRating',
          'ratingValue': rating.toString(),
          'reviewCount': reviewCount.toString(),
        },
      if (priceRange != null) 'priceRange': priceRange,
    };
  }

  /// Creates an Event schema.
  ///
  /// See: https://schema.org/Event
  static Map<String, dynamic> event({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? image,
    String? location,
    String? url,
    SeoEventStatus status = SeoEventStatus.scheduled,
    SeoEventAttendanceMode attendanceMode = SeoEventAttendanceMode.offline,
    String? organizerName,
    double? price,
    String currency = 'USD',
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'Event',
      'name': name,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (description != null) 'description': description,
      if (image != null) 'image': image,
      if (location != null) 'location': {'@type': 'Place', 'name': location},
      if (url != null) 'url': url,
      'eventStatus': status.schemaUrl,
      'eventAttendanceMode': attendanceMode.schemaUrl,
      if (organizerName != null) 'organizer': {'@type': 'Organization', 'name': organizerName},
      if (price != null)
        'offers': {'@type': 'Offer', 'price': price.toString(), 'priceCurrency': currency},
    };
  }

  /// Creates a WebSite schema with sitelinks search box.
  ///
  /// See: https://schema.org/WebSite
  static Map<String, dynamic> website({
    required String name,
    required String url,
    String? searchUrlTemplate,
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      'name': name,
      'url': url,
      if (searchUrlTemplate != null)
        'potentialAction': {
          '@type': 'SearchAction',
          'target': searchUrlTemplate,
          'query-input': 'required name=search_term_string',
        },
    };
  }

  /// Creates an Organization schema.
  ///
  /// See: https://schema.org/Organization
  static Map<String, dynamic> organization({
    required String name,
    String? url,
    String? logo,
    String? description,
    List<String>? sameAs,
    SeoAddress? address,
    String? telephone,
    String? email,
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'Organization',
      'name': name,
      if (url != null) 'url': url,
      if (logo != null) 'logo': logo,
      if (description != null) 'description': description,
      if (sameAs != null && sameAs.isNotEmpty) 'sameAs': sameAs,
      if (address != null) 'address': address.toJson(),
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
    };
  }
}

/// Product availability for structured data.
enum SeoAvailability { inStock, outOfStock, preOrder, backOrder, discontinued, limitedAvailability }

extension on SeoAvailability {
  String get schemaUrl {
    switch (this) {
      case SeoAvailability.inStock:
        return 'https://schema.org/InStock';
      case SeoAvailability.outOfStock:
        return 'https://schema.org/OutOfStock';
      case SeoAvailability.preOrder:
        return 'https://schema.org/PreOrder';
      case SeoAvailability.backOrder:
        return 'https://schema.org/BackOrder';
      case SeoAvailability.discontinued:
        return 'https://schema.org/Discontinued';
      case SeoAvailability.limitedAvailability:
        return 'https://schema.org/LimitedAvailability';
    }
  }
}

/// Event status for structured data.
enum SeoEventStatus { scheduled, cancelled, movedOnline, postponed, rescheduled }

extension on SeoEventStatus {
  String get schemaUrl {
    switch (this) {
      case SeoEventStatus.scheduled:
        return 'https://schema.org/EventScheduled';
      case SeoEventStatus.cancelled:
        return 'https://schema.org/EventCancelled';
      case SeoEventStatus.movedOnline:
        return 'https://schema.org/EventMovedOnline';
      case SeoEventStatus.postponed:
        return 'https://schema.org/EventPostponed';
      case SeoEventStatus.rescheduled:
        return 'https://schema.org/EventRescheduled';
    }
  }
}

/// Event attendance mode for structured data.
enum SeoEventAttendanceMode { offline, online, mixed }

extension on SeoEventAttendanceMode {
  String get schemaUrl {
    switch (this) {
      case SeoEventAttendanceMode.offline:
        return 'https://schema.org/OfflineEventAttendanceMode';
      case SeoEventAttendanceMode.online:
        return 'https://schema.org/OnlineEventAttendanceMode';
      case SeoEventAttendanceMode.mixed:
        return 'https://schema.org/MixedEventAttendanceMode';
    }
  }
}

/// A breadcrumb item for structured data.
class SeoBreadcrumb {
  const SeoBreadcrumb({required this.name, required this.url});
  final String name;
  final String url;
}

/// An FAQ item for structured data.
class SeoFaqItem {
  const SeoFaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

/// A postal address for structured data.
class SeoAddress {
  const SeoAddress({
    this.streetAddress,
    this.addressLocality,
    this.addressRegion,
    this.postalCode,
    this.addressCountry,
  });

  final String? streetAddress;
  final String? addressLocality;
  final String? addressRegion;
  final String? postalCode;
  final String? addressCountry;

  Map<String, dynamic> toJson() {
    return {
      '@type': 'PostalAddress',
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (addressLocality != null) 'addressLocality': addressLocality,
      if (addressRegion != null) 'addressRegion': addressRegion,
      if (postalCode != null) 'postalCode': postalCode,
      if (addressCountry != null) 'addressCountry': addressCountry,
    };
  }
}

/// Geographic coordinates for structured data.
class SeoGeo {
  const SeoGeo({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return {
      '@type': 'GeoCoordinates',
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
  }
}

/// Opening hours for structured data.
class SeoOpeningHours {
  const SeoOpeningHours({required this.dayOfWeek, required this.opens, required this.closes});

  final List<String> dayOfWeek;
  final String opens;
  final String closes;

  Map<String, dynamic> toJson() {
    return {
      '@type': 'OpeningHoursSpecification',
      'dayOfWeek': dayOfWeek,
      'opens': opens,
      'closes': closes,
    };
  }
}
