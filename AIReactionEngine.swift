import Foundation

class AIReactionEngine {
    static let shared = AIReactionEngine()

    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String else {
            fatalError("GEMINI_API_KEY not found in Secrets.plist")
        }
        return key
    }()

    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
    private var lastFingerprint: String?
    private var lastResponse: String?

    /// Generates a lightweight signature for screen text to detect changes.
    private func fingerprint(_ text: String) -> String {
        return String(text.prefix(350)).lowercased().filter { !$0.isWhitespace }
    }

    func analyze(screenText: String, completion: @escaping (String, String) -> Void) {
        let currentFingerprint = fingerprint(screenText)

        // Skip if screen hasn't changed meaningfully
        if currentFingerprint == lastFingerprint {
            print("Skipped reaction (same screen).")
            return
        }

        lastFingerprint = currentFingerprint

        let prompt = """
        You're a productivity buddy. Based on the following screen contents, write ONE message in this format:

        BUDDY_ID: message

        • BUDDY_ID must be one of: leo, zenbunny, spacecat
        • Message should be smart, short, and relevant.
        • If the user is focused (like coding or reading docs), respond nicely.
        • If they’re procrastinating (e.g., YouTube or memes), respond with humor or sarcasm.
        • NEVER repeat the same message twice in a row, or give the same message with different grammar or punctuation or order.
        • Don’t respond if you can't find anything relevant.

        Screen:
        \"\"\"
        \(screenText)
        \"\"\"
        """

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [
                    ["text": prompt]
                ]]
            ]
        ]

        guard let url = URL(string: "\(endpoint)?key=\(apiKey)"),
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Invalid Gemini request setup")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = result["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                print("Failed to parse Gemini response")
                return
            }

            // Parse response
            let components = text.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            if components.count == 2 {
                let buddyID = components[0]
                let message = components[1]

                // Prevent identical duplicate responses
                guard message != self.lastResponse else {
                    print("Skipped duplicate message.")
                    return
                }

                self.lastResponse = message
                DispatchQueue.main.async {
                    completion(buddyID, message)
                }
            }

            else {
                print("Unexpected Gemini response format: \(text)")
            }
        }

        task.resume()
    }
}
