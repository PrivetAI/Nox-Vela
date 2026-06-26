import SwiftUI

struct RadioRootView: View {
    @StateObject private var store = RadioGameStore()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            RadioTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { BoothView(store: store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { CrateView(store: store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { AlmanacView(store: store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { SettingsView(store: store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Booth", AnyView(BoothIcon(size: 26, color: tint(0))))
            tabButton(1, "Crate", AnyView(CrateIcon(size: 26, color: tint(1))))
            tabButton(2, "Almanac", AnyView(AlmanacIcon(size: 26, color: tint(2))))
            tabButton(3, "Settings", AnyView(SettingsIcon(size: 26, color: tint(3))))
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            RadioTheme.bgDeep
                .overlay(Rectangle().frame(height: 1).foregroundColor(RadioTheme.stroke.opacity(0.5)), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tint(_ i: Int) -> Color {
        selectedTab == i ? RadioTheme.amber : RadioTheme.textDim
    }

    private func tabButton(_ index: Int, _ label: String, _ icon: AnyView) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                icon.frame(height: 26)
                Text(label)
                    .font(.system(size: 11, weight: selectedTab == index ? .bold : .medium, design: .rounded))
                    .foregroundColor(tint(index))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
