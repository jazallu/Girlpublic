//
//  InterestSelectionView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//

import SwiftUI

struct InterestSelectionView: View {
    @Binding var step: Int
    @Binding var interests: [String]
    let allInterests: [String]
    var onSave: () -> Void

    private let totalSteps = 7

    var body: some View {
        GeometryReader { geometry in
            ZStack {
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

                    Text("Pick Your Interests")
                        .font(.system(size: geometry.size.width * 0.07, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    VStack(spacing: geometry.size.height * 0.02) {
                        ForEach(allInterests, id: \.self) { interest in
                            Button(action: {
                                if interests.contains(interest) {
                                    interests.removeAll { $0 == interest }
                                } else if interests.count < 5 {
                                    interests.append(interest)
                                }
                            }) {
                                HStack {
                                    Text(interest)
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                    Spacer()
                                    if interests.contains(interest) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .padding()
                                .frame(width: geometry.size.width * 0.8, height: 65)
                                .background(interests.contains(interest) ? Color.pink.opacity(0.3) : Color.white.opacity(0.12))
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal, 25)

                    Spacer()

                    Button(action: {
                        print("📌 InterestSelectionView Next tapped, step before: \(step)")
                        onSave()
                        UserDefaults.standard.set(true, forKey: "hasCompletedInterestSelection")
                        step += 1
                        print("📌 Step after: \(step)")
                    }) {
                        Text("Next")
                            .frame(width: geometry.size.width * 0.8, height: 65)
                            .background(interests.count >= 1 ? Color.pink : Color.gray) // Pink when active, gray when inactive
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .bold))
                            .cornerRadius(15)
                    }
                    .disabled(interests.count < 1) // Disable until at least 1 interest
                    .padding(.bottom, geometry.size.height * 0.06)
                }
                .frame(width: geometry.size.width)
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "hasCompletedInterestSelection") && !interests.isEmpty {
                print("⚠️ Skipping InterestSelectionView, step before: \(step)")
                step += 1
                print("⚠️ Step after: \(step)")
            }
        }
    }
}
