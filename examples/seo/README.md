# Flutter SEO Example

This example demonstrates how to make a Flutter Web application indexable by search engines using the proposed Semantic Shadow Tree (SST) solution.

## Problem

Flutter Web renders to `<canvas>` elements, which search engine crawlers cannot index:

```html
<!-- What search engines see today -->
<body>
  <canvas></canvas>
</body>
```

## Solution

The SEO package generates a hidden semantic HTML shadow tree alongside the canvas:

```html
<!-- What search engines will see -->
<body>
  <canvas></canvas>

  <!-- Hidden from users, visible to crawlers -->
  <div id="flutter-seo-root" aria-hidden="true" style="position:absolute;...">
    <nav>
      <a href="/movies">Movies</a>
      <a href="/theaters">Theaters</a>
    </nav>
    <main>
      <h1>Now Showing</h1>
      <article>
        <h2>Avengers: Secret Wars</h2>
        <p>The epic conclusion...</p>
        <a href="/movie/avengers">Book Tickets</a>
      </article>
    </main>
  </div>
</body>
```

## Running the Example

```bash
cd examples/seo
flutter run -d chrome
```

Then use browser DevTools to inspect the generated shadow DOM.

## Key Widgets

| Widget | Purpose |
|--------|---------|
| `SeoTreeRoot` | Initializes the SEO system at app root |
| `SeoHead` | Page-level meta tags (title, description, OG) |
| `Seo` | Wraps any widget with semantic HTML tag |
| `SeoText` | Shorthand for text with semantic tag |
| `SeoLink` | Crawlable navigation links |
| `SeoImage` | Images with alt text and dimensions |
| `SeoList` | Ordered/unordered lists |
| `SeoNav` | Navigation landmark |
| `SeoBreadcrumbs` | Breadcrumb navigation |
| `SeoStructuredData` | JSON-LD schema.org data |
| `SeoRouter` | SEO-aware routing with sitemap |

## Example Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter/seo.dart';

void main() {
  runApp(
    SeoTreeRoot(
      sitemapBaseUrl: 'https://movieapp.com',
      child: MovieApp(),
    ),
  );
}

class MoviePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SeoHead(
      title: 'Avengers: Secret Wars - MovieApp',
      description: 'Book tickets for Avengers: Secret Wars...',
      canonicalUrl: 'https://movieapp.com/movie/avengers',
      ogImage: 'https://movieapp.com/posters/avengers.jpg',
      child: SeoStructuredData(
        data: SeoSchema.product(
          name: 'Movie Ticket: Avengers',
          description: 'Admission ticket...',
          price: 15.99,
          currency: 'USD',
          availability: 'InStock',
        ),
        child: Scaffold(
          body: Column(
            children: [
              Seo(
                tag: SeoTag.h1,
                child: Text('Avengers: Secret Wars'),
              ),
              SeoImage.network(
                'https://movieapp.com/posters/avengers.jpg',
                alt: 'Movie poster',
                width: 300,
                height: 450,
              ),
              Seo(
                tag: SeoTag.p,
                child: Text('The epic conclusion...'),
              ),
              SeoLink(
                href: '/checkout',
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/checkout'),
                  child: Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Structured Data Examples

### FAQ Schema
```dart
SeoStructuredData(
  data: SeoSchema.faqPage(
    questions: [
      SeoFaqItem(
        question: 'How do I cancel?',
        answer: 'Go to My Bookings...',
      ),
    ],
  ),
  child: FaqWidget(),
)
```

### Product Schema
```dart
SeoStructuredData(
  data: SeoSchema.product(
    name: 'Movie Ticket',
    price: 15.99,
    currency: 'USD',
    availability: 'InStock',
    ratingValue: 4.8,
    reviewCount: 1250,
  ),
  child: TicketWidget(),
)
```

### Article Schema
```dart
SeoStructuredData(
  data: SeoSchema.article(
    headline: 'New Releases This Week',
    author: 'MovieApp Editorial',
    datePublished: DateTime(2025, 1, 15),
    image: 'https://movieapp.com/blog/releases.jpg',
  ),
  child: ArticleWidget(),
)
```

## Sitemap Generation

The `SeoRouter` automatically generates:

- **sitemap.xml**: List of all SEO routes with priorities and change frequencies
- **robots.txt**: Bot directives with sitemap location

```dart
SeoRouter(
  routes: [
    SeoRoute(
      path: '/',
      priority: 1.0,
      changeFrequency: SeoChangeFrequency.daily,
      builder: (context) => HomePage(),
    ),
    SeoRoute(
      path: '/movie/:id',
      priority: 0.8,
      builder: (context) => MoviePage(),
    ),
  ],
)
```

## Pre-rendering Support

For SSR/pre-rendering, use:

```bash
flutter build web --seo-prerender
```

This generates static HTML files with the SEO content for each route:

```
build/web/
├── index.html          # With inline SEO shadow tree
├── movies/
│   └── index.html
├── movie/
│   └── avengers/
│       └── index.html
├── sitemap.xml
└── robots.txt
```

## Testing SEO

Use these tools to validate your SEO implementation:

1. **Google Rich Results Test**: https://search.google.com/test/rich-results
2. **Schema.org Validator**: https://validator.schema.org
3. **Google Search Console**: Submit sitemap and monitor indexing
4. **Lighthouse SEO Audit**: Built into Chrome DevTools

## Limitations

- SEO widgets only generate output on web platform
- No impact on visual rendering (by design)
- Requires explicit opt-in for each SEO element
- Pre-rendering requires server-side infrastructure

## References

- [RFC: Semantic Shadow Tree for Flutter Web SEO](../../docs/contributing/design-documents/RFC-Semantic-Shadow-Tree-SEO.md)
- [schema.org](https://schema.org)
- [Google SEO Guidelines](https://developers.google.com/search/docs)
