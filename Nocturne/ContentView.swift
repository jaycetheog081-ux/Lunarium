import SwiftUI

private enum Theme {
    static let background = Color(red: 0.035, green: 0.047, blue: 0.060)
    static let surface = Color(red: 0.075, green: 0.090, blue: 0.100)
    static let raised = Color(red: 0.105, green: 0.125, blue: 0.130)
    static let line = Color.white.opacity(0.085)
    static let green = Color(red: 0.66, green: 0.84, blue: 0.43)
    static let greenDim = Color(red: 0.39, green: 0.57, blue: 0.27)
    static let purple = Color(red: 0.65, green: 0.57, blue: 0.86)
    static let gold = Color(red: 0.82, green: 0.70, blue: 0.43)
    static let text = Color(red: 0.93, green: 0.95, blue: 0.91)
    static let muted = Color(red: 0.58, green: 0.63, blue: 0.61)
}

struct NocturneRootView: View {
    @State private var tab = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Group {
                    switch tab {
                    case 0: OverviewScreen()
                    case 1: ResearchScreen()
                    case 2: DeviceScreen()
                    default: AboutScreen()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.green)
    }

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.raised)
                    .frame(width: 37, height: 37)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("NOCTURNE")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(Theme.text)

                Text("RESEARCH TOOLKIT")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.green)
                    .frame(width: 6, height: 6)

                Text("LOCAL")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.surface, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 13)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            nav("square.grid.2x2", "Home", 0)
            nav("doc.text.magnifyingglass", "Research", 1)
            nav("iphone", "Device", 2)
            nav("ellipsis", "About", 3)
        }
        .padding(.top, 10)
        .padding(.bottom, 7)
        .background(Theme.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }

    private func nav(_ symbol: String, _ title: String, _ index: Int) -> some View {
        Button {
            tab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: tab == index ? .semibold : .regular))

                Text(title)
                    .font(.system(size: 9, weight: tab == index ? .semibold : .medium))
            }
            .foregroundStyle(tab == index ? Theme.green : Theme.muted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Theme.green)

            Text(title)
                .font(.system(size: 27, weight: .bold))
                .tracking(-0.6)
                .foregroundStyle(Theme.text)

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 5)
    }
}

private struct SectionLabel: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Theme.muted)

            Spacer()

            if let trailing {
                Text(trailing.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.greenDim)
            }
        }
    }
}

private struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
    }
}

struct OverviewScreen: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 23) {
                PageHeading(
                    eyebrow: "Workspace / 01",
                    title: "Overview",
                    subtitle: "A focused space for device notes and vulnerability documentation."
                )

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("CURRENT DOSSIER", systemImage: "doc.text")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.green)

                        Spacer()

                        Text("IMPORTED")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Theme.gold)
                    }

                    Text("CVE-2026-112477")
                        .font(.system(size: 21, weight: .semibold, design: .monospaced))
                        .tracking(-0.8)
                        .foregroundStyle(Theme.text)

                    Text("IOSurfaceRoot user-client registry research")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)

                    Hairline()

                    HStack(spacing: 18) {
                        metric("SOURCE FILES", "06")
                        metric("STATUS", "Review")
                        Spacer(minLength: 0)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.green)
                    }
                }
                .padding(16)
                .background(
                    Theme.surface,
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Theme.line, lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(title: "Workspace", trailing: "03 MODULES")

                    moduleRow(
                        "Research dossier",
                        "Source summary and limitations",
                        "doc.text.magnifyingglass",
                        Theme.purple
                    )

                    Hairline()

                    moduleRow(
                        "Device record",
                        "Manually maintained device details",
                        "iphone",
                        Theme.green
                    )

                    Hairline()

                    moduleRow(
                        "Build pipeline",
                        "Unsigned iOS build workflow",
                        "hammer",
                        Theme.gold
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Scope", systemImage: "info.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.text)

                    Text("NOCTURNE is a documentation interface. It does not execute proof-of-concept code, access kernel memory, or modify device security.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundStyle(Theme.muted)

            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.text)
        }
    }

    private func moduleRow(
        _ name: String,
        _ detail: String,
        _ symbol: String,
        _ color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 25)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.text)

                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.muted.opacity(0.8))
        }
        .padding(.vertical, 3)
    }
}

struct ResearchScreen: View {
    private let facts: [(String, String)] = [
        ("Project label", "CVE-2026-112477 — IOSurfaceRoot User Client Registry UAF."),
        ("Research target", "The archive describes a use-after-free-style condition in the IOSurfaceRoot user-client registry."),
        ("Reported environment", "The README claims testing on iOS 26.4 (23E246), arm64e. This claim has not been independently verified."),
        ("Reported observation", "The author reports a repeatable stale-entry condition in their test environment. The uploaded materials alone do not establish that the issue affects other devices or OS builds."),
        ("Open questions", "The analysis says the internal entry field layout was not fully mapped and that no kernel write primitive had been attempted."),
        ("Archive completeness", "The README refers to a build.sh file and a src/ path, but neither appears in the uploaded ZIP. The Objective-C proof-of-concept is not embedded or run by NOCTURNE.")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                PageHeading(
                    eyebrow: "Dossier / CVE-2026-112477",
                    title: "IOSurfaceRoot UAF",
                    subtitle: "A source-derived summary. Statements are attributed to the supplied archive."
                )

                HStack(spacing: 7) {
                    statusTag("RESEARCH POC", color: Theme.purple)
                    statusTag("UNVERIFIED", color: Theme.gold)
                    statusTag("DOCS ONLY", color: Theme.green)
                }

                VStack(spacing: 0) {
                    ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                        VStack(alignment: .leading, spacing: 7) {
                            Text(fact.0.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .tracking(1.35)
                                .foregroundStyle(Theme.green)

                            Text(fact.1)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.text.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)

                        if index != facts.count - 1 {
                            Hairline()
                        }
                    }
                }
                .padding(.horizontal, 15)
                .background(
                    Theme.surface,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.line, lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "Source archive")

                    Text("README.md · docs/ANALYSIS.md · LICENSE · entry_isurf_uaf.m")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.muted)

                    Text("The source trigger is excluded from this app package. This dossier records the available material without operational exploit instructions.")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private func statusTag(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(0.10), in: Capsule())
    }
}

struct DeviceScreen: View {
    @State private var model = ""
    @State private var ios = ""
    @State private var chip = ""
    @State private var notes = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 19) {
                PageHeading(
                    eyebrow: "Inventory / Manual",
                    title: "Device record",
                    subtitle: "Keep a local note of the device used for your research."
                )

                VStack(alignment: .leading, spacing: 15) {
                    field("DEVICE MODEL", placeholder: "e.g. iPhone model", text: $model)
                    field("IOS VERSION", placeholder: "e.g. 26.x", text: $ios)
                    field("CHIP / ARCHITECTURE", placeholder: "Optional", text: $chip)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("NOTES")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(Theme.muted)

                        TextEditor(text: $notes)
                            .font(.system(size: 12))
                            .frame(height: 118)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(
                                Theme.background,
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Theme.line, lineWidth: 1)
                            }
                    }
                }
                .padding(15)
                .background(
                    Theme.surface,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

                Text("Entries remain temporary and are not saved or transmitted.")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private func field(
        _ title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(Theme.muted)

            TextField(placeholder, text: text)
                .font(.system(size: 12))
                .padding(.horizontal, 11)
                .padding(.vertical, 12)
                .background(
                    Theme.background,
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Theme.line, lineWidth: 1)
                }
        }
    }
}

struct AboutScreen: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                PageHeading(
                    eyebrow: "Project / About",
                    title: "NOCTURNE",
                    subtitle: "A quiet, native-feeling iOS research interface."
                )

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "Version")

                    Text("NOCTURNE 0.3")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Theme.text)

                    Text("SwiftUI · iOS 16+ · Documentation-only")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }

                Hairline()

                aboutRow(
                    "Included",
                    "Overview, source-derived research dossier, manual device record, project notes, and an unsigned IPA workflow.",
                    "checkmark.circle",
                    Theme.green
                )

                Hairline()

                aboutRow(
                    "Not included",
                    "No exploit trigger, kernel read/write primitive, privilege escalation, persistence, or security bypass.",
                    "minus.circle",
                    Theme.gold
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private func aboutRow(
        _ title: String,
        _ detail: String,
        _ symbol: String,
        _ color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.text)

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
