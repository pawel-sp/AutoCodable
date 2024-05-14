import Foundation

public extension KeyedDecodingContainer {
    func decode<T: Decodable>(for key: KeyedDecodingContainer<K>.Key) throws -> T {
        try decode(T.self, forKey: key)
    }

    func decodeIfPresent<T: Decodable>(for key: KeyedDecodingContainer<K>.Key) throws -> T? {
        try decodeIfPresent(T.self, forKey: key)
    }
}
