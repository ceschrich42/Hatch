//
//  CheckInViewController.swift
//  PLC
//
//  Created by Connor Eschrich on 7/18/18.
//  Copyright © 2018 Chris Chou. All rights reserved.
//

import UIKit
import Firebase

//Protocol for CheckInViewControllerDelegate
protocol CheckInViewControllerDelegate
{
    func setCheckInCurrentTask()
    
}

class CheckInViewController: UIViewController {
    
    //MARK: Properties
    var delegate: CheckInViewControllerDelegate?
    @IBOutlet weak var checkInButton: UIButton!
    var task: Task?
    var usersCheckedIn: [String] = []
    @IBOutlet weak var alreadyCheckedInLabel: UILabel!
    @IBOutlet weak var usersCheckedInLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alreadyCheckedInLabel.isHidden = true
        checkInButton.setTitleColor(UIColor.lightGray, for: .disabled)
        configurePage()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func checkInButton(_ sender: UIButton) {
        //Adds userID to the category taskCheckIn on the task object in the database
        Constants.refs.databaseTasks.child((task?.id)!).child("taskCheckIn").child(currentUser.uid).child("userID").setValue(currentUser.uid)
        //Adds taskID to the category tasks_participated on the user object in the database
        Constants.refs.databaseUsers.child(currentUser.uid ).child("tasks_participated").child(task!.id).setValue(true)
        
        //Gives user participant points for checking in and updates in database
        let point = Points.init()
        let addedPoints = point.getPoints(type: "Participant", thisTask: task!)
        Constants.refs.databaseUsers.child(currentUser.uid).child("points").setValue(currentUser.points + addedPoints)
    }
    
    //MARK: Helper Functions
    //Checks to see if user already checked in to the event
    private func userAlreadyCheckedIn(){
        alreadyCheckedInLabel.isHidden = false
        return
    }
    
    private func configurePage(){
        //Getting users that are already checked in
        Constants.refs.databaseTasks.child(task!.id).child("taskCheckIn").observe(.value, with: { snapshot in
            if (snapshot.exists()){
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot{
                        let checkedInInfo = snapshot.value as! [String : String ]
                        if !self.usersCheckedIn.contains(checkedInInfo["userID"]!){
                            self.usersCheckedIn.append(checkedInInfo["userID"]!)
                        }
                    
                        if (checkedInInfo["userID"]! == currentUser.uid){
                            self.alreadyCheckedInLabel.isHidden = false
                            self.checkInButton.isEnabled = false
                        }
                    }
                }
                  self.usersCheckedInLabel.text = "\(String(describing: self.usersCheckedIn.count)) people already checked in"
            }
            else{
                self.usersCheckedInLabel.text = "\(String(describing: self.usersCheckedIn.count)) people already checked in"
            }
        })
        return
    }
    
}

