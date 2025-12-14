//
//  SM2Service.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation

struct SM2Result {
    let interval: Int
    let easeFactor: Double
    let repetitions: Int
    let nextReviewDate: Date
}

class SM2Service {
    static let shared = SM2Service()

    private init() {}

    /// Calculate next review parameters using SM-2 algorithm
    /// - Parameters:
    ///   - currentEF: Current ease factor (default 2.5)
    ///   - currentInterval: Current interval in days
    ///   - currentReps: Current number of successful repetitions
    ///   - quality: User response quality (0-5: 0-2 = incorrect, 3 = hard, 4 = good, 5 = easy)
    /// - Returns: SM2Result with updated parameters
    func calculateNextReview(currentEF: Double, currentInterval: Int, currentReps: Int, quality: Int) -> SM2Result {
        var newEF = currentEF
        var newInterval = currentInterval
        var newReps = currentReps

        // If quality is acceptable (3 or above), increase interval
        if quality >= 3 {
            switch newReps {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = Int(Double(currentInterval) * currentEF)
            }
            newReps += 1
        } else {
            // If quality is poor, reset to beginning
            newReps = 0
            newInterval = 1
        }

        // Update ease factor based on quality
        newEF = currentEF + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        newEF = max(1.3, newEF)

        // Calculate next review date
        let nextDate = Calendar.current.date(byAdding: .day, value: newInterval, to: Date())!

        return SM2Result(interval: newInterval, easeFactor: newEF, repetitions: newReps, nextReviewDate: nextDate)
    }
}
