/// Data of a test source.
class SourceTestData {
  String sourceKey;

  Duration duration;

  bool isLiveStream;

  SourceTestData({
    required this.sourceKey,
    required this.duration,
    this.isLiveStream = false,
  });

  @override
  String toString() {
    return 'SourceTestData('
        'sourceKey: $sourceKey, '
        'duration: $duration, '
        'isLiveStream: $isLiveStream'
        ')';
  }
}
