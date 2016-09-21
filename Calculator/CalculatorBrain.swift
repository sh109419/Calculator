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
    private var internalProgram = [AnyObject]()
    
    //whether there is a binary operation pending
    private var isPartialResult: Bool {
        get {
            return (pending != nil)
        }
    }
    
    private var currentExpression = "0" {
        didSet {
            if pending == nil {
                currentPrecedence = Precedence.Max
            }
        }
    }

    private var showConstantOrUnaryOperation = false
    
    var description: String {
        get {
            var desc = ""
            if pending == nil {
                desc = currentExpression
            } else {
                desc = pending!.descriptionFunction(pending!.firstDescription,
                                                    showConstantOrUnaryOperation ? currentExpression : "")
            }
            return isPartialResult ? (desc + "...") : (desc + "=")
        }
    }

    var result: Double {
        get {
            return accumulator
        }
    }
   
    private func formatDigit(number: Double) -> String {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        //numberFormatter.minimumIntegerDigits = 1;
        numberFormatter.maximumFractionDigits = 6
        numberFormatter.minimumFractionDigits = 0
        return numberFormatter.stringFromNumber(number)!
    }
    
    func setOperand(operand: Double) {
        accumulator = operand
        currentExpression = formatDigit(operand)
        internalProgram.append(operand)
    }
    
    func performOperation(symbol: String) {
        
        if let operation = operations[symbol] {
            switch operation {
            case .Constant(let associatedConstantValue):
                accumulator = associatedConstantValue
                currentExpression = symbol
                showConstantOrUnaryOperation = true
            case .UnaryOperation(let function, let descriptionFunc):
                accumulator = function(accumulator)
                currentExpression = descriptionFunc(currentExpression)
                showConstantOrUnaryOperation = true
            case .BinaryOperation(let function, let descriptionFunc, let precedence):
                // input "5 X + - 3" means "5 - 3" output "2"
                if theLastInputIsBinaryOperation() == false {
                    executePendingBinaryOperation()
                }
                // add "()"
                if currentPrecedence.rawValue < precedence.rawValue {
                    currentExpression = "(\(currentExpression))"
                } else if currentPrecedence.rawValue > precedence.rawValue {
                    // remove unecessary "()"
                    if currentExpression.hasPrefix("(") && currentExpression.hasSuffix(")") {
                        let range = Range<String.Index>( currentExpression.startIndex.advancedBy(1) ..< currentExpression.endIndex.advancedBy(-1))
                        currentExpression = currentExpression.substringWithRange(range)
                        currentPrecedence = Precedence.Min// restore precedence
                    }
                }
                
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunc, firstDescription: currentExpression)
                currentPrecedence = precedence
                showConstantOrUnaryOperation = false
            case .Equals:
                executePendingBinaryOperation()
            }
        }
        internalProgram.append(symbol)
    }
    
    private func theLastInputIsBinaryOperation() -> Bool {
        if let operation = internalProgram.last as? String {
            return ["+","−","×","÷"].contains(operation)
        }
        return false
    }
    
    private enum Precedence: Int {
        case Min = 0, Max
    }
    
    private var currentPrecedence = Precedence.Max
    
    private var operations: Dictionary<String, Operation> = [
        "π": Operation.Constant(M_PI),
        "e": Operation.Constant(M_E),
        "cos": Operation.UnaryOperation(cos,      {"cos(\($0))"}),
        "√": Operation.UnaryOperation(sqrt,       {"√(\($0))"}),
        "x²": Operation.UnaryOperation({$0 * $0}, {"(\($0))²"}),
        "±": Operation.UnaryOperation({-$0},      {"-(\($0))"}),
        "%": Operation.UnaryOperation({$0 / 100}, {"(\($0))%"}),
        "+": Operation.BinaryOperation({$0 + $1}, {"\($0)+\($1)"}, Precedence.Min),
        "−": Operation.BinaryOperation({$0 - $1}, {"\($0)-\($1)"}, Precedence.Min),
        "×": Operation.BinaryOperation({$0 * $1}, {"\($0)×\($1)"}, Precedence.Max),
        "÷": Operation.BinaryOperation({$0 / $1}, {"\($0)÷\($1)"}, Precedence.Max),
        "=": Operation.Equals
    ]
    
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double)->Double, (String)->String)
        case BinaryOperation((Double,Double)->Double,(String,String)->String,Precedence)
        case Equals
    }
    
    
    private var pending: PendingBinaryOperationInfo?
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var firstDescription: String
    }
    
    private func executePendingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            currentExpression = pending!.descriptionFunction(pending!.firstDescription, currentExpression)
            pending = nil
        }
    }

    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return internalProgram
        }
        
        set {
            clear()
            if let arrayOfOps = newValue as? [AnyObject] {
                for op in arrayOfOps {
                    if let operand = op as? Double {
                        setOperand(operand)
                    } else if let operation = op as? String {
                        performOperation(operation)
                    }
                }
            }
        }
    }
    
    func clear() {
        accumulator = 0.0
        currentExpression = "0"
        pending = nil
        internalProgram.removeAll()
    }
    
   
}
