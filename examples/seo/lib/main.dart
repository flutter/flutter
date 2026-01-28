// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// # Flutter SEO Example
///
/// This example demonstrates how to use the Flutter SEO package to make
/// a Flutter Web application indexable by search engines.
///
/// ## Key Concepts
///
/// 1. **SeoTreeRoot** - Initializes the SEO Shadow Tree at the app root
/// 2. **SeoHead** - Sets page-level metadata (title, description, etc.)
/// 3. **Seo** - Wraps widgets with semantic HTML representation
/// 4. **SeoLink** - Creates crawlable navigation links
/// 5. **SeoImage** - Provides alt text and dimensions for images
/// 6. **SeoStructuredData** - Adds JSON-LD structured data for rich snippets
///
/// ## Usage
///
/// Run this example with:
/// ```
/// flutter run -d chrome
/// ```
///
/// Then inspect the page source to see the generated SEO Shadow Tree.
library flutter_seo_example;

import 'package:flutter/material.dart';
// In real usage: import 'package:flutter/seo.dart';

// ============================================================================
// EXAMPLE: Movie Booking App with Full SEO Support
// ============================================================================

void main() {
  runApp(const MovieApp());
}

/// Root of the movie booking application.
///
/// Note: In production, wrap with SeoTreeRoot:
/// ```dart
/// SeoTreeRoot(
///   sitemapBaseUrl: 'https://movieapp.com',
///   child: MovieApp(),
/// )
/// ```
class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieApp - Book Movie Tickets Online',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // In production, use SeoRouter for URL-based navigation
      home: const MovieListPage(),
    );
  }
}

/// Home page showing list of movies.
///
/// This page demonstrates:
/// - Page-level SEO metadata with SeoHead
/// - Semantic headings with Seo
/// - Crawlable links with SeoLink
/// - Image SEO with SeoImage
/// - Structured data with SeoStructuredData
class MovieListPage extends StatelessWidget {
  const MovieListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // In production, this would be:
    // return SeoHead(
    //   title: 'Now Showing - MovieApp',
    //   description: 'Browse and book tickets for movies now showing...',
    //   canonicalUrl: 'https://movieapp.com/movies',
    //   ogImage: 'https://movieapp.com/og-movies.jpg',
    //   child: SeoStructuredData(
    //     data: SeoSchema.website(...),
    //     child: _buildContent(context),
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // SEO: Main heading wrapped in Seo widget
        // Seo(tag: SeoTag.h1, child: Text('Now Showing'))
        title: const Text('Now Showing'),
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================================================================
          // SECTION: Navigation (would use SeoNav + SeoLink)
          // ================================================================
          _buildNavigation(context),
          const SizedBox(height: 24),

          // ================================================================
          // SECTION: Featured Movie (would use Seo + SeoImage)
          // ================================================================
          _buildFeaturedMovie(context),
          const SizedBox(height: 32),

          // ================================================================
          // SECTION: Movie List (would use SeoList)
          // ================================================================
          _buildSectionHeading(context, 'All Movies'),
          const SizedBox(height: 16),
          _buildMovieGrid(context),
          const SizedBox(height: 32),

          // ================================================================
          // SECTION: FAQ (would use SeoStructuredData with FAQPage schema)
          // ================================================================
          _buildSectionHeading(context, 'Frequently Asked Questions'),
          const SizedBox(height: 16),
          _buildFaq(context),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    // In production:
    // return SeoNav(
    //   label: 'Main navigation',
    //   children: [
    //     SeoLink(href: '/', child: Text('Home')),
    //     SeoLink(href: '/movies', child: Text('Movies')),
    //     SeoLink(href: '/theaters', child: Text('Theaters')),
    //     SeoLink(href: '/about', child: Text('About')),
    //   ],
    // );

    return Wrap(
      spacing: 16,
      children: [
        TextButton(onPressed: () {}, child: const Text('Home')),
        TextButton(onPressed: () {}, child: const Text('Movies')),
        TextButton(onPressed: () {}, child: const Text('Theaters')),
        TextButton(onPressed: () {}, child: const Text('About')),
      ],
    );
  }

  Widget _buildFeaturedMovie(BuildContext context) {
    // In production:
    // return Seo(
    //   tag: SeoTag.article,
    //   child: Card(
    //     child: Row(
    //       children: [
    //         SeoImage.network(
    //           'https://movieapp.com/posters/avengers.jpg',
    //           alt: 'Avengers: Secret Wars movie poster',
    //           width: 200,
    //           height: 300,
    //         ),
    //         Column(
    //           children: [
    //             Seo(tag: SeoTag.h2, child: Text('Avengers: Secret Wars')),
    //             Seo(tag: SeoTag.p, child: Text('The epic conclusion...')),
    //             SeoLink(
    //               href: '/movie/avengers-secret-wars',
    //               child: ElevatedButton(...),
    //             ),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured movie poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 150,
                height: 225,
                color: Colors.grey[300],
                child: const Icon(Icons.movie, size: 64),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Would be: Seo(tag: SeoTag.h2, child: ...)
                  Text(
                    'Avengers: Secret Wars',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Featured',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Would be: Seo(tag: SeoTag.p, child: ...)
                  const Text(
                    'The epic conclusion to the multiverse saga. '
                    'Heroes from across realities unite to face the greatest threat ever.',
                  ),
                  const SizedBox(height: 16),
                  // Would be: SeoLink(href: '/movie/avengers', child: ...)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.confirmation_number),
                    label: const Text('Book Tickets'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeading(BuildContext context, String text) {
    // In production: Seo(tag: SeoTag.h2, child: Text(text))
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  Widget _buildMovieGrid(BuildContext context) {
    final movies = [
      _Movie('Inception', 'A mind-bending thriller about dream infiltration.'),
      _Movie('The Matrix', 'Reality is not what it seems.'),
      _Movie('Interstellar', 'A journey beyond the stars to save humanity.'),
      _Movie('Dune: Part Two', 'The epic saga continues on Arrakis.'),
    ];

    // In production, each card would be:
    // SeoLink(
    //   href: '/movie/${movie.id}',
    //   child: Seo(
    //     tag: SeoTag.article,
    //     child: Card(
    //       child: Column(
    //         children: [
    //           SeoImage(...),
    //           Seo(tag: SeoTag.h3, child: Text(movie.title)),
    //           Seo(tag: SeoTag.p, child: Text(movie.description)),
    //         ],
    //       ),
    //     ),
    //   ),
    // )

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              // Navigate to movie details
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.movie, size: 48),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaq(BuildContext context) {
    // In production:
    // return SeoStructuredData(
    //   data: SeoSchema.faqPage(
    //     questions: [
    //       SeoFaqItem(
    //         question: 'How do I book tickets?',
    //         answer: 'Select a movie, choose your showtime...',
    //       ),
    //       ...
    //     ],
    //   ),
    //   child: Column(children: [...]),
    // );

    final faqs = [
      _Faq(
        'How do I book tickets?',
        'Select a movie, choose your showtime and seats, then complete '
            'payment. You\'ll receive a confirmation email with your tickets.',
      ),
      _Faq(
        'Can I cancel my booking?',
        'Yes, you can cancel up to 2 hours before the showtime for a full '
            'refund. Go to My Bookings and select Cancel.',
      ),
      _Faq(
        'What payment methods do you accept?',
        'We accept all major credit cards, debit cards, PayPal, Apple Pay, '
            'and Google Pay.',
      ),
    ];

    return Column(
      children: faqs.map((faq) {
        return ExpansionTile(
          title: Text(faq.question),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(faq.answer),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _Movie {
  const _Movie(this.title, this.description);
  final String title;
  final String description;
}

class _Faq {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;
}

// ============================================================================
// GENERATED SEO SHADOW TREE (What search engines would see)
// ============================================================================
//
// The above Flutter widgets would generate this hidden HTML structure:
//
// ```html
// <div id="flutter-seo-root" aria-hidden="true">
//   <nav aria-label="Main navigation">
//     <a href="/">Home</a>
//     <a href="/movies">Movies</a>
//     <a href="/theaters">Theaters</a>
//     <a href="/about">About</a>
//   </nav>
//
//   <main>
//     <h1>Now Showing</h1>
//
//     <article>
//       <h2>Avengers: Secret Wars</h2>
//       <img src="/posters/avengers.jpg"
//            alt="Avengers: Secret Wars movie poster"
//            width="200" height="300" loading="eager">
//       <p>The epic conclusion to the multiverse saga...</p>
//       <a href="/movie/avengers-secret-wars">Book Tickets</a>
//     </article>
//
//     <section>
//       <h2>All Movies</h2>
//       <article>
//         <a href="/movie/inception">
//           <img src="/posters/inception.jpg" alt="Inception poster">
//           <h3>Inception</h3>
//           <p>A mind-bending thriller...</p>
//         </a>
//       </article>
//       <!-- More movie articles... -->
//     </section>
//
//     <section>
//       <h2>Frequently Asked Questions</h2>
//       <!-- FAQ content for schema.org FAQPage -->
//     </section>
//   </main>
// </div>
//
// <script type="application/ld+json">
// {
//   "@context": "https://schema.org",
//   "@type": "WebSite",
//   "name": "MovieApp",
//   "url": "https://movieapp.com",
//   "potentialAction": {
//     "@type": "SearchAction",
//     "target": "https://movieapp.com/search?q={search_term_string}",
//     "query-input": "required name=search_term_string"
//   }
// }
// </script>
//
// <script type="application/ld+json">
// {
//   "@context": "https://schema.org",
//   "@type": "FAQPage",
//   "mainEntity": [
//     {
//       "@type": "Question",
//       "name": "How do I book tickets?",
//       "acceptedAnswer": {
//         "@type": "Answer",
//         "text": "Select a movie, choose your showtime..."
//       }
//     }
//   ]
// }
// </script>
// ```
//
// ============================================================================
