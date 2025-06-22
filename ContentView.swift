import SwiftUI

struct ContentView: View {
    @State private var dragAmount = CGSize.zero
    @State private var windowPosition: CGPoint = CGPoint(x: 100, y: 100)
    @State private var currentWidth: CGFloat = 400
    @State private var currentHeight: CGFloat = 300

    @State private var buddies: [Buddy] = []
    @State private var openBuddies: Set<String> = []
    @State private var currentBuddyID: String? = nil
    @State private var expanded = false
    @State private var showCameraOverlay = false


    @State private var buddyPositions: [String: CGPoint] = [:]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Leo Pal's floating card
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    if showCameraOverlay {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .overlay(Text("📷 Dummy Webcam").foregroundColor(.white))
                            .cornerRadius(8)
                            .frame(height: 120)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                }
                .frame(width: currentWidth, height: currentHeight)
                .background(Color.clear)
                .cornerRadius(15)
                .shadow(radius: 10)
                .position(x: windowPosition.x, y: windowPosition.y)
                .gesture(DragGesture()
                    .onChanged { value in
                        self.dragAmount = value.translation
                    }
                    .onEnded { _ in
                        self.windowPosition = CGPoint(
                            x: windowPosition.x + dragAmount.width,
                            y: windowPosition.y + dragAmount.height
                        )
                        saveWindowPositionToFile()
                    }
                )
                .overlay(
                    VStack {
                        HStack {
                            Image("avatar1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            Text("Leo Pal")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            Spacer()
                            HStack {
                                Button(action: toggleCard) {
                                    Image(systemName: "mic.fill").foregroundColor(.white)
                                }
                                Button(action: toggleCard) {
                                    Image(systemName: "video.fill").foregroundColor(.white)
                                }
                                Button(action: toggleCard) {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)

                        ScrollView {
                            VStack(alignment: .leading) {
                                Text("Stretch alert! Leo's been curled up 2 h 17 m—time for a walk?")
                                Text("All quiet, light snoozing detected, logged nap 1633-1635, syncing to diary.")
                            }
                            .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                )
                .onAppear {
                    loadWindowPositionFromFile()
                    loadInitialBuddies()
                    BuddyWindowManager.shared.restoreOpenBuddies(buddies)

                    // TEMP AI test loop
                    Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                        ScreenOCR.shared.captureScreenAndExtractText { text in
                            print("OCR TEXT: \(text)")
                            AIReactionEngine.shared.analyze(screenText: text) { buddyID, message in
                                BuddyMessenger.shared.post(to: buddyID, message: message)
                            }
                        }
                    }
                }


                .onChange(of: geometry.size) { _ in
                    currentWidth = geometry.size.width
                    currentHeight = geometry.size.height
                }
            }

            //  Dock strip
            BuddyDock(
                buddies: buddies,
                openBuddies: $openBuddies,
                currentBuddyID: $currentBuddyID,
                expanded: $expanded
            )
        }
        .onChange(of: openBuddies) { _ in
            saveOpenBuddyIDs()
        }
    }

    private func toggleCard() {
        withAnimation {
            // Placeholder toggle logic
        }
    }
    
    private func loadInitialBuddies() {
        guard let url = Bundle.main.url(forResource: "buddies", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Buddy].self, from: data) else {
            print("Failed to load initial buddies.json")
            return
        }
        self.buddies = decoded
    }

    private func loadBuddies() {
        guard let url = Bundle.main.url(forResource: "buddies", withExtension: "json") else {
            print("buddies.json not found")
            return
        }

        DispatchQueue.global().async {
            let previousIDs = Set(self.buddies.map { $0.id })
            while true {
                if let data = try? Data(contentsOf: url),
                   let decoded = try? JSONDecoder().decode([Buddy].self, from: data) {
                    DispatchQueue.main.async {
                        let newIDs = Set(decoded.map { $0.id })
                        let difference = newIDs.subtracting(previousIDs)
                        if !difference.isEmpty {
                            self.buddies = decoded
                            print("New buddies loaded: \(difference)")
                        }
                    }
                }
                sleep(2)
            }
        }
    }



    private func saveWindowPositionToFile() {
        let position = ["x": windowPosition.x, "y": windowPosition.y]
        if let fileURL = getDocumentsDirectory()?.appendingPathComponent("windowPosition.json") {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: position, options: [])
                try jsonData.write(to: fileURL)
            } catch {
                print("Error saving position: \(error)")
            }
        }
    }

    private func loadWindowPositionFromFile() {
        if let fileURL = getDocumentsDirectory()?.appendingPathComponent("windowPosition.json"),
           let data = try? Data(contentsOf: fileURL),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: CGFloat],
           let x = dict["x"], let y = dict["y"] {
            windowPosition = CGPoint(x: x, y: y)
        }
    }

    private func saveBuddyPositions() {
        let data = buddyPositions.mapValues { ["x": $0.x, "y": $0.y] }
        if let url = getDocumentsDirectory()?.appendingPathComponent("buddyPositions.json"),
           let json = try? JSONSerialization.data(withJSONObject: data) {
            try? json.write(to: url)
        }
    }

    private func loadBuddyPositions() {
        if let url = getDocumentsDirectory()?.appendingPathComponent("buddyPositions.json"),
           let data = try? Data(contentsOf: url),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: [String: CGFloat]] {
            for (id, pos) in dict {
                if let x = pos["x"], let y = pos["y"] {
                    buddyPositions[id] = CGPoint(x: x, y: y)
                }
            }
        }
    }

    private func saveOpenBuddyIDs() {
        let idsArray = Array(openBuddies)
        if let fileURL = getDocumentsDirectory()?.appendingPathComponent("openBuddies.json") {
            do {
                let json = try JSONEncoder().encode(idsArray)
                try json.write(to: fileURL)
                print(" Open buddies saved")
            } catch {
                print("Error saving open buddy list: \(error.localizedDescription)")
            }
        }
    }

    private func loadOpenBuddyIDs() {
        if let fileURL = getDocumentsDirectory()?.appendingPathComponent("openBuddies.json"),
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            openBuddies = Set(decoded)
            currentBuddyID = decoded.last
            for id in decoded {
                if let buddy = buddies.first(where: { $0.id == id }) {
                    BuddyWindowManager.shared.open(buddy: buddy)
                }
            }
        }
    }

    private func getDocumentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
