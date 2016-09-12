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
    
    var result: Double {
        get {
            return accumulator
        }
    }
    
    func restart() {
        accumulator = 0.0
        theLastInputIsBinaryOperation = false
        pending = nil
    }

    func setOperand(operand: Double) {
        accumulator = operand
        theLastInputIsBinaryOperation = false
    }
    
    func performOperation(symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .Constant(let associatedConstantValue):
                accumulator = associatedConstantValue
            case .UnaryOperation(let funcion):
                accumulator = funcion(accumulator)
            case .BinaryOperation(let function):
                if theLastInputIsBinaryOperation == false {
                    executePendingBinaryOperation()
                    theLastInputIsBinaryOperation = true
                }
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
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            pending = nil
        }
        
    }

    
}
