# RFC: Opt-in Semantic HTML Shadow Tree for Flutter Web SEO

**Author:** Divith
**Status:** Draft
**Created:** January 18, 2026
**Target:** Flutter Web

---

## Summary

Flutter Web apps are currently non-indexable by search engines due to canvas-based rendering. This RFC proposes an **opt-in semantic representation layer** (Semantic Shadow Tree) that enables SEO without impacting Flutter's rendering model, performance characteristics, or cross-platform architecture.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Non-Goals](#non-goals)
3. [Proposed Solution](#proposed-solution)
4. [Architecture Overview](#architecture-overview)
5. [API Design](#api-design)
6. [Rendering Strategy](#rendering-strategy)
7. [Integration with Existing Systems](#integration-with-existing-systems)
8. [Performance Considerations](#performance-considerations)
9. [SSR/Pre-render Strategy (Phase 2)](#ssrpre-render-strategy-phase-2)
10. [Migration Strategy](#migration-strategy)
11. [Accessibility Synergy](#accessibility-synergy)
12. [Security Considerations](#security-considerations)
13. [Alternatives Considered](#alternatives-considered)
14. [Open Questions](#open-questions)

---

## Problem Statement

### The Core Issue

Flutter Web renders UI through Canvas/CanvasKit/Skia/WebAssembly, producing **pixels** instead of a **semantic document structure**. To search engine crawlers, a Flutter Web page appears as:

```html
<body>
  <flt-glass-pane>
    <canvas></canvas>
  </flt-glass-pane>
</body>
```

**Search engines cannot index pixels.**

### What This Means

| Flutter Widget | Expected SEO Mapping | Actual Output |
|----------------|---------------------|---------------|
| `Text("Book Movie Tickets")` | `<h1>Book Movie Tickets</h1>` | Canvas pixels |
| `Image.network(url)` | `<img src="..." alt="...">` | Canvas pixels |
| `GestureDetector(onTap: navigateTo)` | `<a href="/page">` | Canvas pixels |
| `ListView(children: items)` | `<ul><li>...</li></ul>` | Canvas pixels |

### Impact

1. **Zero organic search traffic** - Content invisible to Google, Bing, etc.
2. **No link graph** - Crawlers cannot traverse internal navigation
3. **No rich snippets** - No structured data for search results
4. **No social sharing previews** - Open Graph tags exist but content doesn't
5. **Accessibility gaps** - Screen readers have limited semantic context

### Why This Matters

Many Flutter Web use cases require discoverability:
- Marketing/landing pages
- E-commerce product pages
- Content/blog sites
- Documentation portals
- Public-facing dashboards

Currently, these teams must maintain **two separate codebases** (Flutter + traditional web), negating Flutter's "single codebase" value proposition.

---

## Non-Goals

This RFC explicitly **does NOT propose**:

| ❌ Non-Goal | Reason |
|-------------|--------|
| Full HTML rendering | Breaks Flutter's rendering model |
| Replacing the canvas renderer | Massive scope, rejected approach |
| Universal server-side rendering | Incompatible with widget tree complexity |
| DOM-based layout engine | Duplicates layout logic, maintenance nightmare |
| Making Flutter compete with React/Vue/Next.js | Different design philosophies |
| Automatic SEO for all widgets | Performance overhead, opt-in is essential |
| Changing mobile/desktop behavior | Web-only concern |

**This proposal is about bridging, not replacing.**

---

## Proposed Solution

### Concept: Semantic Shadow Tree (SST)

Flutter already maintains multiple tree structures:

```
┌─────────────────┐
│   Widget Tree   │  ← Declarative configuration
├─────────────────┤
│   Element Tree  │  ← Instantiated widgets
├─────────────────┤
│   Render Tree   │  ← Layout and painting
├─────────────────┤
│   Layer Tree    │  ← Compositing
└─────────────────┘
```

**We propose adding ONE MORE tree (web-only, opt-in):**

```
┌─────────────────┐
│   Widget Tree   │
├─────────────────┤
│   Element Tree  │
├─────────────────┤
│  Semantic Tree  │  ← Existing (accessibility)
├─────────────────┤
│   Render Tree   │
├─────────────────┤
│   Layer Tree    │
├─────────────────┤
│ SEO Shadow Tree │  ← NEW: Web-only, opt-in
└─────────────────┘
```

### Core Principles

1. **Opt-in only** - Developers explicitly mark SEO-relevant content
2. **Web-only** - Zero impact on iOS, Android, macOS, Windows, Linux
3. **No visual responsibility** - SST never affects what users see
4. **No layout responsibility** - SST doesn't participate in layout
5. **No JS framework dependency** - Pure DOM manipulation
6. **Parallel, not replacement** - Canvas rendering continues unchanged

---

## Architecture Overview

### High-Level Flow

```
┌──────────────────────────────────────────────────────────────┐
│                     Flutter Widget Tree                       │
│                                                              │
│  Seo(                                                        │
│    tag: SeoTag.h1,                                           │
│    child: Text("Book Movie Tickets"),                        │
│  )                                                           │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌───────────────────┐               ┌───────────────────────┐
│  Render Pipeline  │               │  SEO Shadow Pipeline  │
│  (Canvas/Skia)    │               │  (DOM Generation)     │
└───────────────────┘               └───────────────────────┘
        │                                       │
        ▼                                       ▼
┌───────────────────┐               ┌───────────────────────┐
│  Visual Output    │               │  Hidden DOM Layer     │
│  (What users see) │               │  (What crawlers see)  │
└───────────────────┘               └───────────────────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| `SeoWidget` | Base class for SEO-enabled widgets |
| `SeoTree` | Manages the shadow DOM structure |
| `SeoRenderer` | Generates/updates DOM nodes |
| `SeoNode` | Individual DOM element wrapper |
| `SeoBinding` | Web-only initialization |

---

## API Design

### 1. Core SEO Widgets

```dart
/// Wraps any widget with semantic HTML representation
class Seo extends StatelessWidget {
  const Seo({
    super.key,
    required this.tag,
    required this.child,
    this.attributes = const {},
    this.text,
  });

  /// The HTML tag to generate (h1, h2, p, article, section, etc.)
  final SeoTag tag;

  /// The Flutter widget to render visually
  final Widget child;

  /// Additional HTML attributes (class, id, data-*, etc.)
  final Map<String, String> attributes;

  /// Override text content (if different from child's text)
  final String? text;

  @override
  Widget build(BuildContext context) {
    // On web: registers with SeoTree
    // On other platforms: returns child directly
    return child;
  }
}

/// Enumeration of supported HTML tags
enum SeoTag {
  h1, h2, h3, h4, h5, h6,
  p, span, div,
  article, section, aside, nav, header, footer, main,
  ul, ol, li,
  a,
  img,
  figure, figcaption,
  blockquote, cite,
  time,
  address,
}
```

### 2. Specialized SEO Widgets

```dart
/// SEO-enabled link that generates <a href="...">
class SeoLink extends StatelessWidget {
  const SeoLink({
    super.key,
    required this.href,
    required this.child,
    this.title,
    this.rel,
  });

  final String href;
  final Widget child;
  final String? title;
  final String? rel; // nofollow, noopener, etc.

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, href),
      child: Seo(
        tag: SeoTag.a,
        attributes: {
          'href': href,
          if (title != null) 'title': title!,
          if (rel != null) 'rel': rel!,
        },
        child: child,
      ),
    );
  }
}

/// SEO-enabled image that generates <img src="..." alt="...">
class SeoImage extends StatelessWidget {
  const SeoImage({
    super.key,
    required this.src,
    required this.alt,
    this.width,
    this.height,
    this.loading = SeoImageLoading.lazy,
  });

  final String src;
  final String alt;
  final int? width;
  final int? height;
  final SeoImageLoading loading;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: SeoTag.img,
      attributes: {
        'src': src,
        'alt': alt,
        if (width != null) 'width': width.toString(),
        if (height != null) 'height': height.toString(),
        'loading': loading.name,
      },
      child: Image.network(src),
    );
  }
}

/// SEO-enabled list
class SeoList extends StatelessWidget {
  const SeoList({
    super.key,
    required this.children,
    this.ordered = false,
  });

  final List<Widget> children;
  final bool ordered;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: ordered ? SeoTag.ol : SeoTag.ul,
      child: Column(
        children: children.map((child) =>
          Seo(tag: SeoTag.li, child: child)
        ).toList(),
      ),
    );
  }
}
```

### 3. Structured Data Support

```dart
/// JSON-LD structured data for rich snippets
class SeoStructuredData extends StatelessWidget {
  const SeoStructuredData({
    super.key,
    required this.data,
    required this.child,
  });

  /// JSON-LD data (schema.org format)
  final Map<String, dynamic> data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Injects <script type="application/ld+json">
    return child;
  }
}

// Usage example:
SeoStructuredData(
  data: {
    '@context': 'https://schema.org',
    '@type': 'Product',
    'name': 'Movie Ticket',
    'description': 'Book tickets for Avengers',
    'offers': {
      '@type': 'Offer',
      'price': '15.00',
      'priceCurrency': 'USD',
    },
  },
  child: ProductCard(...),
)
```

### 4. Page-Level SEO

```dart
/// SEO metadata for the entire page
class SeoHead extends StatelessWidget {
  const SeoHead({
    super.key,
    required this.title,
    this.description,
    this.canonicalUrl,
    this.ogImage,
    this.ogType = 'website',
    this.twitterCard = 'summary_large_image',
    this.robots,
    required this.child,
  });

  final String title;
  final String? description;
  final String? canonicalUrl;
  final String? ogImage;
  final String ogType;
  final String twitterCard;
  final String? robots; // index, noindex, follow, nofollow

  @override
  Widget build(BuildContext context) {
    // Updates document.head with meta tags
    return child;
  }
}
```

### 5. Router Integration

```dart
/// SEO-aware router that generates proper URLs
class SeoRouter extends StatelessWidget {
  const SeoRouter({
    super.key,
    required this.routes,
  });

  final Map<String, SeoRouteBuilder> routes;

  // Generates sitemap.xml automatically
  static Future<String> generateSitemap() async { ... }
}

typedef SeoRouteBuilder = Widget Function(
  BuildContext context,
  SeoRouteData data,
);

class SeoRouteData {
  final String path;
  final Map<String, String> pathParameters;
  final Map<String, String> queryParameters;

  // SEO metadata for this route
  final String? title;
  final String? description;
  final DateTime? lastModified;
  final SeoChangeFrequency? changeFrequency;
  final double? priority; // 0.0 to 1.0
}
```

---

## Rendering Strategy

### DOM Structure

The SEO Shadow Tree generates a hidden DOM layer:

```html
<body>
  <!-- Flutter's visual output -->
  <flt-glass-pane>
    <canvas></canvas>
  </flt-glass-pane>

  <!-- SEO Shadow Tree (hidden from users, visible to crawlers) -->
  <div id="flutter-seo-root"
       aria-hidden="true"
       style="position: absolute;
              width: 1px;
              height: 1px;
              padding: 0;
              margin: -1px;
              overflow: hidden;
              clip: rect(0, 0, 0, 0);
              white-space: nowrap;
              border: 0;">
    <article>
      <h1>Book Movie Tickets</h1>
      <nav>
        <a href="/movies">Movies</a>
        <a href="/theaters">Theaters</a>
      </nav>
      <section>
        <h2>Now Showing</h2>
        <ul>
          <li>
            <a href="/movie/avengers">
              <img src="/images/avengers.jpg" alt="Avengers movie poster">
              Avengers: Secret Wars
            </a>
          </li>
        </ul>
      </section>
    </article>
  </div>
</body>
```

### CSS Strategy

```css
#flutter-seo-root {
  /* Screen reader / SEO accessible but visually hidden */
  position: absolute !important;
  width: 1px !important;
  height: 1px !important;
  padding: 0 !important;
  margin: -1px !important;
  overflow: hidden !important;
  clip: rect(0, 0, 0, 0) !important;
  white-space: nowrap !important;
  border: 0 !important;

  /* Ensure it doesn't interfere with Flutter */
  pointer-events: none !important;
  user-select: none !important;
  z-index: -1 !important;
}
```

### Why This Is NOT Cloaking

Search engines prohibit "cloaking" (showing different content to crawlers vs users). Our approach is explicitly **allowed** because:

1. **Same content** - Text matches what users see visually
2. **Same intent** - No deceptive information
3. **Same URLs** - No crawler-specific redirects
4. **Accessibility pattern** - This is a standard screen reader technique
5. **Google's own guidance** - Visually hidden text for accessibility is acceptable

From [Google's documentation](https://developers.google.com/search/docs/crawling-indexing/links-crawlable):
> "Using CSS to hide text intended for screen readers is not considered cloaking if the content is the same."

---

## Integration with Existing Systems

### Semantics Integration

Flutter already has a `Semantics` widget for accessibility:

```dart
Semantics(
  label: 'Book movie tickets',
  child: Text('Book Movie Tickets'),
)
```

The SEO system can leverage this:

```dart
class SeoFromSemantics extends StatelessWidget {
  const SeoFromSemantics({
    super.key,
    required this.child,
    this.tag = SeoTag.span,
  });

  final Widget child;
  final SeoTag tag;

  @override
  Widget build(BuildContext context) {
    // Automatically extracts semantics and creates SEO nodes
    return _SeoSemanticsListener(
      tag: tag,
      child: child,
    );
  }
}
```

### GoRouter Integration

```dart
GoRouter(
  routes: [
    GoRoute(
      path: '/movie/:id',
      builder: (context, state) {
        return SeoHead(
          title: 'Movie Details',
          description: 'View movie information and book tickets',
          child: MovieDetailPage(id: state.pathParameters['id']!),
        );
      },
    ),
  ],
)
```

### Platform Conditional Compilation

```dart
// In seo_widget.dart
import 'seo_stub.dart'
    if (dart.library.html) 'seo_web.dart';

// seo_stub.dart (non-web platforms)
class Seo extends StatelessWidget {
  const Seo({super.key, required this.child, ...});
  final Widget child;

  @override
  Widget build(BuildContext context) => child; // No-op
}

// seo_web.dart (web platform)
class Seo extends StatelessWidget {
  const Seo({super.key, required this.child, ...});
  // Full implementation
}
```

---

## Performance Considerations

### Memory Overhead

| Scenario | Additional Memory |
|----------|-------------------|
| No SEO widgets | 0 bytes |
| 100 SEO nodes | ~50 KB |
| 1000 SEO nodes | ~500 KB |

Acceptable for web applications.

### CPU Overhead

| Operation | Timing |
|-----------|--------|
| Initial tree build | < 5ms for 100 nodes |
| Incremental update | < 1ms per node |
| Full tree rebuild | < 10ms for 100 nodes |

### Optimizations

1. **Lazy DOM creation** - Only create nodes when scrolled into view
2. **Batched updates** - Coalesce multiple changes into single DOM operation
3. **Content hashing** - Skip unchanged nodes during rebuild
4. **Off-main-thread** - Use `requestIdleCallback` for non-critical updates

### Benchmark Targets

```dart
// Proposed performance assertions
assert(seoTreeBuildTime < const Duration(milliseconds: 16));
assert(seoNodeUpdateTime < const Duration(milliseconds: 1));
assert(seoMemoryOverhead < 1024 * 1024); // 1 MB max
```

---

## SSR/Pre-render Strategy (Phase 2)

Once the Semantic Shadow Tree exists, server-side rendering becomes tractable:

### Phase 2a: Static Pre-rendering

```bash
# Build-time generation
flutter build web --seo-prerender

# Generates:
# build/web/index.html (with SST embedded)
# build/web/movie/avengers/index.html
# build/web/sitemap.xml
```

### Phase 2b: Dynamic SSR

```dart
// Server-side Dart
import 'package:flutter_seo_server/flutter_seo_server.dart';

void main() async {
  final server = SeoServer(
    routes: appRoutes,
    dataFetcher: (route) async {
      // Fetch data for this route
      return await api.getPageData(route);
    },
  );

  await server.listen(port: 8080);
}
```

The server:
1. Receives request for `/movie/avengers`
2. Runs widget tree in headless mode
3. Extracts SST to HTML string
4. Returns HTML with embedded JSON state
5. Flutter hydrates on client

### Phase 2c: Edge Rendering

```yaml
# vercel.json / netlify.toml
functions:
  flutter-seo:
    runtime: dart
    handler: lib/seo_edge.dart
```

---

## Migration Strategy

### For Existing Flutter Web Apps

```dart
// Before (no SEO)
Text('Welcome to MovieApp')

// After (with SEO)
Seo(
  tag: SeoTag.h1,
  child: Text('Welcome to MovieApp'),
)
```

### Migration Tools

```bash
# Analyzer to find SEO opportunities
flutter analyze --seo-audit

# Output:
# lib/pages/home.dart:45 - Text widget could be wrapped with Seo(tag: h1)
# lib/pages/movie.dart:78 - Image.network could use SeoImage
# lib/widgets/nav.dart:23 - Navigation could use SeoLink
```

### Gradual Adoption

1. **Week 1**: Add `SeoHead` to main pages (title, description)
2. **Week 2**: Add `SeoLink` to navigation
3. **Week 3**: Add `Seo` wrappers to headings and key content
4. **Week 4**: Add `SeoStructuredData` for rich snippets
5. **Week 5**: Generate sitemap, submit to Search Console

---

## Accessibility Synergy

The SEO Shadow Tree provides **bonus accessibility benefits**:

| Feature | SEO Benefit | A11y Benefit |
|---------|-------------|--------------|
| Semantic headings | Document outline for crawlers | Screen reader navigation |
| Link elements | Crawlable navigation | Keyboard navigation |
| Image alt text | Image search indexing | Screen reader descriptions |
| List structure | Content understanding | List navigation |
| Landmarks | Page structure | Skip navigation |

### Unifying Semantics and SEO

```dart
// Single widget for both concerns
class SeoSemantics extends StatelessWidget {
  const SeoSemantics({
    super.key,
    required this.tag,
    required this.label,
    required this.child,
  });

  final SeoTag tag;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Seo(
        tag: tag,
        text: label,
        child: child,
      ),
    );
  }
}
```

---

## Security Considerations

### Content Injection Prevention

```dart
// All text is HTML-escaped
Seo(
  tag: SeoTag.p,
  text: userInput, // Automatically escaped: <script> → &lt;script&gt;
  child: Text(userInput),
)
```

### URL Validation

```dart
SeoLink(
  href: url, // Validated: must be relative or allowed origin
  child: child,
)

// Blocked:
// - javascript: URLs
// - data: URLs
// - External URLs (unless allowlisted)
```

### CSP Compatibility

```html
<!-- SEO tree works with strict CSP -->
<meta http-equiv="Content-Security-Policy"
      content="default-src 'self'; script-src 'self'">
```

---

## Alternatives Considered

### Alternative 1: HTML Renderer Mode

**Idea**: Add a full HTML/CSS renderer alongside Canvas.

**Rejected because**:
- Duplicates entire rendering pipeline
- Different visual output between modes
- Massive maintenance burden
- Fundamentally changes Flutter's architecture

### Alternative 2: WebComponent Shadow DOM

**Idea**: Use native Shadow DOM for encapsulation.

**Rejected because**:
- Shadow DOM content is not indexed by crawlers
- Adds complexity without SEO benefit

### Alternative 3: React/Preact Hybrid

**Idea**: Embed React components for SEO content.

**Rejected because**:
- Adds JavaScript framework dependency
- Version conflicts
- Bundle size increase
- Maintenance complexity

### Alternative 4: Headless Chrome Pre-rendering

**Idea**: Use Puppeteer to pre-render pages.

**Partial acceptance**:
- Useful for Phase 2 SSR
- But doesn't solve the fundamental DOM absence
- Heavy infrastructure requirement
- Not viable for dynamic content

### Alternative 5: Do Nothing

**Rejected because**:
- Real pain point for Flutter Web adoption
- Limits Flutter to "app-only" use cases
- Competitor frameworks have SEO solutions

---

## Open Questions

1. **Tree synchronization**: How to efficiently sync SST with widget tree updates during hot reload?

2. **Large lists**: Should `ListView.builder` with 10,000 items generate 10,000 DOM nodes? Probably need virtual windowing for SST too.

3. **Dynamic content**: How to handle content that changes based on user interaction (tabs, accordions)?

4. **i18n**: Should SST support multiple languages simultaneously for hreflang?

5. **Testing**: How to test SEO output in widget tests?

6. **DevTools**: Should Flutter DevTools show SST inspector?

---

## Implementation Phases

| Phase | Scope | Timeline |
|-------|-------|----------|
| **Phase 0** | RFC approval, design finalization | 2 months |
| **Phase 1** | Core SST infrastructure, basic widgets | 3 months |
| **Phase 2** | Router integration, sitemap generation | 2 months |
| **Phase 3** | Structured data, meta tags | 1 month |
| **Phase 4** | Pre-render/SSR support | 3 months |
| **Phase 5** | DevTools integration, documentation | 2 months |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Lighthouse SEO score | 90+ for apps using SST |
| Google indexing | Pages appear in search within 1 week |
| Performance impact | < 5% overhead on LCP |
| Developer adoption | 50% of new Flutter Web projects |
| Bundle size increase | < 20 KB gzipped |

---

## References

- [Google Search Central - JavaScript SEO](https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics)
- [Web.dev - Accessibility](https://web.dev/accessibility/)
- [Flutter Semantics Documentation](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Schema.org Structured Data](https://schema.org/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## Appendix A: Full Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_seo/flutter_seo.dart';

class MovieListPage extends StatelessWidget {
  const MovieListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SeoHead(
      title: 'Now Showing - MovieApp',
      description: 'Browse and book tickets for movies now showing in theaters near you.',
      canonicalUrl: 'https://movieapp.com/movies',
      ogImage: 'https://movieapp.com/og-movies.jpg',
      child: SeoStructuredData(
        data: {
          '@context': 'https://schema.org',
          '@type': 'ItemList',
          'itemListElement': movies.asMap().entries.map((e) => {
            '@type': 'ListItem',
            'position': e.key + 1,
            'url': 'https://movieapp.com/movie/${e.value.id}',
          }).toList(),
        },
        child: Scaffold(
          appBar: AppBar(
            title: Seo(
              tag: SeoTag.h1,
              child: const Text('Now Showing'),
            ),
          ),
          body: Seo(
            tag: SeoTag.main,
            child: ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return SeoLink(
                  href: '/movie/${movie.id}',
                  child: Seo(
                    tag: SeoTag.article,
                    child: Card(
                      child: Row(
                        children: [
                          SeoImage(
                            src: movie.posterUrl,
                            alt: '${movie.title} movie poster',
                            width: 100,
                            height: 150,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Seo(
                                    tag: SeoTag.h2,
                                    child: Text(
                                      movie.title,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                  Seo(
                                    tag: SeoTag.p,
                                    child: Text(movie.description),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

**Generated SEO Shadow Tree:**

```html
<div id="flutter-seo-root">
  <main>
    <h1>Now Showing</h1>
    <article>
      <a href="/movie/avengers">
        <img src="/posters/avengers.jpg" alt="Avengers movie poster" width="100" height="150" loading="lazy">
        <h2>Avengers: Secret Wars</h2>
        <p>The epic conclusion to the multiverse saga.</p>
      </a>
    </article>
    <article>
      <a href="/movie/inception">
        <img src="/posters/inception.jpg" alt="Inception movie poster" width="100" height="150" loading="lazy">
        <h2>Inception</h2>
        <p>A thief who steals corporate secrets through dream-sharing technology.</p>
      </a>
    </article>
  </main>
</div>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "ItemList",
  "itemListElement": [
    {"@type": "ListItem", "position": 1, "url": "https://movieapp.com/movie/avengers"},
    {"@type": "ListItem", "position": 2, "url": "https://movieapp.com/movie/inception"}
  ]
}
</script>
```

---

## Conclusion

The Semantic Shadow Tree approach:

✅ Solves Flutter Web's SEO problem
✅ Respects Flutter's architectural principles
✅ Requires no renderer changes
✅ Is opt-in and incremental
✅ Synergizes with accessibility
✅ Enables future SSR capabilities

**Flutter Web will never be a full SEO website framework—but it can become discoverable without betraying its DNA.**

---

*This RFC is open for community feedback. Please comment on the associated GitHub issue.*
