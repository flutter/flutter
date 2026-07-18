/// Metadata for OTA Dart isolate snapshot blobs (heap + AOT instructions).
class PatchInfo {
  const PatchInfo({
    required this.patchNumber,
    required this.releaseVersion,
    required this.dataDownloadUrl,
    required this.instrDownloadUrl,
    required this.isolateDataSha256,
    required this.isolateInstrSha256,
    this.isolateDataLengthBytes,
    this.isolateInstrLengthBytes,
    this.enabled = true,
  });

  final int patchNumber;
  final String releaseVersion;
  final String dataDownloadUrl;
  final String instrDownloadUrl;
  final String isolateDataSha256;
  final String isolateInstrSha256;
  final int? isolateDataLengthBytes;
  final int? isolateInstrLengthBytes;
  final bool enabled;

  factory PatchInfo.fromJson(Map<String, dynamic> json) {
    return PatchInfo(
      patchNumber: json['patch_number'] as int,
      releaseVersion: json['release_version'] as String,
      dataDownloadUrl: json['data_download_url'] as String,
      instrDownloadUrl: json['instr_download_url'] as String,
      isolateDataSha256: json['isolate_data_sha256'] as String,
      isolateInstrSha256: json['isolate_instr_sha256'] as String,
      isolateDataLengthBytes: json['isolate_data_length_bytes'] as int?,
      isolateInstrLengthBytes: json['isolate_instr_length_bytes'] as int?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'patch_number': patchNumber,
        'release_version': releaseVersion,
        'data_download_url': dataDownloadUrl,
        'instr_download_url': instrDownloadUrl,
        'isolate_data_sha256': isolateDataSha256,
        'isolate_instr_sha256': isolateInstrSha256,
        if (isolateDataLengthBytes != null)
          'isolate_data_length_bytes': isolateDataLengthBytes,
        if (isolateInstrLengthBytes != null)
          'isolate_instr_length_bytes': isolateInstrLengthBytes,
        'enabled': enabled,
      };
}
