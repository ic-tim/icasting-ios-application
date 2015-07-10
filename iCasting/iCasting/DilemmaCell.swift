//
//  BaseCells.swift
//  iCasting
//
//  Created by Tim van Steenoven on 08/07/15.
//  Copyright (c) 2015 T. van Steenoven. All rights reserved.
//

import Foundation


protocol DilemmaCellDelegate {
    func dilemmaCell(cell: UITableViewCell, didPressButtonForState decisionState: DecisionState, forIndexPath indexPath: NSIndexPath, startAnimation: ()->())
}

protocol DilemmaCellExtendedButtonDelegate: DilemmaCellDelegate {
    func dilemmaCell(cell: UITableViewCell, didPressDecidedButtonForState decidedState: DecisionState, forIndexPath indexPath: NSIndexPath)
}

// Because we want to switch easily the internal workings of the left and right button for a client class, we bind it inside an enumeration with the meaning of reject and accept, so we just need to change the return values.
enum DecisionState {
    case Accept, Reject
    
    func getState(dilemmaView: DilemmaView) -> DilemmaState {
        switch self {
        case .Reject:
            return DilemmaLeftState(view: dilemmaView)
        case .Accept:
            return DilemmaRightState(view: dilemmaView)
        }
    }
}




class DilemmaCell: UITableViewCell {
    
    // A tableview cell can conform to a dilemma cell as long as it contains a dilemma view in it. This is especially usefull for offers and matches
    @IBOutlet weak var dilemmaView: DilemmaView!
    
    var indexPath: NSIndexPath?
    
    var delegate: DilemmaCellDelegate? {
        didSet {
            setup()
        }
    }
    
    var acceptedWithButton: Bool? {
        willSet {
            dilemmaView.reinitialize()
            if let nv = newValue {
                let decisionState: DecisionState = nv == true ? DecisionState.Accept : DecisionState.Reject
                var dilemmaState: DilemmaState = decisionState.getState(dilemmaView)
                
                if let d = delegate as? DilemmaCellExtendedButtonDelegate {
                    dilemmaState.addExtendedButtonTarget(self, action: "onAcceptedButtonPress:", forControlEvents: UIControlEvents.TouchUpInside)
                    dilemmaState.setExtendedButtonModeView()
                } else {
                    println("DEBUG: delegate is nil or class doesn't conform to DilemmaCellExtendedButtonDelegate")
                }
            }
        }
    }
    
    var accepted: Bool? {
        willSet {
            dilemmaView.reinitialize()
            if let nv = newValue {
                let decisionState: DecisionState = nv == true ? DecisionState.Accept : DecisionState.Reject
                let dilemmaState: DilemmaState = decisionState.getState(dilemmaView)
                dilemmaState.setView()
            }
        }
    }
    
    var enabled: Bool = true {
        willSet {
            if newValue == true {
                dilemmaView.enableButtons()
            } else {
                dilemmaView.disableButtons()
            }
        }
    }
    
    var rejectTitle: String? {
        set {
            var decision = DecisionState.Reject.getState(dilemmaView)
            decision.buttonTitle = newValue
        }
        get { return DecisionState.Reject.getState(dilemmaView).buttonTitle }
    }
    
    var acceptTitle: String? {
        set {
            var decision = DecisionState.Accept.getState(dilemmaView)
            decision.buttonTitle = newValue
        }
        get { return DecisionState.Accept.getState(dilemmaView).buttonTitle }
    }
    
    var rejectedTitle: String? {
        set {
            var decision = DecisionState.Reject.getState(dilemmaView)
            decision.decidedTitle = newValue
        }
        get { return DecisionState.Reject.getState(dilemmaView).decidedTitle }
    }
    
    var acceptedTitle: String? {
        set {
            var decision = DecisionState.Accept.getState(dilemmaView)
            decision.decidedTitle = newValue
        }
        get { return DecisionState.Accept.getState(dilemmaView).decidedTitle }
    }
    
    override func awakeFromNib() {

        // Default values, they can be changed with the computed properties
        rejectTitle = NSLocalizedString("Reject", comment: "")
        acceptTitle = NSLocalizedString("Accept", comment: "")
        rejectedTitle = NSLocalizedString("Rejected", comment: "")
        acceptedTitle = NSLocalizedString("Accepted", comment: "")
        
        DecisionState.Accept.getState(dilemmaView).setColor(UIColor.ICGreenDilemmaColor())
        DecisionState.Reject.getState(dilemmaView).setColor(UIColor.ICRedDilemmaColor())
    }
    
    private func setup() {
        DecisionState.Reject.getState(dilemmaView).addTarget(self, action: "onRejectButtonPress:", forControlEvents: UIControlEvents.TouchUpInside)
        DecisionState.Accept.getState(dilemmaView).addTarget(self, action: "onAcceptButtonPress:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func onAcceptButtonPress(event: UIButton) {
        callDelegate(decisionState: DecisionState.Accept)
    }
    
    func onRejectButtonPress(event: UIButton) {
        callDelegate(decisionState: DecisionState.Reject)
    }
    
    func onAcceptedButtonPress(event: UIButton) {
        if let ip = indexPath {
            println("onAcceptedButtonPress")
            (delegate as? DilemmaCellExtendedButtonDelegate)?.dilemmaCell(self, didPressDecidedButtonForState: DecisionState.Accept, forIndexPath: ip)
        } else {
            println("DEBUG: No indexpath given")
        }
    }
    
    func callDelegate(decisionState state: DecisionState) {

        if let ip = indexPath {
            delegate?.dilemmaCell(self, didPressButtonForState: state, forIndexPath: ip, startAnimation: { () -> () in
                state.getState(self.dilemmaView).startAnimation()
            })
        } else {
            println("DEBUG: No indexpath given")
        }
    }
}
