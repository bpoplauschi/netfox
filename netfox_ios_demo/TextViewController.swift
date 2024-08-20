import UIKit

final class RemoteJokeLoader {
	private var session: URLSession
	private var dataTask: URLSessionDataTask?

	init(session: URLSession) {
		self.session = session
	}

	func loadNewJoke(completion: @escaping (_ error: String?, _ data: Data?) -> Void) {
		dataTask?.cancel()

		guard let url = URL(string: "https://api.chucknorris.io/jokes/random") else { return }
		let request = URLRequest(url: url)
		dataTask = session.dataTask(with: request) { (data, response, error) in
			self.handleLoadResponse(error, data, response, completion: completion)
		}

		dataTask?.resume()
	}

	private func handleLoadResponse(
		_ error: Error?,
		_ data: Data?,
		_ response: URLResponse?,
		completion: @escaping (_ error: String?, _ data: Data?) -> Void
	) {
		if let error = error {
			completion(error.localizedDescription, data)
		} else {
			guard let data = data else { completion("Invalid data", nil); return }
			guard let response = response as? HTTPURLResponse else { completion("Invalid response", data); return }
			guard response.statusCode >= 200 && response.statusCode < 300 else { completion("Invalid response code", data); return }

			completion(error?.localizedDescription, data)
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
		jokeLoader.loadNewJoke(completion: self.handleCompletion(error:data:))
    }

    private func handleCompletion(error: String?, data: Data?) {
        DispatchQueue.main.async {
            
            if let error = error {
                NSLog(error)
				self.onDataLoad?()
                return
            }
            
            if let data = data {
                do {
                    let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let message = dict?["value"] as? String {
                        self.textView.text = message
						self.onDataLoad?()
                    }
                } catch {
                    
                }
            }
        }
    }
}
