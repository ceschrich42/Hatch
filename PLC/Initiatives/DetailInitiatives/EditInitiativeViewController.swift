//
//  EditInitiativeViewController.swift
//  PLC
//
//  Created by Connor Eschrich on 7/11/18.
//  Copyright © 2018 Chris Chou. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class EditInitiativeViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: Properties
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var endTimeTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var leadAmountTextField: UITextField!
    @IBOutlet weak var leadCheckBox: UIButton!
    @IBOutlet weak var participateAmountTextField: UITextField!
    @IBOutlet weak var participateCheckBox: UIButton!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var validationCheckBoxLabel: UILabel!
    @IBOutlet weak var taskImageView: UIImageView!
    @IBOutlet weak var addImageLabel: UILabel!
    @IBOutlet weak var removeImageButton: UIButton!
    @IBOutlet weak var addImageButton: UIButton!
    @IBOutlet weak var categoryTextField: UITextField!
    
    let startDatePicker = UIDatePicker()
    let endDatePicker = UIDatePicker()
    let categoryPickerView = UIPickerView()
    let categories: [String] = ["Fun and Games", "Philanthropy", "Shared Interests", "Skill Building", "Other"]
    var eventTime: TimeInterval = 0.0
    var eventEndTime: TimeInterval = 0.0
    var task_in:Task!
    var task_out:Task!
    var taskPhoto: UIImage = UIImage()
    var taskPhotoURL: NSURL = NSURL()
    var titleChanged = false
    var descriptionChanged = false
    var timeChanged = false
    var endTimeChanged = false
    var locationChanged = false
    var tagsChanged = false
    var photoChanged = false
    var photoRemoved = false
    var categoryChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTask()
        
        //Initial Setup For Edit Page
        validationCheckBoxLabel.text = ""
        taskImageView.isHidden = true
        
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        categoryTextField.inputView = categoryPickerView
        
        startDatePicker.datePickerMode = UIDatePickerMode.dateAndTime
        endDatePicker.datePickerMode = UIDatePickerMode.dateAndTime
        timeTextField.inputView = startDatePicker
        endTimeTextField.inputView = endDatePicker
        startDatePicker.addTarget(self, action: #selector(datePickerChanged), for:UIControlEvents.valueChanged)
        endDatePicker.addTarget(self, action: #selector(datePickerChanged), for:UIControlEvents.valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Actions
    @IBAction func createButton(_ sender: UIButton) {
        //Checks to make sure all fields are still all filled out correctly
        if validate(){
            self.performSegue(withIdentifier: "unwindToDetail", sender: self)
        }
    }
    
    //Checks to see if image is added
    @IBAction func addImageButton(_ sender: UIButton) {
        photoChanged = true
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true)
    }
    
    //Checks to see if image removed
    @IBAction func removeImageButton(_ sender: UIButton) {
        photoRemoved = true
        taskImageView.isHidden = true
        addImageLabel.text = "Add Image"
        addImageButton.isHidden = false
        removeImageButton.isHidden = true
    }
    
    @IBAction func leadCheckBox(_ sender: UIButton) {
        tagsChanged = true
        //Unchecks and checks box
        sender.isSelected = !sender.isSelected
        //If checked, the amount textfield is enabled
        if (sender.isSelected){
            leadAmountTextField.isEnabled = true
        }
        else{
            leadAmountTextField.isEnabled = false
        }
    }
    @IBAction func participateCheckBox(_ sender: UIButton) {
        tagsChanged = true
        //Unchecks and checks box
        sender.isSelected = !sender.isSelected
        //If checked, the amount textfield is enabled
        if (sender.isSelected){
            participateAmountTextField.isEnabled = true
        }
        else{
            participateAmountTextField.isEnabled = false
        }
    }
    
    //Checks to see if title changes
    @IBAction func titleChanged(_ sender: UITextField) {
        titleChanged = true
    }
    
    //Checks to see if description changes
    @IBAction func descriptionChanged(_ sender: UITextField) {
        descriptionChanged = true
    }
    
    //Checks to see if location changes
    @IBAction func locationChanged(_ sender: UITextField) {
        locationChanged = true
    }
    
    //Checks to see if category changes
    @IBAction func categoryChanged(_ sender: UITextField) {
        categoryChanged = true
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        dismiss()
    }
    
    //MARK: Date Picker
    @objc func datePickerChanged(datePicker:UIDatePicker) {
        if datePicker == startDatePicker{
            eventTime = datePicker.date.timeIntervalSince1970
            timeTextField.text = format(datePicker: datePicker)
            endDatePicker.minimumDate = datePicker.date
        }
        else{
            eventEndTime = datePicker.date.timeIntervalSince1970
            endTimeTextField.text = format(datePicker: datePicker)
        }
    }
    
    //Helper Function for Date Picker
    private func format(datePicker:UIDatePicker) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.medium
        return dateFormatter.string(from:datePicker.date)
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: Segue Functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToDetail"{
            handleTaskChange()
        }
    }
    
    //MARK: Helper Functions
    private func dismiss(){
        self.dismiss(animated: true, completion: nil)
    }
    
    private func configureTask(){
        titleTextField.text = task_in.title
        descriptionTextField.text = task_in.description
        timeTextField.text = task_in.startTime
        endTimeTextField.text = task_in.endTime
        locationTextField.text = task_in.location
        categoryTextField.text = task_in.category
        addImageButton.isHidden = true
        removeImageButton.isHidden = true
        
        let storageRef = Constants.refs.storage.child("taskPhotos/\(task_in.id).png")
        // Load the image using SDWebImage
        self.taskImageView.isHidden = false
        taskImageView.sd_setImage(with: storageRef, placeholderImage: nil) { (image, error, cacheType, storageRef) in
            if error != nil {
                self.taskImageView.isHidden = true
                self.addImageButton.isHidden = false
                self.addImageLabel.text = "Add Image"
            }
            else{
                self.taskImageView.isHidden = false
                self.removeImageButton.isHidden = false
                self.addImageLabel.text = "\(self.task_in.id).png"
            }
            
        }
        
        leadCheckBox.isSelected = false
        leadAmountTextField.isEnabled = false
        participateCheckBox.isSelected = false
        participateAmountTextField.isEnabled = false
        let tags = task_in.tag
        let tagArray = tags.components(separatedBy: " ")
        for tag in tagArray{
            //Parses amount of leaders needed and puts it in a dictionary if the amount needed is greater than 0
            if tag == "#lead"{
                leadCheckBox.isSelected = true
                leadAmountTextField.isEnabled = true
                
                leadAmountTextField.text = String(task_in.amounts["leaders"]!)
            }
            //Parses amount of participants needed and puts it in a dictionary if the amount needed is greater than 0
            if tag == "#participate"{
                participateCheckBox.isSelected = true
                participateAmountTextField.isEnabled = true
                participateAmountTextField.text = String(task_in.amounts["participants"]!)
            }
        }
        
    }

    private func validate() -> Bool{
        var valid:Bool = true
        if (titleTextField.text?.isEmpty)! {
            //Change the placeholder color to P.S. red
            titleTextField.attributedPlaceholder = NSAttributedString(string: "Please enter Task Title", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (descriptionTextField.text?.isEmpty)!{
            //Change the placeholder color to P.S. red
            descriptionTextField.attributedPlaceholder = NSAttributedString(string: "Please enter Task Description", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (timeTextField.text?.isEmpty)!{
            //Change the placeholder color to P.S. red
            timeTextField.attributedPlaceholder = NSAttributedString(string: "Please enter a Start Time", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (endTimeTextField.text?.isEmpty)!{
            //Change the placeholder color to P.S. red
            endTimeTextField.attributedPlaceholder = NSAttributedString(string: "Please enter an End Time", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (locationTextField.text?.isEmpty)!{
            //Change the placeholder color to P.S. red
            locationTextField.attributedPlaceholder = NSAttributedString(string: "Please enter a Location", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (categoryTextField.text?.isEmpty)!{
            //Change the placeholder color to P.S. red
            categoryTextField.attributedPlaceholder = NSAttributedString(string: "Please select a Category", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if !(leadCheckBox.isSelected) && !(participateCheckBox.isSelected){
            validationCheckBoxLabel.textColor = UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)
            validationCheckBoxLabel.text = "'People Needed' not complete"
            valid = false
        }
        else{
            if ((leadAmountTextField.isEnabled) && (leadAmountTextField.text?.isEmpty)!) || ((participateAmountTextField.isEnabled) && (participateAmountTextField.text?.isEmpty)!){
                validationCheckBoxLabel.textColor = UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)
                validationCheckBoxLabel.text = "'People Needed' not complete"
                valid = false
            }
            else{
                validationCheckBoxLabel.text = ""
            }
        }
        return valid
    }
    
    private func handleTaskChange(){
        //Edits task in database if there are any changes
            if (titleChanged || descriptionChanged || timeChanged || endTimeChanged || locationChanged || tagsChanged || photoChanged || photoRemoved || categoryChanged){
                let currentTask = Constants.refs.databaseTasks.child(task_in.id)
                if (titleChanged){
                    currentTask.child("taskTitle").setValue(titleTextField.text!)
                    
                }
                if (descriptionChanged){
                    currentTask.child("taskDescription").setValue(descriptionTextField.text!)
                }
                if (timeChanged){
                    currentTask.child("taskTime").setValue(timeTextField.text!)
                    currentTask.child("taskTimeMilliseconds").setValue(eventTime)
                }
                if (endTimeChanged){
                    currentTask.child("taskEndTime").setValue(endTimeTextField.text!)
                    currentTask.child("taskEndTimeMilliseconds").setValue(eventEndTime)
                }
                if (locationChanged){
                    currentTask.child("taskLocation").setValue(locationTextField.text!)
                }
                if (categoryChanged){
                    currentTask.child("category").setValue(categoryTextField.text!)
                }
                if (photoChanged){
                    let imageName:String = String("\(task_in.id).png")
                    
                    let storageRef = Constants.refs.storage.child("taskPhotos/\(imageName)")
                    
                    // Delete the file
                    storageRef.delete { error in
                        if error != nil {
                            print("Error deleting image")
                        }
                    }
                    
                    SDImageCache.shared().removeImage(forKey: storageRef.fullPath)
                    SDImageCache.shared().clearMemory()
                    SDImageCache.shared().clearDisk()

                    if let uploadData = UIImageJPEGRepresentation(taskPhoto, CGFloat(0.50)){
                        storageRef.putData(uploadData, metadata: nil
                            , completion: { (metadata, error) in
                                if error != nil {
                                    print("Error adding image")
                                    return
                                }
                        })
                        
                    }
                }
                if (photoRemoved){
                    let imageName:String = String("\(task_in.id).png")
                    
                    let storageRef = Constants.refs.storage.child("taskPhotos/\(imageName)")
                    
                    // Delete the file
                    storageRef.delete { error in
                        if error != nil {
                            print("Error deleting image")
                        }
                 
                    }
                }
                if (tagsChanged){
                    var amounts = Dictionary<String, Int>()
                    var tagResult: String = ""
                    var participantAmount = 0
                    var leaderAmount = 0
                    if leadCheckBox.isSelected {
                        leaderAmount = Int(leadAmountTextField.text!)!
                        if tagResult == ""{
                            tagResult.append("#lead")
                        }
                        else{
                            tagResult.append(" #lead")
                        }
                        amounts["leaders"] = leaderAmount
                    }
                    if participateCheckBox.isSelected {
                        participantAmount = Int(participateAmountTextField.text!)!
                        if tagResult == ""{
                            tagResult.append("#participate")
                        }
                        else{
                            tagResult.append(" #participate")
                        }
                        amounts["participants"] = participantAmount
                    }
                    currentTask.child("taskTag").setValue(tagResult)
                    currentTask.child("participantAmount").setValue(participantAmount)
                    currentTask.child("leaderAmount").setValue(leaderAmount)
                }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ _picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        taskPhoto = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
        taskImageView.isHidden = false
        taskImageView.image = taskPhoto
        taskPhotoURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        let imageName = taskPhotoURL.lastPathComponent
        addImageLabel.text = imageName
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: UIPickerViewDataSource methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    //MARK: UIPickerViewDelegates methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryTextField.text = "\(categories[pickerView.selectedRow(inComponent: 0)])"
    }
}
