import UIKit

struct Joke: Equatable {
	let text: String
}

protocol JokeLoader {
	typealias JokeResult = Result<Joke, Error>
	func loadNewJoke(completion: @escaping (JokeResult) -> Void)
}

final class RemoteJokeMapper {
	enum Error: Swift.Error {
		case invalidData
		case invalidResponse
		case invalidStatusCode
	}

	static func map(
		error: Swift.Error?,
		data: Data?,
		response: URLResponse?
	) -> JokeLoader.JokeResult {
		if let error = error {
			return .failure(error)
		} else {
			guard let data = data else {
				return .failure(Error.invalidData)
			}
			guard let response = response as? HTTPURLResponse else {
				return .failure(Error.invalidResponse)
			}
			guard response.statusCode >= 200 && response.statusCode < 300 else {
				return .failure(Error.invalidStatusCode)
			}

			return self.map(data: data)
		}
	}

	private static func map(
		data: Data
	) -> JokeLoader.JokeResult {
		do {
			let decoder = JSONDecoder()
			let joke = try decoder.decode(RemoteJoke.self, from: data)
			return .success(joke.asJoke)
		} catch {
			return .failure(error)
		}
	}

	private struct RemoteJoke: Codable {
		let value: String

		var asJoke: Joke {
			return Joke(text: self.value)
		}
	}
}

final class RemoteJokeLoader: JokeLoader {
	private let url: URL
	private let session: URLSession
	private var dataTask: URLSessionDataTask?

	init(
		url: URL = URL(string: "https://api.chucknorris.io/jokes/random")!,
		session: URLSession
	) {
		self.url = url
		self.session = session
	}

	func loadNewJoke(completion: @escaping (JokeResult) -> Void) {
		dataTask?.cancel()

		let request = URLRequest(url: url)
		dataTask = session.dataTask(with: request) { (data, response, error) in
			let result = RemoteJokeMapper.map(error: error, data: data, response: response)
			DispatchQueue.main.async {
				completion(result)
			}
		}

		dataTask?.resume()
	}
}

final class TextViewController: UIViewController {
    @IBOutlet private weak var textView: UITextView!
	private var jokeLoader: JokeLoader!
	var onDataLoad: (() -> Void)?

	static func loadFromStoryboard(
		jokeLoader: JokeLoader
	) -> TextViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: .main)
		return storyboard.instantiateViewController(
			identifier: "TextViewController",
			creator: { coder in
				return TextViewController(
					jokeLoader: jokeLoader,
					coder: coder
				)
			}
		)
	}

	init?(jokeLoader: JokeLoader, coder: NSCoder) {
		self.jokeLoader = jokeLoader
		super.init(coder: coder)
	}

	@available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
	
	@IBAction private func tappedLoad(_ sender: Any) {
		jokeLoader.loadNewJoke(completion: { result in
			switch result {
			case .success(let joke):
				self.textView.text = joke.text

			case .failure(let error):
				print(error)
				self.textView.text = ""
			}

			self.onDataLoad?()
		})
    }
}
