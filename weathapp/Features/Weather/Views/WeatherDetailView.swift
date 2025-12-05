// WeatherDetailView.swift
import SwiftUI

struct WeatherDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WeatherViewModel

    init(city: City) {
        _viewModel = StateObject(wrappedValue: WeatherViewModel(city: city))
    }

    var body: some View {
        ZStack {
            // BACKGROUND
            LinearGradient(
                colors: viewModel.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // MAIN CONTENT
            ScrollView {
                VStack(spacing: 24) {
                    headerBar
                    mainInfo
                    statsCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            // 🔁 Pull-to-refresh -> calls API
            .refreshable {
                await viewModel.refreshAsync()
            }

            // 🔄 LOADER OVERLAY WHILE REFRESHING
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.white)
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        // No automatic refresh here:
        // the first screen shows data from Firebase via City.
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.18))
                    )
            }

            Spacer()

            Text(viewModel.title)
                .font(.title2.bold())
                .foregroundColor(.white)

            Spacer()

            // 🔁 Manual refresh button
            Button {
                Task { await viewModel.refreshAsync() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.18))
                    )
            }
        }
    }

    private var mainInfo: some View {
        VStack(spacing: 12) {
            if let w = viewModel.weather {
                Text(viewModel.cityAndCountryText)
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text(viewModel.formattedUpdatedText())
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))

                Text("\(Int(w.main.temp.rounded()))°")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)

                Image(systemName: viewModel.conditionSymbolName)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text(viewModel.descriptionText)
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.top, 4)
            } else {
                Text(viewModel.statusText ?? "No data yet")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
            }
        }
    }

    private var statsCard: some View {
        Group {
            if viewModel.weather != nil {
                VStack(spacing: 16) {
                    HStack {
                        statBlock(title: "Feels like", value: viewModel.feelsLikeText)
                        Spacer()
                        statBlock(title: "Humidity", value: viewModel.humidityText)
                    }

                    HStack {
                        statBlock(title: "Min", value: viewModel.tempMinText)
                        Spacer()
                        statBlock(title: "Max", value: viewModel.tempMaxText)
                    }

                    HStack {
                        statBlock(title: "Sunrise", value: viewModel.sunriseText)
                        Spacer()
                        statBlock(title: "Sunset", value: viewModel.sunsetText)
                    }

                    HStack {
                        statBlock(title: "Wind", value: viewModel.windText)
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.18))
                )
                .padding(.top, 24)
            }
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
