//
//  AppDelegate.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/8/25.
//


import UIKit
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Kick off anonymous sign-in right after configure to verify everything works
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Anonymous sign-in error:", error)
            } else {
                print("Anonymous sign-in UID:", result?.user.uid ?? "nil")
            }
        }
        return true
    }
}
