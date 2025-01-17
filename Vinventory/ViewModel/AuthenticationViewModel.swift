import Foundation
import _AuthenticationServices_SwiftUI

@Observable class AuthenticationViewModel {
  let wAS: WebAuthenticationSession
  var idToken: String? {
    didSet {
      AppEnvironment.shared.idToken = idToken
    }
  }

  init(wAS: WebAuthenticationSession) {
    self.wAS = wAS
  }

  func loginWithMicrosoft() {
    let clientId = "c132c4d6-8e26-47dc-a612-3adbcc833b2a"
    let tenantId = "04be5fbc-9a03-4766-9bed-0b63fa21d707"
    let redirectUri = "msauth.com.ilhanipek.Vinventory://auth"
    let scope = "openid profile email"

    guard var urlComponents = URLComponents(string: "https://login.microsoftonline.com/\(tenantId)/oauth2/v2.0/authorize") else {
      return
    }

    urlComponents.queryItems = [
      URLQueryItem(name: "client_id", value: clientId),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: redirectUri),
      URLQueryItem(name: "scope", value: scope)
    ]

    guard let url = urlComponents.url else {
      return
    }

    Task {
      do {
        let urlWithToken = try await wAS.authenticate(using: url,
                                                      callback: .customScheme("msauth.com.ilhanipek.Vinventory"),
                                                      preferredBrowserSession: .shared,
                                                      additionalHeaderFields: [:])
        handleCallbackURL(urlWithToken)
      } catch {
        print("Authentication error: \(error.localizedDescription)")
      }
    }
  }

  private func handleCallbackURL(_ url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      print("Invalid callback URL format")
      return
    }

    if let authorizationCode = queryItems.first(where: { $0.name == "code" })?.value {
      print("Authorization Code: \(authorizationCode)")
      Task {
        await exchangeCodeForToken(authorizationCode)
        do {
          let httpClient = HTTPClient()
          try await httpClient.getCurrentUser()
          if let currentUser = AppEnvironment.shared.currentUser {
            print("Current user: \(currentUser)")
          }
          print("3")
        } catch {
          print("Error getting current user: \(error)")
        }
      }
    } else {
      print("Authorization code not found in callback URL")
    }
  }

  private func exchangeCodeForToken(_ authorizationCode: String) async {
    let clientId = "c132c4d6-8e26-47dc-a612-3adbcc833b2a"
    let tenantId = "04be5fbc-9a03-4766-9bed-0b63fa21d707"
    let redirectUri = "msauth.com.ilhanipek.Vinventory://auth"
    let tokenEndpoint = "https://login.microsoftonline.com/\(tenantId)/oauth2/v2.0/token"

    guard let url = URL(string: tokenEndpoint) else {
      print("Invalid token endpoint URL")
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let bodyParameters = [
      "client_id": clientId,
      "scope": "openid profile email",
      "code": authorizationCode,
      "redirect_uri": redirectUri,
      "grant_type": "authorization_code"
    ]

    let bodyData = bodyParameters
      .map { "\($0.key)=\($0.value)" }
      .joined(separator: "&")
      .data(using: .utf8)

    request.httpBody = bodyData

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        print("Error exchanging code for token: \(error)")
        return
      }

      guard let response = response as? HTTPURLResponse else {
        print("Invalid response")
        return
      }
      if let data = data {
        do {
          if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let idToken = json["id_token"] as? String {
              DispatchQueue.main.async {
                self.idToken = idToken
                AppEnvironment.shared.idToken = idToken
              }
              print("ID Token: \(idToken)")
            } else {
              print("ID token not found in response")
            }
            if let accessToken = json["access_token"] as? String {
              AppEnvironment.shared.accessToken = accessToken
              Task {
                let httpClient = HTTPClient()
                do {
                  try await httpClient.getCurrentUser()

                } catch {
                  print("Error getting current user: \(error)")
                }
              }
            } else {
              print("Access token not found in response")
            }
          }
        } catch {
          print("Error parsing response data: \(error)")
        }
      }
    }
    task.resume()
  }

}
