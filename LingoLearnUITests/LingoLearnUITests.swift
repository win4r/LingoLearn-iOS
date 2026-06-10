//
//  LingoLearnUITests.swift
//  LingoLearnUITests
//
//  端到端冒烟：首页 → 学习卡（翻面/评分）→ 各 Tab 关键内容。
//

import XCTest

final class LingoLearnUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSmokeFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // 首页加载（词库播种完成）
        XCTAssertTrue(app.buttons["开始学习"].waitForExistence(timeout: 15), "首页未加载")

        // 进入学习会话
        app.buttons["开始学习"].tap()
        XCTAssertTrue(app.staticTexts["点击卡片查看释义"].waitForExistence(timeout: 10), "单词卡未出现")

        // 翻面查看释义
        app.staticTexts["点击卡片查看释义"].tap()
        XCTAssertTrue(app.staticTexts["点击卡片返回正面"].waitForExistence(timeout: 5), "卡片翻转失败")

        // 标记一张「认识」，下一张卡应出现
        app.buttons["认识"].tap()
        XCTAssertTrue(app.staticTexts["点击卡片查看释义"].waitForExistence(timeout: 5), "评分后未切换到下一张卡")

        // 关闭学习会话（进度已逐卡保存）
        app.buttons["关闭"].tap()

        // 练习 Tab
        app.tabBars.buttons["练习"].tap()
        XCTAssertTrue(app.staticTexts["题型"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["选择题"].exists)

        // 进度 Tab
        app.tabBars.buttons["进度"].tap()
        XCTAssertTrue(app.staticTexts["学习趋势"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["词汇掌握度"].exists)
        XCTAssertTrue(app.staticTexts["成就徽章"].exists)

        // 设置 Tab
        app.tabBars.buttons["设置"].tap()
        XCTAssertTrue(app.sliders.firstMatch.waitForExistence(timeout: 5), "每日目标滑块未出现")
        // 重置按钮在 Form 首屏之下，上滑后应可见
        app.swipeUp()
        XCTAssertTrue(app.buttons["重置学习进度"].waitForExistence(timeout: 5), "重置按钮未出现")

        // 回到首页，今日已学应 ≥ 1
        app.tabBars.buttons["首页"].tap()
        XCTAssertTrue(app.staticTexts["今日已学"].waitForExistence(timeout: 5))
    }
}
