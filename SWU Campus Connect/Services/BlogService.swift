import Foundation
import FirebaseFirestore

class BlogService {
    static let shared = BlogService()
    private let db = Firestore.firestore()
    private let collection = "posts"
    
    private init() {}
    
    func fetchPosts(completion: @escaping (Result<[BlogPost], Error>) -> Void) {
        db.collection(collection)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let posts = documents.compactMap { doc -> BlogPost? in
                    try? doc.data(as: BlogPost.self)
                }
                completion(.success(posts))
            }
    }
    
    func createPost(content: String, author: User, completion: @escaping (Error?) -> Void) {
        let newPost = BlogPost(
            id: UUID().uuidString,
            content: content,
            authorId: author.id,
            authorName: author.displayName,
            timestamp: Date(),
            likes: 0,
            likedBy: [],
            commentCount: 0
        )
        
        do {
            try db.collection(collection).document(newPost.id).setData(from: newPost) { error in
                if let error = error {
                    print("Error creating post: \(error.localizedDescription)")
                } else {
                    print("Post created successfully!")
                }
                completion(error)
            }
        } catch {
            print("Error encoding post: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    func toggleLike(post: BlogPost, userId: String, completion: @escaping (Error?) -> Void) {
        let postRef = db.collection(collection).document(post.id)
        
        if post.likedBy.contains(userId) {

            postRef.updateData([
                "likes": FieldValue.increment(Int64(-1)),
                "likedBy": FieldValue.arrayRemove([userId])
            ]) { error in
                completion(error)
            }
        } else {

            postRef.updateData([
                "likes": FieldValue.increment(Int64(1)),
                "likedBy": FieldValue.arrayUnion([userId])
            ]) { error in
                completion(error)
            }
        }
    }
    
    // MARK: - Comments
    
    func addComment(postId: String, content: String, author: User, completion: @escaping (Error?) -> Void) {
        let newComment = Comment(
            id: UUID().uuidString,
            content: content,
            authorId: author.id,
            authorName: author.displayName,
            timestamp: Date()
        )
        
        let postRef = db.collection(collection).document(postId)
        let commentsRef = postRef.collection("comments")
        
        do {
            try commentsRef.document(newComment.id).setData(from: newComment) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                postRef.updateData([
                    "commentCount": FieldValue.increment(Int64(1))
                ]) { error in
                    completion(error)
                }
            }
        } catch {
            completion(error)
        }
    }
    
    func fetchComments(postId: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        db.collection(collection).document(postId).collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let comments = documents.compactMap { doc -> Comment? in
                    try? doc.data(as: Comment.self)
                }
                completion(.success(comments))
            }
    }
    
    // MARK: - Post Management
    
    func deletePost(postId: String, completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(postId).delete { error in
            completion(error)
        }
    }
    
    func updatePost(postId: String, newContent: String, completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(postId).updateData([
            "content": newContent
        ]) { error in
            completion(error)
        }
    }
    
    func deleteComment(postId: String, commentId: String, completion: @escaping (Error?) -> Void) {
        let postRef = db.collection(collection).document(postId)
        let commentRef = postRef.collection("comments").document(commentId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.deleteDocument(commentRef)
            transaction.updateData(["commentCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
            
            return nil
        }) { (_, error) in
            completion(error)
        }
    }
}
