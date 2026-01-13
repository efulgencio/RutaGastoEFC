import SwiftUI
import SwiftData

@main
struct RutaGastoEFCApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.modelContainer(for: Viaje.self)
    }
}
