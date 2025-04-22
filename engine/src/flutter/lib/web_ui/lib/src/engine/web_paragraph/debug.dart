class WebParagraphDebug {
  static bool logging = false;

  static void log(String arg) {
    if (logging) {
      print(arg);
    }
  }

  static void error(String arg) {
    print('ERROR: $arg');
  }
}
