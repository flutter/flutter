# Recipe Changelog

## 31 Oct 2019

* Recipe Link: https://chromium-review.googlesource.com/c/chromium/tools/build/+/1894232
* Reason: Upload `sky_engine` to CIPD.

## 30 Oct 2019

* Recipe Link: https://chromium-review.googlesource.com/c/chromium/tools/build/+/1891522
* Reason: Pass the `out-dir` arg in the recipe.

## 29 Oct 2019

* Recipe Link: https://chromium-review.googlesource.com/c/chromium/tools/build/+/1887742
* Reason: Start uploading Fuchsia debug symbols to CIPD.

## 28 Oct 2019

* Recipe Link: https://chromium-review.googlesource.com/c/chromium/tools/build/+/1885414
* Reason: We were not uploading dart_aot_runner artifacts.

### 23 Oct 2019

* Recipe Link: https://chromium-review.googlesource.com/c/chromium/tools/build/+/1877152
* Reason: Clobber the cache directory after each build to clean-up outdated
    artifacts.

### 23 Oct 2019

* Recipe Link: https://chromium-review.googlesource.com/c/chromium/tools/build/+/1875314
* Reason: Using `unopt` flutter_tester is slower than the optimized alternative.

### 21 Oct 2019

* Recipe Link: https://chromium-review.googlesource.com/c/chromium/tools/build/+/1872832
* Reason: `dart:kernel_compiler` is no longer a valid target after https://github.com/flutter/engine/pull/13158. This change is to account for that.
