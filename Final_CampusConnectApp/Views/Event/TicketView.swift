import SwiftUI

struct TicketView: View {
    let event: Event
    let user: User
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Ticket Header
                VStack(spacing: 10) {
                    Text(event.category.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                .background(Color.white)
                
                // Dashed Line Divider
                HStack(alignment: .center, spacing: 5) {
                    ForEach(0..<30) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 5, height: 2)
                    }
                }
                .frame(height: 20)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .overlay(
                    HStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 20, height: 20)
                            .offset(x: -10)
                        Spacer()
                        Circle()
                            .fill(Color.black)
                            .frame(width: 20, height: 20)
                            .offset(x: 10)
                    }
                )
                
                // QR Code Section
                VStack(spacing: 20) {
                    Image(uiImage: QRCodeGenerator.generateQRCode(from: "\(event.id):\(user.id)"))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    VStack(spacing: 5) {
                        Text(user.displayName)
                            .font(.headline)
                        Text("Ticket Holder")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Show this QR code at the entrance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(30)
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}
