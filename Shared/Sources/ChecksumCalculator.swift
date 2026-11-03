import Foundation
import CryptoKit

/// Computes file checksums by streaming the file in chunks, so even very
/// large files don't need to fit in memory at once.
struct ChecksumCalculator {
    enum Algorithm {
        case sha256
        case md5
    }

    private static let bufferSize = 1 << 20 // 1 MB

    func hexDigest(for fileURL: URL, using algorithm: Algorithm) throws -> String {
        guard let stream = InputStream(url: fileURL) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        stream.open()
        defer { stream.close() }

        switch algorithm {
        case .sha256:
            var hasher = SHA256()
            try feed(stream, into: &hasher)
            return hasher.finalize().hexEncodedString
        case .md5:
            var hasher = Insecure.MD5()
            try feed(stream, into: &hasher)
            return hasher.finalize().hexEncodedString
        }
    }

    private func feed<H: HashFunction>(_ stream: InputStream, into hasher: inout H) throws {
        var buffer = [UInt8](repeating: 0, count: Self.bufferSize)
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: buffer.count)
            if bytesRead < 0 {
                throw stream.streamError ?? CocoaError(.fileReadUnknown)
            }
            if bytesRead == 0 { break }
            hasher.update(data: Data(buffer[0..<bytesRead]))
        }
    }
}

private extension Digest {
    var hexEncodedString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
