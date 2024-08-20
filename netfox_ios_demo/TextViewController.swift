import UIKit

final class TextViewController: UIViewController {
    @IBOutlet private weak var textView: UITextView!
	private var session: URLSession!
	private var dataTask: URLSessionDataTask?
	var onDataLoad: (() -> Void)?

	static func loadFromStoryboard(session: URLSession) -> TextViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: .main)
		return storyboard.instantiateViewController(
			identifier: "TextViewController",
			creator: { coder in
				return TextViewController(session: session, coder: coder)
			}
		)
	}

	init?(session: URLSession, coder: NSCoder) {
		self.session = session
		super.init(coder: coder)
	}

	@available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
	
	@IBAction private func tappedLoad(_ sender: Any) {
        dataTask?.cancel()

        guard let url = URL(string: "https://api.chucknorris.io/jokes/random") else { return }
        let request = URLRequest(url: url)
        dataTask = session.dataTask(with: request) { (data, response, error) in
			self.handleLoadResponse(error, data, response)
        }
        
        dataTask?.resume()
    }

	private func handleLoadResponse(_ error: Error?, _ data: Data?, _ response: URLResponse?) {
		if let error = error {
			self.handleCompletion(error: error.localizedDescription, data: data)
		} else {
			guard let data = data else { self.handleCompletion(error: "Invalid data", data: nil); return }
			guard let response = response as? HTTPURLResponse else { self.handleCompletion(error: "Invalid response", data: data); return }
			guard response.statusCode >= 200 && response.statusCode < 300 else { self.handleCompletion(error: "Invalid response code", data: data); return }

			self.handleCompletion(error: error?.localizedDescription, data: data)
		}
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

	func cancelLoad() {
		dataTask?.cancel()
	}
}

extension TextViewController : URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
    }
}

