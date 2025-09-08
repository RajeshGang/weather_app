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

    init() { Task { await load() } }

    func load() async {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Place].self, from: data) {
            places = decoded
        }
    }

    func add(_ p: Place) {
        places.append(p)
        persist()
    }

    func remove(_ p: Place) {
        places.removeAll { $0.id == p.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(places) {
            try? data.write(to: fileURL)
        }
    }
}
