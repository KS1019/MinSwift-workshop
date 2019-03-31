import Foundation
import SwiftSyntax

class Parser: SyntaxVisitor {
    private(set) var tokens: [TokenSyntax] = []
    private var index = 0
    private(set) var currentToken: TokenSyntax!

    // MARK: Practice 1

    override func visit(_ token: TokenSyntax) {
        print("Parsing \(token.tokenKind)")
        tokens.append(token)
    }

    @discardableResult
    func read() -> TokenSyntax {
        let i = index
        index = index + 1
        currentToken = tokens[i]
        return currentToken
    }

    func peek(_ n: Int = 0) -> TokenSyntax {
        return tokens[n + index]
    }

    // MARK: Practice 2

    private func extractNumberLiteral(from token: TokenSyntax) -> Double? {
        if case .integerLiteral(let str) = token.tokenKind {
            return Double(str)
        } else if case .floatingLiteral(let str) = token.tokenKind {
            return Double(str)
        }
        return nil
    }

    func parseNumber() -> Node {
        guard let value = extractNumberLiteral(from: currentToken) else {
            fatalError("any number is expected")
        }
        read() // eat literal
        return NumberNode(value: value)
    }

    func parseIdentifierExpression() -> Node {
        var arguments = [CallExpressionNode.Argument]()
        guard case .identifier (let val) = currentToken.tokenKind else { fatalError("any variable is expected") }
        read()
        if currentToken.tokenKind == .leftParen {
            read()
            while currentToken.tokenKind != .rightParen {
                
                if currentToken.tokenKind == .comma {
                    read()
                }
                print("currentVal = \(currentToken.tokenKind)")
                guard case .identifier(let val) = currentToken.tokenKind else { fatalError("any variable is expected") }
                read()
                read()
                arguments.append(CallExpressionNode.Argument(label: val, value: parseExpression()!))
                print("after Val = \(currentToken.tokenKind)")

            }
            read()
            return CallExpressionNode(callee: val, arguments: arguments)
        } else {
            read()
            return VariableNode(identifier: val)
        }
    }
    
    // MARK: Practice 3
    
    func extractBinaryOperator(from token: TokenSyntax) -> BinaryExpressionNode.Operator? {
        if case .spacedBinaryOperator (let str) = currentToken.tokenKind {
            if str == "+" {
                return .addition
            } else if str == "-" {
                return .subtraction
            } else if str == "*" {
                return .multication
            } else if str == "/" {
                return .division
            } else if str == "<" {
                return .lessThan
            }
        }
        return nil
    }

    private func parseBinaryOperatorRHS(expressionPrecedence: Int, lhs: Node?) -> Node? {
        var currentLHS: Node? = lhs
        while true {
            let binaryOperator = extractBinaryOperator(from: currentToken!)
            let operatorPrecedence = binaryOperator?.precedence ?? -1
            
            // Compare between nextOperator's precedences and current one
            if operatorPrecedence < expressionPrecedence {
                return currentLHS
            }
            
            read() // eat binary operator
            var rhs = parsePrimary()
            if rhs == nil {
                return nil
            }
            
            // If binOperator binds less tightly with RHS than the operator after RHS, let
            // the pending operator take RHS as its LHS.
            let nextPrecedence = extractBinaryOperator(from: currentToken)?.precedence ?? -1
            if (operatorPrecedence < nextPrecedence) {
                // Search next RHS from currentRHS
                // next precedence will be `operatorPrecedence + 1`
                rhs = parseBinaryOperatorRHS(expressionPrecedence: operatorPrecedence + 1, lhs: rhs)
                if rhs == nil {
                    return nil
                }
            }
            
            guard let nonOptionalRHS = rhs else {
                fatalError("rhs must be nonnull")
            }
            
            currentLHS = BinaryExpressionNode(binaryOperator!,
                                              lhs: currentLHS!,
                                              rhs: nonOptionalRHS)
        }
    }

    // MARK: Practice 4

    func parseFunctionDefinitionArgument() -> FunctionNode.Argument {
        print("Current = \(currentToken.tokenKind)")
        guard case .identifier (let val) = currentToken.tokenKind else { fatalError("any variable is expected") }
        read()
        read()
        read()
        if currentToken.tokenKind == .comma {
            read()
        }
        return FunctionNode.Argument(label: val, variableName: val)
    }
    
    func parseFunctionDefinition() -> Node {
        var name = ""
        var arr = [FunctionNode.Argument]()
        var returnType: Type
        let body: Node
        guard currentToken.tokenKind == .funcKeyword else { fatalError("function is expected") }
        read()
        guard case .identifier (let val) =  currentToken.tokenKind else { fatalError("function is expected")  }
        name = val
        read()
        guard currentToken.tokenKind == .leftParen else { fatalError("function is expected")  }
        read()
        if currentToken.tokenKind != .rightParen {
            while currentToken.tokenKind != .rightParen {
                arr.append(parseFunctionDefinitionArgument())
            }
        }
        read()
        print("Current = \(currentToken.tokenKind)")
        guard currentToken.tokenKind == .arrow else { fatalError("function is expected") }
        read()
        guard case .identifier(let type) = currentToken.tokenKind else { fatalError("function is expected")  }
        print("type == \(type)")
        if type == "Double" {
            returnType = Type.double
        } else if type == "Void" {
            returnType = Type.void
        } else if type == "Int" {
            returnType = Type.int
        } else {
            returnType = Type.void
        }
        read()
        print("Current = \(currentToken.tokenKind)")
        guard currentToken.tokenKind == .leftBrace else { fatalError("function is expected") }
        read()
        body = parseExpression()!
        print("Current = \(currentToken.tokenKind)")
        guard case .rightBrace = currentToken.tokenKind else { fatalError("Error") }
        read()
        return FunctionNode(name: name, arguments: arr, returnType: returnType, body: body)
    }
    
    
    // MARK: Practice 7

    func parseIfElse() -> Node {
        fatalError("Not Implemented")
    }

    // PROBABLY WORKS WELL, TRUST ME

    func parse() -> [Node] {
        var nodes: [Node] = []
        read()
        while true {
            switch currentToken.tokenKind {
            case .eof:
                return nodes
            case .funcKeyword:
                let node = parseFunctionDefinition()
                nodes.append(node)
            default:
                if let node = parseTopLevelExpression() {
                    nodes.append(node)
                    break
                } else {
                    read()
                }
            }
        }
        return nodes
    }

    private func parsePrimary() -> Node? {
        switch currentToken.tokenKind {
        case .identifier:
            return parseIdentifierExpression()
        case .integerLiteral, .floatingLiteral:
            return parseNumber()
        case .leftParen:
            return parseParen()
        case .funcKeyword:
            return parseFunctionDefinition()
        case .returnKeyword:
            return parseReturn()
        case .ifKeyword:
            return parseIfElse()
        case .eof:
            return nil
        default:
            fatalError("Unexpected token \(currentToken.tokenKind) \(currentToken.text)")
        }
        return nil
    }

    func parseExpression() -> Node? {
        guard let lhs = parsePrimary() else {
            return nil
        }
        return parseBinaryOperatorRHS(expressionPrecedence: 0, lhs: lhs)
    }

    private func parseReturn() -> Node {
        guard case .returnKeyword = currentToken.tokenKind else {
            fatalError("returnKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat return
        if let expression = parseExpression() {
            return ReturnNode(body: expression)
        } else {
            // return nothing
            return ReturnNode(body: nil)
        }
    }

    private func parseParen() -> Node? {
        read() // eat (
        guard let v = parseExpression() else {
            return nil
        }

        guard case .rightParen = currentToken.tokenKind else {
                fatalError("expected ')'")
        }
        read() // eat )

        return v
    }

    private func parseTopLevelExpression() -> Node? {
        if let expression = parseExpression() {
            // we treat top level expressions as anonymous functions
            let anonymousPrototype = FunctionNode(name: "main", arguments: [], returnType: .int, body: expression)
            return anonymousPrototype
        }
        return nil
    }
}

private extension BinaryExpressionNode.Operator {
    var precedence: Int {
        switch self {
        case .addition, .subtraction: return 20
        case .multication, .division: return 40
        case .lessThan:
            fatalError("Not Implemented")
        }
    }
}
