class WebParagraphDebug {
  static const bool logging = true;

  static void log(String arg) {
    if (logging) {
      print(arg);
    }
  }

  static void error(String arg) {
    print(arg);
  }
}
