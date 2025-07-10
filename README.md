# AutoCodable

`AutoCodable` exposes Swift macros that generate code to fulfill `Encodable` and `Decodable` requirements when adding the protocol conformance to an extension of a type in a different file.

## Motivation

The Swift's built-in `Codable` API has a major advantage - it automatically synthesizes many different encoding and decoding implementations when using it. This behavior allows to easy create custom types and makes them conform to `Encodable` or `Decodable` without a need to implement `func encode(to encoder: Encoder) throws` or `init(from decoder: Decoder) throws` explicitly.

However, one of its limitations is the necessity to keep everything within the same file. It means that the following scenario may happen:

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String 
}

// User+Decodable.swift
extension User: Decodable {
    // 🛑 Extension outside of file declaring struct 'User' prevents 
    // automatic synthesis of 'init(from:)' for protocol 'Decodable'
}

// User+Encodable.swift
extension User: Encodable {
    // 🛑 Extension outside of file declaring struct 'User' prevents 
    // automatic synthesis of 'encode(to:)' for protocol 'Encodable'
}
```

There may be many reasons why you would like to keep the conformance to `Codable` or `Decodable` outside of the file with the type declaration. Unfortunately, in such cases, it's required to implement it explicitly. The `AutoDecodable` and `AutoEncodable` macro fills this gap. It allows to generation of necessary code and still keeps the declaration separate from the conformance to the protocols.

## Usage

### Encodable

<details>
<summary>@AutoEncodable</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String 
}

// User+Encodable.swift
@AutoEncodable
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }
}

🔽

// User+Encodable.swift
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
    }
}
```
</details>

<details>
<summary>@AutoEncodable + public access control</summary>

```swift
// User.swift
public struct User {
    public let firstName: String
    public let lastName: String
}

// User+Encodable.swift
@AutoEncodable(accessControl: .public)
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }
}

🔽

// User+Encodable.swift
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
    }
}
```
</details>

<details>
<summary>@AutoEncodable + singleValueContainer</summary>

```swift
// Identifier.swift
struct Identifier {
    let value: Int
}

// Identifier+Encodable.swift
//❗️The name associated with `singleValue` must match the property name inside the type.
@AutoEncodable(container: .singleValue("value"))
extension Identifier: Encodable {}

🔽

// Identifier+Encodable.swift
extension Identifier: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
```
</details>

<details>
<summary>@AutoEncodable + nestedContainer</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String
}

// User+Encodable.swift
@AutoEncodable
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case names
        
        //❗️The nested coding keys enum must follow the name convention: `CaseName` + `CodingKeys`
        enum NamesCodingKeys: String, CodingKey {
            case firstName
            case lastName
        }
    }
}

🔽

// User+Encodable.swift
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case names
        
        enum NamesCodingKeys: String, CodingKey {
            case firstName
            case lastName
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var namesContainer = container.nestedContainer(
            keyedBy: CodingKeys.NamesCodingKeys.self,
            forKey: .names
        )
        try namesContainer.encode(firstName, forKey: .firstName)
        try namesContainer.encode(lastName, forKey: .lastName)
    }
}
```
</details>

<details>
<summary>@AutoEncodable + ifPresent</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String?
}

// User+Encodable.swift
@AutoEncodable
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        @Conditional
        case lastName
    }
}

🔽

// User+Encodable.swift
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
    }
}
```

</details>

<details>
<summary>@AutoEncodable + enum</summary>

```swift
// Membership.swift
enum Membership {
    case regular
    case premium
}

// Membership+Encodable.swift
@AutoEncodable(container: .singleValueForEnum)
extension Membership: Encodable {
    enum CodingKeys: String, CodingKey {
        case regular
        case premium
    }
}

🔽

// Membership+Encodable.swift
extension Membership: Encodable {
    enum CodingKeys: String, CodingKey {
        case regular
        case premium
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .regular:
            try container.encode(CodingKeys.regular.rawValue)
        case .premium:
            try container.encode(CodingKeys.premium.rawValue)
        }
    }
}
```
</details>

<details>
<summary>@AutoEncodable + property custom encoding</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String
    let avatarUrl: URL
}

// User+Encodable.swift
@AutoEncodable
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        @EncodedValue(Avatar.self)
        case avatarUrl
    }

    private struct Avatar: EncodableValue {
        let path: String
        let `extension`: String

        init(from value: URL) {
            self.path = value.deletingPathExtension().absoluteString
            self.extension = value.pathExtension
        }
    }
}

🔽

// User+Encodable.swift
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        @EncodedValue(Avatar.self)
        case avatarUrl
    }

    private struct Avatar: EncodableValue {
        let path: String
        let `extension`: String

        init(from value: URL) {
            self.path = value.deletingPathExtension().absoluteString
            self.extension = value.pathExtension
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(Avatar(from: avatarUrl), forKey: .avatarUrl)
    }
}
```
</details>

### Decodable

<details>
<summary>@AutoDecodable</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String
}

// User+Decodable.swift
@AutoDecodable
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }
}

🔽

// User+Decodable.swift
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            firstName: container.decode(for: .firstName),
            lastName: container.decode(for: .lastName)
        )
    }
}
```
</details>

<details>
<summary>@AutoDecodable + public access control</summary>

```swift
// User.swift
public struct User {
    public let firstName: String
    public let lastName: String
}

// User+Decodable.swift
@AutoDecodable(accessControl: .public)
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }
}

🔽

// User+Decodable.swift
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            firstName: container.decode(for: .firstName),
            lastName: container.decode(for: .lastName)
        )
    }
}
```
</details>

<details>
<summary>@AutoDecodable + singleValueContainer</summary>

```swift
// Identifier.swift
struct Identifier {
    let value: Int
}

// Identifier+Decodable.swift
//❗️The name associated with `singleValue` must match the property name inside the type.
@AutoDecodable(container: .singleValue("value"))
extension Identifier: Encodable {}

🔽

// Identifier+Decodable.swift
extension Identifier: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(value: container.decode())
    }
}
```
</details>

<details>
<summary>@AutoDecodable + nestedContainer</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String
}

// User+Decodable.swift
@AutoDecodable
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case names
        
        //❗️The nested coding keys enum must follow the name convention: `CaseName` + `CodingKeys`
        enum NamesCodingKeys: String, CodingKey {
            case firstName
            case lastName
        }
    }
}

🔽

// User+Decodable.swift
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case names
        
        enum NamesCodingKeys: String, CodingKey {
            case firstName
            case lastName
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let namesContainer = try container.nestedContainer(
            keyedBy: CodingKeys.NamesCodingKeys.self,
            forKey: .names
        )
        try self.init(
            firstName: namesContainer.decode(for: .firstName),
            lastName: namesContainer.decode(for: .lastName)
        )
    }
}
```
</details>

<details>
<summary>@AutoDecodable + ifPresent</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String?
}

// User+Decodable.swift
@AutoDecodable
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        @Conditional
        case lastName
    }
}

🔽

// User+Decodable.swift
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            firstName: container.decode(for: .firstName),
            lastName: container.decodeIfPresent(for: .lastName)
        )
    }
}
```
</details>

<details>
<summary>@AutoDecodable + enum</summary>

```swift
// Membership.swift
enum Membership {
    case regular
    case premium
}

// Membership+Decodable.swift
@AutoDecodable(container: .singleValueForEnum)
extension Membership: Decodable {
    enum CodingKeys: String, CodingKey {
        case regular
        case premium
    }
}

🔽

// Membership+Decodable.swift
extension Membership: Decodable {
    enum CodingKeys: String, CodingKey {
        case regular
        case premium
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        switch stringValue {
        case CodingKeys.regular.rawValue:
            self = .regular
        case CodingKeys.premium.rawValue:
            self = .premium
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid value: \(stringValue)"
            )
        }
    }
}
```
</details>

<details>
<summary>@AutoDecodable + property custom decoding</summary>

```swift
// User.swift
struct User {
    let firstName: String
    let lastName: String
    let avatarUrl: URL?
}

// User+Decodable.swift
@AutoDecodable
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        @DecodedValue(Avatar.self)
        case avatarUrl
    }

    private struct Avatar: DecodableValue {
        let path: String
        let `extension`: String

        func value() -> URL? {
            .init(string: path + "." + `extension`)
        }
    }
}

🔽

// User+Decodable.swift
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        @DecodedValue(Avatar.self)
        case avatarUrl
    }

    private struct Avatar: DecodableValue {
        let path: String
        let `extension`: String

        func value() -> URL? {
            .init(string: path + "." + `extension`)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            firstName: container.decode(for: .firstName),
            lastName: container.decode(for: .lastName),
            avatarUrl: container.decode(Avatar.self, forKey: .avatarUrl).value()
        )
    }
}
```
</details>

## License

`AutoCodable` is released under the MIT license. See the [LICENSE](LICENSE) file for more info.