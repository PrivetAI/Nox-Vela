import SwiftUI

@main
struct NoxVelaApp: App {
    @State private var radioLinkReady: Bool? = nil
    private let radioSourceLink = "https://deepmines.org/click.php"
    private let radioCheckDomain = "privacypolicies.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = radioLinkReady {
                    if ready {
                        RadioWebPanel(urlString: radioSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RadioRootView()
                            .preferredColorScheme(.dark)
                    }
                } else {
                    RadioLoadingScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { checkRadioLink() }
                }
            }
        }
    }

    private func checkRadioLink() {
        guard let url = URL(string: radioSourceLink) else {
            radioLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = RadioRedirectTracker(checkDomain: radioCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    radioLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.radioCheckDomain) {
                    radioLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.radioCheckDomain) {
                    radioLinkReady = false; return
                }
                if error != nil {
                    radioLinkReady = false; return
                }
                radioLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if radioLinkReady == nil { radioLinkReady = false }
        }
    }
}

final class RadioRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
