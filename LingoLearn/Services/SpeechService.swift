//
//  SpeechService.swift
//  LingoLearn
//
//  系统 TTS 发音（AVSpeechSynthesizer）。
//

import AVFoundation
import Foundation

final class SpeechService {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// 朗读英文单词或句子
    func speak(_ text: String, slow: Bool = false) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 播放前打断上一条，避免排队堆积
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = slow ? 0.35 : 0.48
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
