//
//  FirestoreFavoritesClient.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/8/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct PlaceDTO: Codable {
    let id: String
    let userId: String
    let name: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date
}

final class FirestoreFavoritesClient {
    private let db = FirebaseManager.shared.db
    private var uid: String { Auth.auth().currentUser?.uid ?? "anon" }
    private var col: CollectionReference { db.collection("favorites") }

    func fetchAll() async throws -> [Place] {
        let snap = try await col
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt")
            .getDocuments()

        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard
                let idStr = data["id"] as? String,
                let name = data["name"] as? String,
                let lat  = data["latitude"] as? Double,
                let lon  = data["longitude"] as? Double
            else { return nil }

            return Place(
                id: UUID(uuidString: idStr) ?? UUID(),
                name: name,
                latitude: lat,
                longitude: lon
            )
        }
    }

    func add(_ p: Place) async throws {
        let dto: [String: Any] = [
            "id": p.id.uuidString,
            "userId": uid,
            "name": p.name,
            "latitude": p.latitude,
            "longitude": p.longitude,
            "createdAt": Timestamp(date: Date())
        ]
        try await col.document(p.id.uuidString).setData(dto, merge: true)
    }

    func remove(_ p: Place) async throws {
        try await col.document(p.id.uuidString).delete()
    }
}

