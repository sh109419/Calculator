//
//  ViewController.swift
//  Calculator
//
//  Created by hyf on 16/9/7.
//  Copyright © 2016年 hyf. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    
    @IBOutlet private weak var display: UILabel!
    @IBOutlet private weak var desc: UILabel!
    
    private var userIsInTheMiddleOfTyping = false
    private var hasDotInDigits = false
    
    @IBAction private func editControl(sender: UIButton) {
        let command = sender.currentTitle!
        if command == "C" {
            userIsInTheMiddleOfTyping = false
            brain.restart()
            display.text = "0"
            desc.text = "..."
        } else if command == "⬅︎" {
            // if userIsInTheMiddleOfTyping = true then do "backspace"
            // if userIsInTheMiddleOfTyping = false then do "undo"
            if userIsInTheMiddleOfTyping {
                let inputCount = display.text?.characters.count
                if inputCount == 1 {
                    display.text = "0"
                    userIsInTheMiddleOfTyping = false
                } else if (inputCount == 2) && (display.text?.characters.first == "-") {
                    display.text = "0"
                } else if inputCount > 1 {
                    let removedChar = display.text?.removeAtIndex(display.text!.endIndex.predecessor())
                    // check dot
                    if removedChar == "." {
                        hasDotInDigits = false
                    }
                }
            } else {
                brain.undo()
                displayValue = brain.result
                desc.text = brain.description
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
            desc.text = brain.description
        }
    }
    
    @IBAction func saveVariable(sender: UIButton) {
        save()
        if let variableName = sender.currentTitle {
            if variableName.characters.count > 0  {
                brain.setVariable(variableName.substringFromIndex(variableName.endIndex.predecessor()), value: displayValue ?? 0.0)
            }
        }
        restore()
        userIsInTheMiddleOfTyping = false

    }
    
    @IBAction func touchVariable(sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue!)
            userIsInTheMiddleOfTyping = false
        }
        if let variableName = sender.currentTitle {
            brain.setOperand(variableName)
        }
        displayValue = brain.result
        desc.text = brain.description
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
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "show chart" {
            if (userIsInTheMiddleOfTyping == true) || (brain.isPartialResult == true) {
                return false
            }
        }
        return true
    }
    
     //var function: (CGFloat -> Double)?
    /*func foo(x: CGFloat) -> Double {
        self.brain.setVariable("M", value: Double(x))
        self.brain.program = self.brain.program
        return self.brain.result
    }*/
    
    let storedKeyName = "brain.program"
    
    private func setGraphViewController(program: AnyObject, vc: GraphViewController) {
        let brain = CalculatorBrain()
        brain.setVariable("M", value: 0.0)// make sure variable "m" in variablevalues
        // if not in varibalevalues, variable 'm' will be remove from program
        // in this case, brain.program will not include 'm', event it is in program

        brain.program = program
        
        let title = brain.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "="))
        vc.navigationItem.title = title
        vc.function = {
            brain.setVariable("M", value: Double($0))
            let temp = brain.program
            brain.program = temp
            return brain.result
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     
        if segue.identifier == "show chart" {
            var destnationVC = segue.destinationViewController
            if destnationVC is UINavigationController {
                destnationVC = (destnationVC as! UINavigationController).visibleViewController!
            }
            if let graphVC = destnationVC as? GraphViewController {
                setGraphViewController(self.brain.program, vc: graphVC)
            }
            // save last program
            NSUserDefaults.standardUserDefaults().setObject(self.brain.program, forKey: storedKeyName)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // When your application first launches, have it show the last graph it was showing
        let program = NSUserDefaults.standardUserDefaults().objectForKey(storedKeyName) ?? []
        if let splitViewController = splitViewController {
            let controllers = splitViewController.viewControllers
            if let graphViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? GraphViewController {
                setGraphViewController(program, vc: graphViewController)
            }
        }
    }
    

}

