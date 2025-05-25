//
//  photouplaodreview.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/26/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LandingView: View {
    @State private var isLoggedIn: Bool? = nil
    @State private var hasCompletedProfile: Bool = UserDefaults.standard.bool(forKey: "hasCompletedProfile")
    @State private var profileStep: Int = UserDefaults.standard.integer(forKey: "profileStep")

    var body: some View {
        VStack {
            if isLoggedIn == nil {
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .padding()
                    Text("Checking your profile setup...")
                        .foregroundColor(.pink)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.edgesIgnoringSafeArea(.all))
            } else if isLoggedIn == true {
                if hasCompletedProfile {
                    ContentView(isLoggedIn: Binding(get: { isLoggedIn ?? false }, set: { isLoggedIn = $0 }))
                } else {
                    ProfileCreationView(isLoggedIn: Binding(get: { isLoggedIn ?? false }, set: { isLoggedIn = $0 }), step: $profileStep)
                }
            } else {
                SignInView(isLoggedIn: Binding(get: { isLoggedIn ?? false }, set: { isLoggedIn = $0 }))
            }
        }
        .onAppear { setupRealtimeListener() }
        .onChange(of: isLoggedIn) { _, newValue in
            print("🔍 LandingView - isLoggedIn changed to: \(String(describing: newValue)), hasCompletedProfile: \(hasCompletedProfile)")
        }
    }

    private func setupRealtimeListener() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("🔍 No user logged in")
            isLoggedIn = false
            return
        }

        let db = Firestore.firestore().collection("users").document(userID)

        db.addSnapshotListener { document, error in
            if let error = error {
                print("❌ Listener error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.isLoggedIn = false }
                return
            }

            let data = document?.data() ?? [:]
            print("🔍 Real-Time Firestore Data: \(data)")

            DispatchQueue.main.async {
                self.isLoggedIn = true

                let firestoreProfileStep = data["profileStep"] as? Int ?? 2
                let storedProfileStep = UserDefaults.standard.integer(forKey: "profileStep")

                let firestoreHasCompleted = data["hasCompletedProfile"] as? Bool ?? false
                let storedHasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedProfile")

                // ✅ Fix: **Update only when there's an actual change**
                if self.profileStep != firestoreProfileStep {
                    self.profileStep = firestoreProfileStep
                    UserDefaults.standard.set(firestoreProfileStep, forKey: "profileStep")
                    print("📌 Updated profileStep: \(firestoreProfileStep)")
                }

                if self.hasCompletedProfile != firestoreHasCompleted {
                    self.hasCompletedProfile = firestoreHasCompleted
                    UserDefaults.standard.set(firestoreHasCompleted, forKey: "hasCompletedProfile")
                    print("📌 Updated hasCompletedProfile: \(firestoreHasCompleted)")
                }
            }
        }
    }
}
