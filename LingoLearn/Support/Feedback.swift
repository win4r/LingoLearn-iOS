//
//  Feedback.swift
//  LingoLearn
//
//  触觉反馈与音效，统一受设置开关控制。
//

import AudioToolbox
import UIKit

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.hapticsEnabled)
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

enum SoundFX {
    private static var enabled: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.soundEnabled)
    }

    /// 答对提示音
    static func correct() {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    /// 答错提示音
    static func wrong() {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1053)
    }

    /// 完成一轮
    static func complete() {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    /// 翻卡/滑卡轻音
    static func swipe() {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}
