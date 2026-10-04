import XCTest

@MainActor final class M2UITests: XCTestCase {
    private func launch(store: String = UUID().uuidString, skip: Bool = true, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-test-store", store] + (skip ? ["-skip-tutorial"] : [])
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }
    private func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.exists || element.waitForExistence(timeout: 8))
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: element)], timeout: 5), .completed)
        element.tap()
    }
    private func chapter(_ number: Int, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "第 \(number) 章 ·")).firstMatch
    }
    private func choose(_ app: XCUIApplication, _ colors: [Int]) {
        for color in colors { tap(app.buttons["color-\(color)"]) }
    }
    private func screenshot(_ app: XCUIApplication, _ name: String) {
        // iOS 17 的可访问元素会在转场结束前出现;截图需等待导航动画稳定。
        Thread.sleep(forTimeInterval: 0.5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testUnifiedSoloHomeAndBrowsing() {
        let app = launch()
        XCTAssertTrue(app.buttons["soloLevels"].exists && app.buttons["duo"].exists && app.buttons["settings"].exists)
        XCTAssertFalse(app.buttons["continueGame"].exists || app.buttons["easyLevels"].exists || app.buttons["advancedLevels"].exists)
        screenshot(app, "三入口首页")
        tap(app.buttons["soloLevels"])
        XCTAssertTrue(app.segmentedControls["soloBand"].buttons["简单"].isSelected)
        screenshot(app, "统一简单选关")
        tap(app.segmentedControls["soloBand"].buttons["进阶"])
        tap(chapter(1, in: app))
        tap(chapter(2, in: app))
        tap(app.segmentedControls["soloBand"].buttons["简单"])
        tap(app.segmentedControls["soloBand"].buttons["进阶"])
        XCTAssertFalse(app.buttons["level-101"].exists)
        XCTAssertTrue(app.buttons["level-151"].exists)
        screenshot(app, "统一进阶选关")
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["soloLevels"])
        XCTAssertTrue(app.segmentedControls["soloBand"].buttons["简单"].isSelected)
        XCTAssertEqual(app.buttons["soloShortcut"].label, "开始闯关 · 简单第 1 关")
    }

    func testUnifiedSoloLargeText() {
        let app = launch(largeText: true)
        screenshot(app, "大字体三入口首页")
        tap(app.buttons["soloLevels"])
        screenshot(app, "大字体统一选关顶部")
        scrollTo(app.buttons["level-100"], in: app)
        screenshot(app, "大字体简单末关")
        scrollTo(app.segmentedControls["soloBand"], in: app, towardTop: true)
        tap(app.segmentedControls["soloBand"].buttons["进阶"])
        tap(chapter(1, in: app))
        scrollTo(chapter(10, in: app), in: app)
        tap(chapter(10, in: app))
        scrollTo(app.buttons["level-600"], in: app)
        screenshot(app, "大字体进阶末关")
        app.navigationBars.buttons.firstMatch.tap()
        scrollTo(app.buttons["settings"], in: app)
        tap(app.buttons["settings"])
        XCTAssertTrue(app.switches["answerSetting"].waitForExistence(timeout: 8))
    }

    func testTutorialAndReplayPreservesGame() {
        let app = launch(skip: false)
        tap(app.buttons["color-0"])
        tap(app.buttons["下一步"])
        tap(app.buttons["提交示例"])
        tap(app.buttons["下一步"])
        choose(app, [6, 3, 0, 4])
        tap(app.buttons["确认密码"])
        XCTAssertTrue(app.staticTexts["E-002"].waitForExistence(timeout: 8))
        tap(app.buttons["color-2"])
        tap(app.buttons["gameBack"])
        tap(app.alerts.buttons["保存并退出"])
        app.navigationBars.buttons.firstMatch.tap()
        scrollTo(app.buttons["settings"], in: app)
        screenshot(app, "首页底部设置入口")
        tap(app.buttons["settings"])
        tap(app.buttons["重放教程"])
        tap(app.buttons["跳过"])
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["soloLevels"])
        tap(app.buttons["soloShortcut"])
        XCTAssertTrue(app.buttons["cell-0"].value as? String == "黄色,未选中")
    }

    func testSaveAcrossRelaunchAndRestart() {
        let store = UUID().uuidString
        var app = launch(store: store)
        tap(app.buttons["soloLevels"])
        tap(app.buttons["soloShortcut"])
        choose(app, [0, 1])
        app.terminate()
        app = launch(store: store)
        tap(app.buttons["soloLevels"])
        tap(app.buttons["soloShortcut"])
        XCTAssertEqual(app.buttons["cell-0"].value as? String, "红色,未选中")
        XCTAssertEqual(app.buttons["cell-1"].value as? String, "橙色,未选中")
        screenshot(app, "恢复单人棋盘")
        tap(app.buttons["restart"])
        tap(app.alerts.buttons["重开"])
        let cleared = NSPredicate(format: "value == %@", "空白,已选中")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: cleared, object: app.buttons["cell-0"])], timeout: 5), .completed)
        screenshot(app, "重开后棋盘")
    }

    func testWinNextLevelAndSelection() {
        let app = launch()
        tap(app.buttons["soloLevels"])
        XCTAssertEqual(app.buttons["level-1"].label, "E-001，未通关")
        XCTAssertFalse(app.buttons["level-1"].label.contains("checkmark"))
        tap(app.buttons["level-1"])
        choose(app, [6, 3, 0, 4])
        tap(app.buttons["submit"])
        XCTAssertTrue(app.staticTexts["破译成功!"].waitForExistence(timeout: 8))
        screenshot(app, "单人成功结算")
        tap(app.buttons["选关"])
        XCTAssertEqual(app.buttons["soloShortcut"].label, "下一关 · 简单第 2 关")
        tap(app.buttons["soloShortcut"])
        XCTAssertTrue(app.staticTexts["E-002"].waitForExistence(timeout: 8))
        tap(app.buttons["gameBack"])
        tap(app.alerts.buttons["保存并退出"])
        XCTAssertEqual(app.buttons["level-1"].label, "E-001，已通关")
        tap(app.buttons["level-1"])
        tap(app.alerts.buttons["取消"])
        tap(app.buttons["level-1"])
        tap(app.alerts.buttons["替换并开始"])
        XCTAssertTrue(app.staticTexts["E-001"].waitForExistence(timeout: 8))
    }

    func testAdvancedHelpAndChapters() {
        let app = launch()
        tap(app.buttons["soloLevels"])
        tap(app.segmentedControls["soloBand"].buttons["进阶"])
        XCTAssertFalse(app.buttons["明白了,开始闯关"].exists)
        XCTAssertEqual(app.buttons["soloShortcut"].label, "开始闯关 · 简单第 1 关")
        XCTAssertEqual(app.buttons["level-101"].label, "A-001，未通关")
        XCTAssertFalse(app.buttons["level-101"].label.contains("bookmark"))
        screenshot(app, "进阶章节")
        tap(app.buttons["level-101"])
        tap(app.buttons["明白了,开始闯关"])
        XCTAssertTrue(app.staticTexts["A-001"].waitForExistence(timeout: 8))
        screenshot(app, "进阶棋盘")
        tap(app.buttons["gameBack"]); tap(app.alerts.buttons["保存并退出"])
        XCTAssertTrue(app.segmentedControls["soloBand"].buttons["进阶"].isSelected)
        tap(app.segmentedControls["soloBand"].buttons["简单"])
        XCTAssertEqual(app.buttons["soloShortcut"].label, "继续闯关 · 进阶第 1 关")
        tap(app.buttons["soloShortcut"])
        XCTAssertTrue(app.staticTexts["A-001"].waitForExistence(timeout: 8))
        tap(app.buttons["gameBack"]); tap(app.alerts.buttons["保存并退出"])
        XCTAssertTrue(app.segmentedControls["soloBand"].buttons["进阶"].isSelected)
    }

    func testDuoDuplicateHandoffWinAndSwap() {
        let app = launch()
        tap(app.buttons["duo"])
        choose(app, [0, 0, 4, 2])
        XCTAssertFalse(app.buttons["handoff"].isEnabled)
        tap(app.buttons["密码第 2 格"])
        tap(app.buttons["color-3"])
        tap(app.buttons["handoff"])
        XCTAssertFalse(app.buttons["color-0"].exists)
        screenshot(app, "双人交接遮罩")
        tap(app.buttons["privacyContinue"])
        choose(app, [0, 3, 4, 2])
        tap(app.buttons["submit"])
        XCTAssertTrue(app.staticTexts["破译成功!"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["玩家 1: 0 分 · 玩家 2: 1 分"].exists)
        screenshot(app, "双人结算")
        tap(app.buttons["换边再来"])
        XCTAssertTrue(app.staticTexts["玩家 2 出题"].waitForExistence(timeout: 8))
    }

    func testFailureAnswerSetting() {
        let app = launch()
        scrollTo(app.buttons["settings"], in: app)
        screenshot(app, "首页底部设置入口")
        tap(app.buttons["settings"])
        let toggle = app.switches["answerSetting"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 8))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
        screenshot(app, "答案设置关闭")
        app.navigationBars.buttons.firstMatch.tap()
        scrollTo(app.buttons["settings"], in: app)
        screenshot(app, "首页底部设置入口")
        tap(app.buttons["settings"])
        XCTAssertEqual(app.switches["answerSetting"].value as? String, "0")
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["soloLevels"])
        tap(app.buttons["soloShortcut"])
        for _ in 0..<6 {
            choose(app, [1, 1, 1, 1]); tap(app.buttons["submit"])
            let enabled = NSPredicate(format: "enabled == true")
            if app.buttons["color-1"].exists {
                _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: app.buttons["color-1"])], timeout: 2)
            }
        }
        XCTAssertTrue(app.staticTexts["这次没猜中"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["查看答案"].exists)
    }
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, towardTop: Bool = false) {
        for _ in 0..<20 {
            if element.exists && element.isHittable { return }
            if towardTop { app.swipeDown() } else { app.swipeUp() }
        }
        XCTFail("无法滚动到目标元素")
    }

    func testFirstAndLastLevelsInBothModes() {
        let app = launch()
        tap(app.buttons["soloLevels"])
        scrollTo(app.buttons["level-100"], in: app)
        tap(app.buttons["level-100"])
        XCTAssertTrue(app.staticTexts["E-100"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["直接提示"].exists)
        tap(app.buttons["gameBack"]); tap(app.alerts.buttons["保存并退出"])
        XCTAssertTrue(app.segmentedControls["soloBand"].waitForExistence(timeout: 8))
        scrollTo(app.segmentedControls["soloBand"], in: app, towardTop: true)
        tap(app.segmentedControls["soloBand"].buttons["进阶"])
        let firstChapter = chapter(1, in: app)
        tap(firstChapter)
        let lastChapter = chapter(10, in: app)
        scrollTo(lastChapter, in: app); tap(lastChapter)
        scrollTo(app.buttons["level-600"], in: app); tap(app.buttons["level-600"])
        tap(app.alerts.buttons["替换并开始"])
        tap(app.buttons["明白了,开始闯关"])
        XCTAssertTrue(app.staticTexts["A-500"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["间接提示"].exists)
        screenshot(app, "进阶末关")
    }

    func testDuoBackgroundPauseAndPrivacy() {
        let app = launch()
        tap(app.buttons["duo"])
        choose(app, [0, 3, 4, 2])
        tap(app.buttons["handoff"])
        tap(app.buttons["privacyContinue"])
        choose(app, [1])
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["对局已暂停"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["color-0"].exists)
        screenshot(app, "双人后台恢复遮罩")
        tap(app.buttons["privacyContinue"])
        XCTAssertTrue(app.buttons["color-0"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.buttons["cell-0"].value as? String, "橙色,未选中")
    }

    func testDefaultFailureCanRevealAndRestore() {
        let store = UUID().uuidString
        var app = launch(store: store)
        tap(app.buttons["soloLevels"])
        tap(app.buttons["soloShortcut"])
        for _ in 0..<6 {
            choose(app, [1, 1, 1, 1]); tap(app.buttons["submit"])
        }
        tap(app.buttons["查看答案"])
        XCTAssertTrue(app.staticTexts["答案"].exists)
        app.terminate(); app = launch(store: store)
        tap(app.buttons["soloLevels"])
        XCTAssertEqual(app.buttons["soloShortcut"].label, "重试 · 简单第 1 关")
        tap(app.buttons["level-1"])
        XCTAssertTrue(app.staticTexts["答案"].waitForExistence(timeout: 8))
        screenshot(app, "失败后答案恢复")
        tap(app.buttons["选关"])
        tap(app.buttons["soloShortcut"])
        let cleared = NSPredicate(format: "value == %@", "空白,已选中")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: cleared, object: app.buttons["cell-0"])], timeout: 5), .completed)
        screenshot(app, "重开后棋盘")
    }

}
