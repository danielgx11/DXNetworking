enum HTTPMethod: String {
    case GET
    case POST
    case DELETE
    case PUT
    case PATCH

    // TODO: - Phase 1 #7 — stringValue is redundant; rawValue already returns the HTTP verb string. Remove this and update callers.
    var stringValue: String {
        self.rawValue
    }
}
