//
//  SummaryView.swift
//  DawnCast
//

import SwiftUI

struct SummaryView: View {
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text("Daily Summary")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Your personalized news summary will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
