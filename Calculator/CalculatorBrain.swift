//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by hyf on 16/9/8.
//  Copyright © 2016年 hyf. All rights reserved.
//

import Foundation


class CalculatorBrain {
    
    private var accumulator = 0.0
    
    //a description of the sequence of operands and operations that led to the value returned by result.
    // if previous is not binary operation, start new sequence
    private var sequenceInfo = SequenceOperandAndOperationInfo()
    
        private struct SequenceOperandAndOperationInfo {
        var lastExpression: String
        var firstExpression: String
        var operation: String
        var showHalfExpress: Bool        
        
        init() {
            firstExpression = ""
            lastExpression = ""
            operation = ""
            showHalfExpress = true
        }
        
        mutating func clear() {
            firstExpression = ""
            lastExpression = ""
            operation = ""
        }
        
        //sequenceInfo.lastExpression = "\(symbol)(\(sequenceInfo.lastExpression))"
        func formatUnaryOperation(expression: String, symbol: String) -> String {
            var formatString = "(" + expression + ")"
            if symbol == "√" {
                formatString = symbol + formatString
            } else if symbol == "x²" {
                formatString += "²"
            } else if symbol == "±" {
                formatString = "(-1)×" + formatString
            } else if symbol == "%" {
                formatString += "÷100"
            }
            return formatString
        }
        
        func result(isPartialResult: Bool) -> String {
            var sequenceString = ""
            if showHalfExpress {
                sequenceString = lastExpression + operation

            } else {
                sequenceString = firstExpression + operation + lastExpression
                            }
            
            if isPartialResult {
                sequenceString += "..."
            } else {
                sequenceString += "="
            }
            
            return sequenceString
        }
        
    }
    
    private func stringWithBrackets(s: String) -> Bool {
        return (s.characters.first == "(") && (s.characters.last == ")")
    }
    
    private func addBrackets(s: String) -> String {
        if stringWithBrackets(s) == false {
            return "(" + s + ")"
        }
        return s
    }
    
    private func removeBrackets(s: String) -> String {
        if stringWithBrackets(s) == true {
            let range=Range<String.Index>( s.startIndex.advancedBy(1) ..< s.endIndex.advancedBy(-1))
            return s.substringWithRange(range)
        }
        return s
    }
    
    private func shouldFixPriorityOfOperation( expression: String, nextOperation: String) -> Bool {
        if (nextOperation == "×") || (nextOperation == "÷") {
            for i in expression.characters.reverse() {
                if i == ")"  { break }
                if (i == "+") || (i == "−") { return true }
            }
        }
        return false
    }

    
    //whether there is a binary operation pending
    private var isPartialResult: Bool {
        get {
            return (pending != nil)
        }
    }
    
    var description: String {
        get {
            return sequenceInfo.result(isPartialResult)
        }
    }

    var result: Double {
        get {
            return accumulator
        }
    }
    
    func restart() {
        accumulator = 0.0
        theLastInputIsBinaryOperation = false
        pending = nil
        sequenceInfo.clear()
    }

    func setOperand(operand: Double) {
        accumulator = operand
        
        theLastInputIsBinaryOperation = false
        
        // is new sequence
        if isPartialResult == false {
            sequenceInfo.clear()
        }
        //sequenceInfo.lastExpression = String(accumulator)
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        //numberFormatter.minimumIntegerDigits = 1;
        numberFormatter.maximumFractionDigits = 6
        numberFormatter.minimumFractionDigits = 0
        
        sequenceInfo.lastExpression = numberFormatter.stringFromNumber(accumulator)!

    }
    
    func performOperation(symbol: String) {
        
        if let operation = operations[symbol] {
            sequenceInfo.showHalfExpress = false
            
            switch operation {
            case .Constant(let associatedConstantValue):
                theLastInputIsBinaryOperation = false
                // is new sequence list
                if isPartialResult == false {
                    sequenceInfo.clear()
                }
                sequenceInfo.lastExpression = symbol
                
                accumulator = associatedConstantValue
            case .UnaryOperation(let funcion):
                sequenceInfo.lastExpression = sequenceInfo.formatUnaryOperation(sequenceInfo.lastExpression, symbol: symbol)
                
                accumulator = funcion(accumulator)
            case .BinaryOperation(let function):
                
                if theLastInputIsBinaryOperation == false {
                    executePendingBinaryOperation()
                    theLastInputIsBinaryOperation = true
                }
                
                if shouldFixPriorityOfOperation(sequenceInfo.lastExpression, nextOperation: symbol) {
                    sequenceInfo.lastExpression = addBrackets(sequenceInfo.lastExpression)
                } else if (symbol == "+") || (symbol == "−") {//ie. input 5 + 3 X - 2
                    sequenceInfo.lastExpression = removeBrackets(sequenceInfo.lastExpression)
                }

                sequenceInfo.firstExpression = sequenceInfo.lastExpression
                sequenceInfo.operation = symbol
                sequenceInfo.showHalfExpress = true
                
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
            case .Equals:
                executePendingBinaryOperation()
                
            }
        }
    }
    
    
    // input "5 X + - 3" means "5 - 3" output "2"
    private var theLastInputIsBinaryOperation = false
    
    
    private var operations: Dictionary<String, Operation> = [
        "π": Operation.Constant(M_PI),
        "e": Operation.Constant(M_E),
        "cos": Operation.UnaryOperation(cos),
        "√": Operation.UnaryOperation(sqrt),
        "x²": Operation.UnaryOperation({$0 * $0}),
        "±": Operation.UnaryOperation({-$0}),
        "%": Operation.UnaryOperation({$0 / 100}),
        "+": Operation.BinaryOperation({$0 + $1}),
        "−": Operation.BinaryOperation({$0 - $1}),
        "×": Operation.BinaryOperation({$0 * $1}),
        "÷": Operation.BinaryOperation({$0 / $1}),

        "=": Operation.Equals
        
    ]
    
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double)->Double)
        case BinaryOperation((Double,Double)->Double)
        case Equals
    }
    
    
    private var pending: PendingBinaryOperationInfo?
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
    }
    
    private func executePendingBinaryOperation() {
        if pending != nil {
            sequenceInfo.lastExpression = sequenceInfo.firstExpression+sequenceInfo.operation+sequenceInfo.lastExpression
            sequenceInfo.firstExpression = ""
            sequenceInfo.operation = ""

            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            pending = nil
        }
        
    }

    
}
