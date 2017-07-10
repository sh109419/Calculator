//
//  GraphView.swift
//  Calculator
//
//  Created by hyf on 16/10/8.
//  Copyright © 2016年 hyf. All rights reserved.
//

import UIKit

protocol GraphViewDataSource {
    func getCoordinateY(_ x: CGFloat) -> CGFloat?
}

@IBDesignable
class GraphView: UIView {
    @IBInspectable
    var scale: CGFloat = 40 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var color: UIColor = UIColor.blue { didSet { setNeedsDisplay() } }
    @IBInspectable
    var lineWidth: CGFloat = 5.0 { didSet { setNeedsDisplay() } }
    
    //var program: CalculatorBrain.PropertyList?
    //As we’ve learned, a function is a first-class-citizen type in Swift. Thus, it is perfectly legal to have an Optional function if you want.
    //private var brain = CalculatorBrain()
    var dataSource: GraphViewDataSource?
    
    fileprivate let axes = AxesDrawer(color: UIColor.red)
    fileprivate var origin: CGPoint! { didSet { setNeedsDisplay() } }
    
    //set UIViewContentMode to redraw, when transite size, system run drawRect()
    // in this case, how to change the point 'origin'?
    // according to the changed size to change the position of origin
    // use viewWillTransitionToSize()
    
    func addjustPointOrigin(_ preBounds: CGRect) {
        let x = origin.x * bounds.width / preBounds.width
        let y = origin.y * bounds.height / preBounds.height
        origin = CGPoint(x: x, y: y)
    }
    
    /* the methods that handle the gestures */
    
    // pinch gesture
    func changeScale(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            scale *= recognizer.scale
            recognizer.scale = 1.0
            
        default: break
        }
    }
    
    // double tap gesture
    func setOriginPoint(_ recognizer: UITapGestureRecognizer) {
        origin = recognizer.location(in: self)
    }
    
    // pan gesture
    func moveGraph(_ recognizer: UIPanGestureRecognizer) {
        /*let _transX = recognizer.translationInView(self).x
        let _transY = recognizer.translationInView(self).y
        switch recognizer.state {
        case .Changed:
            self.transform = CGAffineTransformMakeTranslation(_transX, _transY)
        case .Ended:
            self.transform = CGAffineTransformMakeTranslation(_transX, _transY)
            let x = self.center.x + _transX
            let y = self.center.y + _transY
            self.center = CGPointMake(x, y)
            self.transform = CGAffineTransformIdentity;
        default:
            break
        }*/
        switch recognizer.state {
        case .changed, .ended:
            // Update anything that depends on the pan gesture using translation.x and translation.y
            origin.x += recognizer.translation(in: self).x
            origin.y += recognizer.translation(in: self).y
            // Cumulative since start of recognition, get 'incremental' translation
            recognizer.setTranslation(CGPoint.zero, in: self)
        default: break
        }

    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        origin = origin ?? CGPoint(x: bounds.midX, y: bounds.midY)
        color.set()
        
        // draw program
        drawGraph()
        
        // draw axes
        //axes.drawAxesInRect(rect, origin: origin, pointsPerUnit: scale)
        axes.drawAxes(in: rect, origin: origin, pointsPerUnit: scale)
    }
    
    /*
    not drawing an almost vertical line between those two points if the function is actually probably discontinuous there (e.g. tan(x)).
     if the sign changed (from +y to -y) then start new line
    */
    fileprivate func drawGraph() {
        guard let data = dataSource else {
            print("data set not found")
            return
        }

        let path = UIBezierPath()
        var point = CGPoint()
        var prePointY = CGFloat(0.0)
        let width = Int(bounds.width)
        var isNewLine = true
        for piexl in 0...width {
            point.x = CGFloat(piexl)
            if let y = data.getCoordinateY((point.x - origin.x) / scale) {
                if y.isZero || y.isNormal {
                    point.y = origin.y - CGFloat(y) * scale
                    // remove vertical line for tan(x)
                    if prePointY * point.y < 0.0 {
                        isNewLine = true
                    }
                    prePointY = point.y
                   
                    if isNewLine {
                        path.move(to: point)
                        isNewLine = false
                    } else {
                        path.addLine(to: point)
                    }
                } else {
                    isNewLine = true
                }
                
            }
            
        }
        path.lineWidth = lineWidth
        path.stroke()
    }

}
