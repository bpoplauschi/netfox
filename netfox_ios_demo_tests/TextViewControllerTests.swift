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
		let _ = try XCTUnwrap(sut.view.subviews.first(where: { $0 is UITextView }) as? UITextView)
	}

	// MARK: - Private

	private func makeSUT() -> TextViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: .main)
		let sut = storyboard.instantiateViewController(identifier: "TextViewController") as! TextViewController
		return sut
	}
}
