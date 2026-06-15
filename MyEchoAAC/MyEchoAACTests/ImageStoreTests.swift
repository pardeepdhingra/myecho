import Foundation
import Testing
import UIKit
@testable import MyEchoAAC

struct ImageStoreTests {
    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }

    @Test("save() returns a filename that load() can read back")
    func saveRoundTrips() throws {
        let filename = try ImageStore.save(makeImage())
        #expect(!filename.isEmpty)
        #expect(ImageStore.exists(filename))
        #expect(ImageStore.load(filename) != nil)

        ImageStore.delete(filename)   // cleanup — keep the shared Documents dir tidy
        #expect(!ImageStore.exists(filename))
    }

    @Test("ImageStoreError always carries a user-facing message")
    func errorHasMessage() {
        #expect(ImageStoreError.encodingFailed.errorDescription?.isEmpty == false)
        let wrapped = ImageStoreError.writeFailed(URLError(.cannotCreateFile))
        #expect(wrapped.errorDescription?.isEmpty == false)
    }
}
