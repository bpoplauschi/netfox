import UIKit

final class RemoteJokeLoader {
	private let session: URLSession
	private var dataTask: URLSessionDataTask?

	init(session: URLSession) {
		self.session = session
	}

	func loadNewJoke(completion: @escaping (String?) -> Void) {
		dataTask?.cancel()

		guard let url = URL(string: "https://api.chucknorris.io/jokes/random") else { return }
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
		completion: @escaping (String?) -> Void
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
		completion: @escaping (String?) -> Void
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
						completion(message)
					} else {
						completion(nil)
					}
				} catch {
					completion(nil)
				}
			}
		}
	}

	func cancelLoad() {
		dataTask?.cancel()
	}
}

final class TextViewController: UIViewController {
    @IBOutlet private weak var textView: UITextView!
	private var jokeLoader: RemoteJokeLoader!
	var onDataLoad: (() -> Void)?

	static func loadFromStoryboard(
		jokeLoader: RemoteJokeLoader
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

	init?(jokeLoader: RemoteJokeLoader, coder: NSCoder) {
		self.jokeLoader = jokeLoader
		super.init(coder: coder)
	}

	@available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
	
	@IBAction private func tappedLoad(_ sender: Any) {
		jokeLoader.loadNewJoke(completion: { text in
			self.textView.text = text
			self.onDataLoad?()
		})
    }
}
