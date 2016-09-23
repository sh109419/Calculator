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

    /* 
       "a + b": a is the first operand, b is the second operand
       var(showSecondOperand) indicate whether show part of 'b'
       it is worked while pending != nil
    */
    private var showSecondOperand = false
    
    var description: String {
        get {
            var desc = ""
            if pending == nil {
                desc = currentExpression
            } else {
                desc = pending!.descriptionFunction(pending!.firstDescription,
                                                    showSecondOperand ? currentExpression : "")
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
    
    func setOperand(variableName: String) {
        accumulator = variableValues[variableName] ?? 0.0
        currentExpression = variableName
        internalProgram.append(variableName)
        showSecondOperand = true
    }

    func performOperation(symbol: String) {
        showSecondOperand = true
        if let operation = operations[symbol] {
            switch operation {
            case .Constant(let associatedConstantValue):
                accumulator = associatedConstantValue
                currentExpression = symbol
            case .UnaryOperation(let function, let descriptionFunc):
                if symbol == "±" {
                    currentExpression =  MiunsOrPlusSignChange(currentExpression)
                }
                accumulator = function(accumulator)
                currentExpression = descriptionFunc(currentExpression)
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
                showSecondOperand = false
            case .Equals:
                executePendingBinaryOperation()
            }
        }
        internalProgram.append(symbol)
    }
    
    private func MiunsOrPlusSignChange(expression: String) -> String {
        var currentExpression = expression
        if (Double(currentExpression) == nil) {
            currentExpression = "(\(currentExpression))" // if "9" then "9" else if "2+3=" then "(2+3)"
        }
        currentExpression = "-" + currentExpression // "-9" or "-(2+3)"
        
        if pending != nil {
            currentExpression = "(\(currentExpression))" // 9 + (-(2+3))
        }
        return currentExpression
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
        "±": Operation.UnaryOperation({-$0},      {"\($0)"}),// do in MiunsOrPlusSignChange()
        "%": Operation.UnaryOperation({$0 / 100}, {"(\($0))%"}),
        "+": Operation.BinaryOperation({$0 + $1}, {"\($0)+\($1)"}, Precedence.Min),
        "−": Operation.BinaryOperation({$0 - $1}, {"\($0)-\($1)"}, Precedence.Min),
        "×": Operation.BinaryOperation({$0 * $1}, {"\($0)×\($1)"}, Precedence.Max),
        "÷": Operation.BinaryOperation({$0 / $1}, {"\($0)÷\($1)"}, Precedence.Max),
        "=": Operation.Equals,
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
                        if variableValues[operation] != nil {
                            setOperand(operation)
                        } else {
                            performOperation(operation)
                        }
                    }
                }
            }
        }
    }
    
    func undo() {
        if internalProgram.isEmpty == false {
            internalProgram.removeLast()
        } else {
            clear()
        }
        program = internalProgram
    }
    
    func clear() {
        accumulator = 0.0
        currentExpression = "0"
        pending = nil
        internalProgram.removeAll()
    }
    
    func restart() {
        clear()
        variableValues.removeAll()
    }
    
    var variableValues: Dictionary<String, Double> = [:]
    
    func setVariable(name: String, value: Double) {
        variableValues[name] = value
    }
   
}
