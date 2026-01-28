import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of the current day
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
    
    /// Start of the current week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// End of the current week
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }
    
    /// Start of the current month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Formatted string for display
    var formattedShort: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    var formattedMedium: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    var formattedWithTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var formattedRelative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is this week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Days ago from now
    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }
}

// MARK: - String Extensions
extension String {
    /// Trimmed string with no leading/trailing whitespace
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Check if string is empty or only whitespace
    var isBlank: Bool {
        trimmed.isEmpty
    }
}

// MARK: - Double Extensions
extension Double {
    /// Format as weight string
    func formatAsWeight(unit: WeightUnit = .pounds) -> String {
        if self == floor(self) {
            return "\(Int(self)) \(unit.abbreviation)"
        }
        return String(format: "%.1f %@", self, unit.abbreviation)
    }
    
    /// Format as volume (e.g., 1,000 lbs)
    var formattedVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    /// Format as duration string (e.g., "1h 30m")
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Format as timer string (e.g., "01:30:45")
    var formattedTimer: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - View Extensions
extension View {
    /// Apply card styling
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
    }
    
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Color Extensions
extension Color {
    /// Brand colors
    static let brandPrimary = Color("BrandPrimary", bundle: nil)
    static let brandSecondary = Color("BrandSecondary", bundle: nil)
    
    /// Semantic colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let prGold = Color.yellow
    
    /// Gradient colors for charts
    static let chartGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - ViewModel Error Handling

/// Shared error handling for ViewModels to eliminate duplicate handleError methods
protocol ViewModelErrorHandling: AnyObject {
    var showError: Bool { get set }
    var errorMessage: String { get set }
}

extension ViewModelErrorHandling {
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        #if DEBUG
        print("❌ \(type(of: self)) error: \(error)")
        #endif
    }
}

// MARK: - Array Extensions
extension Array {
    /// Safe subscript that returns nil for out of bounds
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Identifiable {
    /// Find index of element by ID
    func index(of element: Element) -> Int? {
        firstIndex(where: { $0.id == element.id })
    }
    
    /// Remove element by ID
    mutating func remove(_ element: Element) {
        if let index = index(of: element) {
            remove(at: index)
        }
    }
}
