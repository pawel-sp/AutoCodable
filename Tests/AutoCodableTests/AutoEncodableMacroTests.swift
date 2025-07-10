import AutoCodableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let testMacros: [String: Macro.Type] = [
    "AutoEncodable": AutoEncodableMacro.self,
    "EncodedValue": EncodedValueMacro.self,
    "Conditional": ConditionalMacro.self
]

final class AutoEncodableMacroTests: XCTestCase {
    // MARK: Keyed Container

    func testDefaultMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoEncodable
            extension Foo: Encodable {
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
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(bar, forKey: .bar)
                    try container.encode(baz, forKey: .baz)
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
            @AutoEncodable(accessControl: .internal)
            extension Foo: Encodable {
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
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(bar, forKey: .bar)
                    try container.encode(baz, forKey: .baz)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testPublicAccessControlMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoEncodable(accessControl: .public)
            extension Foo: Encodable {
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
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(bar, forKey: .bar)
                    try container.encode(baz, forKey: .baz)
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
            @AutoEncodable(container: .singleValue("bar"))
            extension Foo: Encodable {
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
            }
            extension Foo: Encodable {

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(bar)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testSingleValueContainerWithPublicAccessControlMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
            }
            @AutoEncodable(accessControl: .public, container: .singleValue("bar"))
            extension Foo: Encodable {
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
            }
            extension Foo: Encodable {

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(bar)
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
            @AutoEncodable(container: .singleValueForEnum)
            extension Foo: Encodable {
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
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    switch self {
                    case .bar:
                        try container.encode(CodingKeys.bar.rawValue)
                    case .baz:
                        try container.encode(CodingKeys.baz.rawValue)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: Conditional

    func testConditionalMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String?
            }
            @AutoEncodable
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    @Conditional
                    case baz
                }
            }
            """,
            expandedSource:
            """
            struct Foo {
                let bar: Int
                let baz: String?
            }
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(bar, forKey: .bar)
                    try container.encodeIfPresent(baz, forKey: .baz)
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: EncodedValue

    func testEncodedValueMacro() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoEncodable
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    @EncodedValue(Baz.self)
                    case baz
                }

                private struct Baz: EncodableValue {
                    let value1: String
                    let value2: String

                    init(from value: String) {
                        self.value1 = value.prefix(2)
                        self.value2 = value.suffix(2)
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
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case baz
                }

                private struct Baz: EncodableValue {
                    let value1: String
                    let value2: String

                    init(from value: String) {
                        self.value1 = value.prefix(2)
                        self.value2 = value.suffix(2)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(bar, forKey: .bar)
                    try container.encode(Baz(from: baz), forKey: .baz)
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
            @AutoEncodable
            extension Foo: Encodable {
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
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case qux

                    enum QuxCodingKeys: String, CodingKey {
                        case baz
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    var quxContainer = container.nestedContainer(
                        keyedBy: CodingKeys.QuxCodingKeys.self,
                        forKey: .qux
                    )
                    try container.encode(bar, forKey: .bar)
                    try quxContainer.encode(baz, forKey: .baz)
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: Nested Coding Keys + EncodedValue

    func testDefaultMacroWithNestedCodingKeysUsingEncodedValue() {
        assertMacroExpansion(
            """
            struct Foo {
                let bar: Int
                let baz: String
            }
            @AutoEncodable
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case qux

                    enum QuxCodingKeys: String, CodingKey {
                        @EncodedValue(Baz.self)
                        case baz
                    }
                }

                private struct Baz: EncodableValue {
                    let value1: String
                    let value2: String

                    init(from value: String) {
                        self.value1 = value.prefix(2)
                        self.value2 = value.suffix(2)
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
            extension Foo: Encodable {
                enum CodingKeys: String, CodingKey {
                    case bar
                    case qux

                    enum QuxCodingKeys: String, CodingKey {
                        case baz
                    }
                }

                private struct Baz: EncodableValue {
                    let value1: String
                    let value2: String

                    init(from value: String) {
                        self.value1 = value.prefix(2)
                        self.value2 = value.suffix(2)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    var quxContainer = container.nestedContainer(
                        keyedBy: CodingKeys.QuxCodingKeys.self,
                        forKey: .qux
                    )
                    try container.encode(bar, forKey: .bar)
                    try quxContainer.encode(Baz(from: baz), forKey: .baz)
                }
            }
            """,
            macros: testMacros
        )
    }
}
