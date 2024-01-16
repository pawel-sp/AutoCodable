import Foundation

public extension KeyedDecodingContainer {
    func decode<T: Decodable>(for key: KeyedDecodingContainer<K>.Key) throws -> T {
        try decode(T.self, forKey: key)
    }
}
