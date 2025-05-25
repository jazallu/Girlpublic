//
//  ProgressBar.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//

import SwiftUI

// ✅ Bumble-Style Progress Bar (Reusable)
struct ProgressBar: View {
    var progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: geometry.size.width, height: 8)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.pink)
                    .frame(width: geometry.size.width * progress, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

#Preview {
    ProgressBar(progress: 7)
}
