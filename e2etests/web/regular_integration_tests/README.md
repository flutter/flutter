```
This directory is for Flutter Web engine integration tests that does not
need a specific configuration. If an e2e test needs specialized app
configuration (e.g. PWA vs non-PWA packaging), please create another
directory under e2etests/web. Otherwise tests such as text_editing, history,
scrolling, pointer events... should all go under this package.

# To run the application under test for traouble shooting purposes.
flutter run -d web-server lib/text_editing_main.dart --local-engine=host_debug_unopt

# To run the Text Editing test and use the developer tools in the browser.
flutter run --target=test_driver/text_editing_e2e.dart -d web-server --web-port=8080 --release --local-engine=host_debug_unopt

# To test the Text Editing test with driver:
flutter drive -v --target=test_driver/text_editing_e2e.dart -d web-server --release --browser-name=chrome --local-engine=host_debug_unopt
```
