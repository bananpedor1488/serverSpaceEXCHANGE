import SwiftUI
//
struct DevicesView: View {
    @Environment(\.dismiss) var dismiss
    let identityId: String
    
    @State private var devices: [DeviceInfo] = []
    @State private var isLoading = true
    @State private var deviceToLogout: DeviceInfo?
    @State private var showLogoutAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Устройства")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for centering
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color.black)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            // Info card
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18))
                                
                                Text("Список всех устройств, на которых выполнен вход в ваш аккаунт")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineSpacing(3)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            // Devices list
                            ForEach(devices) { device in
                                DeviceItemView(
                                    device: device,
                                    onLogout: {
                                        deviceToLogout = device
                                        showLogoutAlert = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            if devices.isEmpty {
                                Text("Нет активных устройств")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 32)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .onAppear {
            loadDevices()
        }
        .alert("Завершить сеанс?", isPresented: $showLogoutAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Завершить", role: .destructive) {
                if let device = deviceToLogout {
                    logoutDevice(device)
                }
            }
        } message: {
            if let device = deviceToLogout {
                Text("Вы уверены, что хотите выйти из аккаунта на устройстве \"\(device.deviceName)\"?")
            }
        }
    }
    
    func loadDevices() {
        isLoading = true
        
        guard let url = URL(string: "\(APIService.shared.baseURL)/devices/\(identityId)") else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(UIDevice.current.identifierForVendor?.uuidString ?? "", forHTTPHeaderField: "x-device-id")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                guard let data = data, error == nil else {
                    print("❌ Error loading devices: \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let response = try decoder.decode(DevicesResponse.self, from: data)
                    devices = response.devices
                    print("✅ Devices loaded: \(devices.count)")
                } catch {
                    print("❌ Error decoding devices: \(error)")
                }
            }
        }.resume()
    }
    
    func logoutDevice(_ device: DeviceInfo) {
        guard let url = URL(string: "\(APIService.shared.baseURL)/devices/logout") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "deviceId": device.id
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    print("❌ Error logging out device: \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                // Remove device from list
                devices.removeAll { $0.id == device.id }
                print("✅ Device logged out")
            }
        }.resume()
    }
}

struct DeviceItemView: View {
    let device: DeviceInfo
    let onLogout: () -> Void
    
    var platformColor: Color {
        switch device.platform.lowercased() {
        case "ios": return Color(red: 0, green: 122/255, blue: 1)
        case "android": return Color(red: 61/255, green: 220/255, blue: 132/255)
        case "macos": return Color(red: 88/255, green: 86/255, blue: 214/255)
        default: return .blue
        }
    }
    
    var platformIcon: String {
        switch device.platform.lowercased() {
        case "ios": return "iphone"
        case "android": return "smartphone"
        case "macos": return "desktopcomputer"
        default: return "devices"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Platform icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(platformColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: platformIcon)
                        .font(.system(size: 20))
                        .foregroundColor(platformColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(device.deviceName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if device.isCurrent {
                            Text("Текущее")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(device.deviceModel)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(12)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal)
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Платформа")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("\(device.platform.uppercased()) \(device.osVersion)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Версия приложения")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(device.appVersion)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            
            Text("Последняя активность: \(formatLastActive(device.lastActive))")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    func formatLastActive(_ timestamp: Int64) -> String {
        let now = Date().timeIntervalSince1970 * 1000
        let diff = Int64(now) - timestamp
        
        if diff < 60_000 {
            return "только что"
        } else if diff < 3600_000 {
            return "\(diff / 60_000) мин назад"
        } else if diff < 86400_000 {
            return "\(diff / 3600_000) ч назад"
        } else if diff < 604800_000 {
            return "\(diff / 86400_000) дн назад"
        } else {
            let date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: date)
        }
    }
}

// Device model
struct DeviceInfo: Identifiable, Codable {
    let id: String
    let identityId: String
    let deviceName: String
    let deviceModel: String
    let platform: String
    let osVersion: String
    let appVersion: String
    let lastActive: Int64
    let isCurrent: Bool
}

struct DevicesResponse: Codable {
    let devices: [DeviceInfo]
}
