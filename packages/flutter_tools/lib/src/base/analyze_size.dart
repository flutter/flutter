import '../globals.dart' as globals;

class SizeAnalyzer {
  static const String kAotSizeJson = 'aot-size.json';

  static String getAotSizeAnalysisExtraGenSnapshotOption(String aotOutputPath) {
    return  '--print-instructions-sizes-to=${globals.fs.path.join(aotOutputPath, kAotSizeJson)}';
  }
}