import SwiftUI
import FirebaseAuth

/// Main content view that handles authentication state routing
struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView(userId: authViewModel.currentUserId ?? "")
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

/// Main tab-based navigation for authenticated users
struct MainTabView: View {
    let userId: String
    
    @StateObject private var programViewModel: ProgramViewModel
    @StateObject private var logViewModel: WorkoutLogViewModel
    @StateObject private var levelViewModel: LevelViewModel
    @State private var selectedTab = Tab.home
    @State private var showStartWorkout = false
    
    enum Tab {
        case home, programs, reports, settings
    }
    
    init(userId: String) {
        self.userId = userId
        _programViewModel = StateObject(wrappedValue: ProgramViewModel(userId: userId))

        let logVM = WorkoutLogViewModel(userId: userId)
        let levelVM = LevelViewModel(userId: userId)

        // Connect ViewModels
        logVM.levelViewModel = levelVM

        _logViewModel = StateObject(wrappedValue: logVM)
        _levelViewModel = StateObject(wrappedValue: levelVM)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView_Premium(logViewModel: logViewModel, programViewModel: programViewModel, levelViewModel: levelViewModel)
                case .programs:
                    ProgramListView_Premium(viewModel: programViewModel)
                case .reports:
                    ReportsView_Premium(userId: userId, logViewModel: logViewModel)
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
            
            // Premium Custom Tab Bar
            PremiumTabBar(selectedTab: $selectedTab) {
                showStartWorkout = true
            }
        }
        .sheet(isPresented: $showStartWorkout) {
            StartWorkoutSheet(
                programViewModel: programViewModel,
                onSelect: { program, day in
                    logViewModel.startWorkout(from: day, program: program)
                    showStartWorkout = false
                },
                onQuickStart: {
                    logViewModel.startBlankWorkout()
                    showStartWorkout = false
                }
            )
        }
        .fullScreenCover(isPresented: $logViewModel.isWorkoutActive) {
            ActiveWorkoutView(viewModel: logViewModel)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let onStartWorkout: () -> Void
    
    var body: some View {
        HStack {
            // Home
            TabButton(icon: "house.fill", title: "Home", isSelected: selectedTab == .home) {
                selectedTab = .home
            }
            
            Spacer()
            
            // Programs
            TabButton(icon: "doc.text.fill", title: "Programs", isSelected: selectedTab == .programs) {
                selectedTab = .programs
            }
            
            Spacer()
            
            // Start Workout Button
            Button(action: onStartWorkout) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -20)
            
            Spacer()
            
            // Reports
            TabButton(icon: "chart.bar.fill", title: "Reports", isSelected: selectedTab == .reports) {
                selectedTab = .reports
            }
            
            Spacer()
            
            // Settings
            TabButton(icon: "gearshape.fill", title: "Settings", isSelected: selectedTab == .settings) {
                selectedTab = .settings
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 1)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .blue : .secondary)
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

/// Settings view for app configuration
struct SettingsView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationManager = NotificationManager.shared

    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @AppStorage(Constants.UserDefaultsKeys.preferredWeightUnit) private var weightUnit = WeightUnit.pounds.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                // Pure black background
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Profile Card
                        if let user = authViewModel.currentUser {
                            profileCard(user: user)
                                .padding(.horizontal, 16)
                        }

                        // Preferences Section
                        preferencesSection
                            .padding(.horizontal, 16)

                        // Notifications Section
                        notificationsSection
                            .padding(.horizontal, 16)

                        // About Section
                        aboutSection
                            .padding(.horizontal, 16)

                        // Sign Out Button
                        signOutButton
                            .padding(.horizontal, 16)

                        // Delete Account Button
                        deleteAccountButton
                            .padding(.horizontal, 16)

                        // Spacer for tab bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.vertical, 16)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? await FirebaseService.shared.auth.deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))

                Text("PROFILE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.8)
            }

            Text("Settings")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)

            Text("Manage your account and app preferences.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "999999"))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Profile Card

    private func profileCard(user: FirebaseAuth.User) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: "2A2A2A"))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(user.email?.prefix(1).uppercased() ?? "U"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppTheme.neonGreen)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName ?? "User")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)

                Text(user.email ?? "")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "999999"))
            }

            Spacer()
        }
        .padding(20)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREFERENCES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "666666"))
                .tracking(0.8)

            VStack(spacing: 0) {
                HStack {
                    Text("Weight Unit")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white)

                    Spacer()

                    Menu {
                        ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                            Button(action: {
                                weightUnit = unit.rawValue
                            }) {
                                HStack {
                                    Text(unit.fullName)
                                    if weightUnit == unit.rawValue {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(WeightUnit(rawValue: weightUnit)?.fullName ?? "Pounds")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "999999"))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "666666"))
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(16)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NOTIFICATIONS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "666666"))
                .tracking(0.8)

            VStack(spacing: 1) {
                HStack {
                    Text("Workout Reminders")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white)

                    Spacer()

                    Toggle("", isOn: $notificationManager.reminderEnabled)
                        .labelsHidden()
                        .tint(AppTheme.neonGreen)
                        .onChange(of: notificationManager.reminderEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await notificationManager.requestAuthorization()
                                    if !granted {
                                        notificationManager.reminderEnabled = false
                                    } else {
                                        notificationManager.saveSettings()
                                    }
                                }
                            } else {
                                notificationManager.saveSettings()
                            }
                        }
                }
                .padding(16)
                .background(Color(hex: "1A1A1A"))

                if notificationManager.reminderEnabled {
                    NavigationLink {
                        ReminderSettingsView()
                    } label: {
                        HStack {
                            Text("Reminder Schedule")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "666666"))
                        }
                        .padding(16)
                        .background(Color(hex: "1A1A1A"))
                    }
                }
            }
            .cornerRadius(16)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ABOUT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "666666"))
                .tracking(0.8)

            VStack(spacing: 1) {
                HStack {
                    Text("Version")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(Constants.App.appVersion)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "999999"))
                }
                .padding(16)
                .background(Color(hex: "1A1A1A"))

                Link(destination: URL(string: "https://firebase.google.com")!) {
                    HStack {
                        Text("Powered by Firebase")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "666666"))
                    }
                    .padding(16)
                    .background(Color(hex: "1A1A1A"))
                }
            }
            .cornerRadius(16)
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button(action: { showSignOutAlert = true }) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .semibold))

                Text("SIGN OUT")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(Color(hex: "1A1A1A"))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white)
            .cornerRadius(24)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delete Account Button

    private var deleteAccountButton: some View {
        Button(action: { showDeleteAccountAlert = true }) {
            Text("Delete Account")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.plain)
    }
}

/// Reminder settings view for notification configuration
struct ReminderSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var reminderDate = Date()
    
    private let weekdays = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]
    
    var body: some View {
        List {
            Section("Reminder Time") {
                DatePicker(
                    "Time",
                    selection: $reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: reminderDate) { _, newDate in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                    notificationManager.reminderTime = components
                    notificationManager.saveSettings()
                }
            }
            
            Section("Reminder Days") {
                ForEach(weekdays, id: \.0) { weekday, name in
                    Toggle(name, isOn: Binding(
                        get: { notificationManager.reminderDays.contains(weekday) },
                        set: { isOn in
                            if isOn {
                                notificationManager.reminderDays.insert(weekday)
                            } else {
                                notificationManager.reminderDays.remove(weekday)
                            }
                            notificationManager.saveSettings()
                        }
                    ))
                }
            }
        }
        .navigationTitle("Reminder Schedule")
        .onAppear {
            // Set initial date from reminder time
            var components = DateComponents()
            components.hour = notificationManager.reminderTime.hour ?? 9
            components.minute = notificationManager.reminderTime.minute ?? 0
            if let date = Calendar.current.date(from: components) {
                reminderDate = date
            }
        }
    }
}

#Preview {
    ContentView()
}
