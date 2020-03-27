```
This directory is for Flutter Web engine integration tests that does not
need a specific configuration. If an e2e test needs specialized app
configuration (e.g. PWA vs non-PWA packaging), please create another
directory under e2etests/web. Otherwise tests such as text_editing, history,
scrolling, pointer events... should all go under this package.

Tests can be run on both 'release' and 'profile' modes. However 'release' mode
will shorten the error. Use 'profile' mode for trouble-shooting purposes where
you can also see the full stack trace.

# To run the application under test for trouble shooting purposes.
flutter run -d web-server lib/text_editing_main.dart --local-engine=host_debug_unopt

# To run the Text Editing test and use the developer tools in the browser.
flutter run --target=test_driver/text_editing_e2e.dart -d web-server --web-port=8080 --profile --local-engine=host_debug_unopt

# To test the Text Editing test with driver you either of the following:
flutter drive -v --target=test_driver/text_editing_e2e.dart -d web-server --profile --browser-name=chrome --local-engine=host_debug_unopt

flutter drive -v --target=test_driver/text_editing_e2e.dart -d web-server --release --browser-name=chrome --local-engine=host_debug_unopt
```
