import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var filteredEvents: [Event] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterEvents(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    func fetchEvents() {
        isLoading = true
        Task {
            do {
                let fetchedEvents = try await FirebaseService.shared.fetchApprovedEvents()
                await MainActor.run {
                    self.events = fetchedEvents
                    self.filterEvents(searchText: self.searchText)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func filterEvents(searchText: String) {
        if searchText.isEmpty {
            filteredEvents = events
        } else {
            filteredEvents = events.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
