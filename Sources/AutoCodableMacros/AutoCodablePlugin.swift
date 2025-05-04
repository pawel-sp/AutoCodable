import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AutoCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoDecodableMacro.self,
        DecodedValueMacro.self,
        AutoEncodableMacro.self,
        EncodedValueMacro.self,
        ConditionalMacro.self
    ]
}
