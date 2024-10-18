//  
//  Created by Terry Grossman.
//
//  This class is part of the Swift infrastructure implementation project.  It provides
//  the code typically required in world-class apps such as Tik-Tok or Instagram:
//    *A/B Testing support based on (anonymized) user id.
//    *Call monitoring 
//    *Crash Diagnostics
//    *Anonymizing users
//
//  This class This class handles non-trivial operations related to user management, such as:
//    *Logging in a user using email and password.
//    *Managing session persistence via UserDefaults.
//    *Implementing a retry mechanism for network requests during login.
//    *Handling the current user session, including retrieval, storage, and logout.
//
//   The class decouples data management (handled by the User model) from operations, 
//    ensuring a clean separation of responsibilities.
//
//  Key Features:
//    *Manage login with retry on timeout.
//    *Save and retrieve the current user using UserDefaults.
//    *Provide a logout method to clear user session and data.
//    *Loads current user on app startup
//
import Foundation

class UserOperations {
    // MARK: - Constants
    static let loginURL = "https://example.com/api/login"
    static let userDefaultsFirstNameKey = "currentUserFirstName"
    static let userDefaultsLastNameKey = "currentUserLastName"
    static let userDefaultsEmailKey = "currentUserEmail"
    static let userDefaultsPasswordHashKey = "currentUserPasswordHash"
    static let userDefaultsUserIDKey = "currentUserUserID"
    static let loginTimeoutInterval: TimeInterval = 1.5 // 1.5 second timeout
    static let maxLoginRetries: Int = 3 // Maximum number of retries for login
    
    // MARK: - Enum for User State
    enum UserState {
        case notLoggedIn
        case pendingVerification      
        case verified
    }
    
    // MARK: - Static Current User State Management
    static var currentUserState: UserState = {
        return currentUser == nil ? .notLoggedIn : .verified
    }()
    
    // Static variable to hold the current user and load from UserDefaults
    static var currentUser: User? = {
        let user = readCurrentUser()
        currentUserState = user == nil ? .notLoggedIn : .verified
        return user
    }()
    
    // MARK: - Async Login with Retry Mechanism
    static func loginUser(email: String, password: String) async -> User? {
        currentUserState = .pendingVerification

        let hashedPassword = User(firstName: "", lastName: "", email: email, userID: "", password: password).verifyPassword(password) ? password : ""
        
        // Await the async call to loginUserWithRetries
        return await loginUserWithRetries(email: email, passwordHash: hashedPassword, retriesLeft: maxLoginRetries)
    }

    // Internal method to handle retries (now async)
    private static func loginUserWithRetries(email: String, passwordHash: String, retriesLeft: Int) async -> User? {
        guard retriesLeft > 0 else {
            print("Login failed after maximum retries.")
            currentUserState = .notLoggedIn
            return nil
        }
        
        // Create the URL with the query parameters (email and hashed password)
        guard var urlComponents = URLComponents(string: loginURL) else {
            currentUserState = .notLoggedIn
            return nil
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "password", value: passwordHash)
        ]
        
        guard let url = urlComponents.url else {
            currentUserState = .notLoggedIn
            return nil
        }
        
        // Create a URLSession configuration with a timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = loginTimeoutInterval
        let session = URLSession(configuration: config)
        
         do {
            // Perform the request asynchronously using async/await
            let (data, response) = try await session.data(for: request)
            
            // Cast the response to HTTPURLResponse to access statusCode
            if let httpResponse = response as? HTTPURLResponse {
                // Check if the status code is 200 (OK)
                guard httpResponse.statusCode == 200 else {
                    print("Server error: \(httpResponse.statusCode)")
                    currentUserState = .notLoggedIn
                    return nil
                }
            }
            
            // Parse the response (assuming JSON format with fields: firstName, lastName, userID)
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
               let firstName = json["firstName"],
               let lastName = json["lastName"],
               let userID = json["userID"] {
                
                let user = User(firstName: firstName, lastName: lastName, email: email, userID: userID, password: passwordHash)
                currentUser = user
                currentUserState = .verified
                return user
            } else {
                currentUserState = .notLoggedIn
                return nil
            }
        } catch {
            // Handle timeout and retry if necessary
            if (error as NSError).code == NSURLErrorTimedOut {
                print("Request timed out. Retrying... (\(retriesLeft - 1) retries left)")
                return await loginUserWithRetries(email: email, passwordHash: passwordHash, retriesLeft: retriesLeft - 1)
            } else {
                print("Error during login request: \(error)")
                currentUserState = .notLoggedIn
                return nil
            }
        }
    }
    
    // MARK: - Logout Method
    static func logout() {
        clearCurrentUser()
        currentUser = nil
        currentUserState = .notLoggedIn
        print("User logged out. All stored data cleared.")
    }

    // MARK: - UserDefaults Operations

    private static func readCurrentUser() -> User? {
        let defaults = UserDefaults.standard
        guard let firstName = defaults.string(forKey: userDefaultsFirstNameKey),
              let lastName = defaults.string(forKey: userDefaultsLastNameKey),
              let email = defaults.string(forKey: userDefaultsEmailKey),
              let userID = defaults.string(forKey: userDefaultsUserIDKey),
              let passwordHash = defaults.string(forKey: userDefaultsPasswordHashKey) else {
            return nil
        }
        let user = User(firstName: firstName, lastName: lastName, email: email, userID: userID, password: "")
        user.updatePassword(newPassword: passwordHash) // Password is read as hash, not plain text
        return user
    }
    
    private static func saveCurrentUser(user: User) {
        let defaults = UserDefaults.standard
        defaults.set(user.firstName, forKey: userDefaultsFirstNameKey)
        defaults.set(user.lastName, forKey: userDefaultsLastNameKey)
        defaults.set(user.email, forKey: userDefaultsEmailKey)
        defaults.set(user.userID, forKey: userDefaultsUserIDKey)
        defaults.set(user.anonymousID(), forKey: userDefaultsPasswordHashKey)
    }
    
    private static func clearCurrentUser() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: userDefaultsFirstNameKey)
        defaults.removeObject(forKey: userDefaultsLastNameKey)
        defaults.removeObject(forKey: userDefaultsEmailKey)
        defaults.removeObject(forKey: userDefaultsUserIDKey)
        defaults.removeObject(forKey: userDefaultsPasswordHashKey)
    }
}
