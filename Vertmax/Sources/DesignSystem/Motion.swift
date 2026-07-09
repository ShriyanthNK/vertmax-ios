import SwiftUI

extension View {
    /// Shared entrance choreography: fade + rise, staggered by `delay` so a
    /// screen's stacked elements build in rather than snapping in at once.
    /// Drive `appeared` from a `@State` flipped to `true` in `onAppear`.
    ///
    /// `nonisolated` — see the note on `cardStyle` in Chrome.swift.
    nonisolated func reveal(_ appeared: Bool, delay: Double = 0) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.easeOut(duration: 0.45).delay(delay), value: appeared)
    }
}
