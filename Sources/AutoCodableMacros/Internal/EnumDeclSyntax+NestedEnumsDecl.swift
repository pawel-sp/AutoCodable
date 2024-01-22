import SwiftSyntax

extension EnumDeclSyntax {
    func nestedEnumsDecl(named names: [String]) -> NamedDeclArray<EnumDeclSyntax> {
        names.map { ($0, "\($0.prefix(1).uppercased() + $0.dropFirst())CodingKeys") }.compactMap {
            if let enumDecl = enumDecl(named: $0.1, ofType: "CodingKey") {
                ($0.0, enumDecl)
            } else {
                nil
            }
        }
    }
}
