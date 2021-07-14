//
//  ViewController.swift
//  DraggableView
//
//  Created by Fardan Akhter on 12/23/18.
//  Copyright © 2018 Swift Dev Journal. All rights reserved.
//

import UIKit

struct Point: Codable {
    var id: Int
    var x: CGFloat
    var y: CGFloat
}

class ViewController: UIViewController {

    @IBOutlet weak var imageview: UIImageView!
    
    var highlightedView: UIView?
    var deleteView: UIView?
    
    
    var isDrag: Bool = true {
        didSet{
            if isDrag { isResize = false }
        }
    }
    
    var isResize: Bool = false {
        didSet{
            if isResize { isDrag = false }
        }
    }
    
    var points : [Point] {
        get{
            if let data = UserDefaults.standard.data(forKey: "Points"){
                return ((try? JSONDecoder().decode([Point].self, from: data)) ?? [])
            }
            return []
        }
        set{
            if let data = try? JSONEncoder().encode(newValue){
                UserDefaults.standard.set(data, forKey: "Points")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let values = points
        values.forEach {
            self.addViewWithPanGesture($0)
        }
        
    }
    
    @IBAction func panView(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        
        if let viewToDrag = sender.view {
            //To drag on move
            moveToDrag(view: viewToDrag, translation: translation)
//            if sender.state == .ended{
//                updatePoint(pt: Point(id: viewToDrag.tag, x: viewToDrag.center.x, y: viewToDrag.center.y))
//            }
            sender.setTranslation(CGPoint(x: 0, y: 0), in: viewToDrag)
        }
    }
    
    @objc func resizeView(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        
        if let viewToDrag = gesture.view {
            //To resize on move
            moveToResizeView(view: viewToDrag, translation: translation)
            gesture.setTranslation(CGPoint(x: 0, y: 0), in: viewToDrag)
        }
    }
    
    func moveToDrag(view: UIView, translation: CGPoint){
//        let newCenter = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
//        view.center = newCenter
        
        if let parent = view.superview{
            parent.center = CGPoint(x: parent.center.x + translation.x, y: parent.center.y + translation.y)
        }
    }
    
    func moveToResizeView(view: UIView, translation: CGPoint){
        let newSize = CGSize(width: view.frame.size.width + translation.x, height: view.frame.size.width + translation.y)
        view.frame.size = newSize
        
        for sub in view.subviews{
            let size = newSize.width / 2
            sub.frame = CGRect(x: size / 2, y: size / 2, width: size, height: size)
        }
    }
    
    @objc func longPresed(_ gesture: UILongPressGestureRecognizer){
        
        if gesture.state != .ended { return }
        
        let tappedView = gesture.view!
        
        highlightedView = tappedView
        
        //Delete View to remove view on tap gesture
        /*
         deleteView = UIView(frame: CGRect(x: tappedView.frame.midX, y: tappedView.frame.midY, width: 100.0, height: 50.0))
         deleteView?.backgroundColor = .red
         deleteView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.deleteAction)))
         deleteView?.isUserInteractionEnabled  = true
         self.view.addSubview(deleteView!)
         **/
        
        //Heighlight boundary of view to show resize func
        tappedView.layer.borderColor = UIColor.red.cgColor
        tappedView.layer.borderWidth = 2.0
        isResize = true
    }
    
    @objc func deleteAction(_ sender: UITapGestureRecognizer){
        //removePoint(with: highlightedView!.tag)
        
        //Removes view from superview
        /*
         highlightedView?.removeFromSuperview()
         highlightedView = nil
         deleteView?.removeFromSuperview()
         deleteView = nil
         **/
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self.view)
        
        points.sort{ $0.id < $1.id }
        let newpoint = Point(id: ((points.last?.id) ?? 0) + 1, x: point.x, y: point.y)
        
        addViewWithPanGesture(newpoint)
        //saveToUserdefaults(newpoint)
    }
    
    func addViewWithPanGesture(_ pt: Point){
        //containerView
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        containerView.backgroundColor = .cyan //.clear
        containerView.center = CGPoint(x: pt.x, y: pt.y)
        containerView.layer.borderColor = UIColor.cyan.cgColor
        containerView.layer.borderWidth = 2.0
//        containerView.clipsToBounds = true
        containerView.tag = pt.id
        self.view.addSubview(containerView)
        
        //resize Pan Gesture
        let resizePanGesture = UIPanGestureRecognizer(target: self, action: #selector(resizeView(_:)))
        containerView.addGestureRecognizer(resizePanGesture)
        
        //Drag Pan Gesture
        let dragDetectView = UIView()
        let size = containerView.frame.width / 2
        dragDetectView.frame = CGRect(x: size / 2, y: size / 2, width: size, height: size)
        dragDetectView.backgroundColor = .green
        containerView.addSubview(dragDetectView)
        
        //Drag Pan Gesture
        let dragPanGesture = UIPanGestureRecognizer(target: self, action: #selector(panView(_:)))
        dragDetectView.addGestureRecognizer(dragPanGesture)
        
        //        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPresed))
        //        longPressGesture.minimumPressDuration = 0.5
        //        newview.addGestureRecognizer(longPressGesture)

    }
    
    func saveToUserdefaults(_ pt: Point){
        var values = points
        values.append(pt)
        self.points = values //Saves to userdefaults
    }
    
    //removed from userdefaults
    func removePoint(with id: Int){
        points.removeAll{ $0.id == id }
        let values = points
        points = values // saving latest values
    }
    
    //new position to view and save to userdefault
    func updatePoint(pt: Point){
        var excludedItemList = points.filter{ $0.id != pt.id }
        excludedItemList.append(pt)
        points = excludedItemList // saving latest values
    }
}

