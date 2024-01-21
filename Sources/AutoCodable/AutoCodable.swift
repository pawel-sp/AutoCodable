public enum AccessControl {
    case `internal`
    case `public`
}

public enum Container {
    case keyed
    case singleValue(String)
    case singleValueForEnum
}

@attached(member, names: named(init))
public macro AutoDecodable(
    accessControl: AccessControl = .internal,
    container: Container = .keyed
) = #externalMacro(module: "AutoCodableMacros", type: "AutoDecodableMacro")

public protocol DecodableValue: Decodable {
    associatedtype Value
    func value() -> Value
}

@attached(peer)
public macro DecodedValue<T: DecodableValue>(
    _ type: T.Type
) = #externalMacro(module: "AutoCodableMacros", type: "DecodedValueMacro")
