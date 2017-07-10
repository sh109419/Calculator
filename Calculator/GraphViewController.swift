//
//  GraphViewController.swift
//  Calculator
//
//  Created by hyf on 16/10/8.
//  Copyright © 2016年 hyf. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {

    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(GraphView.changeScale(_:))))
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(GraphView.setOriginPoint(_:)))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(doubleTapGestureRecognizer)
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: #selector(GraphView.moveGraph(_:))))
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let preBounds = graphView.bounds
        coordinator.animate(alongsideTransition: { _ in  self.graphView.addjustPointOrigin(preBounds);  self.printSizeClass()  }, completion: nil)
        printSizeClass()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printSizeClass()
    }
    
    /*override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { coordinator in self.printSizeClass() }, completion: nil)
    }*/
    

    // MARK:- Size Class
    fileprivate func printSizeClass() {
        print("Graph view# vertical: \(sizeClassToString(traitCollection.verticalSizeClass)), horizon: \(sizeClassToString(traitCollection.horizontalSizeClass))")
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

    //it is perfectly legal to have an Optional function
    var function: ((CGFloat) -> Double)?

    deinit {
        print("I have break a memory cycle by setting dataSource = nil")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //break memory cycle
        graphView.dataSource = nil
    }

}

extension GraphViewController: GraphViewDataSource {
    
    func getCoordinateY(_ x: CGFloat) -> CGFloat? {
        if let function = function {
            return CGFloat(function(x))
        }
        return nil
    }
    
}
