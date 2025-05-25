//
//  BasicInfoView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//
import SwiftUI

struct BasicInfoView: View {
    @Binding var step: Int
    @Binding var name: String
    @Binding var birthMonth: String
    @Binding var birthDay: String
    @Binding var birthYear: String
    var onSave: () -> Void
    
    // Focus states for each field
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var monthFieldFocused: Bool
    @FocusState private var dayFieldFocused: Bool
    @FocusState private var yearFieldFocused: Bool
    
    @State private var keyboardShowing = false
    
    private let totalSteps = 7

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: geometry.size.height * 0.03) {
                    VStack {
                        Text("Step \(step) of \(totalSteps)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: geometry.size.width * 0.045, weight: .medium))
                        ProgressBar(progress: CGFloat(step) / CGFloat(totalSteps))
                            .frame(width: geometry.size.width * 0.8, height: 8)
                    }
                    .padding(.top, 10)

                    Text("Oh hey! Let's start with an intro.")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    // Name Field with Label
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your first name")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        CustomTextField(
                            text: $name,
                            placeholder: "",
                            onSubmit: { monthFieldFocused = true }
                        )
                        .focused($nameFieldFocused)
                        .frame(width: geometry.size.width * 0.85, height: 65)
                        .submitLabel(.next)
                    }
                    .padding(.top, 30)

                    // Birthdate Fields with Labels
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your birthday")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))

                        HStack(spacing: geometry.size.width * 0.03) {
                            VStack {
                                Text("Month")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14))
                                CustomTextField(
                                    text: $birthMonth,
                                    placeholder: "",
                                    onSubmit: { dayFieldFocused = true },
                                    keyboardType: .numberPad
                                )
                                .focused($monthFieldFocused)
                                .frame(width: geometry.size.width * 0.25, height: 65)
                                .submitLabel(.next)
                            }

                            VStack {
                                Text("Day")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14))
                                CustomTextField(
                                    text: $birthDay,
                                    placeholder: "",
                                    onSubmit: { yearFieldFocused = true },
                                    keyboardType: .numberPad
                                )
                                .focused($dayFieldFocused)
                                .frame(width: geometry.size.width * 0.25, height: 65)
                                .submitLabel(.next)
                            }

                            VStack {
                                Text("Year")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14))
                                CustomTextField(
                                    text: $birthYear,
                                    placeholder: "",
                                    onSubmit: {
                                        // When done with all fields, continue to next step
                                        proceedToNextStep()
                                    },
                                    keyboardType: .numberPad
                                )
                                .focused($yearFieldFocused)
                                .frame(width: geometry.size.width * 0.35, height: 65)
                                .submitLabel(.done)
                            }
                        }
                        Text("It's never too early to count down")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14))
                            .padding(.top, 5)
                    }
                    .frame(width: geometry.size.width * 0.85)
                    .padding(.top, 10)

                    Spacer()

                    // Next Button (only visible when keyboard is hidden)
                    if !keyboardShowing {
                        Button(action: {
                            proceedToNextStep()
                        }) {
                            ZStack {
                                Circle()
                                    .foregroundColor(.black)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .onAppear {
                // Set initial focus to name field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    nameFieldFocused = true
                }
                
                // Check if there's a name from Apple Sign In
                if name.isEmpty {
                    if UserDefaults.standard.bool(forKey: "hasSignedInWithApple"),
                       let savedName = UserDefaults.standard.string(forKey: "userName"),
                       !savedName.isEmpty {
                        name = savedName
                    }
                }
            }
            .overlay(
                // Keyboard navigation button (visible when keyboard is showing)
                VStack {
                    Spacer()
                    if keyboardShowing {
                        HStack {
                            Spacer()
                            Button(action: {
                                if nameFieldFocused {
                                    monthFieldFocused = true
                                } else if monthFieldFocused {
                                    dayFieldFocused = true
                                } else if dayFieldFocused {
                                    yearFieldFocused = true
                                } else if yearFieldFocused {
                                    hideKeyboard()
                                    proceedToNextStep()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(.black)
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 8)
                        }
                    }
                }
            )
            // Listen for keyboard notifications
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardShowing = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardShowing = false
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func proceedToNextStep() {
        // Basic validation
        if !name.isEmpty && !birthMonth.isEmpty && !birthDay.isEmpty && !birthYear.isEmpty {
            onSave()
            UserDefaults.standard.set(true, forKey: "hasCompletedBasicInfo")
            step += 1
        }
    }
}

// Custom TextField with improved handling
struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String = ""
    var onSubmit: (() -> Void)? = nil
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundColor(.white)
            .padding()
            .frame(height: 65)
            .background(Color.white.opacity(0.15))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.3), lineWidth: 1))
            .font(.system(size: 20))
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .onSubmit {
                onSubmit?()
            }
            .keyboardType(keyboardType)
    }
}
