//
//  ConfettiView.swift
//  LingoLearn
//
//  成就解锁时的彩带庆祝动画（Canvas + TimelineView，无第三方依赖）。
//

import SwiftUI

struct ConfettiView: View {
    struct Particle {
        let x: Double          // 0...1 相对横坐标
        let delay: Double
        let speed: Double      // 每秒下落比例
        let size: CGFloat
        let colorIndex: Int
        let spin: Double
        let sway: Double
    }

    private let particles: [Particle]
    private let colors: [Color] = [.brandPrimary, .brandSecondary, .orange, .pink, .yellow, .purple]
    private let startDate = Date()

    init(count: Int = 60) {
        var generator = SystemRandomNumberGenerator()
        particles = (0..<count).map { _ in
            Particle(
                x: Double.random(in: 0...1, using: &generator),
                delay: Double.random(in: 0...0.8, using: &generator),
                speed: Double.random(in: 0.25...0.55, using: &generator),
                size: CGFloat.random(in: 6...12, using: &generator),
                colorIndex: Int.random(in: 0..<6, using: &generator),
                spin: Double.random(in: -4...4, using: &generator),
                sway: Double.random(in: 10...40, using: &generator)
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                for p in particles {
                    let t = elapsed - p.delay
                    guard t > 0 else { continue }
                    let progress = t * p.speed
                    guard progress < 1.3 else { continue }
                    let y = progress * size.height
                    let x = p.x * size.width + sin(t * 3 + p.x * 10) * p.sway
                    let alpha = progress > 1 ? max(0, 1.3 - progress) / 0.3 : 1
                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(t * p.spin))
                    ctx.opacity = alpha
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(colors[p.colorIndex]))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
