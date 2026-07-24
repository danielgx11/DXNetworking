public enum HTTPMethod: String {
    case GET
    case POST
    case DELETE
    case PUT
    case PATCH

    public var stringValue: String {
        self.rawValue
    }
}
