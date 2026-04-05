import SwiftUI

struct DataSettingsView: View {
    @State private var showClearCacheSheet = false
    @State private var isClearing = false
    @State private var cacheSize: Int64 = 0
    @State private var autoDownloadPhotos = true
    @State private var autoDownloadVideos = false
    @State private var autoDownloadFiles = false
    @State private var showStorageBreakdown = false
    @State private var showCacheLimitSheet = false
    @State private var showWiFiOnlySheet = false
    @State private var showDownloadQualitySheet = false
    @AppStorage("cacheLimitMB") private var cacheLimitMB: Int = 0 // 0 = безлимит
    @AppStorage("wifiOnlyDownload") private var wifiOnlyDownload: Bool = false
    @AppStorage("downloadQuality") private var downloadQuality: String = "high" // low, medium, high
    
    var maxCacheSize: Int64 {
        cacheLimitMB == 0 ? Int64.max : Int64(cacheLimitMB) * 1_000_000
    }
    
    var cachePercentage: Double {
        if cacheLimitMB == 0 {
            return 0 // Безлимит - не показываем прогресс
        }
        return min(Double(cacheSize) / Double(maxCacheSize), 1.0)
    }
    
    var cacheLimitText: String {
        cacheLimitMB == 0 ? "Безлимит" : "\(cacheLimitMB) MB"
    }
    
    var downloadQualityText: String {
        switch downloadQuality {
        case "low": return "Низкое"
        case "medium": return "Среднее"
        case "high": return "Высокое"
        default: return "Высокое"
        }
    }
    
    var wifiOnlyText: String {
        wifiOnlyDownload ? "Включено" : "Выключено"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Storage Usage Card
                    VStack(spacing: 20) {
                        // Circular Progress
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 12)
                                .frame(width: 160, height: 160)
                            
                            // Progress circle (только если есть лимит)
                            if cacheLimitMB > 0 {
                                Circle()
                                    .trim(from: 0, to: cachePercentage)
                                    .stroke(
                                        cachePercentage > 0.8 ? Color.red : Color.blue,
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .frame(width: 160, height: 160)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: cachePercentage)
                            }
                            
                            // Center text
                            VStack(spacing: 4) {
                                Text(formatBytes(cacheSize))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if cacheLimitMB > 0 {
                                    Text("из \(formatBytes(maxCacheSize))")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                } else {
                                    Text("без лимита")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Status text
                        VStack(spacing: 8) {
                            Text("Использование кэша")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if cacheLimitMB > 0 {
                                Text("\(Int(cachePercentage * 100))% заполнено")
                                    .font(.system(size: 15))
                                    .foregroundColor(cachePercentage > 0.8 ? .red : .white.opacity(0.7))
                            } else {
                                Text("Лимит не установлен")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Buttons row
                        HStack(spacing: 12) {
                            Button(action: { showStorageBreakdown = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.system(size: 16))
                                    Text("Детализация")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(20)
                            }
                            
                            Button(action: { showCacheLimitSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 16))
                                    Text("Лимит")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.purple)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.purple.opacity(0.15))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    
                    // Clear Cache Button
                    Button(action: { showClearCacheSheet = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Очистить кэш")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Освободить \(formatBytes(cacheSize))")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    .disabled(cacheSize == 0)
                    .opacity(cacheSize == 0 ? 0.5 : 1.0)
                    
                    // Auto Download Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("АВТОЗАГРУЗКА МЕДИА")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            AutoDownloadToggle(
                                icon: "photo.fill",
                                title: "Фото",
                                subtitle: "Автоматически загружать фото",
                                color: .green,
                                isOn: $autoDownloadPhotos
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 80)
                            
                            AutoDownloadToggle(
                                icon: "video.fill",
                                title: "Видео",
                                subtitle: "Автоматически загружать видео",
                                color: .blue,
                                isOn: $autoDownloadVideos
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 80)
                            
                            AutoDownloadToggle(
                                icon: "doc.fill",
                                title: "Файлы и документы",
                                subtitle: "Автоматически загружать файлы",
                                color: .orange,
                                isOn: $autoDownloadFiles
                            )
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    
                    // Network Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("СЕТЬ")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            Button(action: { showWiFiOnlySheet = true }) {
                                DataSettingsRow(
                                    icon: "wifi",
                                    title: "Только Wi-Fi",
                                    subtitle: wifiOnlyText,
                                    color: .blue
                                )
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 80)
                            
                            Button(action: { showDownloadQualitySheet = true }) {
                                DataSettingsRow(
                                    icon: "arrow.down.circle",
                                    title: "Качество загрузки",
                                    subtitle: downloadQualityText,
                                    color: .green
                                )
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            
            // Clear Cache Sheet
            if showClearCacheSheet {
                ClearCacheSheet(
                    isPresented: $showClearCacheSheet,
                    isClearing: $isClearing,
                    cacheSize: $cacheSize
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            
            // Storage Breakdown Sheet
            if showStorageBreakdown {
                StorageBreakdownSheet(
                    isPresented: $showStorageBreakdown,
                    cacheSize: cacheSize,
                    maxCacheSize: maxCacheSize
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            
            // Cache Limit Sheet
            if showCacheLimitSheet {
                CacheLimitSheet(
                    isPresented: $showCacheLimitSheet,
                    cacheLimitMB: $cacheLimitMB
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            
            // WiFi Only Sheet
            if showWiFiOnlySheet {
                WiFiOnlySheet(
                    isPresented: $showWiFiOnlySheet,
                    wifiOnlyDownload: $wifiOnlyDownload
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            
            // Download Quality Sheet
            if showDownloadQualitySheet {
                DownloadQualitySheet(
                    isPresented: $showDownloadQualitySheet,
                    downloadQuality: $downloadQuality
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .navigationTitle("Данные и память")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateCacheSize()
        }
        .animation(.easeInOut(duration: 0.3), value: showClearCacheSheet)
        .animation(.easeInOut(duration: 0.3), value: showStorageBreakdown)
        .animation(.easeInOut(duration: 0.3), value: showCacheLimitSheet)
        .animation(.easeInOut(duration: 0.3), value: showWiFiOnlySheet)
        .animation(.easeInOut(duration: 0.3), value: showDownloadQualitySheet)
    }
    
    private func calculateCacheSize() {
        cacheSize = CacheManager.shared.getCacheSize()
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct AutoDownloadToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(16)
    }
}

struct ClearCacheSheet: View {
    @Binding var isPresented: Bool
    @Binding var isClearing: Bool
    @Binding var cacheSize: Int64
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    if isClearing {
                        ProgressView()
                            .tint(.red)
                            .scaleEffect(1.8)
                    } else {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.red)
                    }
                }
                .padding(.bottom, 24)
                
                // Title
                Text(isClearing ? "Очистка кэша..." : "Очистить кэш?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 12)
                
                // Description
                Text(isClearing ? "Удаление временных файлов и данных" : "Будут удалены все временные файлы, кэшированные изображения и данные\n\n\(formatBytes(cacheSize))")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                
                if !isClearing {
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: clearCache) {
                            Text("Очистить кэш")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.red)
                                .cornerRadius(14)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            Text("Отмена")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isClearing {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                }
        )
    }
    
    private func clearCache() {
        isClearing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            CacheManager.shared.clearAll()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cacheSize = 0
                isClearing = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct StorageBreakdownSheet: View {
    @Binding var isPresented: Bool
    let cacheSize: Int64
    let maxCacheSize: Int64
    
    var categoryData: (photos: Int64, videos: Int64, files: Int64, messages: Int64, avatars: Int64) {
        CacheManager.shared.getCacheSizeByCategory()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Header
                HStack {
                    Text("Детализация памяти")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Total usage
                VStack(spacing: 12) {
                    HStack {
                        Text("Общий размер")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(formatBytes(cacheSize))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Лимит кэша")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(formatBytes(maxCacheSize))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 12) {
                        if categoryData.avatars > 0 {
                            StorageItem(
                                icon: "person.crop.circle.fill",
                                title: "Аватарки",
                                size: categoryData.avatars,
                                color: .cyan,
                                totalSize: cacheSize
                            )
                        }
                        
                        if categoryData.photos > 0 {
                            StorageItem(
                                icon: "photo.fill",
                                title: "Фото",
                                size: categoryData.photos,
                                color: .green,
                                totalSize: cacheSize
                            )
                        }
                        
                        if categoryData.videos > 0 {
                            StorageItem(
                                icon: "video.fill",
                                title: "Видео",
                                size: categoryData.videos,
                                color: .blue,
                                totalSize: cacheSize
                            )
                        }
                        
                        if categoryData.files > 0 {
                            StorageItem(
                                icon: "doc.fill",
                                title: "Файлы",
                                size: categoryData.files,
                                color: .orange,
                                totalSize: cacheSize
                            )
                        }
                        
                        if categoryData.messages > 0 {
                            StorageItem(
                                icon: "message.fill",
                                title: "Сообщения",
                                size: categoryData.messages,
                                color: .purple,
                                totalSize: cacheSize
                            )
                        }
                        
                        if cacheSize == 0 {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                
                                Text("Кэш пуст")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Нет данных для отображения")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 550)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
        )
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct StorageItem: View {
    let icon: String
    let title: String
    let size: Int64
    let color: Color
    let totalSize: Int64
    
    var percentage: Double {
        totalSize > 0 ? Double(size) / Double(totalSize) : 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(Int(percentage * 100))% от общего")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(formatBytes(size))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: size)
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct CacheLimitSheet: View {
    @Binding var isPresented: Bool
    @Binding var cacheLimitMB: Int
    @State private var selectedLimit: Int
    
    let limitOptions = [0, 100, 250, 500, 1000, 2000, 5000] // 0 = безлимит
    
    init(isPresented: Binding<Bool>, cacheLimitMB: Binding<Int>) {
        self._isPresented = isPresented
        self._cacheLimitMB = cacheLimitMB
        self._selectedLimit = State(initialValue: cacheLimitMB.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Header
                HStack {
                    Text("Лимит кэша")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Description
                Text("Выберите максимальный размер кэша. При превышении лимита старые данные будут автоматически удаляться.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                // Current selection display
                VStack(spacing: 8) {
                    Text("Текущий лимит")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(selectedLimit == 0 ? "Безлимит" : "\(selectedLimit) MB")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Options list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(limitOptions, id: \.self) { limit in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedLimit = limit
                                }
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .stroke(selectedLimit == limit ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                        
                                        if selectedLimit == limit {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(limit == 0 ? "Безлимит" : "\(limit) MB")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Text(limitDescription(for: limit))
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedLimit == limit {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(selectedLimit == limit ? Color.blue.opacity(0.1) : Color.clear)
                            }
                            
                            if limit != limitOptions.last {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 300)
                
                // Apply button
                Button(action: {
                    cacheLimitMB = selectedLimit
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Применить")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 650)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
        )
    }
    
    private func limitDescription(for limit: Int) -> String {
        switch limit {
        case 0:
            return "Без ограничений"
        case 100:
            return "Минимальный размер"
        case 250:
            return "Экономия памяти"
        case 500:
            return "Рекомендуемый"
        case 1000:
            return "Стандартный"
        case 2000:
            return "Увеличенный"
        case 5000:
            return "Максимальный"
        default:
            return ""
        }
    }
}

struct DataSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var color: Color = .blue
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
    }
}

struct WiFiOnlySheet: View {
    @Binding var isPresented: Bool
    @Binding var wifiOnlyDownload: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Header
                HStack {
                    Text("Только Wi-Fi")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Description
                Text("Загружать медиафайлы только при подключении к Wi-Fi сети. Это поможет сэкономить мобильный трафик.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                // Options
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            wifiOnlyDownload = false
                        }
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(!wifiOnlyDownload ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if !wifiOnlyDownload {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Всегда загружать")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Загружать через любое соединение")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            if !wifiOnlyDownload {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(!wifiOnlyDownload ? Color.blue.opacity(0.1) : Color.clear)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 60)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            wifiOnlyDownload = true
                        }
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(wifiOnlyDownload ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if wifiOnlyDownload {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Только Wi-Fi")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Экономия мобильного трафика")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            if wifiOnlyDownload {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(wifiOnlyDownload ? Color.blue.opacity(0.1) : Color.clear)
                    }
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
        )
    }
}

struct DownloadQualitySheet: View {
    @Binding var isPresented: Bool
    @Binding var downloadQuality: String
    
    let qualityOptions = [
        ("low", "Низкое", "Экономия трафика и памяти"),
        ("medium", "Среднее", "Баланс качества и размера"),
        ("high", "Высокое", "Максимальное качество")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Header
                HStack {
                    Text("Качество загрузки")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Description
                Text("Выберите качество загружаемых медиафайлов. Более низкое качество экономит трафик и место на устройстве.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                // Options
                VStack(spacing: 0) {
                    ForEach(Array(qualityOptions.enumerated()), id: \.offset) { index, option in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                downloadQuality = option.0
                            }
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .stroke(downloadQuality == option.0 ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if downloadQuality == option.0 {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.1)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(option.2)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if downloadQuality == option.0 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(downloadQuality == option.0 ? Color.green.opacity(0.1) : Color.clear)
                        }
                        
                        if index < qualityOptions.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
        )
    }
}
