//
//  PersonalitySelectionView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//

import SwiftUI

struct PersonalitySelectionView: View {
    @Binding var step: Int
    @Binding var personalityTraits: [String]
    let allTraits: [String]
    var onSave: () -> Void

    private let totalSteps = 7

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 🔥 Full black background
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                VStack(spacing: geometry.size.height * 0.025) {
                    
                    VStack {
                        Text("Step \(step) of \(totalSteps)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: geometry.size.width * 0.04, weight: .medium))

                        ProgressBar(progress: CGFloat(step) / CGFloat(totalSteps))
                            .frame(width: geometry.size.width * 0.75, height: 6)
                    }
                    .padding(.top, geometry.size.height * 0.04)

                    // 📝 Title
                    Text("Select Your Personality Traits")
                        .font(.system(size: geometry.size.width * 0.07, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // 📌 Selection Buttons (Centered)
                    VStack(spacing: geometry.size.height * 0.02) {
                        ForEach(allTraits, id: \.self) { trait in
                            Button(action: {
                                if personalityTraits.contains(trait) {
                                    personalityTraits.removeAll { $0 == trait }
                                } else if personalityTraits.count < 3 {
                                    personalityTraits.append(trait)
                                }
                            }) {
                                HStack {
                                    Text(trait)
                                        .foregroundColor(.white)
                                        .font(.system(size: 20)) // 🔥 Slightly smaller text
                                    Spacer()
                                    if personalityTraits.contains(trait) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .padding()
                                .frame(width: geometry.size.width * 0.8, height: 65) // 🔥 Slightly smaller button
                                .background(personalityTraits.contains(trait) ? Color.pink.opacity(0.3) : Color.white.opacity(0.12))
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal, 25)

                    Spacer()

                    // ✅ Next Button (Netflix-style, slightly smaller)
                    Button(action: {
                        onSave()
                        UserDefaults.standard.set(true, forKey: "hasSeenPersonalitySelection") // ✅ Save to UserDefaults
                        step += 1
                    }) {
                        Text("Next")
                            .frame(width: geometry.size.width * 0.8, height: 65) // 🔥 Reduced height
                            .background(personalityTraits.count >= 1 ? Color.pink : Color.gray) // Pink when active, gray when inactive
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .bold)) // 🔥 Slightly smaller text
                            .cornerRadius(15)
                    }
                    .disabled(personalityTraits.count < 1) // Disable until at least 1 trait
                    .padding(.bottom, geometry.size.height * 0.06)
                }
                .frame(width: geometry.size.width) // 🔥 Keeps everything centered
            }
        }
        .onAppear {
            // ✅ Skip this screen if already seen
            if UserDefaults.standard.bool(forKey: "hasSeenPersonalitySelection") {
                step += 1
            }
        }
    }
}



