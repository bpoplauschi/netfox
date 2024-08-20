//
//  RemoteJokeLoaderTests.swift
//  netfox_ios_demo_tests
//
//  Created by Bogdan on 20.08.2024.
//  Copyright © 2024 kasketis. All rights reserved.
//

@testable import netfox_ios_demo
import XCTest

final class RemoteJokeLoaderTests: XCTestCase {
	func test_loadNewJoke_onSuccess() {
		let sut = makeSUT()
		let exp = expectation(description: "Wait for completion")

		sut.loadNewJoke(completion: { result in
			guard let result else {
				XCTFail("Missing result")
				return
			}
			XCTAssertFalse(result.isEmpty)
			exp.fulfill()
		})

		wait(for: [exp], timeout: 1.0)
	}

	func test_loadNewJoke_onCancel() {
		let sut = makeSUT()
		let exp = expectation(description: "Wait for completion")

		sut.loadNewJoke(completion: { result in
			XCTAssertNil(result)
			exp.fulfill()
		})
		sut.cancelLoad()

		wait(for: [exp], timeout: 1.0)
	}

	private func makeSUT() -> RemoteJokeLoader {
		let session = URLSession(configuration: .ephemeral)
		return RemoteJokeLoader(session: session)
	}
}
