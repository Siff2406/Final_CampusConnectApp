import SwiftUI
import UIKit
import Combine

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // เก็บได้สูงสุด 100 รูป
        cache.totalCostLimit = 1024 * 1024 * 100 // เก็บได้สูงสุด 100 MB
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var urlString: String?
    
    func load(from urlString: String) {
        self.urlString = urlString

        if let cachedImage = ImageCache.shared.get(forKey: urlString) {
            self.image = cachedImage
            return
        }

        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let loadedImage = UIImage(data: data) else { return }

                ImageCache.shared.set(loadedImage, forKey: urlString)
                
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } catch {
                print("Error loading image: \(urlString) -> \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    @StateObject private var loader = ImageLoader()
    let url: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    init(
        url: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loader.load(from: url)
        }
    }
}
