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
	override func setUp() {
		super.setUp()

		URLProtocolStub.removeStub()
	}

	override func tearDown() {
		super.tearDown()

		URLProtocolStub.removeStub()
	}

	func test_loadNewJoke_onAllEmptyValues() {
		let sut = makeSUT()

		let result = loadNewJokeResultFor((data: nil, response: nil, error: nil), sut: sut)

		XCTAssertNil(result)
	}

	func test_loadNewJoke_onError() {
		let sut = makeSUT()

		let result = loadNewJokeResultFor((data: nil, response: nil, error: NSError(domain: "", code: 0)), sut: sut)

		XCTAssertNil(result)
	}

	func test_loadNewJoke_onHTTPSuccessWithoutData() {
		let sut = makeSUT()

		let result = loadNewJokeResultFor((data: nil, response: httpResponse(statusCode: 200), error: nil), sut: sut)

		XCTAssertNil(result)
	}

	func test_loadNewJoke_onInvalidResponse() {
		let sut = makeSUT()

		let result = loadNewJokeResultFor((data: "any joke".data(using: .utf8), response: URLResponse(), error: nil), sut: sut)

		XCTAssertNil(result)
	}

	func test_loadNewJoke_onHTTPNotSuccessCode() {
		[0, 199, 300, 400, 401, 500, 505].forEach { statusCode in
			let sut = makeSUT()
			let jsonString = "{\"value\": \"any joke\"}"

			let result = loadNewJokeResultFor((data: jsonString.data(using: .utf8), response: httpResponse(statusCode: statusCode), error: nil), sut: sut)

			XCTAssertNil(result)
		}
	}

	func test_loadNewJoke_onHTTPSuccessButNotJSON() {
		let sut = makeSUT()

		let result = loadNewJokeResultFor((data: "any joke".data(using: .utf8), response: httpResponse(statusCode: 200), error: nil), sut: sut)

		XCTAssertNil(result)
	}

	func test_loadNewJoke_onHTTPSuccessWithJSONButMissingValueKey() {
		let sut = makeSUT()
		let jsonString = "{\"other key\": \"any joke\"}"

		let result = loadNewJokeResultFor((data: jsonString.data(using: .utf8), response: httpResponse(statusCode: 200), error: nil), sut: sut)

		XCTAssertNil(result)
	}

	func test_loadNewJoke_onSuccess() {
		let sut = makeSUT()
		let jsonString = "{\"value\": \"any joke\"}"

		let result = loadNewJokeResultFor((data: jsonString.data(using: .utf8), response: httpResponse(statusCode: 200), error: nil), sut: sut)

		XCTAssertEqual(result?.text, "any joke")
	}

	private func loadNewJokeResultFor(
		_ values: (data: Data?, response: URLResponse?, error: Error?)?,
		sut: RemoteJokeLoader
	) -> Joke? {
		values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }

		let exp = expectation(description: "Wait for request")

		var receivedResult: Joke?

		sut.loadNewJoke(completion: { result in
			receivedResult = result
			exp.fulfill()
		})

		wait(for: [exp], timeout: 1.0)

		return receivedResult
	}

	private func makeSUT() -> RemoteJokeLoader {
		let configuration = URLSessionConfiguration.ephemeral
		configuration.protocolClasses = [URLProtocolStub.self]
		let session = URLSession(configuration: configuration)
		return RemoteJokeLoader(session: session)
	}
}

func anyURL() -> URL { URL(string: "http://any-url.com")! }

func httpResponse(statusCode: Int) -> HTTPURLResponse {
	HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [:])!
}
