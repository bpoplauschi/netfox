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
			self.handleCompletion(error: error.localizedDescription, data: data, completion: completion)
		} else {
			guard let data = data else { self.handleCompletion(error: "Invalid data", data: nil, completion: completion); return }
			guard let response = response as? HTTPURLResponse else { self.handleCompletion(error: "Invalid response", data: data, completion: completion); return }
			guard response.statusCode >= 200 && response.statusCode < 300 else { self.handleCompletion(error: "Invalid response code", data: data, completion: completion); return }

			self.handleCompletion(error: error?.localizedDescription, data: data, completion: completion)
		}
	}

	private func handleCompletion(
		error: String?,
		data: Data?,
		completion: @escaping (Joke?) -> Void
	) {
		DispatchQueue.main.async {

			if let error = error {
				NSLog(error)
				completion(nil)
				return
			}

			if let data = data {
				do {
					let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]

					if let message = dict?["value"] as? String {
						completion(Joke(text: message))
					} else {
						completion(nil)
					}
				} catch {
					completion(nil)
				}
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
