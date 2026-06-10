//
//  ShakeEffect.swift
//  LingoLearn
//

import SwiftUI

/// 答错时的水平抖动动画。`trigger` 每 +1 抖一轮。
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    init(trigger: Int) {
        animatableData = CGFloat(trigger)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

extension View {
    func shake(trigger: Int) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

private struct ShakeModifier: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(trigger: trigger))
            .animation(.linear(duration: 0.4), value: trigger)
    }
}
