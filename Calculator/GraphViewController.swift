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
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let preBounds = graphView.bounds
        coordinator.animateAlongsideTransition({ _ in self.graphView.addjustPointOrigin(preBounds)}, completion: nil)
        printSizeClass()
    }
    
    // MARK:- Size Class
    private func printSizeClass() {
        UIDevice.currentDevice().model
        print(" vertical: \(sizeClassToString(traitCollection.verticalSizeClass)), horizon: \(sizeClassToString(traitCollection.horizontalSizeClass))")
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

    //it is perfectly legal to have an Optional function
    var function: (CGFloat -> Double)?

    deinit {
        print("I have break a memory cycle by setting dataSource = nil")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //break memory cycle
        graphView.dataSource = nil
    }

}

extension GraphViewController: GraphViewDataSource {
    
    func getCoordinateY(x: CGFloat) -> CGFloat? {
        if let function = function {
            return CGFloat(function(x))
        }
        return nil
    }
    
}