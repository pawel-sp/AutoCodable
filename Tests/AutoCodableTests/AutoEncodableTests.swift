import AutoCodable
import XCTest

final class AutoEncodableTests: XCTestCase {
    func testParsingModelWithAutoEncodable() throws {
        let user = User(
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]

        let data = try encoder.encode(user)
        let dataString = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertEqual(
            dataString,
            """
            {
              "address" : {
                "line1" : "Street name",
                "line2" : "City name"
              },
              "age" : {
                "birthday" : "2001-12-31T23:00:00Z"
              },
              "avatar_url" : {
                "extension" : "jpg",
                "path" : "http://images.com/avatar"
              },
              "contact" : {
                "email" : "me@mail.com",
                "mobile" : {
                  "dial_code" : "00",
                  "number" : "123 456 789"
                }
              },
              "id" : 123,
              "membership" : "user_gold",
              "names" : {
                "first_name" : "John",
                "last_name" : "Doe"
              }
            }
            """
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

@AutoEncodable
extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case names
        case address
        @EncodedValue(Avatar.self)
        case avatarUrl = "avatar_url"
        @EncodedValue(Age.self)
        case age
        case contact
        case membership

        enum NamesCodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
        }

        enum ContactCodingKeys: String, CodingKey {
            case email
            @EncodedValue(PhoneNumber.self)
            case phoneNumber = "mobile"
        }
    }

    private struct Avatar: EncodableValue {
        let path: String?
        let `extension`: String?

        init(from value: URL?) {
            path = value?.deletingPathExtension().absoluteString
            self.extension = value?.pathExtension
        }
    }

    private struct Age: EncodableValue {
        let dateOfBirth: Date

        enum CodingKeys: String, CodingKey {
            case dateOfBirth = "birthday"
        }

        init(from value: Int) {
            let calendar = Calendar.current
            let birthYear = calendar.component(.year, from: .now) - value
            var dateComponents = DateComponents()
            dateComponents.year = birthYear
            dateOfBirth = calendar.date(from: dateComponents)!
        }
    }

    private struct PhoneNumber: EncodableValue {
        let dialCode: String
        let number: String

        enum CodingKeys: String, CodingKey {
            case dialCode = "dial_code"
            case number
        }

        init(from value: String) {
            dialCode = String(value.prefix(3).dropFirst())
            number = String(value.dropFirst(4))
        }
    }
}

@AutoEncodable
extension Address: Encodable {
    enum CodingKeysAAA: String, CodingKey {
        case line1
        case line2
    }
}

@AutoEncodable(container: .singleValue("value"))
extension Identifier: Encodable {}

@AutoEncodable(container: .singleValueForEnum)
extension Membership: Encodable {
    enum CodingKeys: String, CodingKey {
        case premium = "user_premium"
        case gold = "user_gold"
    }
}
