# WeatherApp (iOS, SwiftUI + Firebase)

An iOS weather app built with SwiftUI and Firebase as part of a mobile development course.  
The app shows real-time weather for the user’s current location and allows saving favorite cities (synced to Firestore).  

---

## Features

- Current Location Weather  
  Uses CoreLocation to fetch GPS coordinates and show live weather.

- Favorites  
  Add cities by name and latitude/longitude. Tap to view that city’s weather.  
  Favorites are stored locally and synced to Firebase Firestore with authentication.

- Switch Between Current Location and Favorites  
  Home screen shows either current location weather or a selected favorite city.  
  Toolbar button allows switching back to "Use My Location."

- 7-Day Forecast  
  Fetches daily highs and lows with weather symbols.

- Modern SwiftUI UI  
  Gradient backgrounds, system weather icons, and cards with material blur.

---

## Screenshots

*(Add screenshots here, e.g., Current Location view, Favorites list, Add Favorite form.)*  

---

## Tech Stack

- Frontend: SwiftUI (iOS 17+)  
- Location: CoreLocation  
- Weather API: [Open-Meteo](https://open-meteo.com/)  
- Backend: Firebase
  - Authentication (anonymous sign-in)
  - Firestore Database (favorites sync)

---

## Setup and Run

1. Clone repository
   ```bash
   git clone https://github.com/<your-username>/weather_app.git
   cd weather_app
Open in Xcode
Open WeatherApp.xcodeproj (or WeatherApp.xcworkspace if using CocoaPods/SPM).
Requires Xcode 15 or newer.
Install Firebase
Integrated via Swift Package Manager.
If missing, add https://github.com/firebase/firebase-ios-sdk under Package Dependencies.
Ensure FirebaseAuth and FirebaseFirestore are added to the WeatherApp target.
Firebase Setup
Create a Firebase project.
Add an iOS app with your bundle ID.
Download GoogleService-Info.plist and add it to the Xcode project.
Firebase is initialized in AppDelegate:
FirebaseApp.configure()
Auth.auth().signInAnonymously()
Firestore Rules
Secure the favorites collection per user:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /favorites/{docId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create, update: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
Run on device
Select iPhone under Product ▸ Destination.
Tap Run.
Grant location permission when prompted.
Usage
On first launch, grant location permission to view current location weather.
In the Favorites tab:
Tap the plus button to add a city (e.g., Tokyo 35.6762, 139.6503).
Tap a row to display that city’s weather in Home.
Swipe to delete entries.
In Home:
Use the toolbar button to return to current location weather.
Pull down to refresh weather.
What I Learned
Setting up an Xcode project with SwiftUI
Using CoreLocation to fetch GPS coordinates
Making asynchronous API calls with Swift async/await
Using Git/GitHub for version control
Integrating Firebase with Swift Package Manager
Implementing Firebase Authentication and Firestore security rules
Debugging Firebase initialization, Firestore indexes, and iOS location permissions
Designing SwiftUI interfaces with cards, gradients, and SF Symbols
Repository Structure
WeatherApp/
 ├── ios/
 │    ├── WeatherApp/          # SwiftUI source
 │    │    ├── HomeView.swift
 │    │    ├── FavoritesView.swift
 │    │    ├── AppSession.swift
 │    │    ├── WeatherService.swift
 │    │    ├── Models/Place.swift
 │    │    └── ...
 │    ├── WeatherApp.xcodeproj
 │    └── GoogleService-Info.plist
 ├── README.md
 └── .gitignore
Acknowledgements
Open-Meteo for the weather API
Firebase for backend services
Apple’s SwiftUI tutorials for UI guidance
