import UIKit

struct Joke: Equatable {
	let text: String
}

protocol JokeLoader {
	typealias JokeResult = Result<Joke, Error>
	func loadNewJoke(completion: @escaping (JokeResult) -> Void)
}

final class RemoteJokeLoader: JokeLoader {
	enum LoadError: Error {
		case invalidData
		case invalidResponse
		case invalidStatusCode
	}

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
			self.handleLoadResponse(
				error: error,
				data: data,
				response: response,
				completion: completion
			)
		}

		dataTask?.resume()
	}

	private func handleLoadResponse(
		error: Error?,
		data: Data?,
		response: URLResponse?,
		completion: @escaping (JokeResult) -> Void
	) {
		if let error = error {
			DispatchQueue.main.async {
				completion(.failure(error))
			}
		} else {
			guard let data = data else {
				DispatchQueue.main.async {
					completion(.failure(LoadError.invalidData))
				}
				return
			}
			guard let response = response as? HTTPURLResponse else {
				DispatchQueue.main.async {
					completion(.failure(LoadError.invalidResponse))
				}
				return
			}
			guard response.statusCode >= 200 && response.statusCode < 300 else {
				DispatchQueue.main.async {
					completion(.failure(LoadError.invalidStatusCode))
				}
				return
			}

			self.handleSuccess(data: data, completion: completion)
		}
	}

	private struct RemoteJoke: Codable {
		let value: String

		var asJoke: Joke {
			return Joke(text: self.value)
		}
	}

	private func handleSuccess(
		data: Data,
		completion: @escaping (JokeResult) -> Void
	) {
		do {
			let decoder = JSONDecoder()
			let joke = try decoder.decode(RemoteJoke.self, from: data)
			DispatchQueue.main.async {
				completion(.success(joke.asJoke))
			}
		} catch {
			DispatchQueue.main.async {
				completion(.failure(error))
			}
		}
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
