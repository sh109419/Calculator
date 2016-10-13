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
    }
    
    //it is perfectly legal to have an Optional function 
    var function: (CGFloat -> Double)?

}

extension GraphViewController: GraphViewDataSource {
    
    func getCoordinateY(x: CGFloat) -> CGFloat? {
        if let function = function {
            return CGFloat(function(x))
        }
        return nil
    }
    
}