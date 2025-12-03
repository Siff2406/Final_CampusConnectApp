import SwiftUI
import UIKit

class SocialShareManager {
    static let shared = SocialShareManager()
    
    private init() {}
    
    func shareEventToInstagramStory(event: Event, view: UIView) {
        // 1. Check if Instagram is installed
        guard let storiesUrl = URL(string: "instagram-stories://share?source_application=com.campusconnect.app") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(storiesUrl) {
            // 2. Generate Image from View
            let renderer = ImageRenderer(content: ShareEventCard(event: event))
            
            // Use window scene scale or fallback to main screen scale (silencing warning if needed, or use traitCollection)
            if let windowScene = view.window?.windowScene {
                renderer.scale = windowScene.screen.scale
            } else {
                renderer.scale = view.traitCollection.displayScale > 0 ? view.traitCollection.displayScale : 2.0
            }
            
            if let image = renderer.uiImage {
                // 3. Prepare Pasteboard Items
                guard let imageData = image.pngData() else { return }
                
                let pasteboardItems: [String: Any] = [
                    "com.instagram.sharedSticker.backgroundImage": imageData,
                    "com.instagram.sharedSticker.backgroundTopColor": "#FFFFFF",
                    "com.instagram.sharedSticker.backgroundBottomColor": "#FFFFFF"
                ]
                
                // 4. Set Pasteboard Options
                let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
                    .expirationDate: Date().addingTimeInterval(60 * 5)
                ]
                
                // 5. Copy to Pasteboard
                UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
                
                // 6. Open Instagram
                UIApplication.shared.open(storiesUrl)
            }
        } else {
            print("Instagram is not installed.")
            // Fallback: Share via standard ActivityViewController
            shareViaActivityController(event: event, view: view)
        }
    }
    
    private func shareViaActivityController(event: Event, view: UIView) {
        let text = "Check out this event: \(event.title) at \(event.location)!"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // Find the active window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            // If rootVC is presenting something, present from that instead
            var topController = rootVC
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(activityVC, animated: true)
        }
    }
}

// The View specifically designed for sharing
struct ShareEventCard: View {
    let event: Event
    
    var body: some View {
        ZStack {
            // Background Image (Blurred)
            AsyncImage(url: URL(string: event.imageUrl)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 1080/3, height: 1920/3) // 9:16 Aspect Ratio (Scaled down for rendering)
            .blur(radius: 20)
            .overlay(Color.black.opacity(0.3))
            
            // Content Card
            VStack(spacing: 20) {
                // Event Image
                AsyncImage(url: URL(string: event.imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 280, height: 280)
                .cornerRadius(20)
                .shadow(radius: 10)
                
                VStack(spacing: 10) {
                    Text(event.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(event.location)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                
                // App Branding
                HStack {
                    Image(systemName: "graduationcap.fill")
                    Text("Campus Connect")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.top, 20)
            }
            .padding()
        }
        .frame(width: 1080/3, height: 1920/3)
        .background(Color.black)
    }
}
