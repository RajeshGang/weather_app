import Foundation

struct Place: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
}

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var places: [Place] = []
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("favorites.json")
    }()

    private let remote = FirestoreFavoritesClient()

    init() {
        Task {
            await loadLocal()                                     // 1) local first
            _ = try? await FirebaseManager.shared.ensureSignedIn()// 2) anon auth
            await syncFromRemote()                                 // 3) merge remote
        }
    }

    // MARK: - Local
    func loadLocal() async {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Place].self, from: data) {
            places = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(places) {
            try? data.write(to: fileURL)
        }
    }

    // MARK: - Remote sync
    func syncFromRemote() async {
        do {
            let remoteList = try await remote.fetchAll()
            let remoteIDs = Set(remoteList.map(\.id))
            let localsOnly = places.filter { !remoteIDs.contains($0.id) }
            places = (remoteList + localsOnly).sorted { $0.name < $1.name }
            persist()
        } catch {
            print("Remote fetch failed:", error.localizedDescription)
        }
    }

    // MARK: - Mutations
    func add(_ p: Place) {
        places.append(p)
        persist()
        Task { try? await remote.add(p) }
    }

    func remove(_ p: Place) {
        places.removeAll { $0.id == p.id }
        persist()
        Task { try? await remote.remove(p) }
    }
}
