import Foundation
import CryptoKit
import Security
import CommonCrypto

enum SkyflagURLBuilderError: Error {
  case invalidBaseURL
  case encryptFailed(Int32)
}

/// SKYFLAG オファーウォール URL 生成（Swift 側）
/// - userId を AES-256-CBC(PKCS7) で暗号化し `suid` として付与
/// - `isStg` を切替えるだけで STG/PROD のベースURLを変更
final class SkyflagOfferwallURLBuilder {
  /// true: STG (`ow.stg.skyflag.jp`) / false: 本番 (`ow.skyflag.jp`)
  var isStg: Bool

  /// SKYFLAG のメディアID（`_owp`）
  var mediaId: String

  /// suid 暗号化に使う秘密鍵（Dart 側 SKYFLAG_AES_SECRET と同じ値にする）
  var aesSecret: String

  init(isStg: Bool, mediaId: String, aesSecret: String) {
    self.isStg = isStg
    self.mediaId = mediaId
    self.aesSecret = aesSecret
  }

  private var baseURLString: String {
    isStg
      ? "https://ow.stg.skyflag.jp/ad/p/ow/index"
      : "https://ow.skyflag.jp/ad/p/ow/index"
  }

  /// userId を暗号化した suid 付きの OW URL を返す
  func buildURL(
    userId: String,
    spram1: String? = nil,
    spram2: String? = nil
  ) throws -> URL {
    guard var components = URLComponents(string: baseURLString) else {
      throw SkyflagURLBuilderError.invalidBaseURL
    }

    let suid = try Self.encryptSuid(uid: userId, aesSecret: aesSecret)
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "_owp", value: mediaId),
      URLQueryItem(name: "suid", value: suid)
    ]
    if let spram1, !spram1.isEmpty {
      queryItems.append(URLQueryItem(name: "spram1", value: spram1))
    }
    if let spram2, !spram2.isEmpty {
      queryItems.append(URLQueryItem(name: "spram2", value: spram2))
    }
    components.queryItems = queryItems

    guard let url = components.url else {
      throw SkyflagURLBuilderError.invalidBaseURL
    }
    return url
  }

  private static func encryptSuid(uid: String, aesSecret: String) throws -> String {
    let keyData = Data(SHA256.hash(data: Data(aesSecret.utf8))) // 32 bytes
    let iv = randomBytes(count: kCCBlockSizeAES128)
    let plain = Data(uid.utf8)
    let cipher = try aes256CbcPkcs7Encrypt(data: plain, key: keyData, iv: iv)
    let packed = iv + cipher
    return base64UrlNoPadding(packed)
  }

  private static func aes256CbcPkcs7Encrypt(data: Data, key: Data, iv: Data) throws -> Data {
    var outLength = 0
    var out = Data(count: data.count + kCCBlockSizeAES128)

    let status = out.withUnsafeMutableBytes { outBytes in
      data.withUnsafeBytes { dataBytes in
        key.withUnsafeBytes { keyBytes in
          iv.withUnsafeBytes { ivBytes in
            CCCrypt(
              CCOperation(kCCEncrypt),
              CCAlgorithm(kCCAlgorithmAES128),
              CCOptions(kCCOptionPKCS7Padding),
              keyBytes.baseAddress, key.count,
              ivBytes.baseAddress,
              dataBytes.baseAddress, data.count,
              outBytes.baseAddress, out.count,
              &outLength
            )
          }
        }
      }
    }

    guard status == kCCSuccess else {
      throw SkyflagURLBuilderError.encryptFailed(status)
    }
    out.removeSubrange(outLength..<out.count)
    return out
  }

  private static func randomBytes(count: Int) -> Data {
    var data = Data(count: count)
    _ = data.withUnsafeMutableBytes { ptr in
      SecRandomCopyBytes(kSecRandomDefault, count, ptr.baseAddress!)
    }
    return data
  }

  private static func base64UrlNoPadding(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

private func + (lhs: Data, rhs: Data) -> Data {
  var merged = lhs
  merged.append(rhs)
  return merged
}
