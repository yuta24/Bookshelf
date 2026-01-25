import SwiftUI
import ComposableArchitecture
import Inject
import DataManagementCore
import UniformTypeIdentifiers
import BookModel
import DataClient

struct DataManagementScreen: View {
    @Bindable
    var store: StoreOf<DataManagementFeature>

    @State
    var isExporting: Bool = false
    @State
    var isImporting: Bool = false

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isExporting = true
                    } label: {
                        Label("export_data", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.json == nil)

                    Button {
                        isImporting = true
                    } label: {
                        Label("import_data", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("data_management")
                } footer: {
                    Text("data_management_description")
                }
            }
            .navigationTitle(Text("screen.title.data_management"))
            .fileExporter(
                isPresented: $isExporting,
                document: store.json.map { ExportableDocument(json: $0) },
                contentType: .json,
                onCompletion: { result in
                    switch result {
                    case .success:
                        break
                    case .failure:
                        break
                    }
                }
            )
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                onCompletion: { result in
                    switch result {
                    case let .success(url):
                        store.send(.screen(.imported(url)))
                    case .failure:
                        break
                    }
                }
            )
            .onLoad { store.send(.screen(.onLoad)) }
            .alert($store.scope(state: \.alert, action: \.alert))
            .enableInjection()
        }
    }
}

private struct ExportableDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    var json: String

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw DataError.invalidData
        }

        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw DataError.invalidData
        }
        self.json = jsonString
    }

    init(json: String) {
        self.json = json
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        guard let data = json.data(using: .utf8) else {
            throw DataError.invalidData
        }

        return .init(regularFileWithContents: data)
    }
}
