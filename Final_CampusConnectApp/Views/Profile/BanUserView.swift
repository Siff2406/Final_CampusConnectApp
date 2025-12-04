import SwiftUI

struct BanUserView: View {
    @StateObject private var viewModel = BanUserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
             
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search by name...", text: $viewModel.searchText)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            viewModel.successMessage = nil
                        }
                    }
            }
            
            List(viewModel.users) { user in
                HStack {
                     
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
                    
                    Button(action: {
                        viewModel.banUser(user: user)
                    }) {
                        Text("Ban")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Ban User")
        .navigationBarTitleDisplayMode(.inline)
    }
}
