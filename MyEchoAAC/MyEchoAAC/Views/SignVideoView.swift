import AVFoundation
import SwiftUI
import UIKit

struct SignVideoView: UIViewRepresentable {
    let url: URL
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    func makeUIView(context: Context) -> SignVideoPlayerView {
        let view = SignVideoPlayerView()
        view.configure(url: url, gravity: videoGravity)
        return view
    }

    func updateUIView(_ uiView: SignVideoPlayerView, context: Context) {
        uiView.configure(url: url, gravity: videoGravity)
    }

    static func dismantleUIView(_ uiView: SignVideoPlayerView, coordinator: ()) {
        uiView.tearDown()
    }
}

final class SignVideoPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    func configure(url: URL, gravity: AVLayerVideoGravity) {
        playerLayer.videoGravity = gravity
        if currentURL == url, player != nil { return }
        tearDown()
        currentURL = url

        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = true
        queue.actionAtItemEnd = .none
        self.player = queue
        self.looper = AVPlayerLooper(player: queue, templateItem: item)
        playerLayer.player = queue
        queue.play()
    }

    func tearDown() {
        player?.pause()
        looper = nil
        player = nil
        playerLayer.player = nil
        currentURL = nil
    }
}
