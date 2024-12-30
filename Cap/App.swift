import ScreenCaptureKit
import SwiftUI

@main
struct AppMain: App {
    @StateObject private var capturer = Capturer()
    @Environment(\.openSettings) var openSettings
    
    var body: some Scene {
        MenuBarExtra("Cap", systemImage: "sparkles") {
            Button(action: {
                Task {
                    if capturer.isRunning {
                        await capturer.stop()
                        
                        return
                    }
                    
                    await capturer.start()
                }
            }) {
                if capturer.isRunning {
                    Image(systemName: "stop.circle.fill")
                    Text("Stop transcript")
                }

                Image(systemName: "record.circle.fill")
                Text("Start transcript")
            }
            
            Divider()

            Button(action: {
                // TODO
            }) {
                Text("Check for Updates")
            }
            
            Button(action: {
                openSettings()
            }) {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: [.command])
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
            }
            .keyboardShortcut("Q", modifiers: [.command])
        }
        
        Settings {
            AppSettingsView()
        }
    }
}
