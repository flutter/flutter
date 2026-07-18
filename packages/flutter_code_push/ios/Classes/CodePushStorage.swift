import CommonCrypto
import Foundation

final class CodePushStorage {
  static let rootDirectoryName = "code_push"
  static let activeDirectoryName = "active"
  static let stagingDirectoryName = "staging"
  static let manifestFileName = "patch_manifest.json"
  static let isolateSnapshotDataFileName = "isolate_snapshot_data"
  static let isolateSnapshotInstrFileName = "isolate_snapshot_instr"

  private let fileManager = FileManager.default

  private var documentsDirectory: URL {
    fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
  }

  private var rootDirectory: URL {
    documentsDirectory.appendingPathComponent(Self.rootDirectoryName, isDirectory: true)
  }

  private var activeDirectory: URL {
    rootDirectory.appendingPathComponent(Self.activeDirectoryName, isDirectory: true)
  }

  private var stagingDirectory: URL {
    rootDirectory.appendingPathComponent(Self.stagingDirectoryName, isDirectory: true)
  }

  func readCurrentPatchNumber() throws -> Int? {
    let manifestURL = activeDirectory.appendingPathComponent(Self.manifestFileName)
    guard fileManager.fileExists(atPath: manifestURL.path) else {
      return nil
    }
    let data = try Data(contentsOf: manifestURL)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    return json?["patch_number"] as? Int
  }

  func stagePatchFromUrls(
    patchNumber: Int,
    releaseVersion: String,
    dataDownloadURL: String,
    instrDownloadURL: String,
    dataSha256: String,
    instrSha256: String,
    dataLengthBytes: Int?,
    instrLengthBytes: Int?,
    enabled: Bool
  ) throws {
    try ensureDirectory(stagingDirectory)
    try removeDirectoryContents(stagingDirectory)

    let dataURL = stagingDirectory.appendingPathComponent(Self.isolateSnapshotDataFileName)
    let instrURL = stagingDirectory.appendingPathComponent(Self.isolateSnapshotInstrFileName)
    try downloadAndVerify(
      urlString: dataDownloadURL,
      destination: dataURL,
      expectedSha256: dataSha256,
      expectedLengthBytes: dataLengthBytes
    )
    try downloadAndVerify(
      urlString: instrDownloadURL,
      destination: instrURL,
      expectedSha256: instrSha256,
      expectedLengthBytes: instrLengthBytes
    )

    let manifest: [String: Any] = [
      "patch_number": patchNumber,
      "release_version": releaseVersion,
      "isolate_data_sha256": dataSha256.lowercased(),
      "isolate_instr_sha256": instrSha256.lowercased(),
      "isolate_data_length_bytes": try fileSize(dataURL),
      "isolate_instr_length_bytes": try fileSize(instrURL),
      "enabled": enabled,
    ]
    let manifestData = try JSONSerialization.data(withJSONObject: manifest)
    try manifestData.write(to: stagingDirectory.appendingPathComponent(Self.manifestFileName))
  }

  func applyStagedPatch() throws {
    let stagedData = stagingDirectory.appendingPathComponent(Self.isolateSnapshotDataFileName)
    let stagedInstr = stagingDirectory.appendingPathComponent(Self.isolateSnapshotInstrFileName)
    let stagedManifest = stagingDirectory.appendingPathComponent(Self.manifestFileName)
    guard fileManager.fileExists(atPath: stagedData.path),
      fileManager.fileExists(atPath: stagedInstr.path),
      fileManager.fileExists(atPath: stagedManifest.path)
    else {
      throw NSError(
        domain: "CodePushStorage",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No staged code push patch is available."]
      )
    }

    try ensureDirectory(activeDirectory)
    try removeDirectoryContents(activeDirectory)

    try fileManager.copyItem(at: stagedData, to: activeDirectory.appendingPathComponent(Self.isolateSnapshotDataFileName))
    try fileManager.copyItem(at: stagedInstr, to: activeDirectory.appendingPathComponent(Self.isolateSnapshotInstrFileName))
    try fileManager.copyItem(at: stagedManifest, to: activeDirectory.appendingPathComponent(Self.manifestFileName))
    try removeDirectoryContents(stagingDirectory)
  }

  func clearActivePatch() throws {
    try removeDirectoryContents(activeDirectory)
    try removeDirectoryContents(stagingDirectory)
  }

  private func downloadAndVerify(
    urlString: String,
    destination: URL,
    expectedSha256: String,
    expectedLengthBytes: Int?
  ) throws {
    guard let url = URL(string: urlString) else {
      throw NSError(
        domain: "CodePushStorage",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Invalid download URL."]
      )
    }

    var request = URLRequest(url: url)
    request.timeoutInterval = 300
    let (tempURL, response) = try URLSession.shared.download(for: request)
    defer { try? fileManager.removeItem(at: tempURL) }

    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
      throw NSError(
        domain: "CodePushStorage",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "Patch download failed with HTTP \(httpResponse.statusCode)"]
      )
    }

    if fileManager.fileExists(atPath: destination.path) {
      try fileManager.removeItem(at: destination)
    }
    try fileManager.moveItem(at: tempURL, to: destination)

    let actualLength = try fileSize(destination)
    if let expectedLengthBytes, actualLength != expectedLengthBytes {
      try fileManager.removeItem(at: destination)
      throw NSError(
        domain: "CodePushStorage",
        code: 4,
        userInfo: [NSLocalizedDescriptionKey: "Patch size mismatch."]
      )
    }

    let actualSha256 = try sha256Hex(of: destination)
    if actualSha256.caseInsensitiveCompare(expectedSha256) != .orderedSame {
      try fileManager.removeItem(at: destination)
      throw NSError(
        domain: "CodePushStorage",
        code: 5,
        userInfo: [NSLocalizedDescriptionKey: "Patch SHA-256 mismatch."]
      )
    }
  }

  private func sha256Hex(of fileURL: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: fileURL)
    defer { try? handle.close() }

    var context = CC_SHA256_CTX()
    CC_SHA256_Init(&context)

    while true {
      let chunk = try handle.read(upToCount: 8192) ?? Data()
      if chunk.isEmpty {
        break
      }
      chunk.withUnsafeBytes { buffer in
        _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(chunk.count))
      }
    }

    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256_Final(&digest, &context)
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private func fileSize(_ url: URL) throws -> Int {
    let attributes = try fileManager.attributesOfItem(atPath: url.path)
    return attributes[.size] as? Int ?? 0
  }

  private func ensureDirectory(_ url: URL) throws {
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
  }

  private func removeDirectoryContents(_ directory: URL) throws {
    guard fileManager.fileExists(atPath: directory.path) else {
      return
    }
    let children = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    for child in children {
      try fileManager.removeItem(at: child)
    }
  }
}
