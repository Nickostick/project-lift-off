import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for reports and statistics
@MainActor
final class ReportsViewModel: ObservableObject, ViewModelErrorHandling {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Summary stats
    @Published var totalWorkouts = 0
    @Published var totalVolume: Double = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var averageWorkoutDuration: TimeInterval = 0
    @Published var workoutsThisWeek = 0
    @Published var volumeThisWeek: Double = 0
    
    // Chart data
    @Published var weeklyVolumeData: [WeeklyVolumePoint] = []
    @Published var exerciseProgressData: [ExerciseProgress] = []
    @Published var workoutFrequencyData: [WorkoutFrequencyPoint] = []
    
    // PRs
    @Published var recentPRs: [PersonalRecord] = []
    @Published var allPRs: [PersonalRecord] = []
    
    // Time range selection
    @Published var selectedTimeRange: TimeRange = .month
    
    // Export
    @Published var showExportSheet = false
    @Published var exportURL: URL?
    
    // MARK: - Dependencies
    private let firestoreManager: FirestoreManager
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    private var listenerRegistration: ListenerRegistration?
    
    // MARK: - Time Range Enum
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        case allTime = "All Time"

        var shortLabel: String {
            switch self {
            case .week: return "1W"
            case .month: return "1M"
            case .threeMonths: return "3M"
            case .year: return "1Y"
            case .allTime: return "ALL"
            }
        }

        var startDate: Date {
            let calendar = Calendar.current
            switch self {
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            case .threeMonths:
                return calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            case .allTime:
                return calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
            }
        }
    }
    
    // MARK: - Initialization
    init(userId: String, firestoreManager: FirestoreManager = FirebaseService.shared.firestore) {
        self.userId = userId
        self.firestoreManager = firestoreManager
        setupListeners()
    }

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Data Loading

    private func setupListeners() {
        let result = firestoreManager.fetchPersonalRecords(userId: userId)
        listenerRegistration = result.registration

        result.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] records in
                self?.allPRs = records
                self?.recentPRs = Array(records.prefix(5))
            }
            .store(in: &cancellables)
    }
    
    /// Load all report data for the selected time range
    func loadReportData() async {
        isLoading = true
        
        let startDate = selectedTimeRange.startDate
        let endDate = Date()
        
        do {
            // Fetch logs for the time range
            let logs = try await firestoreManager.fetchWorkoutLogs(userId: userId, from: startDate, to: endDate)
            
            // Calculate summary stats
            calculateSummaryStats(from: logs)
            
            // Generate chart data
            generateWeeklyVolumeData(from: logs)
            generateWorkoutFrequencyData(from: logs)
            
            // This week stats
            let weekStart = Date().startOfWeek
            let thisWeekLogs = logs.filter { $0.startedAt >= weekStart }
            workoutsThisWeek = thisWeekLogs.count
            volumeThisWeek = thisWeekLogs.reduce(0) { $0 + $1.totalVolume }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Load progress data for a specific exercise
    func loadExerciseProgress(exerciseName: String) async {
        do {
            let dataPoints = try await firestoreManager.getExerciseProgress(userId: userId, exerciseName: exerciseName)
            let progress = ExerciseProgress(exerciseName: exerciseName, dataPoints: dataPoints)
            
            // Update or add to exercise progress data
            if let index = exerciseProgressData.firstIndex(where: { $0.exerciseName == exerciseName }) {
                exerciseProgressData[index] = progress
            } else {
                exerciseProgressData.append(progress)
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Calculations
    
    private func calculateSummaryStats(from logs: [WorkoutLog]) {
        totalWorkouts = logs.count
        totalVolume = logs.reduce(0) { $0 + $1.totalVolume }
        totalDuration = logs.reduce(0) { $0 + $1.duration }
        
        if totalWorkouts > 0 {
            averageWorkoutDuration = totalDuration / Double(totalWorkouts)
        } else {
            averageWorkoutDuration = 0
        }
    }
    
    private func generateWeeklyVolumeData(from logs: [WorkoutLog]) {
        let calendar = Calendar.current
        var weeklyData: [Date: Double] = [:]
        
        // Group logs by week
        for log in logs {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: log.startedAt)?.start ?? log.startedAt
            weeklyData[weekStart, default: 0] += log.totalVolume
        }
        
        // Convert to array and sort
        weeklyVolumeData = weeklyData.map { WeeklyVolumePoint(weekStart: $0.key, volume: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }
    
    private func generateWorkoutFrequencyData(from logs: [WorkoutLog]) {
        let calendar = Calendar.current
        var dailyData: [Date: Int] = [:]
        
        // Initialize last 7 days with 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date())?.startOfDay {
                dailyData[date] = 0
            }
        }
        
        // Count workouts per day
        for log in logs {
            let day = log.startedAt.startOfDay
            if dailyData[day] != nil {
                dailyData[day]! += 1
            }
        }
        
        // Convert to array and sort
        workoutFrequencyData = dailyData.map { WorkoutFrequencyPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Export
    
    /// Export data to CSV
    func exportToCSV() async {
        isLoading = true
        
        do {
            let logs = try await firestoreManager.fetchWorkoutLogs(userId: userId, from: selectedTimeRange.startDate, to: Date())
            
            if let url = ExportManager.shared.exportLogsToCSV(logs) {
                exportURL = url
                showExportSheet = true
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Export data to PDF
    func exportToPDF() async {
        isLoading = true
        
        do {
            let logs = try await firestoreManager.fetchWorkoutLogs(userId: userId, from: selectedTimeRange.startDate, to: Date())
            
            if let url = ExportManager.shared.exportSummaryToPDF(
                logs: logs,
                records: allPRs,
                totalVolume: totalVolume,
                workoutCount: totalWorkouts
            ) {
                exportURL = url
                showExportSheet = true
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
}

// MARK: - Chart Data Models
struct WeeklyVolumePoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let volume: Double
    
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }
}

struct WorkoutFrequencyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
