import SwiftUI
import FirebaseAuth

struct CommentsView: View {
    @StateObject private var viewModel: CommentsViewModel
    @State private var newCommentContent = ""
    @FocusState private var isInputFocused: Bool
    
    init(post: BlogPost) {
        _viewModel = StateObject(wrappedValue: CommentsViewModel(post: post))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Original Post
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.post.authorName)
                                    .font(.headline)
                                Text(viewModel.post.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        Text(viewModel.post.content)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.white)
                    
                    Divider()
                    
                    // Comments List
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 20)
                    } else if viewModel.comments.isEmpty {
                        Text("No comments yet. Be the first!")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.comments) { comment in
                            CommentRow(comment: comment, postAuthorId: viewModel.post.authorId, viewModel: viewModel)
                            Divider()
                        }
                    }
                }
            }
            
            // Input Area
            VStack(spacing: 0) {
                Divider()
                
                if AuthService.shared.isGuest {
                    // Guest Message
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        Text("Log in to comment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                } else {
                    // Input Field
                    HStack(alignment: .bottom, spacing: 12) {
                        TextField("Add a comment...", text: $newCommentContent, axis: .vertical)
                            .focused($isInputFocused)
                            .lineLimit(1...5)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(20)
                        
                        Button(action: {
                            if !newCommentContent.isEmpty {
                                viewModel.addComment(content: newCommentContent)
                                newCommentContent = ""
                                isInputFocused = false
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(newCommentContent.isEmpty ? Color.gray : Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(newCommentContent.isEmpty)
                    }
                    .padding()
                }
            }
            .padding(.bottom, 60) // Clear custom tab bar
            .background(Color.white)
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

struct CommentRow: View {
    let comment: Comment
    let postAuthorId: String
    @ObservedObject var viewModel: CommentsViewModel
    @State private var showingDeleteAlert = false
    @State private var showingReportAlert = false
    @State private var showingBlockAlert = false
    
    var isCommentOwner: Bool {
        guard let currentUserId = AuthService.shared.userSession?.uid else { return false }
        return comment.authorId == currentUserId
    }
    
    var isPostOwner: Bool {
        guard let currentUserId = AuthService.shared.userSession?.uid else { return false }
        return postAuthorId == currentUserId
    }
    
    var canDelete: Bool {
        return isCommentOwner || isPostOwner
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.authorName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Menu
                Menu {
                    if canDelete {
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    
                    if !isCommentOwner {
                        Button(action: {
                            showingReportAlert = true
                        }) {
                            Label("Report", systemImage: "exclamationmark.bubble")
                        }
                        
                        Button(role: .destructive, action: {
                            showingBlockAlert = true
                        }) {
                            Label("Block User", systemImage: "hand.raised.slash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(8)
                }
                .opacity(AuthService.shared.isGuest ? 0 : 1)
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.white)
        .alert("Delete Comment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteComment(comment: comment)
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .alert("Report Comment", isPresented: $showingReportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Report", role: .destructive) {
                // Implement report logic in ViewModel if needed, or use generic report
            }
        } message: {
            Text("Are you sure you want to report this comment?")
        }
        .alert("Block User", isPresented: $showingBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                // Implement block logic
            }
        } message: {
            Text("Are you sure you want to block this user?")
        }
    }
}
