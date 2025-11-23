import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.pendingEvents.isEmpty {
                Text("No pending events")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.pendingEvents) { event in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(event.title)
                                .font(.headline)
                            Spacer()
                            Text(event.faculty.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack {
                            Text(event.createBy) // In real app, show user name
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button("Reject") {
                                viewModel.updateStatus(event: event, status: .rejected)
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(.red)
                            
                            Button("Approve") {
                                viewModel.updateStatus(event: event, status: .approved)
                            }
                            .buttonStyle(BorderedProminentButtonStyle())
                            .tint(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Admin Dashboard")
        .onAppear {
            viewModel.fetchPendingEvents()
        }
    }
}
