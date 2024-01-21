import AutoCodableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let testMacros: [String: Macro.Type] = [
    "AutoDecodable": AutoDecodableMacro.self,
]

final class AutoDecodableMacroTests: XCTestCase {
    // MARK: Keyed Container

    func testDefaultMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoDecodable
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    try self.init(
                        bar: container.decode(for: .bar),
                        baz: container.decode(for: .baz)
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    func testInternalAccessControlMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoDecodable(accessControl: .internal)
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    try self.init(
                        bar: container.decode(for: .bar),
                        baz: container.decode(for: .baz)
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    func testPublicAccessControlMacro() {
        assertMacroExpansion(
            """
            public struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoDecodable(accessControl: .public)
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }
            }
            """,
            expandedSource:
            """
            public struct Foo {
                let bar: Int
                let baz: String
            }
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    try self.init(
                        bar: container.decode(for: .bar),
                        baz: container.decode(for: .baz)
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: Single Value Container

    func testSingleValueContainerMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
            }
            @AutoDecodable(container: .singleValue("bar"))
            extension Foo: Decodable {
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
            }
            extension Foo: Decodable {

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    try self.init(bar: container.decode())
                }
            }
            """,
            macros: testMacros
        )
    }

    func testSingleValueContainerWithPublicAccessControlMacro() {
        assertMacroExpansion(
            """
            public struct Foo {
                let bar: Int
            }
            @AutoDecodable(accessControl: .public, container: .singleValue("bar"))
            extension Foo: Decodable {
            }
            """,
            expandedSource:
            """
            public struct Foo {
                let bar: Int
            }
            extension Foo: Decodable {

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    try self.init(bar: container.decode())
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: Single Value Container for enums

    func testSingleValueContainerMacroForEnum() {
        assertMacroExpansion(
            """
            enum Foo {
                case bar
                case baz
            }
            @AutoDecodable(container: .singleValueForEnum)
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }
            }
            """,
            expandedSource:
            """
            enum Foo {
                case bar
                case baz
            }
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let stringValue = try container.decode(String.self)
                    switch stringValue {
                    case CodingKeys.bar.rawValue:
                        self = .bar
                    case CodingKeys.baz.rawValue:
                        self = .baz
                    default:
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Invalid value: \\(stringValue)"
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: DecodedValue

    func testDecodeToMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoDecodable
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    @DecodedValue(Baz.self)
                    case baz
                }

                private struct Baz: DecodableValue {
                    let value1: String
                    let value2: String

                    func value() -> String {
                        value1 + value2
                    }
                }
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    @DecodedValue(Baz.self)
                    case baz
                }

                private struct Baz: DecodableValue {
                    let value1: String
                    let value2: String

                    func value() -> String {
                        value1 + value2
                    }
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    try self.init(
                        bar: container.decode(for: .bar),
                        baz: container.decode(Baz.self, forKey: .baz).value()
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: Nested Coding Keys

    func testDefaultMacroWithNestedCodingKeys() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoDecodable
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case qux

                    enum QuxCodingKeys: String, CodingKey {
                        case baz
                    }
                }
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case qux

                    enum QuxCodingKeys: String, CodingKey {
                        case baz
                    }
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let quxContainer = try container.nestedContainer(
                        keyedBy: CodingKeys.QuxCodingKeys.self,
                        forKey: .qux
                    )
                    try self.init(
                        bar: container.decode(for: .bar),
                        baz: quxContainer.decode(for: .baz)
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: Nested Coding Keys + DecodedValue

    func testDefaultMacroWithNestedCodingKeysUsingDecodedValue() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoDecodable
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case qux

                    enum QuxCodingKeys: String, CodingKey {
                        @DecodedValue(Baz.self)
                        case baz
                    }
                }

                private struct Baz: DecodableValue {
                    let value1: String
                    let value2: String

                    func value() -> String {
                        value1 + value2
                    }
                }
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            extension Foo: Decodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case qux

                    enum QuxCodingKeys: String, CodingKey {
                        @DecodedValue(Baz.self)
                        case baz
                    }
                }

                private struct Baz: DecodableValue {
                    let value1: String
                    let value2: String

                    func value() -> String {
                        value1 + value2
                    }
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let quxContainer = try container.nestedContainer(
                        keyedBy: CodingKeys.QuxCodingKeys.self,
                        forKey: .qux
                    )
                    try self.init(
                        bar: container.decode(for: .bar),
                        baz: quxContainer.decode(Baz.self, forKey: .baz).value()
                    )
                }
            }
            """,
            macros: testMacros
        )
    }
}
