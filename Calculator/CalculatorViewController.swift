//
//  ViewController.swift
//  Calculator
//
//  Created by hyf on 16/9/7.
//  Copyright © 2016年 hyf. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class CalculatorViewController: UIViewController {
    
    
    @IBOutlet fileprivate weak var display: UILabel!
    @IBOutlet fileprivate weak var desc: UILabel!
    
    fileprivate var userIsInTheMiddleOfTyping = false
    fileprivate var hasDotInDigits = false
    
    @IBAction fileprivate func editControl(_ sender: UIButton) {
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
                    let removedChar = display.text?.remove(at: display.text!.characters.index(before: display.text!.endIndex))
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
    
    @IBAction fileprivate func touchDigit(_ sender: UIButton) {
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
    
    fileprivate var displayValue: Double? {
        get {
            return Double(display.text!)
        }
        
        set {
            //display.text = String(newValue!)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            numberFormatter.maximumFractionDigits = 6
            numberFormatter.minimumFractionDigits = 0
            
            display.text = numberFormatter.string(from: NSNumber(value: newValue!))
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
    
    @IBAction func saveVariable(_ sender: UIButton) {
        save()
        if let variableName = sender.currentTitle {
            if variableName.characters.count > 0  {
                brain.setVariable(variableName.substring(from: variableName.characters.index(before: variableName.endIndex)), value: displayValue ?? 0.0)
            }
        }
        restore()
        userIsInTheMiddleOfTyping = false

    }
    
    @IBAction func touchVariable(_ sender: UIButton) {
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
    
    fileprivate var brain = CalculatorBrain()
    
    @IBAction fileprivate func performOperation(_ sender: UIButton) {
        
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
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
    
    fileprivate func setGraphViewController(_ program: AnyObject, vc: GraphViewController) {
        let brain = CalculatorBrain()
        brain.setVariable("M", value: 0.0)// make sure variable "m" in variablevalues
        // if not in varibalevalues, variable 'm' will be remove from program
        // in this case, brain.program will not include 'm', event it is in program

        brain.program = program
        
        let title = brain.description.trimmingCharacters(in: CharacterSet(charactersIn: "="))
        vc.navigationItem.title = title
        vc.function = {
            brain.setVariable("M", value: Double($0))
            let temp = brain.program
            brain.program = temp
            return brain.result
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
        if segue.identifier == "show chart" {
            var destnationVC = segue.destination
            if destnationVC is UINavigationController {
                destnationVC = (destnationVC as! UINavigationController).visibleViewController!
            }
            if let graphVC = destnationVC as? GraphViewController {
                setGraphViewController(self.brain.program, vc: graphVC)
            }
            // save last program
            UserDefaults.standard.set(self.brain.program, forKey: storedKeyName)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // When your application first launches, have it show the last graph it was showing
        let program = UserDefaults.standard.object(forKey: storedKeyName) ?? []
        if let splitViewController = splitViewController {
            let controllers = splitViewController.viewControllers
            if let graphViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? GraphViewController {
                setGraphViewController(program as AnyObject, vc: graphViewController)
            }
        }
        //printSizeClass()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printSizeClass()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { coordinator in self.printSizeClass() }, completion: nil)
    }
    
    // MARK:- Size Class
    fileprivate func printSizeClass() {
        if !userIsInTheMiddleOfTyping {
        print("CAlculator View# vertical: \(sizeClassToString(traitCollection.verticalSizeClass)), horizon: \(sizeClassToString(traitCollection.horizontalSizeClass))")
        }
    }
    
    fileprivate func sizeClassToString(_ sizeClass: UIUserInterfaceSizeClass) -> String {
        var result: String
        switch sizeClass {
            case .unspecified: result = "Unspecified"
            case .compact: result = "Compact"
            case .regular: result = "Regular"
        }
        return result
    }
    
    
        
    
 }

