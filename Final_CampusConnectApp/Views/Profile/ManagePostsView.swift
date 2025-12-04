import SwiftUI

struct ManagePostsView: View {
    @StateObject private var viewModel = BlogViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No posts found")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else {
                List {
                    ForEach(viewModel.posts) { post in
                        VStack(alignment: .leading) {
                            Text(post.content)
                                .font(.headline)
                            Text(post.authorName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.deletePost(post: post)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Manage Posts")
        .onAppear {
            viewModel.fetchPosts()
        }
    }
}
