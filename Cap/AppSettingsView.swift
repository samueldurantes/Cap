import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true

    var body: some View {
        Form {
            Toggle("Show Previews", isOn: $showPreview)
        }
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true
    @AppStorage("fontSize") private var fontSize = 12.0


    var body: some View {
        Text("Hello, World!")
    }
}

struct AppSettingsView: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralSettingsView()
            }
            Tab("Advanced", systemImage: "star") {
                AdvancedSettingsView()
            }
        }
        .scenePadding()
        .frame(maxWidth: 3000, minHeight: 100)
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView()
    }
}
