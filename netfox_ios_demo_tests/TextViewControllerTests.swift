//
//  TextViewControllerTests.swift
//  netfox_ios_demo_tests
//
//  Created by Bogdan on 19.08.2024.
//  Copyright © 2024 kasketis. All rights reserved.
//

@testable import netfox_ios_demo
import XCTest

final class TextViewControllerTests: XCTestCase {
	func test_init_doesNotCrash() {
		let _ = makeSUT()
	}

	func test_viewDidLoad_loadsViews() throws {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertNotNil(sut.view)
		let textView = try XCTUnwrap(sut.textView)
		XCTAssertEqual(textView.text, "", "Text")
		let loadButton = try XCTUnwrap(sut.loadButton)
		XCTAssertEqual(loadButton.title(for: .normal), "Tell me a joke", "Button title")
	}

	func test_loadButtonTap_onSuccess_setsText() throws {
		let sut = makeSUT()
		let exp = expectation(description: "Wait for data load completion")
		sut.onDataLoad = { exp.fulfill() }
		sut.loadViewIfNeeded()

		let loadButton = try XCTUnwrap(sut.loadButton)
		loadButton.simulateTap()

		wait(for: [exp], timeout: 2.0)
		let textView = try XCTUnwrap(sut.textView)
		XCTAssertNotEqual(textView.text, "", "A not empty text was set")
	}

	// MARK: - Private

	private func makeSUT() -> TextViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: .main)
		let sut = storyboard.instantiateViewController(identifier: "TextViewController") as! TextViewController
		return sut
	}
}

private extension TextViewController {
	var textView: UITextView? {
		return self.view.subviews.first(where: { $0.accessibilityIdentifier == "textView" }) as? UITextView
	}

	var loadButton: UIButton? {
		return self.view.subviews.first(where: { $0.accessibilityIdentifier == "loadButton" }) as? UIButton
	}
}

private extension UIButton {
	func simulateTap() {
		self.simulate(event: .touchUpInside)
	}
}

private extension UIControl {
	func simulate(event: UIControl.Event) {
		self.performAllTargetsAndActions(event: event)
	}

	private func performAllTargetsAndActions(event: UIControl.Event, with object: Any? = nil) {
		self.sendActions(for: event)
	}
}
