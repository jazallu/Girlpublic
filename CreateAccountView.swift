//
//  CreateAccountView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/2/25.
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateAccountView: View {
    @Binding var isLoggedIn: Bool
    @Binding var step: Int
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var errorMessage: String = ""
    @State private var navigateToProfileCreation = false
    
    var body: some View {
        NavigationStack { // Replace NavigationView with NavigationStack
            VStack {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                TextField("Name", text: $name)
                    .autocapitalization(.words)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                Button(action: createAccount) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemPink))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                Spacer()
                
                // Use NavigationLink directly within the NavigationStack
                NavigationLink(destination: ProfileCreationView(isLoggedIn: $isLoggedIn, step: $step),
                               isActive: $navigateToProfileCreation) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
    
    func createAccount() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                // Reset UserDefaults for new user to ensure fresh profile creation
                UserDefaults.standard.set(1, forKey: "profileStep")
                UserDefaults.standard.removeObject(forKey: "hasSeenBasicInfo")
                UserDefaults.standard.removeObject(forKey: "hasSeenCollegeSelection")
                UserDefaults.standard.removeObject(forKey: "hasSeenModeSelection")
                UserDefaults.standard.removeObject(forKey: "hasSeenPersonalitySelection")
                UserDefaults.standard.removeObject(forKey: "hasSeenInterestSelection")
                UserDefaults.standard.removeObject(forKey: "hasSeenPhotoUpload")
                UserDefaults.standard.removeObject(forKey: "hasCompletedProfile")
                
                // Save initial data to Firestore
                if let userID = Auth.auth().currentUser?.uid {
                    let db = Firestore.firestore()
                    db.collection("users").document(userID).setData([
                        "name": name,
                        "profileStep": 1,
                        "profileCompleted": false
                    ], merge: true)
                }
                
                isLoggedIn = true
                step = 1
                navigateToProfileCreation = true
                print("✅ Account created, step: \(step), navigating: \(navigateToProfileCreation)")
            }
        }
    }
}
