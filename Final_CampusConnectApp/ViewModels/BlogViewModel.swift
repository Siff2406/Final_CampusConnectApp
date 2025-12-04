import Foundation
import Combine

class BlogViewModel: ObservableObject {
    @Published var posts: [BlogPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = BlogService.shared
    
    init() {
        fetchPosts()
    }
    
    func fetchPosts() {
        isLoading = true
        service.fetchPosts { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let posts):
                    self?.posts = posts
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func createPost(content: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        service.createPost(content: content, author: currentUser) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleLike(post: BlogPost) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            var updatedPost = posts[index]
            if updatedPost.likedBy.contains(currentUser.id) {
                updatedPost.likedBy.removeAll { $0 == currentUser.id }
                updatedPost.likes -= 1
            } else {
                updatedPost.likedBy.append(currentUser.id)
                updatedPost.likes += 1
            }
            posts[index] = updatedPost
        }
        
        service.toggleLike(post: post, userId: currentUser.id) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.fetchPosts()
                }
            }
        }
    }
    
    func deletePost(post: BlogPost) {
        service.deletePost(postId: post.id) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updatePost(post: BlogPost, newContent: String) {
        service.updatePost(postId: post.id, newContent: newContent) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func reportPost(post: BlogPost, reason: String) {
        Task {
            do {
                try await FirebaseService.shared.reportPost(postId: post.id, reason: reason)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func blockUser(userId: String) {
        Task {
            do {
                try await FirebaseService.shared.blockUser(userIdToBlock: userId)
                fetchPosts()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
