import Foundation
import Combine

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let post: BlogPost
    private let service = BlogService.shared
    
    init(post: BlogPost) {
        self.post = post
        fetchComments()
    }
    
    func fetchComments() {
        isLoading = true
        service.fetchComments(postId: post.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let comments):
                    self?.comments = comments
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addComment(content: String) {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        service.addComment(postId: post.id, content: content, author: currentUser) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteComment(comment: Comment) {
        service.deleteComment(postId: post.id, commentId: comment.id) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
