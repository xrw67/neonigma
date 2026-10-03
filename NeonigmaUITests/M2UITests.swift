import XCTest

@MainActor final class M2UITests: XCTestCase {
    private func launch(store: String = UUID().uuidString, skip: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-test-store", store] + (skip ? ["-skip-tutorial"] : [])
        app.launch()
        return app
    }
    private func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.exists || element.waitForExistence(timeout: 8))
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: element)], timeout: 5), .completed)
        element.tap()
    }
    private func choose(_ app: XCUIApplication, _ colors: [Int]) {
        for color in colors { tap(app.buttons["color-\(color)"]) }
    }
    private func screenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
        tap(app.buttons["settings"])
        tap(app.buttons["重放教程"])
        tap(app.buttons["跳过"])
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["continueGame"])
        XCTAssertTrue(app.buttons["cell-0"].value as? String == "黄色,未选中")
    }

    func testSaveAcrossRelaunchAndRestart() {
        let store = UUID().uuidString
        var app = launch(store: store)
        tap(app.buttons["continueGame"])
        choose(app, [0, 1])
        app.terminate()
        app = launch(store: store)
        tap(app.buttons["continueGame"])
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
        tap(app.buttons["easyLevels"])
        tap(app.buttons["level-1"])
        choose(app, [6, 3, 0, 4])
        tap(app.buttons["submit"])
        XCTAssertTrue(app.staticTexts["破译成功!"].waitForExistence(timeout: 8))
        screenshot(app, "单人成功结算")
        tap(app.buttons["nextLevel"])
        XCTAssertTrue(app.staticTexts["E-002"].waitForExistence(timeout: 8))
        tap(app.buttons["gameBack"])
        tap(app.alerts.buttons["保存并退出"])
        tap(app.buttons["level-1"])
        tap(app.alerts.buttons["取消"])
        tap(app.buttons["level-1"])
        tap(app.alerts.buttons["替换并开始"])
        XCTAssertTrue(app.staticTexts["E-001"].waitForExistence(timeout: 8))
    }

    func testAdvancedHelpAndChapters() {
        let app = launch()
        tap(app.buttons["advancedLevels"])
        screenshot(app, "进阶章节")
        tap(app.buttons["level-101"])
        tap(app.buttons["明白了,开始闯关"])
        XCTAssertTrue(app.staticTexts["A-001"].waitForExistence(timeout: 8))
        screenshot(app, "进阶棋盘")
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
        tap(app.buttons["settings"])
        let toggle = app.switches["answerSetting"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 8))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
        screenshot(app, "答案设置关闭")
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["settings"])
        XCTAssertEqual(app.switches["answerSetting"].value as? String, "0")
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["continueGame"])
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
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<20 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("无法滚动到目标元素")
    }

    func testFirstAndLastLevelsInBothModes() {
        let app = launch()
        tap(app.buttons["easyLevels"])
        scrollTo(app.buttons["level-100"], in: app)
        tap(app.buttons["level-100"])
        XCTAssertTrue(app.staticTexts["E-100"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["直接提示"].exists)
        tap(app.buttons["gameBack"]); tap(app.alerts.buttons["保存并退出"])
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["advancedLevels"])
        let firstChapter = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "第 1 章")).firstMatch
        tap(firstChapter)
        let lastChapter = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "第 10 章")).firstMatch
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
        tap(app.buttons["continueGame"])
        for _ in 0..<6 {
            choose(app, [1, 1, 1, 1]); tap(app.buttons["submit"])
        }
        tap(app.buttons["查看答案"])
        XCTAssertTrue(app.staticTexts["答案"].exists)
        app.terminate(); app = launch(store: store)
        tap(app.buttons["continueGame"])
        XCTAssertTrue(app.staticTexts["答案"].waitForExistence(timeout: 8))
        screenshot(app, "失败后答案恢复")
        tap(app.buttons["重试本关"])
        let cleared = NSPredicate(format: "value == %@", "空白,已选中")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: cleared, object: app.buttons["cell-0"])], timeout: 5), .completed)
        screenshot(app, "重开后棋盘")
    }

}
