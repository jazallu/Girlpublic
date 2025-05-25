//
//  ModeSelectionView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var step: Int
    @Binding var selectedMode: String
    var onSave: () -> Void

    private let totalSteps = 7
    let modes = ["Find a Roommate", "Find Friends"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 🔥 Full black background
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                VStack(spacing: geometry.size.height * 0.03) {
                    
                    VStack {
                        Text("Step \(step) of \(totalSteps)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: geometry.size.width * 0.045, weight: .medium))

                        ProgressBar(progress: CGFloat(step) / CGFloat(totalSteps))
                            .frame(width: geometry.size.width * 0.8, height: 8)
                    }
                    .padding(.top, geometry.size.height * 0.05)

                    // 📝 Title
                    Text("What brings you to GIRL?")
                        .font(.system(size: geometry.size.width * 0.08, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // 📌 Selection Buttons
                    VStack(spacing: geometry.size.height * 0.025) {
                        ForEach(modes, id: \.self) { mode in
                            Button(action: {
                                selectedMode = mode
                            }) {
                                HStack {
                                    Text(mode)
                                        .foregroundColor(.white)
                                        .font(.system(size: 22))
                                    Spacer()
                                    if selectedMode == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .padding()
                                .frame(width: geometry.size.width * 0.85, height: 75)
                                .background(selectedMode == mode ? Color.pink.opacity(0.3) : Color.white.opacity(0.15))
                                .cornerRadius(18)
                            }
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    // ✅ Next Button (Netflix-style)
                    Button(action: {
                        onSave()
                        UserDefaults.standard.set(true, forKey: "hasSeenModeSelection") // ✅ Save to UserDefaults
                        step += 1
                    }) {
                        Text("Next")
                            .frame(width: geometry.size.width * 0.85, height: 75)
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .bold))
                            .cornerRadius(18)
                    }
                    .padding(.bottom, geometry.size.height * 0.08)
                }
                .frame(width: geometry.size.width) // 🔥 Keeps everything centered
            }
        }
        .onAppear {
            // ✅ Skip this screen if already seen
            if UserDefaults.standard.bool(forKey: "hasSeenModeSelection") {
                step += 1
            }
        }
    }
}
