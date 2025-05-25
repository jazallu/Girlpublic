//
//  SettingsView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/3/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @State private var showEditProfile = false
    
    // Account management states
    @State private var showDeleteConfirmation = false
    @State private var showFreezeConfirmation = false
    @State private var accountFrozen = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Set background to black, matching the rest of the app
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Logo at the top left
                    HStack {
                        Text("GIRL")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                            .shadow(color: Color.pink.opacity(0.5), radius: 3, x: 0, y: 2)
                            .padding(.leading, 20)
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // "Edit Profile" Button
                    Button(action: {
                        showEditProfile = true
                    }) {
                        Text("Edit Profile")
                            .foregroundColor(.pink)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                    .padding(.horizontal, 40)
                    
                    // Freeze Account Button
                    Button(action: {
                        showFreezeConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: accountFrozen ? "lock.open.fill" : "lock.fill")
                                .foregroundColor(.blue)
                            Text(accountFrozen ? "Unfreeze Account" : "Freeze Account")
                                .foregroundColor(.blue)
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    }
                    .padding(.horizontal, 40)
                    
                    // Delete Account Button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    }
                    .padding(.horizontal, 40)
                    
                    // "Log Out" Button
                    Button(action: logOut) {
                        Text("Log Out")
                            .foregroundColor(.red)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $showEditProfile) {
                EditProfileView(isEditingProfile: $showEditProfile)
            }
            .onAppear {
                checkAccountStatus()
            }
            // Delete account confirmation alert
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
            // Freeze account confirmation sheet
            .actionSheet(isPresented: $showFreezeConfirmation) {
                ActionSheet(
                    title: Text(accountFrozen ? "Unfreeze Account" : "Freeze Account"),
                    message: Text(accountFrozen ?
                                "This will make your profile visible to others again." :
                                "Freezing your account will hide your profile from others until you unfreeze it."),
                    buttons: [
                        .default(Text(accountFrozen ? "Unfreeze Account" : "Freeze Account")) {
                            toggleAccountFreeze()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    // Check if account is frozen
    private func checkAccountStatus() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                if let frozen = document.data()?["accountFrozen"] as? Bool {
                    self.accountFrozen = frozen
                }
            }
        }
    }
    
    // Account deletion function
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        let userID = user.uid
        let db = Firestore.firestore()
        
        // 1. Delete user data from Firestore
        db.collection("users").document(userID).delete { error in
            if let error = error {
                print("Error removing user document: \(error)")
            } else {
                // 2. Delete user from Authentication
                user.delete { error in
                    if let error = error {
                        print("Error deleting user from Auth: \(error)")
                    } else {
                        // Successfully deleted user
                        isLoggedIn = false
                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                    }
                }
            }
        }
    }
    
    // Toggle account freeze function
    private func toggleAccountFreeze() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Toggle frozen state
        accountFrozen.toggle()
        
        db.collection("users").document(userID).updateData([
            "accountFrozen": accountFrozen
        ]) { error in
            if let error = error {
                print("Error updating account freeze status: \(error)")
                // Revert state if update fails
                accountFrozen.toggle()
            }
        }
    }
    
    func logOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}

// Preview for testing
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isLoggedIn: .constant(true))
    }
}
