import Foundation

class DataLoader: NSObject {
    class Handler {
        let completion: (Result<(Data, URLResponse), Error>) -> Void
        var data: Data

        init(completion: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
            self.completion = completion
            self.data = .init()
        }
    }

    private var handlers: [Int: Handler] = [:]

    func load(_ request: URLRequest, using session: URLSession, completion: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        let task = session.dataTask(with: request)
        handlers[task.taskIdentifier] = .init(completion: completion)
        task.resume()
    }

    private func onDidReceive(_ task: URLSessionTask, with data: Data) {
        handlers[task.taskIdentifier]?.data.append(data)
    }

    private func onDidComplete(_ task: URLSessionTask, with error: Error?) {
        guard let handler = handlers[task.taskIdentifier] else { return }
        handlers.removeValue(forKey: task.taskIdentifier)
        if let response = task.response, error == nil {
            handler.completion(.success((handler.data, response)))
        } else {
            handler.completion(.failure(error ?? URLError(.unknown)))
        }
    }
}

extension DataLoader: URLSessionDataDelegate {
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onDidComplete(task, with: error)
    }

    func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        onDidReceive(dataTask, with: data)
    }
}
