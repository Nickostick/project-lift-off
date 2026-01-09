import SwiftUI

/// Authentication view for login and signup - Premium dark theme
struct AuthenticationView: View {
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword, displayName
    }

    var body: some View {
        ZStack {
            // Pure black background
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "666666"))

                            Text("SECURE ACCESS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "666666"))
                                .tracking(0.8)
                        }

                        Text(viewModel.isSignUpMode ? "Create Account" : "Welcome\nBack")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineSpacing(2)

                        Text(viewModel.isSignUpMode ? "Sign up to sync your workout data and access your personalized routines." : "Sign in to sync your workout data and access your personalized routines.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color(hex: "999999"))
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    // Form Section
                    VStack(spacing: 16) {
                        if viewModel.isSignUpMode {
                            MinimalTextField(
                                icon: "person.fill",
                                placeholder: "Display Name (optional)",
                                text: $viewModel.displayName
                            )
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .focused($focusedField, equals: .displayName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }
                        }

                        MinimalTextField(
                            icon: viewModel.isSignUpMode ? "envelope.fill" : "person.fill",
                            placeholder: viewModel.isSignUpMode ? "Email" : "EMAIL OR USERNAME",
                            text: $viewModel.email
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                        MinimalSecureField(
                            icon: "lock.fill",
                            placeholder: "PASSWORD",
                            text: $viewModel.password
                        )
                        .textContentType(viewModel.isSignUpMode ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(viewModel.isSignUpMode ? .next : .go)
                        .onSubmit {
                            if viewModel.isSignUpMode {
                                focusedField = .confirmPassword
                            } else {
                                Task { await viewModel.signIn() }
                            }
                        }

                        if viewModel.isSignUpMode {
                            MinimalSecureField(
                                icon: "lock.shield.fill",
                                placeholder: "CONFIRM PASSWORD",
                                text: $viewModel.confirmPassword
                            )
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.go)
                            .onSubmit {
                                Task { await viewModel.signUp() }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Action Button
                    VStack(spacing: 16) {
                        Button(action: {
                            Task {
                                if viewModel.isSignUpMode {
                                    await viewModel.signUp()
                                } else {
                                    await viewModel.signIn()
                                }
                            }
                        }) {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1A1A1A")))
                                } else {
                                    Text(viewModel.isSignUpMode ? "CREATE ACCOUNT" : "LOGIN")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(0.5)

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundStyle(Color(hex: "1A1A1A"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                viewModel.isFormValid && !viewModel.isLoading
                                    ? .white
                                    : Color(hex: "2A2A2A")
                            )
                            .cornerRadius(24)
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)

                        if !viewModel.isSignUpMode {
                            Button("Forgot Password?") {
                                viewModel.resetPasswordEmail = viewModel.email
                                viewModel.showResetPasswordAlert = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "999999"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Toggle Mode
                    HStack(spacing: 4) {
                        Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(Color(hex: "999999"))

                        Button(viewModel.isSignUpMode ? "Sign In" : "Sign Up") {
                            withAnimation(AppTheme.Animation.spring) {
                                viewModel.toggleMode()
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryBlue)
                    }
                    .font(.system(size: 14, weight: .regular))
                    .padding(.top, 16)

                    Spacer(minLength: 50)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Reset Password", isPresented: $viewModel.showResetPasswordAlert) {
            TextField("Email", text: $viewModel.resetPasswordEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            Button("Send Reset Link") {
                Task { await viewModel.resetPassword() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email to receive a password reset link.")
        }
    }
}

// MARK: - Minimal Text Field

struct MinimalTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "666666"))
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
    }
}

// MARK: - Minimal Secure Field

struct MinimalSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "666666"))
                .frame(width: 20)

            SecureField(placeholder, text: $text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
    }
}

#Preview {
    AuthenticationView()
}
