import SwiftUI
import FirebaseAuth

struct BlogFeedView: View {
    @StateObject private var viewModel = BlogViewModel()
    @State private var newPostContent = ""
    @FocusState private var isInputFocused: Bool
    @State private var showingPostConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                     
                    HStack {
                        Text("SWU Talk")
                            .font(.system(size: 28, weight: .bold))  
                            .foregroundColor(.swuTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(Color(.systemGroupedBackground))
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                             
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    if let profileUrl = AuthService.shared.currentUser?.profileImageUrl,
                                       !profileUrl.isEmpty {
                                        CachedAsyncImage(url: profileUrl) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                        }
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        TextField("What's on your mind?", text: $newPostContent, axis: .vertical)
                                            .focused($isInputFocused)
                                            .lineLimit(1...5)
                                            .padding(10)
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(12)
                                        
                                        if isInputFocused || !newPostContent.isEmpty {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    if !newPostContent.isEmpty {
                                                        showingPostConfirmation = true
                                                    }
                                                }) {
                                                    Text("Post")
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 8)
                                                        .background(newPostContent.isEmpty ? Color.gray : Color.swuRed)  
                                                        .cornerRadius(20)
                                                }
                                                .disabled(newPostContent.isEmpty || AuthService.shared.isGuest)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                            
                             
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.top, 20)
                            } else {
                                ForEach(viewModel.posts) { post in
                                    BlogPostCard(post: post, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(.bottom, 100)  
                    }
                    .refreshable {
                        viewModel.fetchPosts()
                    }
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                isInputFocused = false
            }
            .alert("Post Confirmation", isPresented: $showingPostConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Post", role: .none) {
                    viewModel.createPost(content: newPostContent)
                    newPostContent = ""
                    isInputFocused = false
                }
            } message: {
                Text("Are you sure you want to post this?")
            }
        }
    }
}

struct BlogPostCard: View {
    let post: BlogPost
    @ObservedObject var viewModel: BlogViewModel
    @State private var showingEditSheet = false
    @State private var editContent = ""
    @State private var showingDeleteAlert = false
    @State private var showingReportAlert = false
    @State private var showingBlockAlert = false
    @State private var authorProfile: User?

    var isLiked: Bool {
        guard let userId = AuthService.shared.currentUser?.id else { return false }
        return post.likedBy.contains(userId)
    }
    
    var isOwner: Bool {
        guard let userId = AuthService.shared.userSession?.uid else { return false }
        return post.authorId == userId
    }
    
    var isGuest: Bool {
        return AuthService.shared.isGuest
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
             
            HStack {
                if let profileUrl = authorProfile?.profileImageUrl {
                    CachedAsyncImage(url: profileUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.headline)
                    Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.swuTextSecondary)  
                }
                
                Spacer()
                
                 
                 
                Menu {
                    if isOwner {
                        Button(action: {
                            editContent = post.content
                            showingEditSheet = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
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
                        .foregroundColor(.gray)
                        .padding(8)
                }
                .opacity(isGuest ? 0 : 1)
            }
            
             
            Text(post.content)
                .font(.body)
                .foregroundColor(.swuTextPrimary)  
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
             
            HStack(spacing: 20) {
                 
                Button(action: {
                    viewModel.toggleLike(post: post)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .swuRed : .swuTextSecondary)  
                        Text("\(post.likes)")
                            .font(.subheadline)
                            .foregroundColor(.swuTextSecondary)  
                    }
                }
                .disabled(isGuest)
                
                Spacer()
                
                 
                NavigationLink(destination: CommentsView(post: post)) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                        Text("\(post.commentCount)")  
                            .font(.subheadline)
                    }
                    .foregroundColor(.swuTextSecondary)  
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deletePost(post: post)
            }
        } message: {
            Text("Are you sure you want to delete this post?")
        }
        .alert("Report Post", isPresented: $showingReportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Report", role: .destructive) {
                viewModel.reportPost(post: post, reason: "Inappropriate Content")
            }
        } message: {
            Text("Are you sure you want to report this post?")
        }
        .alert("Block User", isPresented: $showingBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                viewModel.blockUser(userId: post.authorId)
            }
        } message: {
            Text("Are you sure you want to block this user? You won't see their posts anymore.")
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                VStack {
                    Text("Edit Post")
                        .font(.headline)
                        .padding()
                    
                    TextField("Content", text: $editContent, axis: .vertical)
                        .lineLimit(5...10)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding()
                    
                    Spacer()
                }
                .navigationBarItems(
                    leading: Button("Cancel") { showingEditSheet = false },
                    trailing: Button("Save") {
                        viewModel.updatePost(post: post, newContent: editContent)
                        showingEditSheet = false
                    }
                    .disabled(editContent.isEmpty)
                )
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            Task {
                authorProfile = try? await FirebaseService.shared.fetchUserProfile(userId: post.authorId)
            }
        }
    }
}
