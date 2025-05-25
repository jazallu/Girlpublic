//
//  WelcomeView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//
//
//  WelcomeView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct WelcomeView: View {
    @Binding var step: Int
    @State private var termsAccepted = false
    @State private var showTerms = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                Text("Welcome to GIRL 🎀")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()

                Text("Let's set up your profile!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 20)
                
                // Terms of Service
                VStack(alignment: .leading, spacing: 15) {
                    Button(action: {
                        showTerms = true
                    }) {
                        Text("Read Terms of Service")
                            .foregroundColor(.pink)
                            .underline()
                    }
                    
                    HStack(alignment: .top) {
                        Toggle("", isOn: $termsAccepted)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .pink))
                        
                        Text("I agree to the Terms of Service, which include a zero-tolerance policy for objectionable content")
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 10)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                Spacer()

                // Continue Button
                Button(action: {
                    if !termsAccepted {
                        errorMessage = "You must accept the Terms of Service to continue"
                        return
                    }
                    
                    print("🚀 Button tapped! Step BEFORE update: \(step)")
                    
                    // Record terms acceptance in Firestore
                    if let userId = Auth.auth().currentUser?.uid {
                        let db = Firestore.firestore()
                        db.collection("users").document(userId).updateData([
                            "termsAccepted": true,
                            "termsAcceptedDate": FieldValue.serverTimestamp(),
                            "termsVersion": "1.0" // Track which version they accepted
                        ])
                    }
                    
                    // Save locally as well
                    UserDefaults.standard.set(true, forKey: "termsAccepted")
                    UserDefaults.standard.set(Date(), forKey: "termsAcceptedDate")

                    DispatchQueue.main.async {
                        step += 1
                        UserDefaults.standard.set(step, forKey: "profileStep")
                        UserDefaults.standard.synchronize() // ✅ Ensures immediate write

                        print("✅ Step updated! Step AFTER update: \(step)")
                        print("📌 Saved step in UserDefaults: \(UserDefaults.standard.integer(forKey: "profileStep"))")
                    }
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(termsAccepted ? Color.pink : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!termsAccepted)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Check if terms already accepted
            let termsAlreadyAccepted = UserDefaults.standard.bool(forKey: "termsAccepted")
            if termsAlreadyAccepted {
                termsAccepted = true
            }
            
            // ✅ Ensure step is loaded properly from UserDefaults
            DispatchQueue.main.async {
                let savedStep = UserDefaults.standard.integer(forKey: "profileStep")
                print("📌 WelcomeView appeared. Saved step from UserDefaults: \(savedStep), Current step: \(step)")

                if savedStep > 1 && step == 1 { // ✅ Only override if step is still 1
                    step = savedStep
                    print("🔄 Step updated from UserDefaults: \(step)")
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceDetailView()
        }
    }
}

struct TermsOfServiceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Terms of Service & User Agreement")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                        
                        Text("By accessing or using GIRL (\"the App\"), you agree to be bound by these Terms of Service (\"Terms\"). If you do not agree to these Terms, you may not access or use the App.")
                        
                        Text("2. User-Generated Content Policy")
                            .font(.headline)
                        
                        Text("2.1 Zero Tolerance Policy")
                            .fontWeight(.semibold)
                        Text("GIRL has a zero-tolerance policy regarding objectionable content. We are committed to providing a safe and positive experience for all users.")
                        
                        Text("2.2 Prohibited Content")
                            .fontWeight(.semibold)
                        Text("Users are prohibited from posting, uploading, or sharing any content that:")
                        Text("• Promotes hate speech, discrimination, or violence")
                        Text("• Contains sexually explicit or pornographic material")
                        Text("• Depicts graphic violence or gore")
                        Text("• Encourages illegal activities")
                        Text("• Contains personal or private information about others without consent")
                        Text("• Infringes on intellectual property rights")
                        Text("• Constitutes spam, phishing attempts, or fraudulent activities")
                        Text("• Harasses, bullies, or intimidates others")
                        Text("• Impersonates another person or entity")
                    }
                    
                    Group {
                        Text("3. User Conduct")
                            .font(.headline)
                        
                        Text("3.1 Abusive Behavior")
                            .fontWeight(.semibold)
                        Text("GIRL does not tolerate abusive behavior. Users engaging in harassment, threats, bullying, or any form of abuse toward other users will be subject to immediate account suspension or termination.")
                        
                        Text("4. Reporting and Enforcement")
                            .font(.headline)
                        
                        Text("4.1 Reporting Mechanism")
                            .fontWeight(.semibold)
                        Text("The App provides a mechanism for users to report objectionable content and abusive users. Reports will be reviewed promptly, within 24 hours.")
                        
                        Text("4.2 Enforcement Actions")
                            .fontWeight(.semibold)
                        Text("We reserve the right to:")
                        Text("• Remove any content that violates these Terms")
                        Text("• Suspend or terminate accounts of users who violate these Terms")
                        Text("• Take appropriate legal action for violations")
                        
                        Text("5. User Rights")
                            .font(.headline)
                        
                        Text("5.1 Blocking Other Users")
                            .fontWeight(.semibold)
                        Text("Users have the right to block any other user at their discretion. Blocked users will not be able to view your content or interact with you through the App.")
                    }
                }
                .padding()
            }
            .navigationBarTitle("Terms of Service", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }
}
