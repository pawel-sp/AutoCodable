import SwiftSyntax

extension EnumDeclSyntax {
    func nestedEnumsDecl(named names: [String]) -> NamedDeclArray<EnumDeclSyntax> {
        names.map { ($0, "\($0.capitalized)CodingKeys") }.compactMap {
            if let enumDecl = enumDecl(named: $0.1, ofType: "CodingKey") {
                ($0.0, enumDecl)
            } else {
                nil
            }
        }
    }
}
