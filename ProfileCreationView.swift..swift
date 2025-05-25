//
//  ProfileCreationView.swift..swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/3/25.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileCreationView: View {
    @Binding var isLoggedIn: Bool
    @Binding var step: Int

    @State private var name: String = ""
    @State private var birthMonth: String = ""
    @State private var birthDay: String = ""
    @State private var birthYear: String = ""
    @State private var snapchat: String = ""
    @State private var instagram: String = ""
    @State private var selectedColleges: [String] = []
    @State private var selectedMode: String = ""
    @State private var personalityTraits: [String] = []
    @State private var interests: [String] = []
    @State private var profilePhotos: [UIImage?] = Array(repeating: nil, count: 4)
    @State private var uploadedImageURLs: [String] = Array(repeating: "", count: 4)
    @State private var selectedPhotoIndex: Int? = nil
    @State private var imagePickerPresented = false

    @State private var isLoading = true
    @State private var hasMarkedProfileAsComplete = false

    @AppStorage("hasUploadedPhotos") private var hasUploadedPhotos: Bool = false
    @AppStorage("hasPromptedForNotifications") private var hasPromptedForNotifications: Bool = false
    @State private var showNotificationPrompt: Bool = false

    let allTraits = ["Tidy", "Messy", "Introvert", "Extrovert", "Night Owl", "Morning Person"]
    let allInterests = ["🎨 Art", "🎧 Music", "🏋 Fitness", "🍕 Foodie", "✈️ Travel", "Greek Life"]

    var body: some View {
        ZStack {
            if isLoading {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .scaleEffect(1.5)
                    Text("Loading your profile...")
                        .foregroundColor(.white)
                        .padding()
                }
            } else {
                VStack {
                    if step == 1 {
                        WelcomeView(step: $step)
                    } else if step == 2 {
                        BasicInfoView(step: $step, name: $name, birthMonth: $birthMonth, birthDay: $birthDay, birthYear: $birthYear) {
                            saveUserProfile()
                        }
                    } else if step == 3 {
                        CollegeSelectionView(step: $step, selectedColleges: $selectedColleges, isLoggedIn: $isLoggedIn) {
                            saveUserProfile()
                        }
                    } else if step == 4 {
                        ModeSelectionView(step: $step, selectedMode: $selectedMode) {
                            saveUserProfile()
                        }
                    } else if step == 5 {
                        PersonalitySelectionView(step: $step, personalityTraits: $personalityTraits, allTraits: allTraits) {
                            saveUserProfile()
                        }
                    } else if step == 6 {
                        InterestSelectionView(step: $step, interests: $interests, allInterests: allInterests) {
                            saveUserProfile()
                        }
                    } else if step == 7 {
                        ProfilePhotoUploadView(
                            step: $step,
                            profilePhotos: $profilePhotos,
                            uploadedImageURLs: $uploadedImageURLs,
                            imagePickerPresented: $imagePickerPresented,
                            selectedPhotoIndex: $selectedPhotoIndex,
                            isLoggedIn: $isLoggedIn
                        ) { updatedURLs in
                            saveUserProfileWithImages(updatedURLs)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                updateFirestoreToStepEight()
                                self.step = 8
                                NotificationCenter.default.post(name: NSNotification.Name("StepEightReached"), object: nil)
                            }
                        }
                        .onAppear {
                            if !hasMarkedProfileAsComplete {
                                markProfileAsComplete()
                            }
                        }
                    } else if step == 8 {
                        TabView {
                            SwipeCardStackView(isLoggedIn: $isLoggedIn)
                                .tabItem { Label("Home", systemImage: "house.fill") }
                            MatchesView()
                                .tabItem { Label("Matches", systemImage: "heart.fill") }
                            SettingsView(isLoggedIn: $isLoggedIn)
                                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                        }
                        .accentColor(.pink)
                        .onAppear {
                            print("🎯 Step 8 TabView appeared")
                            UserDefaults.standard.set(true, forKey: "hasCompletedProfile")
                            UserDefaults.standard.set(true, forKey: "hasUploadedPhotos")
                            UserDefaults.standard.set(8, forKey: "profileStep")

                            NotificationCenter.default.post(name: NSNotification.Name("StepEightReached"), object: nil)
                            UITabBar.appearance().isHidden = false

                            let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedProfile")
                            if !hasPromptedForNotifications && hasCompleted {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showNotificationPrompt = true
                                }
                            }
                        }
                        .sheet(isPresented: $showNotificationPrompt, onDismiss: {
                            hasPromptedForNotifications = true
                        }) {
                            NotificationPermissionView()
                        }
                    }
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .transition(.opacity)
                .animation(.easeInOut, value: isLoading)
            }
        }
        .onAppear {
            fetchUserProfile()
        }
        .onChange(of: step) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "profileStep")
            if newValue == 7 && !hasMarkedProfileAsComplete {
                markProfileAsComplete()
            }
            if newValue == 8 {
                UserDefaults.standard.set(true, forKey: "hasCompletedProfile")
                UserDefaults.standard.set(true, forKey: "hasUploadedPhotos")
                NotificationCenter.default.post(name: NSNotification.Name("StepEightReached"), object: nil)
            }
            if newValue == 7 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isLoading = false
                }
            }
        }
    }

    private func updateFirestoreToStepEight() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData([
            "profileStep": 8,
            "hasCompletedProfile": true,
            "hasUploadedPhotos": true,
            "lastUpdateTime": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("❌ Error updating to step 8: \(error.localizedDescription)")
            } else {
                print("✅ Successfully updated Firestore to step 8")
            }
        }
    }

    private func markProfileAsComplete() {
        hasMarkedProfileAsComplete = true
        UserDefaults.standard.set(7, forKey: "profileStep")
        UserDefaults.standard.set(true, forKey: "hasCompletedProfile")
        UserDefaults.standard.synchronize()

        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        var profileData: [String: Any] = [
            "profileStep": 7,
            "hasCompletedProfile": true,
            "lastUpdateTime": FieldValue.serverTimestamp(),
            "profileCompletionTime": FieldValue.serverTimestamp(),
            "name": name,
            "birthMonth": birthMonth,
            "birthDay": birthDay,
            "birthYear": birthYear,
            "snapchat": snapchat,
            "instagram": instagram,
            "colleges": selectedColleges,
            "mode": selectedMode,
            "personalityTraits": personalityTraits,
            "interests": interests
        ]
        let filteredURLs = uploadedImageURLs.filter { !$0.isEmpty }
        if !filteredURLs.isEmpty {
            profileData["imageURLs"] = filteredURLs
            profileData["profilePhotos"] = filteredURLs
        }

        db.collection("users").document(userID).setData(profileData, merge: true) { error in
            if let error = error {
                print("❌ Error marking profile as complete: \(error.localizedDescription)")
            } else {
                print("✅ Profile marked as complete in Firestore")
                NotificationCenter.default.post(name: NSNotification.Name("ForceContentViewRefresh"), object: nil)
            }
        }
    }

    private func fetchUserProfile() {
        guard let userID = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    self.name = data["name"] as? String ?? ""
                    self.birthMonth = data["birthMonth"] as? String ?? ""
                    self.birthDay = data["birthDay"] as? String ?? ""
                    self.birthYear = data["birthYear"] as? String ?? ""
                    self.snapchat = data["snapchat"] as? String ?? ""
                    self.instagram = data["instagram"] as? String ?? ""
                    self.selectedColleges = data["colleges"] as? [String] ?? []
                    self.selectedMode = data["mode"] as? String ?? ""
                    self.personalityTraits = data["personalityTraits"] as? [String] ?? []
                    self.interests = data["interests"] as? [String] ?? []
                    let storedURLs = data["imageURLs"] as? [String] ?? []
                    self.uploadedImageURLs = storedURLs + Array(repeating: "", count: max(0, 4 - storedURLs.count))
                    self.hasMarkedProfileAsComplete = data["hasCompletedProfile"] as? Bool ?? false

                    if !storedURLs.isEmpty {
                        UserDefaults.standard.set(true, forKey: "hasUploadedPhotos")
                        self.hasUploadedPhotos = true
                    }

                    let savedStep = data["profileStep"] as? Int ?? self.step
                    if savedStep == 8 {
                        UserDefaults.standard.set(8, forKey: "profileStep")
                        UserDefaults.standard.set(true, forKey: "hasCompletedProfile")
                        UserDefaults.standard.set(true, forKey: "hasUploadedPhotos")
                        NotificationCenter.default.post(name: NSNotification.Name("StepEightReached"), object: nil)
                    }

                    if savedStep > self.step {
                        self.step = savedStep
                        UserDefaults.standard.set(savedStep, forKey: "profileStep")
                    }

                    isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }

    private func saveUserProfile() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let userData: [String: Any] = [
            "name": name,
            "birthMonth": birthMonth,
            "birthDay": birthDay,
            "birthYear": birthYear,
            "snapchat": snapchat,
            "instagram": instagram,
            "colleges": selectedColleges,
            "mode": selectedMode,
            "personalityTraits": personalityTraits,
            "interests": interests,
            "profileStep": step,
            "lastUpdateTime": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if error == nil {
                UserDefaults.standard.set(step, forKey: "profileStep")
                if step < 7 {
                    UserDefaults.standard.set(false, forKey: "hasCompletedProfile")
                }
            }
        }
    }

    private func saveUserProfileWithImages(_ imageURLs: [String]) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let filteredURLs = imageURLs.filter { !$0.isEmpty }
        let userData: [String: Any] = [
            "imageURLs": filteredURLs,
            "profilePhotos": filteredURLs,
            "hasUploadedPhotos": true,
            "lastUpdateTime": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if error == nil {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(true, forKey: "hasUploadedPhotos")
                    self.hasUploadedPhotos = true
                    NotificationCenter.default.post(name: NSNotification.Name("PhotosUploaded"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("ForceContentViewRefresh"), object: nil)
                }
            }
        }
    }
}
