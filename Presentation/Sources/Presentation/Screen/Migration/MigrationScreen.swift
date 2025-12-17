import SwiftUI
import ComposableArchitecture
import Inject
import MigrationCore

struct MigrationScreen: View {
    @Bindable
    var store: StoreOf<MigrationFeature>

    @ObserveInjection
    var inject

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "cylinder.split.1x2")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            VStack(spacing: 16) {
                Text("migration_title")
                    .font(.title)
                    .fontWeight(.bold)

                Text("migration_description")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            migrationContent

            Spacer()
        }
        .padding()
        .onAppear {
            store.send(.screen(.onAppear))
        }
        .alert($store.scope(state: \.completionAlert, action: \.alert))
        .enableInjection()
    }

    @ViewBuilder
    private var migrationContent: some View {
        switch store.migrationState {
        case .idle:
            idleView

        case .checking:
            checkingView

        case .migrating(let progress):
            migratingView(progress: progress)

        case .completed:
            completedView

        case .failed(let error):
            failedView(error: error)
        }
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            if store.bookCount > 0 {
                Text("migration_books_count")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                + Text(" \(store.bookCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 12) {
                Button {
                    store.send(.screen(.skipMigration))
                } label: {
                    Text("migration_skip")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    store.send(.screen(.startMigration))
                } label: {
                    Text("migration_start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
    }

    private var checkingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("migration_checking")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func migratingView(progress: Double) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: progress) {
                Text("migration_progress")
            }
            .progressViewStyle(.linear)

            Text("\(store.migratedCount) / \(store.bookCount)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("migration_completed")
                .font(.headline)
        }
    }

    private func failedView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("migration_failed")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                store.send(.screen(.startMigration))
            } label: {
                Text("migration_retry")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    MigrationScreen(
        store: .init(
            initialState: .init(migrationState: .idle),
            reducer: { MigrationFeature() }
        )
    )
}
