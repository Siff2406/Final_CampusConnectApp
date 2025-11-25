import SwiftUI


struct AddEventView: View {
    @StateObject private var viewModel = AddEventViewModel()
    @Environment(\.dismiss) var dismiss
    
    // UI State for Success Popup
    @State private var showSuccessPopup = false
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                    // Section 1: Basic Info
                    Section(header: Text("Event Details")) {
                        TextField("Event Title", text: $viewModel.title)
                        
                        Picker("Category", selection: $viewModel.category) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        
                        Picker("Faculty", selection: $viewModel.faculty) {
                            ForEach(EventFaculty.allCases, id: \.self) { faculty in
                                Text(faculty.rawValue).tag(faculty)
                            }
                        }
                    }
                    
                    // Section 2: Date & Location
                    Section(header: Text("When & Where")) {
                        DatePicker("Date & Time", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                        
                        TextField("Location", text: $viewModel.location)
                    }
                    
                    // Section 3: Description
                    Section(header: Text("Description")) {
                        TextEditor(text: $viewModel.description)
                            .frame(height: 100)
                    }
                    
                    // Section 4: Image Upload
                    Section(header: Text("Event Image")) {
                        TextField("Image URL (e.g., https://example.com/image.jpg)", text: $viewModel.imageUrlString)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !viewModel.imageUrlString.isEmpty, let url = URL(string: viewModel.imageUrlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                        .clipped()
                                case .failure:
                                    Text("Invalid URL or Image not found")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                    
                    // Section 5: Submit Button
                    Section {
                        Button(action: {
                            viewModel.createEvent()
                        }) {
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                Text("Submit Event")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .listRowBackground(Color.red)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Create Event")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .disabled(showSuccessPopup)
            .blur(radius: showSuccessPopup ? 3 : 0)
            
            // Success Popup Overlay
            if showSuccessPopup {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 8) {
                        Text("Event Created!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your event is now pending approval.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(30)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(40)
                .transition(.scale)
            }
        }
        .onChange(of: viewModel.isSuccess) { _, success in
            if success {
                withAnimation {
                    showSuccessPopup = true
                }
            }
        }
    }
}
