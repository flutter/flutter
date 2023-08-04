# Impeller Benchmarks

Here are some noteworthy benchmarks related to Impeller performance:

- **New Gallery** - Runs through the Flutter Gallery with a driver test.
  - Samsung S10
    - Vulkan: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=X8f96868d3a9eeb120bec1f458c577c30)
    - OpenGLES: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=Xeb13bfef4ef2947f899646422bbad8c6)
    - Vulkan vs OpenGLES - average rasterizer time: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=Xdfca283b38a86fc09129141792cf5a4b)
    - Skia vs Vulkan Impeller - 90th percentile frame rasterizer time: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=X2cacf305c9d4b1b5fc43f81368803a9b)
  - Moto G4 (OpenGLES): [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=Xaeae5aa39c9028be43e8a9ad40540bd8)
  - iPhone 11
    - Metal: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=Xc30b4774a54a03180fa93bf6641c5469)
    - Skia vs Metal Impeller - 90th percentile frame rasterizer time: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=X836c18b955eb83a9102a4391672f37e0)

- **Animated Blur Backdrop Filter** - A driver test that scrolls to a screen and
  animates a Blur Backdrop filter to get progressively blurrier.  This covers a
  gap in the "New Gallery" tests we've seen in places like Wonderous.
  - Samsung S10
    - Vulkan: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=X71aab43432178775be19fe133cdb5528)
    - OpenGLES: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=X8024e2cd402a6afcefdb18aaabc9533a)
    - Vulkan vs OpenGLES - Average rasterizer time: [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=Xb1c6d1bb2e43c633bc3e1aa896cf5b08)
  - Moto G4 (OpenGLES): [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=X78023772ea9e94c81f37456a7fa7bf46)
  - iPhone 11 (Metal): [skiaperf](https://flutter-flutter-perf.skia.org/e/?keys=X2f7504aba3db6aeff08cc896081ace55)
