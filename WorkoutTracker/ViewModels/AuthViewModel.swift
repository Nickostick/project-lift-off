import Foundation
import FirebaseAuth
import Combine

/// ViewModel for authentication state and operations
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    @Published var isSignUpMode = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var showResetPasswordAlert = false
    @Published var resetPasswordEmail = ""
    
    // MARK: - Dependencies
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        authManager.currentUser != nil
    }
    
    /// True while Firebase is restoring auth state from keychain
    var isCheckingAuth: Bool {
        authManager.isCheckingAuth
    }
    
    var currentUser: User? {
        authManager.currentUser
    }
    
    var currentUserId: String? {
        authManager.currentUser?.uid
    }
    
    var userDisplayName: String {
        currentUser?.displayName ?? currentUser?.email?.components(separatedBy: "@").first ?? "User"
    }
    
    var isFormValid: Bool {
        if isSignUpMode {
            return !email.isBlank && !password.isBlank && password == confirmPassword && password.count >= 6
        }
        return !email.isBlank && !password.isBlank
    }
    
    // MARK: - Initialization
    init(authManager: AuthManager = FirebaseService.shared.auth) {
        self.authManager = authManager
        setupBindings()
    }
    
    private func setupBindings() {
        authManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        authManager.$error
            .compactMap { $0?.errorDescription }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showError(message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// Sign in with current email/password
    func signIn() async {
        guard !email.isBlank, !password.isBlank else {
            showError("Please enter email and password")
            return
        }
        
        do {
            try await authManager.signIn(email: email, password: password)
            clearForm()
        } catch {
            // Error already handled by authManager
        }
    }
    
    /// Sign up with current email/password
    func signUp() async {
        guard password == confirmPassword else {
            showError("Passwords don't match")
            return
        }
        
        guard password.count >= 6 else {
            showError("Password must be at least 6 characters")
            return
        }
        
        do {
            try await authManager.signUp(email: email, password: password)
            
            // Update display name if provided
            if !displayName.isBlank {
                try await authManager.updateDisplayName(displayName)
            }
            
            clearForm()
        } catch {
            // Error already handled by authManager
        }
    }
    
    /// Sign out current user
    func signOut() {
        do {
            try authManager.signOut()
            clearForm()
        } catch {
            showError("Failed to sign out")
        }
    }
    
    /// Send password reset email
    func resetPassword() async {
        guard resetPasswordEmail.isValidEmail else {
            showError("Please enter a valid email address")
            return
        }
        
        do {
            try await authManager.resetPassword(email: resetPasswordEmail)
            showResetPasswordAlert = false
            resetPasswordEmail = ""
            showError("Password reset email sent!")
        } catch {
            // Error already handled
        }
    }
    
    /// Toggle between sign in and sign up modes
    func toggleMode() {
        isSignUpMode.toggle()
        clearForm()
    }
    
    // MARK: - Helper Methods
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        showError = false
        errorMessage = ""
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
