import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private let groupId = "group.com.sayujsujeev.cooksense"
  private let pendingSharesKey = "pendingRecipeShares"
  private let maxVideoBytes: Int64 = 150 * 1024 * 1024

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    processShare()
  }

  private func processShare() {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
      finish()
      return
    }

    let providers = items.flatMap { $0.attachments ?? [] }
    let message = items.compactMap(\.attributedContentText?.string).first

    if let movieProvider = providers.first(where: {
      $0.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
    }) {
      movieProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) {
        [weak self] url, error in
        guard let self else { return }
        if let url, let copiedPath = self.copyVideoToGroup(url) {
          var payload: [String: Any] = [
            "filePath": copiedPath,
            "mimeType": self.mimeType(for: url),
          ]
          if let message, !message.isEmpty { payload["text"] = message }
          self.save(payload: payload)
        } else {
          var payload: [String: Any] = [
            "error": error?.localizedDescription ?? "CookSense could not read the shared video."
          ]
          if let message, !message.isEmpty { payload["text"] = message }
          self.save(payload: payload)
        }
        self.finish()
      }
      return
    }

    if let urlProvider = providers.first(where: {
      $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }) {
      urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
        guard let self else { return }
        let urlText = (item as? URL)?.absoluteString ?? (item as? NSURL)?.absoluteString
        self.save(payload: ["text": [message, urlText].compactMap { $0 }.joined(separator: "\n")])
        self.finish()
      }
      return
    }

    if let textProvider = providers.first(where: {
      $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
    }) {
      textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
        guard let self else { return }
        self.save(payload: ["text": (item as? String) ?? message ?? ""])
        self.finish()
      }
      return
    }

    if let message, !message.isEmpty { save(payload: ["text": message]) }
    finish()
  }

  private func copyVideoToGroup(_ source: URL) -> String? {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: groupId
    ) else { return nil }
    let directory = container.appendingPathComponent("SharedRecipeVideos", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let size = (try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
    guard size > 0, size <= maxVideoBytes else { return nil }
    let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension
    let destination = directory.appendingPathComponent("\(UUID().uuidString).\(ext)")
    do {
      try FileManager.default.copyItem(at: source, to: destination)
      return destination.path
    } catch {
      return nil
    }
  }

  private func mimeType(for url: URL) -> String {
    guard let type = UTType(filenameExtension: url.pathExtension),
          let mime = type.preferredMIMEType
    else { return "video/mp4" }
    return mime
  }

  private func save(payload: [String: Any]) {
    guard JSONSerialization.isValidJSONObject(payload),
          let defaults = UserDefaults(suiteName: groupId)
    else { return }

    var pending: [[String: Any]] = []
    if let existing = defaults.data(forKey: pendingSharesKey),
       let decoded = try? JSONSerialization.jsonObject(with: existing) as? [[String: Any]] {
      pending = decoded
    }
    pending.append(payload)
    if pending.count > 5 { pending.removeFirst(pending.count - 5) }
    defaults.set(try? JSONSerialization.data(withJSONObject: pending), forKey: pendingSharesKey)
  }

  private func finish() {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      let url = URL(string: "cooksense-share://import")!
      self.extensionContext?.open(url) { _ in
        self.extensionContext?.completeRequest(returningItems: nil)
      }
    }
  }
}
