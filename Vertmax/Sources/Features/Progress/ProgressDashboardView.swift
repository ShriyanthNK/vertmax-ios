import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Query(sort: \JumpMeasurement.date) private var measurements: [JumpMeasurement]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                if measurements.isEmpty {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(.textMuted)
                        Text("No measurements yet")
                            .font(VertFont.headline)
                            .foregroundStyle(.textPrimary)
                        Text("Your vert-over-time graph shows up after your first measurement.")
                            .font(VertFont.caption)
                            .foregroundStyle(.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                } else {
                    List {
                        Section {
                            Chart(measurements) { m in
                                AreaMark(x: .value("Date", m.date), y: .value("Inches", m.heightInches))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.voltGreen.opacity(0.22), Color.voltGreen.opacity(0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                LineMark(x: .value("Date", m.date), y: .value("Inches", m.heightInches))
                                    .foregroundStyle(Color.voltGreen)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineJoin: .round))
                                PointMark(x: .value("Date", m.date), y: .value("Inches", m.heightInches))
                                    .foregroundStyle(Color.voltGreen)
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                                    AxisValueLabel().foregroundStyle(Color.textMuted)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                                    AxisValueLabel().foregroundStyle(Color.textMuted)
                                }
                            }
                            .frame(height: 220)
                            .listRowBackground(Color.surface)
                        }

                        Section("History") {
                            ForEach(measurements.reversed()) { m in
                                HStack {
                                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                                        Text(String(format: "%.1f in", m.heightInches))
                                            .font(VertFont.numeric(17, weight: .semibold))
                                            .foregroundStyle(.textPrimary)
                                        Text(m.jumpType == .standing ? "Standing" : "Approach")
                                            .font(VertFont.caption)
                                            .foregroundStyle(.textMuted)
                                    }
                                    Spacer()
                                    Text(m.date, style: .date)
                                        .font(VertFont.caption)
                                        .foregroundStyle(.textMuted)
                                }
                                .listRowBackground(Color.surface)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Progress")
            .profileToolbar()
        }
    }
}
