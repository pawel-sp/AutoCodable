public enum AccessControl {
    case `internal`
    case `public`
}

public enum Container {
    case keyed
    case singleValue(String)
    case singleValueForEnum
}

public protocol DecodableValue: Decodable {
    associatedtype Value
    func value() -> Value
}

public protocol EncodableValue: Encodable {
    associatedtype Value
    init(from value: Value)
}

@attached(member, names: named(init(from:)))
public macro AutoDecodable(
    accessControl: AccessControl = .internal,
    container: Container = .keyed
) = #externalMacro(module: "AutoCodableMacros", type: "AutoDecodableMacro")

@attached(member, names: named(encode(to:)))
public macro AutoEncodable(
    accessControl: AccessControl = .internal,
    container: Container = .keyed
) = #externalMacro(module: "AutoCodableMacros", type: "AutoEncodableMacro")

@attached(peer)
public macro DecodedValue<T: DecodableValue>(
    _ type: T.Type
) = #externalMacro(module: "AutoCodableMacros", type: "DecodedValueMacro")

@attached(peer)
public macro EncodedValue<T: EncodableValue>(
    _ type: T.Type
) = #externalMacro(module: "AutoCodableMacros", type: "EncodedValueMacro")

@attached(peer)
public macro Conditional() = #externalMacro(module: "AutoCodableMacros", type: "ConditionalMacro")
