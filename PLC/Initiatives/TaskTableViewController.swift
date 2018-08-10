//
//  InitiativesViewController.swift
//  PLC
//
//  Created by Chris on 6/25/18.
//  Copyright © 2018 Chris Chou. All rights reserved.
//

import UIKit
import Firebase
import Presentr
import SDWebImage


class TaskTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, TaskTableViewCellDelegate {
    
    //MARK: Properties
    var pendingTasks: [String] = []
    var searchController: UISearchController!
    var myIndex = 0
    var currentDB: String = ""
    //All items that will be shown on the feed. No past tasks included
    var overallItems: [Task] = []
    //Every task in the database. Including upcoming, current, pending, and past tasks
    var everyItemCreated: [Task] = []
    //Presentr for Initiative Create form to be presented as a popover when the compose button is clicked
    var presenter = Presentr(presentationType: .custom(width: .default, height: .custom(size:600), center: .center))
    var dataIsAvailable = false
    // Date Formatting for date label for task
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Presentr
        presenter.roundCorners = true
        presenter.cornerRadius = 20
        presenter.dismissOnTap = false
        
        //Tasks Loaded From DB
        Constants.refs.databaseTasks.observe(.value, with: { snapshot in
        var newOverallItems: [Task] = []
            
        for child in snapshot.children {
            if let snapshot = child as? DataSnapshot{
                let tasksInfo = snapshot.value as? [String : Any ] ?? [:]
                var amounts = Dictionary<String, Int>()
                //Parses amount of participants needed and puts it in a dictionary if the amount needed is greater than 0
                if tasksInfo["participantAmount"]! as! Int != 0{
                    amounts["participants"] = (tasksInfo["participantAmount"]! as! Int)
                }
                //Parses amount of leaders needed and puts it in a dictionary if the amount needed is greater than 0
                if tasksInfo["leaderAmount"]! as! Int != 0{
                    amounts["leaders"] = (tasksInfo["leaderAmount"]! as! Int)
                }
                //Creates a new Task object
                let task = Task(title: tasksInfo["taskTitle"]! as! String, description: tasksInfo["taskDescription"]! as! String, tag: tasksInfo["taskTag"]! as! String, startTime: tasksInfo["taskTime"]! as! String, endTime: tasksInfo["taskEndTime"]! as! String, location: tasksInfo["taskLocation"]! as! String, timestamp: tasksInfo["timestamp"]! as! TimeInterval, id: tasksInfo["taskId"]! as! String, createdBy: tasksInfo["createdBy"]! as! String, ranking: tasksInfo["ranking"]! as! Int, timeMilliseconds: tasksInfo["taskTimeMilliseconds"]! as! TimeInterval, endTimeMilliseconds: tasksInfo["taskEndTimeMilliseconds"]! as! TimeInterval, amounts: amounts, usersLikedAmount: tasksInfo["usersLikedAmount"]! as! Int, category: tasksInfo["category"] as! String)
                
                newOverallItems.append(task!)
            }
            
            self.overallItems = newOverallItems
            
            //Retrieves past tasks from the database and removes those tasks from overallItems
            Constants.refs.databasePastTasks.observe(.value, with: {(snapshot) in
                for child in snapshot.children {
                    if let snap = child as? DataSnapshot{
                        let taskInfo = snap.value as? [String : Any ] ?? [:]
                        var upperBound = 0
                        if self.overallItems.count > 0{
                            upperBound = self.overallItems.count-1
                        }
                        overallLoop: for i in 0...upperBound{
                            if self.overallItems[i].id == taskInfo["taskID"] as! String{
                                self.overallItems.remove(at: i)
                                self.tableView.reloadData()
                                break overallLoop
                            }
                        }
                    }
                }
            })
            
            self.everyItemCreated = newOverallItems
            
            //Sorts tasks by timestamp
            self.sortTasks()
            }})
        
        
        //Removes past tasks from the overallItems that are displayed on feed, but not from everyItemCreated
        Constants.refs.databasePastTasks.observe(.value, with: {(snapshot) in
            for child in snapshot.children {
                if let snap = child as? DataSnapshot{
                    let taskInfo = snap.value as? [String : Any ] ?? [:]
                    overallLoop: for i in 0..<self.overallItems.count{
                        if self.overallItems[i].id == taskInfo["taskID"] as! String{
                            self.overallItems.remove(at: i)
                            self.tableView.reloadData()
                            break overallLoop
                        }
                    }
                }
            }
        })
        
        Constants.refs.databasePendingTasks.observe(.value, with: { snapshot in
            var newPendingTasks: [String] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot{
                    newPendingTasks.append(snapshot.key)
                }
                
                self.pendingTasks = newPendingTasks
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    //MARK: Actions
    
    //Compose Button
    @IBAction func composeButton(_ sender: UIBarButtonItem) {
        //get a reference to the view controller for the popover
        let popController = UIStoryboard(name: "InitiativeCreate", bundle: nil).instantiateViewController(withIdentifier: "InitiativeCreateViewController")
        
        customPresentViewController(presenter, viewController: popController, animated: true, completion: nil)
        
        self.tableView.reloadData()
    }
    
    //MARK: TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        //Loads number of sections. If section count is 0, tableview displays "No initiatives available"
        var numOfSections: Int = 0
        if overallItems.count > 0
        {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        }
        else
        {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "No initiatives available"
            noDataLabel.textColor = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }
        return numOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.overallItems.count
    }
    
    // Set myIndex for detailed view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        myIndex = indexPath.row
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Table view cells are reused and should be dequeued using a cell identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath) as! TaskTableViewCell
        
        let currentTasks = Constants.refs.databaseUsers.child(currentUser.uid + "/tasks_liked")

        let thisTask: Task! = self.overallItems[indexPath.row]
        
        //Cell formatting
        cell.taskTitle.numberOfLines = 1
        cell.taskTitle.adjustsFontSizeToFitWidth = true
        cell.taskTitle.text = thisTask!.title
        cell.taskNumberOfLikes.text = String(thisTask!.usersLikedAmount)
        var startTime = thisTask.startTime.split(separator: " ")
        let checkdate = NSDate(timeIntervalSince1970: thisTask.timeMilliseconds)
        let dateString = self.dateFormatter.string(from: checkdate as Date)
        let dayOfWeek = getDayOfWeek(dateString)!
        let taskLocation = thisTask!.location
        var taskTimeInfo = ""
        let currentTime = Date().timeIntervalSince1970
        //If the task is a currentTask, then it will display 'Happening Now'
        if currentTime > thisTask.timeMilliseconds && currentTime < thisTask.endTimeMilliseconds {
            taskTimeInfo = dayOfWeek + ", " + String(startTime[0]) + " " + String(startTime[1]).dropLast()
            taskTimeInfo += " · Happening Now · " + taskLocation
        }
        //If task is an upcoming task, then it will display the start time and date
        else {
            taskTimeInfo = dayOfWeek + ", " + String(startTime[0]) + " " + String(startTime[1]).dropLast()
            taskTimeInfo += " · " + String(startTime[4]) + " "
            taskTimeInfo += String(startTime[5]) + " · " + taskLocation
        }
        cell.taskTime.text = String(taskTimeInfo)
        
        //Check if user has liked the task and display correct heart
        currentTasks.observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.hasChild(thisTask!.id) {
                let unlikedIcon = UIImage(named: "heartIcon")
                cell.taskLiked.setImage(unlikedIcon, for: .normal)
            }
            else {
                let likedIcon = UIImage(named: "redHeart")
                cell.taskLiked.setImage(likedIcon, for: .normal)
            }
        })
        
        let storageRef = Constants.refs.storage.child("taskPhotos/\(thisTask.id).png")
        // Load the image using SDWebImage
        SDImageCache.shared().removeImage(forKey: storageRef.fullPath)
        cell.taskImage.sd_setImage(with: storageRef, placeholderImage: nil) { (image, error, cacheType, storageRef) in
            if error != nil {
                cell.taskImage.image = #imageLiteral(resourceName: "psheader")
                cell.taskImage.contentMode = UIViewContentMode.scaleAspectFill
                cell.taskImage.clipsToBounds = true
            }
            else{
                cell.taskImage.contentMode = UIViewContentMode.scaleAspectFill
                cell.taskImage.clipsToBounds = true
            }
            
        }
        cell.taskCategory.setTitle(thisTask!.category, for: .normal)
        
        var createdByUser = false
        var pendingTask = false
        
        //Displays icons for creation and pending
        if thisTask.createdBy == Auth.auth().currentUser!.uid {
            createdByUser = true
        }
        for id in self.pendingTasks {
            if thisTask.id == id {
                pendingTask = true
            }
        }
        
        if createdByUser && pendingTask {
            cell.taskFirstIcon.image = UIImage(named: "iconChicken")
            cell.taskSecondIcon.image = UIImage(named: "iconPending")
        }
        else if createdByUser && !pendingTask {
            cell.taskFirstIcon.image = UIImage(named: "iconChicken")
            cell.taskSecondIcon.image = nil
        }
        else if !createdByUser && pendingTask {
            cell.taskFirstIcon.image = UIImage(named: "iconPending")
            cell.taskSecondIcon.image = nil
        }
        else {
            cell.taskFirstIcon.image = nil
            cell.taskSecondIcon.image = nil
        }
        cell.delegate = self
        return cell
    }
    
    //MARK: TaskTableViewCell Delegates
    func taskTableViewCellCategoryButtonClicked(_ sender: TaskTableViewCell){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DetailSearchNavigationController") as! UINavigationController
        let childVC = vc.viewControllers[0] as! DetailSearchTableViewController
        childVC.navigationItem.title = sender.taskCategory.title(for: .normal)
        childVC.overallItems = self.everyItemCreated
        
        self.present(vc, animated: true, completion: nil)
    }

    func taskTableViewCellDidTapHeart(_ sender: TaskTableViewCell) {
        guard let tappedIndexPath = tableView.indexPath(for: sender) else { return }
        sender.isSelected = !sender.isSelected
        
        let currentTasks = Constants.refs.databaseUsers.child(currentUser.uid + "/tasks_liked")
        
        currentTasks.observeSingleEvent(of: .value, with: { (snapshot) in
            
            //HEART TAPPED
            if !(snapshot.hasChild(self.overallItems[tappedIndexPath.row].id)){
                let likedIcon = UIImage(named: "redHeart")
                sender.taskLiked.setImage(likedIcon, for: .normal)
                sender.contentView.backgroundColor = UIColor.white
                currentTasks.child(self.overallItems[tappedIndexPath.row].id).setValue(true)
                Constants.refs.databaseTasks.child(self.overallItems[tappedIndexPath.row].id).child("users_liked").child(currentUser.uid).setValue(true)
                Constants.refs.databaseTasks.child(self.overallItems[tappedIndexPath.row].id).child("ranking").setValue(self.overallItems[tappedIndexPath.row].ranking + 1)
                
                Constants.refs.databaseTasks.child(self.overallItems[tappedIndexPath.row].id).child("usersLikedAmount").setValue(self.overallItems[tappedIndexPath.row].usersLikedAmount + 1)
            }
                
            //HEART UNTAPPED
            else {
                let unlikedIcon = UIImage(named: "heartIcon")
                sender.taskLiked.setImage(unlikedIcon, for: .normal)
                currentTasks.child(self.overallItems[tappedIndexPath.row].id).removeValue()
                Constants.refs.databaseTasks.child(self.overallItems[tappedIndexPath.row].id).child("users_liked").child(currentUser.uid).removeValue()
                Constants.refs.databaseTasks.child(self.overallItems[tappedIndexPath.row].id).child("ranking").setValue(self.overallItems[tappedIndexPath.row].ranking - 1)
                
                    if self.overallItems[tappedIndexPath.row].usersLikedAmount - 1 < 0
                    {
                        Constants.refs.databaseTasks.child(self.overallItems[tappedIndexPath.row].id).child("usersLikedAmount").setValue(0)
                }
                    else{
                        Constants.refs.databaseTasks.child(self.overallItems[tappedIndexPath.row].id).child("usersLikedAmount").setValue(self.overallItems[tappedIndexPath.row].usersLikedAmount - 1)
                }
             }
            
        })

    }
    
    //MARK: Segue Functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailTask", let destinationVC = segue.destination as? DetailTaskViewController, let myIndex = tableView.indexPathForSelectedRow?.row {
            
            destinationVC.task_in = self.overallItems[myIndex]
            destinationVC.taskIndex = myIndex
            //This is for the unwind segue after a detail taks is deleted
            destinationVC.segueFromController = "TaskTableViewController"
        }
        if segue.identifier == "toSearch",
            let destinationVC = segue.destination as? SearchViewController{
            //Passes list of all tasks to the search function
            destinationVC.overallItems = self.everyItemCreated
        }
    }
    
    //Unwind Segue
    @IBAction func unwindToInitiatives(segue:UIStoryboardSegue) {
        if segue.identifier == "unwindToInitiatives" {
            let selectedIndex = tableView.indexPathForSelectedRow?.row
            let itemRemoved = self.overallItems[selectedIndex!]
            self.overallItems.remove(at: selectedIndex!)
            let index = self.everyItemCreated.index(where: {$0.id == itemRemoved.id})
            everyItemCreated.remove(at: index!)
            tableView.deleteRows(at: tableView.indexPathsForSelectedRows!, with: .automatic)
            self.tableView.reloadData()
        }
    }
    
    //MARK: Helper Functions
    // Sorts tasks based on creation timestamp
    func sortTasks() -> Void {
        self.overallItems.sort(by: {$0.timestamp > $1.timestamp})
        self.tableView.reloadData()
    }
    
    private func getDayOfWeek(_ today:String) -> String? {
        guard let todayDate = dateFormatter.date(from: today) else { return nil }
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: todayDate)
        
        switch weekDay {
        case 1:
            return "Sun"
        case 2:
            return "Mon"
        case 3:
            return "Tue"
        case 4:
            return "Wed"
        case 5:
            return "Thu"
        case 6:
            return "Fri"
        case 7:
            return "Sat"
        default:
            return "Yikes"
        }
    }
}

