//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by hyf on 16/9/8.
//  Copyright © 2016年 hyf. All rights reserved.
//

import Foundation


class CalculatorBrain {
    
    fileprivate var accumulator = 0.0
    fileprivate var internalProgram = [AnyObject]()
    
    //whether there is a binary operation pending
    var isPartialResult: Bool {
        get {
            return (pending != nil)
        }
    }
    
    fileprivate var currentExpression = "0" {
        didSet {
            if pending == nil {
                currentPrecedence = Precedence.max
            }
        }
    }

    /* 
       "a + b": a is the first operand, b is the second operand
       var(showSecondOperand) indicate whether show part of 'b'
       it is worked while pending != nil
    */
    fileprivate var showSecondOperand = false
    
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
   
    fileprivate func formatDigit(_ number: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        //numberFormatter.minimumIntegerDigits = 1;
        numberFormatter.maximumFractionDigits = 6
        numberFormatter.minimumFractionDigits = 0
        return numberFormatter.string(from: NSNumber(value: number))!
    }
    
    func setOperand(_ operand: Double) {
        accumulator = operand
        currentExpression = formatDigit(operand)
        internalProgram.append(operand as AnyObject)
    }
    
    func setOperand(_ variableName: String) {
        accumulator = variableValues[variableName] ?? 0.0
        currentExpression = variableName
        internalProgram.append(variableName as AnyObject)
        showSecondOperand = true
    }

    func performOperation(_ symbol: String) {
        showSecondOperand = true
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let associatedConstantValue):
                accumulator = associatedConstantValue
                currentExpression = symbol
            case .unaryOperation(let function, let descriptionFunc):
                if symbol == "±" {
                    currentExpression =  MiunsOrPlusSignChange(currentExpression)
                }
                accumulator = function(accumulator)
                currentExpression = descriptionFunc(currentExpression)
            case .binaryOperation(let function, let descriptionFunc, let precedence):
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
                        let range = Range<String.Index>( currentExpression.characters.index(currentExpression.startIndex, offsetBy: 1) ..< currentExpression.characters.index(currentExpression.endIndex, offsetBy: -1))
                        currentExpression = currentExpression.substring(with: range)
                        currentPrecedence = Precedence.min// restore precedence
                    }
                }
                
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunc, firstDescription: currentExpression)
                currentPrecedence = precedence
                showSecondOperand = false
            case .equals:
                executePendingBinaryOperation()
            }
        }
        internalProgram.append(symbol as AnyObject)
    }
    
    fileprivate func MiunsOrPlusSignChange(_ expression: String) -> String {
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

    fileprivate func theLastInputIsBinaryOperation() -> Bool {
        if let operation = internalProgram.last as? String {
            return ["+","−","×","÷"].contains(operation)
        }
        return false
    }
    
    fileprivate enum Precedence: Int {
        case min = 0, max
    }
    
    fileprivate var currentPrecedence = Precedence.max
    
    fileprivate var operations: Dictionary<String, Operation> = [
        "π": Operation.constant(M_PI),
        "e": Operation.constant(M_E),
        "cos": Operation.unaryOperation(cos,      {"cos(\($0))"}),
        "√": Operation.unaryOperation(sqrt,       {"√(\($0))"}),
        "x²": Operation.unaryOperation({$0 * $0}, {"(\($0))²"}),
        "±": Operation.unaryOperation({-$0},      {"\($0)"}),// do in MiunsOrPlusSignChange()
        "%": Operation.unaryOperation({$0 / 100}, {"(\($0))%"}),
        "+": Operation.binaryOperation({$0 + $1}, {"\($0)+\($1)"}, Precedence.min),
        "−": Operation.binaryOperation({$0 - $1}, {"\($0)-\($1)"}, Precedence.min),
        "×": Operation.binaryOperation({$0 * $1}, {"\($0)×\($1)"}, Precedence.max),
        "÷": Operation.binaryOperation({$0 / $1}, {"\($0)÷\($1)"}, Precedence.max),
        "=": Operation.equals,
    ]
    
    fileprivate enum Operation {
        case constant(Double)
        case unaryOperation((Double)->Double, (String)->String)
        case binaryOperation((Double,Double)->Double,(String,String)->String,Precedence)
        case equals
    }
    
    
    fileprivate var pending: PendingBinaryOperationInfo?
    
    fileprivate struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var firstDescription: String
    }
    
    fileprivate func executePendingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            currentExpression = pending!.descriptionFunction(pending!.firstDescription, currentExpression)
            pending = nil
        }
    }

    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return internalProgram as CalculatorBrain.PropertyList
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
        program = internalProgram as CalculatorBrain.PropertyList
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
    
    func setVariable(_ name: String, value: Double) {
        variableValues[name] = value
    }
   
}
