//
//  CountrySelectionView.swift
//  DawnCast
//

import SwiftUI

struct CountrySelectionView: View {
    @Binding var selectedCountry: String

    // NewsData.io supported countries (ISO 3166-1 alpha-2)
    private let countries: [(code: String, name: String)] = [
        ("us", "United States"),
        ("gb", "United Kingdom"),
        ("ca", "Canada"),
        ("au", "Australia"),
        ("in", "India"),
        ("ie", "Ireland"),
        ("nz", "New Zealand"),
        ("sg", "Singapore"),
        ("za", "South Africa"),
        ("ng", "Nigeria"),
        ("ke", "Kenya"),
        ("ph", "Philippines"),
        ("de", "Germany"),
        ("fr", "France"),
        ("jp", "Japan"),
        ("br", "Brazil"),
        ("mx", "Mexico"),
        ("it", "Italy"),
        ("es", "Spain"),
        ("kr", "South Korea"),
        ("ae", "UAE"),
        ("sa", "Saudi Arabia"),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Where are you located?")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Select your country for local news")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 24)

                    // Country chips in a flowing layout
                    FlowLayout(spacing: 12) {
                        ForEach(countries, id: \.code) { country in
                            CountryChip(
                                title: country.name,
                                isSelected: selectedCountry == country.code
                            ) {
                                selectedCountry = country.code
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Country Chip

struct CountryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            Button(action: action) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
        } else {
            Button(action: action) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.glass)
        }
    }
}
