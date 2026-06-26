import Foundation

enum UsersTarget: Endpoint {
    case allUsers
    case userById(Int)

    var baseUrl: String {
        "https://dummyjson.com"
    }

    var path: String {
        switch self {
        case .allUsers:
            return "/users"
        case let .userById(id):
            return "/users/\(id)"
        }
    }

    var headers: [String : String]? {
        switch self {
        case .allUsers, .userById:
            return nil
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .allUsers, .userById:
            return .GET
        }
    }

    var body: Data? {
        switch self {
        case .allUsers, .userById:
            return nil
        }
    }

    var queryParameters: [URLQueryItem]? {
        switch self {
        case .allUsers, .userById:
            return nil
        }
    }

    var retries: Int {
        switch self {
        default: 2
        }
    }
}
