import SwiftUI

/// Confetti animation overlay for celebrations
struct ConfettiView: View {
    @Binding var counter: Int

    var body: some View {
        ZStack {
            ForEach(0..<25, id: \.self) { index in
                ConfettiPiece(counter: counter, index: index)
            }
        }
        .ignoresSafeArea()
    }
}

/// Individual confetti particle with animated motion
struct ConfettiPiece: View {
    let counter: Int
    let index: Int

    @State private var location = CGPoint(x: 0, y: 0)
    @State private var opacity: Double = 0

    private let colors: [Color] = [
        AppTheme.primaryBlue,
        AppTheme.energyOrange,
        AppTheme.vibrantPurple,
        AppTheme.successGreen,
        .white
    ]

    var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: 10, height: 10)
            .position(location)
            .opacity(opacity)
            .onAppear {
                animate()
            }
            .onChange(of: counter) { _ in
                animate()
            }
    }

    private func animate() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Random starting position at top
        let startX = CGFloat.random(in: 0...screenWidth)
        let startY: CGFloat = -20

        // Random end position
        let endX = startX + CGFloat.random(in: -100...100)
        let endY = screenHeight + 20

        // Set initial position
        location = CGPoint(x: startX, y: startY)
        opacity = 0

        // Animate down with delay
        let delay = Double.random(in: 0...0.5)
        let duration = Double.random(in: 2.0...3.5)

        withAnimation(.linear(duration: 0.1).delay(delay)) {
            opacity = 1
        }

        withAnimation(.easeIn(duration: duration).delay(delay)) {
            location = CGPoint(x: endX, y: endY)
        }

        withAnimation(.linear(duration: 0.3).delay(delay + duration - 0.3)) {
            opacity = 0
        }
    }
}
