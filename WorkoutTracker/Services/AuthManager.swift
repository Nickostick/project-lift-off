import Foundation
import FirebaseAuth
import Combine

/// Manages Firebase Authentication operations
final class AuthManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading = false
    @Published private(set) var error: AuthError?
    /// True while waiting for Firebase to restore auth state from keychain
    @Published private(set) var isCheckingAuth = true
    
    // MARK: - Private Properties
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {}
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    /// Setup listener for authentication state changes
    func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                // First callback means Firebase finished checking keychain
                if self?.isCheckingAuth == true {
                    self?.isCheckingAuth = false
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up with email and password
    @MainActor
    func signUp(email: String, password: String) async throws {
        guard !email.trimmed.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email.trimmed, password: password)
            self.currentUser = result.user
            print("✅ User signed up: \(result.user.uid)")
        } catch let authError as NSError {
            self.error = AuthError.from(authError)
            throw self.error!
        }
    }
    
    /// Sign in with email and password
    @MainActor
    func signIn(email: String, password: String) async throws {
        guard !email.trimmed.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw AuthError.wrongPassword
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email.trimmed, password: password)
            self.currentUser = result.user
            print("✅ User signed in: \(result.user.uid)")
        } catch let authError as NSError {
            self.error = AuthError.from(authError)
            throw self.error!
        }
    }
    
    /// Sign out current user
    @MainActor
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            print("✅ User signed out")
        } catch {
            throw AuthError.signOutFailed
        }
    }
    
    /// Send password reset email
    @MainActor
    func resetPassword(email: String) async throws {
        guard email.isValidEmail else {
            throw AuthError.invalidEmail
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email.trimmed)
            print("✅ Password reset email sent")
        } catch let authError as NSError {
            self.error = AuthError.from(authError)
            throw self.error!
        }
    }
    
    /// Update user display name
    @MainActor
    func updateDisplayName(_ name: String) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        
        // Refresh user
        try await user.reload()
        self.currentUser = Auth.auth().currentUser
    }
    
    /// Delete current user account
    @MainActor
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        try await user.delete()
        self.currentUser = nil
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidEmail
    case emailAlreadyInUse
    case wrongPassword
    case weakPassword
    case userNotFound
    case networkError
    case notAuthenticated
    case signOutFailed
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "This email is already registered. Try signing in."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .signOutFailed:
            return "Failed to sign out. Please try again."
        case .unknown(let message):
            return message
        }
    }
    
    /// Convert Firebase auth error to AuthError
    static func from(_ error: NSError) -> AuthError {
        guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
            return .unknown(error.localizedDescription)
        }
        
        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .wrongPassword:
            return .wrongPassword
        case .weakPassword:
            return .weakPassword
        case .userNotFound:
            return .userNotFound
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
