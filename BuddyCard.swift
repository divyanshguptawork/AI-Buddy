import SwiftUI

struct BuddyCard: View {
    let buddy: Buddy
    let onClose: () -> Void

    @State private var expanded: Bool = false
    @State private var showCameraOverlay = false
    @State private var messages: [String] = [
        "Hello from \(UUID().uuidString.prefix(4))!",  // Placeholder so layout doesn't break
        "This card will be interactive in Step 3."
    ]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(buddy.avatar)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())

                    Text(buddy.name)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "mic.fill").foregroundColor(.white)

                        Button(action: {
                            withAnimation {
                                showCameraOverlay.toggle()
                            }
                        }) {
                            Image(systemName: showCameraOverlay ? "video.slash.fill" : "video.fill")
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            BuddyMessenger.shared.unregister(buddyID: buddy.id)
                            onClose()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.purple)

                // Scrollable Message Bubbles
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages, id: \.self) { message in
                            Text(message)
                                .padding(8)
                                .background(Color.blue.opacity(0.7))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity)

                // Webcam Overlay (Dummy)
                if showCameraOverlay {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .overlay(Text("📷 Dummy Webcam").foregroundColor(.white))
                        .cornerRadius(8)
                        .frame(height: 120)
                        .padding(.horizontal)
                        .transition(.opacity)
                }

                // Expand Button
                Button(action: {
                    withAnimation {
                        expanded.toggle()
                    }
                }) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.up")
                        .padding(8)
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .cornerRadius(15)
            .shadow(radius: 6)
        }
        .onAppear {
            registerWithMessenger()
        }
    }

    // Register this buddy to receive messages from the AI engine
    private func registerWithMessenger() {
        BuddyMessenger.shared.register(buddyID: buddy.id) { newMessage in
            DispatchQueue.main.async {
                messages.append(newMessage)
            }
        }
    }
}
