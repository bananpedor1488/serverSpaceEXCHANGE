import SwiftUI

struct AnimatedBackground: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                particle.color.opacity(0.6),
                                particle.color.opacity(0.3),
                                particle.color.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: 30)
                    .offset(x: particle.x, y: particle.y)
                    .animation(
                        .easeInOut(duration: particle.duration)
                        .repeatForever(autoreverses: true),
                        value: particle.x
                    )
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        let colors: [Color] = [.blue, .purple, .pink, .cyan, .indigo]
        
        for i in 0..<15 {
            let particle = Particle(
                id: i,
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: -400...400),
                size: CGFloat.random(in: 100...250),
                color: colors.randomElement()!,
                duration: Double.random(in: 8...15)
            )
            particles.append(particle)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation {
                    particles[i].x = CGFloat.random(in: -200...200)
                    particles[i].y = CGFloat.random(in: -400...400)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let duration: Double
}
