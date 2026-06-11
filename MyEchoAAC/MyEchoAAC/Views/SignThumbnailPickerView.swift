import SwiftUI
import AVFoundation

/// Lets a parent scrub through a sign video and pick a still frame as the tile thumbnail.
/// The extracted frame is saved via ImageStore and the path is returned via `onSave`.
struct SignThumbnailPickerView: View {
    let videoPath: String
    let currentThumbnailPath: String?
    let onSave: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var seekTime: Double = 0
    @State private var duration: Double = 1
    @State private var previewImage: UIImage?
    @State private var isBusy = false

    private var videoURL: URL { SignVideoStore.fileURL(for: videoPath) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                framePreview
                    .frame(maxWidth: .infinity)
                    .background(Color.black)

                scrubberArea
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                Divider()
                actionButtons
                    .padding(16)
            }
            .navigationTitle("Choose Thumbnail Frame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadDurationAndInitialFrame() }
        }
    }

    // MARK: - Frame preview

    private var framePreview: some View {
        Group {
            if let img = previewImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
            } else {
                ZStack {
                    Color.black
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                .frame(height: 280)
            }
        }
    }

    // MARK: - Scrubber

    private var scrubberArea: some View {
        VStack(spacing: 12) {
            Slider(value: $seekTime, in: 0...max(duration, 0.01)) { editing in
                if !editing { extractFrame(at: seekTime) }
            }
            .tint(.indigo)

            HStack {
                Text(formatTime(seekTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatTime(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                saveCurrentFrame()
            } label: {
                Label("Use this frame as thumbnail", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(previewImage == nil || isBusy)

            if currentThumbnailPath != nil {
                Button(role: .destructive) {
                    if let old = currentThumbnailPath { ImageStore.delete(old) }
                    onSave(nil)
                    dismiss()
                } label: {
                    Label("Remove thumbnail", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - AVFoundation helpers

    private func loadDurationAndInitialFrame() {
        let asset = AVURLAsset(url: videoURL)
        Task {
            if let track = try? await asset.loadTracks(withMediaType: .video).first,
               let naturalSize = try? await track.load(.naturalSize),
               naturalSize != .zero {
                let dur = try? await asset.load(.duration)
                let seconds = dur.map { CMTimeGetSeconds($0) } ?? 1
                await MainActor.run {
                    duration = max(seconds, 0.01)
                }
            }
            extractFrame(at: 0)
        }
    }

    private func extractFrame(at seconds: Double) {
        isBusy = true
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 640)

        let time = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        generator.generateCGImageAsynchronously(for: time) { cgImage, _, _ in
            DispatchQueue.main.async {
                if let cg = cgImage {
                    previewImage = UIImage(cgImage: cg)
                }
                isBusy = false
            }
        }
    }

    private func saveCurrentFrame() {
        guard let img = previewImage else { return }
        if let old = currentThumbnailPath { ImageStore.delete(old) }
        let path = ImageStore.save(img)
        onSave(path)
        dismiss()
    }

    private func formatTime(_ t: Double) -> String {
        let secs = Int(t)
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }
}
