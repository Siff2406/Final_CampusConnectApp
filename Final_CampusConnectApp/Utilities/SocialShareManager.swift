import SwiftUI
import UIKit

class SocialShareManager {
    static let shared = SocialShareManager()
    
    private init() {}
    
    func shareEventToInstagramStory(event: Event, view: UIView) {
        guard let storiesUrl = URL(string: "instagram-stories://share?source_application=com.campusconnect.app") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(storiesUrl) {
            // Load image first
            Task {
                var eventImage: UIImage? = nil
                
                if let url = URL(string: event.imageUrl) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        eventImage = UIImage(data: data)
                    } catch {
                        print("Error loading image for sharing: \(error)")
                    }
                }
                
                // Render on Main Actor
                await MainActor.run {
                    let renderer = ImageRenderer(content: ShareEventCard(event: event, eventImage: eventImage))
                    
                    if let windowScene = view.window?.windowScene {
                        renderer.scale = windowScene.screen.scale
                    } else {
                        renderer.scale = view.traitCollection.displayScale > 0 ? view.traitCollection.displayScale : 2.0
                    }
                    
                    if let image = renderer.uiImage {
                        guard let imageData = image.pngData() else { return }
                        
                        let pasteboardItems: [String: Any] = [
                            "com.instagram.sharedSticker.backgroundImage": imageData,
                            "com.instagram.sharedSticker.backgroundTopColor": "#FFFFFF",
                            "com.instagram.sharedSticker.backgroundBottomColor": "#FFFFFF"
                        ]
                        
                        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
                            .expirationDate: Date().addingTimeInterval(60 * 5)
                        ]
                        
                        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
                        UIApplication.shared.open(storiesUrl)
                    }
                }
            }
        } else {
            print("Instagram is not installed.")
            shareViaActivityController(event: event, view: view)
        }
    }
    
    private func shareViaActivityController(event: Event, view: UIView) {
        let text = "Check out this event: \(event.title) at \(event.location)!"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            var topController = rootVC
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(activityVC, animated: true)
        }
    }
}

struct ShareEventCard: View {
    let event: Event
    let eventImage: UIImage?
    
    var body: some View {
        ZStack {
            // Background Image (Blurred)
            if let image = eventImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 1080/3, height: 1920/3)
                    .blur(radius: 20)
                    .overlay(Color.black.opacity(0.3))
            } else {
                Color.swuRed.opacity(0.8)
                    .frame(width: 1080/3, height: 1920/3)
            }
            
            VStack(spacing: 20) {
                // Main Image
                if let image = eventImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 280)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .frame(width: 280, height: 280)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }
                
                VStack(spacing: 10) {
                    Text(event.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
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
