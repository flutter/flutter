## 2.11.3
Check for CHROME_PATH env variable in devtools_shared [#3805](https://github.com/flutter/devtools/pull/3805)

## 2.11.1
- Update CLI test driver with the correct Dart VM Service prefix
## 2.11.0
- Create `devtools_test_utils.dart`, which exposes shared test infrastructure.  
## 2.3.0
- Migrate to null safety.
## 0.2.3
- Coordinated release with DevTools 0.2.3.
## 0.2.2
- Simplified devtools_api.dart.
## 0.2.1
- Added devtools_api.dart to devtools_shared.
## 0.2.0
- Added field to Memory JSON file "dartDevToolsScreen": "memory".
## 0.1.0
- Updated MemoryJson to expose header and footer parts of the JSON file. The data portion is still the persisted List<HeapSample>.  Exposed encodeHeapSample (to add a single HeapSample) and encodeAnotherHeapSample (when adding more than one to the list - comma is added).
## 0.0.1
- initial release
