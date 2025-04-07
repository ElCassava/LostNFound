//
//  ItemDetailView.swift
//  cobacloudkit
//
//  Created by Sessario Ammar Wibowo on 02/04/25.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    var item: Item
    var isAdmin: Bool
    
    // MARK: - Reusable Row
    struct DetailRow: View {
        var title: String
        var icon: String
        var value: String
        var isDate: Bool = false
        var isStatus: Bool = false

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundColor(isStatus ? (value == "Claimed" ? .green : .orange) : .black)

                    Text(formatValue())
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
        }

        private func formatValue() -> String {
            if isDate {
                // Optionally format if needed later
                return value
            }
            return value
        }
        
        private func formattedDate(_ date: Date?) -> String {
            guard let date = date else { return "-" }
            let formatter = DateFormatter()
            formatter.dateFormat = "d/M/yy"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header
                HStack {
                    Text("Item Details")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }

                // MARK: - Image
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 370, height: 300)
                    .clipped()
                    .cornerRadius(20)

                // MARK: - Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 16) {
                    DetailRow(title: "Item", icon: "cube.box.fill", value: item.itemName)
                    DetailRow(title: "Category", icon: "tag.fill", value: item.category)
                    DetailRow(title: "Date Found", icon: "calendar", value: formattedDate(item.dateFound))
                    DetailRow(title: "Location Found", icon: "map.fill", value: item.locationFound)
                    DetailRow(title: "Status", icon: item.isClaimed ? "checkmark.circle.fill" : "clock.fill", value: item.isClaimed ? "Claimed" : "Unclaimed", isStatus: true)

                    if let claimedDate = item.dateClaimed {
                        DetailRow(title: "Date Claimed", icon: "calendar.badge.clock", value: formattedDate(claimedDate))
                    }
                    
                    // ✅ Claimer Info using DetailRow
                    if item.isClaimed, let claimer = item.claimer, let contact = item.claimerContact {
                            DetailRow(title: "Claimer", icon: "person.fill", value: claimer)
                            DetailRow(title: "Contact", icon: "phone.fill", value: contact)
                        
                    }

                    
                }
                .padding(.horizontal, 12)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.black)
                            .padding(.top, 2) // optional tweak for visual alignment

                        Text(item.itemDescription)
                            .font(.body)
                            .fontWeight(.semibold)
                            .fixedSize(horizontal: false, vertical: true) // allows multiline
                    }
                }
                .gridCellColumns(2)
                .padding(.horizontal, 12)
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .presentationDragIndicator(.visible)

    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yy"
        return formatter.string(from: date)
    }
}


