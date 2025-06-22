import SwiftUI
import AppKit

struct BuddyDock: View {
    let buddies: [Buddy]
    @Binding var openBuddies: Set<String>
    @Binding var currentBuddyID: String?
    @Binding var expanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable Buddy List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: expanded ? 45 : -12) {
                    ForEach(buddies, id: \.id) { buddy in
                        if !openBuddies.contains(buddy.id) || expanded {
                            Button(action: {
                                handleBuddyClick(buddy)
                            }) {
                                Image(buddy.avatar)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: expanded ? 70 : 50, height: expanded ? 70 : 50)
                                    .background(Color.clear)
                                    .cornerRadius(35)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 35)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(radius: 3)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 20) // Room for expand button
            }
            .frame(
                maxHeight: expanded ? CGFloat(min(buddies.count, 6)) * 85 : 150 // max visible stack
            )

            // Expand/Collapse Button (always visible)
            Button(action: {
                withAnimation { expanded.toggle() }
            }) {
                Image(systemName: expanded ? "chevron.down" : "chevron.up")
                    .padding(6)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .padding(.trailing, 6)
        .frame(minWidth: 80)
    }

    private func handleBuddyClick(_ buddy: Buddy) {
        print("Clicked: \(buddy.name)")
        if let currentID = currentBuddyID, currentID != buddy.id {
            let alert = NSAlert()
            alert.messageText = "Switch Buddy?"
            alert.informativeText = "Close \(currentID.capitalized) and open \(buddy.name)?"
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                BuddyWindowManager.shared.close(buddyID: currentID)
                BuddyWindowManager.shared.open(buddy: buddy)
                currentBuddyID = buddy.id
                openBuddies = [buddy.id]
            } else {
                BuddyWindowManager.shared.open(buddy: buddy)
                openBuddies.insert(buddy.id)
            }
        } else {
            BuddyWindowManager.shared.open(buddy: buddy)
            openBuddies.insert(buddy.id)
            currentBuddyID = buddy.id
        }
    }
}
