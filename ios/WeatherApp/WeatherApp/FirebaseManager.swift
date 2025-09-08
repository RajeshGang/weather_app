//
//  FirebaseManager.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//


import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

final class FirebaseManager {
    static let shared = FirebaseManager()
    let db: Firestore

    private init() {
        if FirebaseApp.app() == nil { FirebaseApp.configure() }

        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true   // offline cache
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }

    /// Ensure a user exists (anonymous auth for now). Returns uid.
    func ensureSignedIn() async throws -> String {
        if let user = Auth.auth().currentUser { return user.uid }
        return try await withCheckedThrowingContinuation { cont in
            Auth.auth().signInAnonymously { result, error in
                if let error = error { cont.resume(throwing: error); return }
                cont.resume(returning: result?.user.uid ?? "")
            }
        }
    }
}
