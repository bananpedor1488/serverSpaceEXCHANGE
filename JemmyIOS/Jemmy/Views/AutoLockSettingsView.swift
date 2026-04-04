import SwiftUI

struct AutoLockSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var privacyManager = PrivacyManager.shared
    
    let options = [1, 5, 10, 30, 60]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            List {
                ForEach(options, id: \.self) { minutes in
                    Button(action: {
                        privacyManager.autoLockMinutes = minutes
                        dismiss()
                    }) {
                        HStack {
                            Text(timeText(minutes))
                                .foregroundColor(.white)
                            Spacer()
                            if privacyManager.autoLockMinutes == minutes {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Автоблокировка")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func timeText(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) мин"
        } else {
            return "\(minutes / 60) ч"
        }
    }
}

struct AutoDeleteSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var autoDeleteHours: Int
    let onSave: () -> Void
    
    let options: [(hours: Int, title: String)] = [
        (0, "Выключено"),
        (24, "24 часа"),
        (168, "7 дней"),
        (720, "30 дней")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            List {
                ForEach(options, id: \.hours) { option in
                    Button(action: {
                        autoDeleteHours = option.hours
                        onSave()
                        dismiss()
                    }) {
                        HStack {
                            Text(option.title)
                                .foregroundColor(.white)
                            Spacer()
                            if autoDeleteHours == option.hours {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Автоудаление")
        .navigationBarTitleDisplayMode(.inline)
    }
}
