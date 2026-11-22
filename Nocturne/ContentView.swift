import SwiftUI
import PhotosUI

// MARK: - Colors

extension Color {
    init(hex: String) {
        let h = hex.replacingOccurrences(of: "#", with: "")
        let v = UInt64(h, radix: 16) ?? 0
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}

// MARK: - Themes (16)

struct AppTheme: Identifiable {
    let id: String
    let name: String
    let bg: String
    let glow: String
    let accent: String
    let sheet: String
    let text: String
}

let themes: [AppTheme] = [
    .init(id: "teal", name: "Teal", bg: "#0b1416", glow: "#12383a", accent: "#2a6e70", sheet: "#14252a", text: "#eef8f6"),
    .init(id: "red", name: "Red", bg: "#140708", glow: "#4a0f14", accent: "#961e24", sheet: "#2a1214", text: "#fbeeee"),
    .init(id: "ocean", name: "Ocean", bg: "#06142a", glow: "#0e3a7a", accent: "#1f5fb0", sheet: "#0d1f3d", text: "#eef4ff"),
    .init(id: "purple", name: "Purple", bg: "#120818", glow: "#3b1a5e", accent: "#6a2fa0", sheet: "#1d1028", text: "#f6eeff"),
    .init(id: "amber", name: "Amber", bg: "#171006", glow: "#5a3a0a", accent: "#b57412", sheet: "#2a1d0c", text: "#fff8ee"),
    .init(id: "forest", name: "Forest", bg: "#07140b", glow: "#144a26", accent: "#2d7d46", sheet: "#0f2216", text: "#eefaf1"),
    .init(id: "rose", name: "Rose", bg: "#1a0a12", glow: "#5a1838", accent: "#a02c62", sheet: "#2a1220", text: "#fff0f6"),
    .init(id: "slate", name: "Slate", bg: "#0c1014", glow: "#26323e", accent: "#4a5d70", sheet: "#161d25", text: "#eef2f6"),
    .init(id: "midnight", name: "Midnight", bg: "#050818", glow: "#1a2a6a", accent: "#2b3fa0", sheet: "#0c1230", text: "#eef0ff"),
    .init(id: "crimson", name: "Crimson", bg: "#0d0306", glow: "#5c0c1c", accent: "#8a1028", sheet: "#1d0810", text: "#fff0f2"),
    .init(id: "mint", name: "Mint", bg: "#0a1a16", glow: "#1c5a4a", accent: "#2c8a72", sheet: "#10261f", text: "#effcf8"),
    .init(id: "sunset", name: "Sunset", bg: "#1a0c08", glow: "#6a2a14", accent: "#c2572a", sheet: "#2a150d", text: "#fff3ec"),
    .init(id: "cyber", name: "Cyber", bg: "#05090d", glow: "#0a4a3a", accent: "#00a57e", sheet: "#0b1a20", text: "#e6fff8"),
    .init(id: "lavender", name: "Lavender", bg: "#120e1a", glow: "#3c2f63", accent: "#6f5ba8", sheet: "#1c1630", text: "#f4f0ff"),
    .init(id: "gold", name: "Gold", bg: "#120e04", glow: "#5a4410", accent: "#a6851e", sheet: "#221a08", text: "#fff9ea"),
    .init(id: "graphite", name: "Graphite", bg: "#0a0a0a", glow: "#2a2a2a", accent: "#4a4a4a", sheet: "#161616", text: "#f2f2f2")
]

// MARK: - Button styles (16)

struct ButtonStyleOption: Identifiable {
    let id: String
    let name: String
    let fill: String?
    let text: String
    let border: String?
    let radius: CGFloat
    let grouped: Bool
    let jbFill: String?
    let jbText: String
    let jbBorder: String?
}

let buttonStyles: [ButtonStyleOption] = [
    .init(id: "default", name: "Default", fill: "#1e3c3e", text: "#eef8f6", border: nil, radius: 14, grouped: true, jbFill: "#2a6e70", jbText: "#ffffff", jbBorder: nil),
    .init(id: "white", name: "White", fill: "#ffffff", text: "#111111", border: nil, radius: 14, grouped: true, jbFill: "#ffffff", jbText: "#111111", jbBorder: nil),
    .init(id: "outline", name: "Outline", fill: nil, text: "#ffffff", border: "#ffffff", radius: 14, grouped: false, jbFill: nil, jbText: "#ffffff", jbBorder: "#ffffff"),
    .init(id: "pill", name: "Pill", fill: "#3a3f40", text: "#ffffff", border: nil, radius: 999, grouped: false, jbFill: "#4a5051", jbText: "#ffffff", jbBorder: nil),
    .init(id: "square", name: "Square", fill: "#1b2b2d", text: "#eef8f6", border: nil, radius: 4, grouped: false, jbFill: "#2a4a4c", jbText: "#ffffff", jbBorder: nil),
    .init(id: "red", name: "Red", fill: "#c0262d", text: "#ffffff", border: nil, radius: 14, grouped: false, jbFill: "#8e1a20", jbText: "#ffffff", jbBorder: nil),
    .init(id: "blue", name: "Blue", fill: "#1f63d6", text: "#ffffff", border: nil, radius: 14, grouped: false, jbFill: "#143f8f", jbText: "#ffffff", jbBorder: nil),
    .init(id: "green", name: "Green", fill: "#23a35a", text: "#ffffff", border: nil, radius: 14, grouped: false, jbFill: "#16733f", jbText: "#ffffff", jbBorder: nil),
    .init(id: "gold", name: "Gold", fill: "#d9a92c", text: "#1a1200", border: nil, radius: 14, grouped: false, jbFill: "#a57e14", jbText: "#ffffff", jbBorder: nil),
    .init(id: "purple", name: "Purple", fill: "#7c3cd1", text: "#ffffff", border: nil, radius: 14, grouped: false, jbFill: "#55259a", jbText: "#ffffff", jbBorder: nil),
    .init(id: "tealline", name: "Teal Line", fill: nil, text: "#5ff0dc", border: "#5ff0dc", radius: 14, grouped: false, jbFill: nil, jbText: "#5ff0dc", jbBorder: "#5ff0dc"),
    .init(id: "dark", name: "Dark", fill: "#0c0c0c", text: "#f0f0f0", border: "#2a2a2a", radius: 14, grouped: false, jbFill: "#1a1a1a", jbText: "#f0f0f0", jbBorder: nil),
    .init(id: "pink", name: "Pink", fill: "#ff7eb6", text: "#2a0a1a", border: nil, radius: 14, grouped: false, jbFill: "#e0568f", jbText: "#ffffff", jbBorder: nil),
    .init(id: "frost", name: "Frost", fill: "#5a6163", text: "#ffffff", border: "#8a9294", radius: 18, grouped: false, jbFill: "#6a7274", jbText: "#ffffff", jbBorder: nil),
    .init(id: "mint", name: "Mint", fill: "#23705f", text: "#effcf8", border: nil, radius: 14, grouped: false, jbFill: "#1c5a4a", jbText: "#ffffff", jbBorder: nil),
    .init(id: "minimal", name: "Minimal", fill: nil, text: "#eef8f6", border: nil, radius: 10, grouped: false, jbFill: nil, jbText: "#eef8f6", jbBorder: nil)
]

let menuItems = ["Settings", "Restart Springboard", "Reboot Userspace", "Credits"]

let bootLines = [
    "[boot] loading kernel hooks",
    "[boot] checking rootFS",
    "[patch] applying tweak patches",
    "[mount] remounting filesystem",
    "[loader] installing loader",
    "[ok] environment ready"
]

// MARK: - Main screen

struct ContentView: View {
    @AppStorage("theme") private var themeID = "teal"
    @AppStorage("buttons") private var buttonID = "default"
    @AppStorage("device") private var device = "iphone"
    @AppStorage("verbose") private var verbose = false
    @AppStorage("bold") private var bold = false
    @AppStorage("showSettings") private var showSettings = true
    @AppStorage("logo") private var logoData = Data()
    @AppStorage("firstRunDone") private var firstRunDone = false

    @State private var showSheet = false
    @State private var glowOn = false
    @State private var logLines: [String] = []
    @State private var logIndex = 0
    @State private var isJailbreaking = false
    @State private var jailbreakComplete = false
    @State private var isRespringing = false

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var theme: AppTheme {
        themes.first { $0.id == themeID } ?? themes[0]
    }

    private var style: ButtonStyleOption {
        buttonStyles.first { $0.id == buttonID } ?? buttonStyles[0]
    }

    private var maxWidth: CGFloat {
        (device == "ipad" || sizeClass == .regular) ? 640 : 420
    }

    var body: some View {
        ZStack {
            Color(hex: theme.bg)
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: theme.glow))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: -150, y: -300)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header
                    .padding(.top, 20)

                Spacer(minLength: 8)

                menu

                if verbose {
                    logView
                }

                versionChips

                Spacer(minLength: 8)

                jailbreakButton

                Text("Developed and made by @solartech @itechmac @cobr404751")
                    .font(.footnote)
                    .foregroundColor(Color(hex: theme.text).opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(maxWidth: maxWidth)
        }
        .opacity(isRespringing ? 0.05 : 1)
        .foregroundColor(Color(hex: theme.text))
        .sheet(isPresented: $showSheet) {
            SettingsSheet(
                device: $device,
                themeID: $themeID,
                buttonID: $buttonID,
                verbose: $verbose,
                bold: $bold,
                showSettings: $showSettings,
                logoData: $logoData,
                onDeleteAll: deleteAll
            )
        }
        .onAppear {
            if !firstRunDone {
                showSheet = true
                firstRunDone = true
            }

            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowOn = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            if let image = UIImage(data: logoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 90)
                    .onTapGesture {
                        showSheet = true
                    }
            } else {
                Text("NOCTURNE")
                    .font(.system(size: 40, weight: bold ? .black : .bold))
                    .tracking(2)
                    .shadow(
                        color: Color(hex: theme.accent).opacity(0.8),
                        radius: glowOn ? 18 : 6
                    )
                    .onTapGesture {
                        showSheet = true
                    }
            }

            Text("Device ready")
                .font(.footnote)
                .foregroundColor(Color(hex: theme.text).opacity(0.6))
        }
    }

    private var visibleItems: [String] {
        menuItems.filter { showSettings || $0 != "Settings" }
    }

    private var menu: some View {
        VStack(spacing: style.grouped ? 0 : 10) {
            ForEach(visibleItems, id: \.self) { item in
                Button {
                    if item == "Settings" {
                        showSheet = true
                    }
                } label: {
                    HStack {
                        Text(item)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .opacity(0.5)
                    }
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: style.text))
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(style.grouped ? Color.clear : rowFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: style.radius)
                            .stroke(
                                Color(hex: style.border ?? "#000000"),
                                lineWidth: style.grouped || style.border == nil ? 0 : 1
                            )
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: style.grouped ? 0 : style.radius
                        )
                    )
                }
                .buttonStyle(.plain)

                if style.grouped && item != visibleItems.last {
                    Divider()
                        .background(Color.white.opacity(0.15))
                }
            }
        }
        .background {
            if style.grouped {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: style.fill ?? "#1e3c3e"))
            } else {
                Color.clear
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.grouped ? 18 : 0))
    }

    private var rowFill: Color {
        if let fill = style.fill {
            return Color(hex: fill)
        }
        return Color.clear
    }

    private var logView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(logLines, id: \.self) { line in
                Text(line)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(Color(hex: theme.text).opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }

    private var versionChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Supported versions")
                .font(.footnote)
                .foregroundColor(Color(hex: theme.text).opacity(0.6))

            HStack(spacing: 6) {
                ForEach(["iOS 27.0", "27.1", "27.2", "27.3"], id: \.self) { version in
                    Text(version)
                        .font(.caption)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var jailbreakButton: some View {
        Button {
            if jailbreakComplete {
                performRespring()
            } else if !isJailbreaking {
                startJailbreak()
            }
        } label: {
            Text(
                jailbreakComplete
                ? "Respring"
                : (isJailbreaking ? "Jailbreaking..." : "Jailbreak")
            )
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(Color(hex: style.jbText))
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background {
                RoundedRectangle(cornerRadius: style.radius)
                    .fill(
                        style.jbFill.map { Color(hex: $0) } ?? Color.clear
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: style.radius)
                    .stroke(
                        Color(hex: style.jbBorder ?? "#000000"),
                        lineWidth: style.jbBorder == nil ? 0 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isJailbreaking || isRespringing)
    }

    private func startJailbreak() {
        guard !isJailbreaking else { return }

        isJailbreaking = true
        jailbreakComplete = false
        logLines = []
        logIndex = 0

        Task { @MainActor in
            for line in bootLines {
                try? await Task.sleep(nanoseconds: 1_000_000_000)

                logLines.append("> " + line)
                logIndex += 1

                if logLines.count > 4 {
                    logLines.removeFirst()
                }
            }

            isJailbreaking = false
            jailbreakComplete = true
        }
    }

    private func performRespring() {
        guard !isRespringing else { return }

        withAnimation(.easeInOut(duration: 0.35)) {
            isRespringing = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)

            logLines = []
            logIndex = 0

            withAnimation(.easeInOut(duration: 0.45)) {
                isRespringing = false
            }
        }
    }

    private func deleteAll() {
        themeID = "teal"
        buttonID = "default"
        device = "iphone"
        verbose = false
        bold = false
        showSettings = true
        logoData = Data()
        firstRunDone = false
        logLines = []
        logIndex = 0
        isJailbreaking = false
        jailbreakComplete = false
        isRespringing = false
        showSheet = true
    }
}

// MARK: - Settings sheet

struct SettingsSheet: View {
    @Binding var device: String
    @Binding var themeID: String
    @Binding var buttonID: String
    @Binding var verbose: Bool
    @Binding var bold: Bool
    @Binding var showSettings: Bool
    @Binding var logoData: Data

    var onDeleteAll: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var deleteArmed = false

    private let gridColumns = Array(
        repeating: GridItem(.flexible()),
        count: 4
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    section("Device") {
                        Picker("Device", selection: $device) {
                            Text("iPhone").tag("iphone")
                            Text("iPad").tag("ipad")
                        }
                        .pickerStyle(.segmented)
                    }

                    section("Theme (16)") {
                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            ForEach(themes) { theme in
                                ThemePreview(
                                    theme: theme,
                                    selected: themeID == theme.id
                                ) {
                                    themeID = theme.id
                                }
                            }
                        }
                    }

                    section("Button style (16)") {
                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            ForEach(buttonStyles) { option in
                                ButtonStylePreview(
                                    option: option,
                                    selected: buttonID == option.id
                                ) {
                                    buttonID = option.id
                                }
                            }
                        }
                    }

                    section("Boot logo") {
                        PhotosPicker(
                            selection: $pickerItem,
                            matching: .images
                        ) {
                            Text("Pick from photos")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }

                        Button("Use text logo") {
                            logoData = Data()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .onChange(of: pickerItem) { newItem in
                        guard let newItem else { return }

                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                logoData = data
                            }
                        }
                    }

                    section("Options") {
                        toggleRow("Verbose boot", isOn: $verbose)
                        toggleRow("Bold logo", isOn: $bold)
                        toggleRow("Show Settings button", isOn: $showSettings)
                    }

                    Button {
                        if deleteArmed {
                            deleteArmed = false
                            onDeleteAll()
                        } else {
                            deleteArmed = true

                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                deleteArmed = false
                            }
                        }
                    } label: {
                        Text(
                            deleteArmed
                            ? "Tap again to delete everything"
                            : "Delete all settings"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(
                            Color(red: 1, green: 0.54, blue: 0.54)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.14))
                        )
                    }

                    Text("Tap the logo to reopen settings anytime.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .background(Circle().fill(Color.gray.opacity(0.25)))
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)

            content()
        }
    }

    private func toggleRow(
        _ title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            CheckSwitch(isOn: isOn)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Theme preview

private struct ThemePreview: View {
    let theme: AppTheme
    let selected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(theme.name)
                .font(.caption)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: theme.glow),
                                    Color(hex: theme.bg)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.white,
                            lineWidth: selected ? 2 : 0
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Button style preview

private struct ButtonStylePreview: View {
    let option: ButtonStyleOption
    let selected: Bool
    let onSelect: () -> Void

    private var previewRadius: CGFloat {
        min(option.radius, 14)
    }

    private var previewFill: Color {
        guard let fill = option.fill else {
            return Color.gray.opacity(0.2)
        }

        return Color(hex: fill)
    }

    private var previewBorder: Color {
        guard let border = option.border else {
            return Color.white.opacity(selected ? 1 : 0)
        }

        return Color(hex: border)
    }

    private var previewBorderWidth: CGFloat {
        selected ? 2 : 1
    }

    var body: some View {
        Button(action: onSelect) {
            Text(option.name)
                .font(.caption)
                .foregroundColor(Color(hex: option.text))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: previewRadius)
                        .fill(previewFill)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: previewRadius)
                        .stroke(
                            previewBorder,
                            lineWidth: previewBorderWidth
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slider toggle

struct CheckSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(
                        isOn
                        ? Color.green.opacity(0.45)
                        : Color.white.opacity(0.25)
                    )
                    .frame(width: 42, height: 24)

                Circle()
                    .fill(isOn ? Color.green : Color.white)
                    .frame(width: 18, height: 18)
                    .overlay {
                        Image(systemName: isOn ? "checkmark" : "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isOn ? .white : .gray)
                    }
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
