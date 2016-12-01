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
        printSizeClass()
    }
    
    // MARK:- Size Class
    private func printSizeClass() {
        UIDevice.currentDevice().model
        print("\(deviceModelName()) vertical: \(sizeClassToString(traitCollection.verticalSizeClass)), horizon: \(sizeClassToString(traitCollection.horizontalSizeClass))")
    }
    
    private func sizeClassToString(sizeClass: UIUserInterfaceSizeClass) -> String {
        var result: String
        switch sizeClass {
            case .Unspecified: result = "Unspecified"
            case .Compact: result = "Compact"
            case .Regular: result = "Regular"
        }
        return result
    }
    
    //MARK: - UIDevice extension
    private func deviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }

        
    }
 }

