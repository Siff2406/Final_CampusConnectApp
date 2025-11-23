import SwiftUI

struct AddEventView: View {
    @StateObject private var viewModel = AddEventViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $viewModel.title)
                    TextField("Description", text: $viewModel.description)
                    TextField("Location", text: $viewModel.location)
                    TextField("Image URL (Optional)", text: $viewModel.imageUrl)
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Event Date", selection: $viewModel.eventDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Category & Faculty")) {
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
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        viewModel.submitEvent()
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Submit Event")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.red)
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.isSuccess) { success in
                if success {
                    dismiss()
                }
            }
        }
    }
}
