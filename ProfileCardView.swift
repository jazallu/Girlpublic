//
//  ProfileCardView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/22/25.
//

import SwiftUI

struct ProfileCardView: View {
    let name: String
    let snapchat: String
    let instagram: String

    var body: some View {
        VStack {
            Text(name)
                .font(.title)
                .foregroundColor(.white)
            HStack {
                Text("👻 \(snapchat)")
                Spacer()
                Text("📸 \(instagram)")
            }
            .font(.system(size: 18))
            .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(Color.black)
        .cornerRadius(12)
    }
}
