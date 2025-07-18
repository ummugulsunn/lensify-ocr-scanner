import WidgetKit
import SwiftUI
import Intents

// MARK: - Widget Configuration
struct LensifyWidgetProvider: IntentTimelineProvider {
    
    func placeholder(in context: Context) -> LensifyWidgetEntry {
        LensifyWidgetEntry(date: Date(), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (LensifyWidgetEntry) -> ()) {
        let entry = LensifyWidgetEntry(date: Date(), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<LensifyWidgetEntry>) -> ()) {
        var entries: [LensifyWidgetEntry] = []
        
        // Generate timeline entry for current date
        let currentDate = Date()
        let entry = LensifyWidgetEntry(date: currentDate, configuration: configuration)
        entries.append(entry)
        
        // Update timeline every hour
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct LensifyWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

// MARK: - Widget Views
struct LensifyWidgetEntryView: View {
    var entry: LensifyWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView()
        case .systemMedium:
            MediumWidgetView()
        case .systemLarge:
            LargeWidgetView()
        @unknown default:
            SmallWidgetView()
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.89, green: 0.95, blue: 0.99), Color(red: 0.73, green: 0.87, blue: 0.98)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // App Icon
                Image(systemName: "viewfinder.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                
                // App Name
                Text("Lensify")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                // Quick Action Text
                Text("OCR Scanner")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .cornerRadius(16)
        .widgetURL(URL(string: "lensify://widget/camera"))
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.89, green: 0.95, blue: 0.99), Color(red: 0.73, green: 0.87, blue: 0.98)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left side - App branding
                VStack(spacing: 4) {
                    Image(systemName: "viewfinder.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Lensify")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("OCR Scanner")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Quick actions
                VStack(spacing: 8) {
                    // Camera action
                    Link(destination: URL(string: "lensify://widget/camera")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                            Text("Kamera")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    // Gallery action
                    Link(destination: URL(string: "lensify://widget/gallery")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 12))
                            Text("Galeri")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    // History action
                    Link(destination: URL(string: "lensify://widget/history")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text("Geçmiş")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .cornerRadius(16)
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.89, green: 0.95, blue: 0.99), Color(red: 0.73, green: 0.87, blue: 0.98)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "viewfinder.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lensify OCR Scanner")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Fotoğraftan Metne Dönüştürücü")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Quick Actions Grid
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Camera action
                        Link(destination: URL(string: "lensify://widget/camera")!) {
                            VStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                Text("Kamera ile\nTara")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        // Gallery action
                        Link(destination: URL(string: "lensify://widget/gallery")!) {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                Text("Galeri'den\nSeç")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        // History action
                        Link(destination: URL(string: "lensify://widget/history")!) {
                            VStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                Text("OCR\nGeçmişi")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        // Settings action
                        Link(destination: URL(string: "lensify://widget/settings")!) {
                            VStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                Text("Ayarlar &\nPremium")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .cornerRadius(16)
    }
}

// MARK: - Widget Configuration
struct LensifyWidget: Widget {
    let kind: String = "LensifyWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: LensifyWidgetProvider()) { entry in
            LensifyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lensify OCR")
        .description("Hızlı OCR işlemleri için ana ekranınıza ekleyin")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle
@main
struct LensifyWidgetBundle: WidgetBundle {
    var body: some Widget {
        LensifyWidget()
    }
}

// MARK: - Previews
struct LensifyWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LensifyWidgetEntryView(entry: LensifyWidgetEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            LensifyWidgetEntryView(entry: LensifyWidgetEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            LensifyWidgetEntryView(entry: LensifyWidgetEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
} 