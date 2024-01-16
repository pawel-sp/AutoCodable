import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AutoCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoDecodableMacro.self,
        DecodedValueMacro.self,
    ]
}
