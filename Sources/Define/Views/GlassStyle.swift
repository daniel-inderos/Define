import SwiftUI

/// Liquid Glass adoption with graceful degradation.
///
/// The glass APIs exist only in the macOS 26+ SDK, so each helper is
/// double-gated: `#if compiler(>=6.2)` so older toolchains (CI) can still
/// compile the file, and `#available(macOS 26.0, *)` so older systems get
/// the classic material at runtime.
extension View {
    /// Capsule chip: Liquid Glass on macOS 26+, quaternary fill earlier.
    @ViewBuilder
    func glassChipBackground() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: Capsule())
        } else {
            self.background(.quaternary, in: Capsule())
        }
        #else
        self.background(.quaternary, in: Capsule())
        #endif
    }

    /// Primary call-to-action button: glass-prominent on macOS 26+.
    @ViewBuilder
    func glassProminentButtonStyle() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
        #else
        self.buttonStyle(.borderedProminent)
        #endif
    }

    /// Rounded field container (e.g. the history search field).
    @ViewBuilder
    func glassFieldBackground() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
        } else {
            self.background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        #else
        self.background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        #endif
    }
}
