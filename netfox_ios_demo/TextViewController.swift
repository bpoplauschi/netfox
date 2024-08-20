import UIKit

struct Joke {
	let text: String
}

protocol JokeLoader {
	func loadNewJoke(completion: @escaping (Joke?) -> Void)
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

	func loadNewJoke(completion: @escaping (Joke?) -> Void) {
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
		completion: @escaping (Joke?) -> Void
	) {
		if let error = error {
			self.handleError(error: error.localizedDescription, completion: completion)
		} else {
			guard let data = data else { self.handleError(error: "Invalid data", completion: completion); return }
			guard let response = response as? HTTPURLResponse else { self.handleError(error: "Invalid response", completion: completion); return }
			guard response.statusCode >= 200 && response.statusCode < 300 else { self.handleError(error: "Invalid response code", completion: completion); return }

			self.handleSuccess(data: data, completion: completion)
		}
	}

	private func handleError(
		error: String,
		completion: @escaping (Joke?) -> Void
	) {
		DispatchQueue.main.async {
			NSLog(error)
			completion(nil)
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
		completion: @escaping (Joke?) -> Void
	) {
		do {
			let decoder = JSONDecoder()
			let joke = try decoder.decode(RemoteJoke.self, from: data)
			DispatchQueue.main.async {
				completion(joke.asJoke)
			}
		} catch {
			DispatchQueue.main.async {
				completion(nil)
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
		jokeLoader.loadNewJoke(completion: { joke in
			self.textView.text = joke?.text
			self.onDataLoad?()
		})
    }
}
