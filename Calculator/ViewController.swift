//
//  ViewController.swift
//  Calculator
//
//  Created by hyf on 16/9/7.
//  Copyright © 2016年 hyf. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet private weak var display: UILabel!
    @IBOutlet private weak var desc: UILabel!
    
    private var userIsInTheMiddleOfTyping = false
    private var hasDotInDigits = false
    
    @IBAction private func editControl(sender: UIButton) {
        let command = sender.currentTitle!
        if command == "C" {
            userIsInTheMiddleOfTyping = false
            brain.clear()
            display.text = "0"
            desc.text = "..."
        } else if command == "⬅︎" {
            userIsInTheMiddleOfTyping = true
            
            let inputCount = display.text?.characters.count
            if inputCount == 1 {
                display.text = "0"
            } else if (inputCount == 2) && (display.text?.characters.first == "-") {
                display.text = "0"
            } else if inputCount > 1 {
                let removedChar = display.text?.removeAtIndex(display.text!.endIndex.predecessor())
                // check dot
                if removedChar == "." {
                    hasDotInDigits = false
                }
            }
        }
    }
    
    @IBAction private func touchDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTyping == false {
            
            display.text = digit
            
            userIsInTheMiddleOfTyping = true
            
            hasDotInDigits = false
            
            if digit == "." {
                display.text = "0."
                hasDotInDigits = true
            }
            if digit == "00" {
                display.text = "0"
            }
            
            return
        }
        
        //when userIsInTheMiddleOfTyping is true
        
        if digit == "." {
            if hasDotInDigits  {// avoid more '.'
                return
            } else {
                hasDotInDigits = true
            }
        }
        
        let textCurrentlyInDisplay = display.text!
        // avoid input '000000'
        if textCurrentlyInDisplay == "0" {
            if digit == "00" {
                display.text = "0"
            } else if digit == "." {
                display.text = "0."
            } else {
                display.text = digit
            }
            return
        }
           
        display.text = textCurrentlyInDisplay + digit
    }
    
    private var displayValue: Double? {
        get {
            return Double(display.text!)
        }
        
        set {
            //display.text = String(newValue!)
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter.maximumFractionDigits = 6
            numberFormatter.minimumFractionDigits = 0
            
            display.text = numberFormatter.stringFromNumber(newValue!)
        }
        
    }
    
    var savedProgram: CalculatorBrain.PropertyList?
    
    @IBAction func save() {
        savedProgram = brain.program
    }
    
    @IBAction func restore() {
        if savedProgram != nil {
            brain.program = savedProgram!
            displayValue = brain.result
        }
    }
    
    private var brain = CalculatorBrain()
    
    @IBAction private func performOperation(sender: UIButton) {
        
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue!)
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayValue = brain.result
        desc.text = brain.description
    }
}

