import SwiftUI

struct UserManagementView: View {
    @StateObject private var viewModel = UserManagementViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search by email...", text: $viewModel.searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            if let success = viewModel.successMessage {
                Text(success)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding()
                    .onAppear {
                        // Clear message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            viewModel.successMessage = nil
                        }
                    }
            }
            
            List {
                ForEach(viewModel.users) { user in
                    UserRow(user: user, onPromote: {
                        viewModel.promoteToAdmin(user: user)
                    }, onDemote: {
                        viewModel.demoteToNormal(user: user)
                    })
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Manage Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UserRow: View {
    let user: User
    let onPromote: () -> Void
    let onDemote: () -> Void
    
    var body: some View {
        HStack {
            // Avatar
            if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty {
                CachedAsyncImage(url: imageUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.2))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if user.role == .admin {
                Button(action: onDemote) {
                    Text("Demote")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            } else {
                Button(action: onPromote) {
                    Text("Promote")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
