import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/data/demos.dart';
import 'package:gallery/main.dart';
import 'package:gallery/pages/demo.dart';
import 'package:gallery/pages/home.dart';
import 'package:gallery/studies/reply/app.dart';
import 'package:gallery/studies/reply/search_page.dart';

void main() {
  testWidgets(
    'State restoration test - Home Page',
    (tester) async {
      await tester.pumpWidget(const GalleryApp());
      // Let the splash page animations complete.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomePage), findsOneWidget);

      // Test state restoration for carousel cards.
      expect(find.byKey(const ValueKey('reply@study')), findsOneWidget);

      // Move two carousel cards over.
      await tester.fling(
        find.byKey(const ValueKey('reply@study')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(const ValueKey('shrine@study')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('rally@study')), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('rally@study')), findsOneWidget);

      // Test state restoration for category list.
      expect(find.byKey(const ValueKey('app-bar@material')), findsNothing);

      // Open material samples list view.
      await tester.tap(find.byKey(
        const PageStorageKey<GalleryDemoCategory>(GalleryDemoCategory.material),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('app-bar@material')), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('app-bar@material')), findsOneWidget);
    },
    variant: const TargetPlatformVariant(
      <TargetPlatform>{TargetPlatform.android},
    ),
  );

  testWidgets(
    'State restoration test -  Gallery Demo',
    (tester) async {
      await tester.pumpWidget(const GalleryApp());
      // Let the splash page animations complete.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomePage), findsOneWidget);

      // Open material samples list view.
      await tester.tap(find.byKey(
        const PageStorageKey<GalleryDemoCategory>(GalleryDemoCategory.material),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('banner@material')));
      await tester.pumpAndSettle();

      // Should be on Material Banner demo page.
      expect(find.byType(GalleryDemoPage), findsOneWidget);
      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GalleryDemoPage), findsOneWidget);

      const bannerDescriptionText = 'A banner displays an important, succinct '
          'message, and provides actions for users to address (or dismiss the '
          'banner). A user action is required for it to be dismissed.';

      expect(find.text(bannerDescriptionText), findsNothing);

      await tester.tap(find.byIcon(Icons.info));
      await tester.pumpAndSettle();
      expect(find.text(bannerDescriptionText), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(bannerDescriptionText), findsOneWidget);
    },
    variant: const TargetPlatformVariant(
      <TargetPlatform>{TargetPlatform.android},
    ),
  );

  testWidgets(
    'State restoration test - Reply Study',
    (tester) async {
      await tester.pumpWidget(const GalleryApp());
      // Let the splash page animations complete.
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reply@study')));
      await tester.pumpAndSettle();

      // Should be on the reply study.
      expect(find.byType(ReplyApp), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));

      // Should still be on the reply study after restoring state.
      expect(find.byType(ReplyApp), findsOneWidget);

      // Should be on the inbox page.
      expect(find.text('Package shipped!'), findsOneWidget);

      // Navigate to the spam page.
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spam'));
      await tester.pumpAndSettle();

      // Should be on the spam page.
      expect(find.text('Free money'), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));

      // Should still be on the spam page after restoring state.
      expect(find.text('Free money'), findsOneWidget);

      await tester.tap(find.text('Free money'));
      await tester.pumpAndSettle();

      // Star an item
      await tester.tap(find.byKey(const ValueKey('star_email_button')));

      // Navigate to starred mailbox
      await tester.tap(find.byKey(const ValueKey('navigation_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Starred'));
      await tester.pumpAndSettle();

      // Recently starred email should be found.
      expect(find.text('Free money'), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));

      // Should still by on the starred email page.
      expect(find.text('Free money'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ReplySearch')));
      await tester.pumpAndSettle();

      // Open search page.
      expect(find.byType(SearchPage), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pump(const Duration(seconds: 1));

      // Should still by on the search page.
      expect(find.byType(SearchPage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ReplyExit')));
      await tester.pumpAndSettle();

      // Should be on the starred email page instead of any other.
      expect(find.text('Free money'), findsOneWidget);
    },
    variant: const TargetPlatformVariant(
      <TargetPlatform>{TargetPlatform.android},
    ),
    skip: true,
    // TODO(x): State restoration test is failing at Inbox tap is failing, but works in App, https://github.com/flutter/gallery/issues/570.
  );
}
