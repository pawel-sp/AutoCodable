import AutoCodable
import XCTest

final class AutoDecodabloTests: XCTestCase {
    func testParsingModelWithAutoDecodable() throws {
        let jsonString = """
            {
                "id": 123,
                "names": {
                    "first_name": "John",
                    "last_name": "Doe",
                },
                "address": {
                    "line1": "Street name",
                    "line2": "City name"
                },
                "avatar_url": {
                    "path": "http://images.com/avatar",
                    "extension": "jpg"
                },
                "age": {
                    "birthday": "2001-02-15T18:32:53+0000"
                },
                "contact": {
                    "email": "me@mail.com",
                    "mobile": {
                        "dial_code": "00",
                        "number": "123 456 789"
                    }
                },
                "membership": "user_gold"
            }
        """
        let jsonData = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let user = try decoder.decode(User.self, from: jsonData)

        XCTAssertEqual(
            user,
            .init(
                identifier: .init(value: 123),
                firstName: "John",
                lastName: "Doe",
                address: .init(
                    line1: "Street name",
                    line2: "City name"
                ),
                avatarUrl: .init(string: "http://images.com/avatar.jpg")!,
                age: 22,
                email: "me@mail.com",
                phoneNumber: "+00 123 456 789",
                membership: .gold
            )
        )
    }
}

// MARK: SUT

private struct User: Equatable {
    let identifier: Identifier
    let firstName: String
    let lastName: String
    let address: Address
    let avatarUrl: URL?
    let age: Int
    let email: String
    let phoneNumber: String
    let membership: Membership
}

private struct Identifier: Equatable {
    let value: Int
}

private struct Address: Equatable {
    let line1: String
    let line2: String
}

private enum Membership: Equatable {
    case premium
    case gold
}

@AutoDecodable
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case names
        case address
        @DecodedValue(Avatar.self)
        case avatarUrl = "avatar_url"
        @DecodedValue(Age.self)
        case age
        case contact
        case membership

        enum NamesCodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
        }

        enum ContactCodingKeys: String, CodingKey {
            case email
            @DecodedValue(PhoneNumber.self)
            case phoneNumber = "mobile"
        }
    }

    private struct Avatar: DecodableValue {
        let path: String
        let `extension`: String

        func value() -> URL? {
            .init(string: path + "." + `extension`)
        }
    }

    private struct Age: DecodableValue {
        let dateOfBirth: Date

        enum CodingKeys: String, CodingKey {
            case dateOfBirth = "birthday"
        }

        func value() -> Int {
            Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year!
        }
    }

    private struct PhoneNumber: DecodableValue {
        let dialCode: String
        let number: String

        enum CodingKeys: String, CodingKey {
            case dialCode = "dial_code"
            case number
        }

        func value() -> String {
            "+" + dialCode + " " + number
        }
    }
}

@AutoDecodable
extension Address: Decodable {
    enum CodingKeysAAA: String, CodingKey {
        case line1
        case line2
    }
}

@AutoDecodable(container: .singleValue("value"))
extension Identifier: Decodable {}

@AutoDecodable(container: .singleValueForEnum)
extension Membership: Decodable {
    enum CodingKeys: String, CodingKey {
        case premium = "user_premium"
        case gold = "user_gold"
    }
}
