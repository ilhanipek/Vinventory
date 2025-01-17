import Foundation

let baseUrl = "http://localhost:8080/api/v1"
let currentUserBaseUrl = "https://graph.microsoft.com/v1.0/me"

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
}

enum RequestError: Error {
  case badUrl
  case badModel
}

enum NetworkError: Error {
  case clientError
  case serverError
  case invalidResponse
  case unknown
}

protocol HTTPClientProtocol {
  func processRequest<T>(urlRequest: URLRequest, returningType: T.Type) async throws -> T where T: Decodable
}

class HTTPClient: HTTPClientProtocol {
  let mainVM = AppEnvironment.shared
  var jsonDecoder = JSONDecoder()
  var jsonEncoder = JSONEncoder()

  init() {
    jsonDecoder.dateDecodingStrategy = .iso8601
    jsonEncoder.dateEncodingStrategy = .iso8601
  }

  func processRequest<T>(urlRequest: URLRequest, returningType: T.Type) async throws -> T where T: Decodable {
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    let result = verifyResponse(data: data, response: response)
    switch result {
    case .success(let data):
      return try jsonDecoder.decode(returningType, from: data)
    case .failure(let error):
      throw error
    }
  }
  func processRequest(urlRequest: URLRequest) async throws {
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    let result = verifyResponse(data: data, response: response)
    switch result {
    case .success(let data):
      print(data)
    case .failure(let error):
      throw error
    }
  }


  func makeUrlRequest<Model: Encodable>(baseUrl: URL,
                                        path: String?,
                                        httpMethod: HTTPMethod,
                                        queryParameters: [String: String]? = nil,
                                        with model: Model? = nil) throws -> URLRequest {
    var url: URL
    if let path = path {
      url = baseUrl.appendingPathComponent(path)
    } else {
      url = baseUrl
    }
    if let queryParameters = queryParameters {
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
      if let newUrl = components?.url {
        url = newUrl
      }
    }
    var urlRequest = URLRequest(url: url)
    setAuthorizationHeader(request: &urlRequest)
    urlRequest.httpMethod = httpMethod.rawValue
    if let model = model, (httpMethod == .post || httpMethod == .put) {
      let jsonData = try jsonEncoder.encode(model)
      urlRequest.httpBody = jsonData
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    return urlRequest
  }
  func makeUrlRequest(baseUrl: URL,
                      path: String?,
                      httpMethod: HTTPMethod,
                      queryParameters: [String: String]? = nil) throws -> URLRequest {
    var url: URL
    if let path = path {
      url = baseUrl.appendingPathComponent(path)
    } else {
      url = baseUrl
    }
    if let queryParameters = queryParameters {
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
      if let newUrl = components?.url {
        url = newUrl
      }
    }
    var urlRequest = URLRequest(url: url)
    setAuthorizationHeader(request: &urlRequest)
    urlRequest.httpMethod = httpMethod.rawValue
    return urlRequest
  }
  func makeUrlRequestWithAccessToken(baseUrl: URL,
                                     path: String?,
                                     queryParameters: [String: String]? = nil) throws -> URLRequest {
      var url: URL
      if let path = path {
          url = baseUrl.appendingPathComponent(path)
      } else {
          url = baseUrl
      }
      if let queryParameters = queryParameters {
          var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
          components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
          if let newUrl = components?.url {
              url = newUrl
          }
      }
      var urlRequest = URLRequest(url: url)
      urlRequest.httpMethod = HTTPMethod.get.rawValue
      setAuthorizationHeaderWithAccessToken(request: &urlRequest)
      return urlRequest
  }

  private func setAuthorizationHeaderWithAccessToken(request: inout URLRequest) {
      if let accessToken = AppEnvironment.shared.accessToken {
          request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
      }
  }

  private func setAuthorizationHeader(request: inout URLRequest) {
    if let token = mainVM.idToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  private func verifyResponse(data: Data, response: URLResponse) -> Result<Data, Error> {
    guard let httpResponse = response as? HTTPURLResponse else {
      return .failure(NetworkError.invalidResponse)
    }
    switch httpResponse.statusCode {
    case 200...299:
      return .success(data)
    case 400...499:
      return .failure(NetworkError.clientError)
    case 500...599:
      return .failure(NetworkError.serverError)
    default:
      return .failure(NetworkError.unknown)
    }
  }
}
