import Foundation

class FileMonitor {
    let url: URL
    let fileHandle: FileHandle
    let source: DispatchSourceFileSystemObject
    let handler: (Data) -> Void

    init(url: URL, handler: @escaping (Data) -> Void) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileHandle.fileDescriptor,
            eventMask: [.write, .extend],
            queue: .main
        )

        self.url = url
        self.fileHandle = fileHandle
        self.source = source
        self.handler = handler

        source.setEventHandler { [weak self] in
            self?.process()
        }
        source.setCancelHandler {
            try? fileHandle.close()
        }

        source.resume()
    }

    deinit {
        source.cancel()
    }

    private func process() {
        guard let data = try? Data(contentsOf: url, options: .uncached) else { return }
        handler(data)
    }
}
