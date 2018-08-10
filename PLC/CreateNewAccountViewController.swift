//
//  CreateNewAccountViewController.swift
//  PLC
//
//  Created by Connor Eschrich on 7/20/18.
//  Copyright © 2018 Chris Chou. All rights reserved.
//

import UIKit
import FirebaseAuth

class CreateNewAccountViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: OUTLETS
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var reEnterPasswordTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var jobTitleTextField: UITextField!
    @IBOutlet weak var departmentTextField: UITextField!
    @IBOutlet weak var funFactTextField: UITextField!
    
    // MARK: Initialize
    var profilePic: UIImage = UIImage()
    let departmentPickerView = UIPickerView()
    let departments: [String] = ["Engineering", "Strategy & Consulting", "Marketing & Experience"]
    
    // MARK: Constants
    let loginToTasks = "LoginToTasks"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up delegates and department appearance
        departmentPickerView.delegate = self
        departmentPickerView.dataSource = self
        departmentTextField.inputView = departmentPickerView
        
        // Profile picture appearance
        profilePhoto.layer.cornerRadius = profilePhoto.frame.size.width/2
        profilePhoto.layer.borderWidth = 0.1
        profilePhoto.layer.borderColor = UIColor.black.cgColor
        profilePhoto.clipsToBounds = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // User add profile picture
    @IBAction func addNewProfilePhoto(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true)
    }
    
    // Cancel button
    @IBAction func cancelButton(_ sender: UIButton) {
        dismiss()
    }
    
    // Save Button
    @IBAction func saveButton(_ sender: UIButton) {
        
        // Valid
        let valid = validate()
        if (valid){
            // Creates a new user account if there are no errors
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { user, error in
                
                // No errors
                if error == nil {
                    
                    // Guard
                    guard let user = Auth.auth().currentUser else { return }
                    
                    // Initialize user object from user data
                    currentUser = User(authData: user, firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, jobTitle: self.jobTitleTextField.text!, department: self.departmentTextField.text!, funFact: self.funFactTextField.text!, points: 0)
                    let key = currentUser.uid
                    
                    // Update database of user info
                    Constants.refs.databaseUsers.observe(.value, with: { snapshot in
                        if !snapshot.hasChild(key) {
                            Constants.refs.databaseUsers.child(key).setValue(["uid": key, "firstName": currentUser.firstName, "lastName": currentUser.lastName, "jobTitle": currentUser.jobTitle, "department": currentUser.department, "funFact": currentUser.funFact, "points": 0, "email": currentUser.email, "tasks_created": [], "tasks_liked": []])
                            
                            // Update profile picture information
                            if (self.profilePhoto.image != #imageLiteral(resourceName: "iconProfile")){
                                let imageName:String = String("\(key).png")
                                
                                let storageRef = Constants.refs.storage.child("userPhotos/\(imageName)")
                                if let uploadData = UIImageJPEGRepresentation(self.profilePic, CGFloat(0.50)){
                                    storageRef.putData(uploadData, metadata: nil
                                        , completion: { (metadata, error) in
                                            if error != nil {
                                                return
                                            }
                                    })
                                    
                                }
                            }
                            
                            // Add user to department database
                            switch(currentUser.department) {
                                case("Engineering"):
                                    Constants.refs.databaseEngineering.child(currentUser.uid).setValue(["userID": currentUser.uid])
                                    break
                                case("Marketing & Experience"):
                                    Constants.refs.databaseMarketing.child(currentUser.uid).setValue(["userID": currentUser.uid])
                                    break
                                case("Strategy & Consulting"):
                                    Constants.refs.databaseStrategy.child(currentUser.uid).setValue(["userID": currentUser.uid])
                                    break
                                default:
                                    break
                            }
                        }
                    })
                }
            }
            // Segue to tutorial
            self.performSegue(withIdentifier: "toTutorial", sender: nil)
        }
    }
    
    @IBAction func passwordEditingDidEnd(_ sender: UITextField) {
        reEnterPasswordTextField.isHidden = false
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(_ _picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        profilePic = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
        profilePhoto.image = profilePic
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
        return departments.count
    }
    
    //MARK: UIPickerViewDelegates methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return departments[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        departmentTextField.text = "\(departments[pickerView.selectedRow(inComponent: 0)])"
    }
    
    
    private func dismiss(){
        self.dismiss(animated: true, completion: nil)
    }
    
    // Validate input
    private func validate() -> Bool{
        var valid:Bool = true
        
        // Validate email text field
        if (emailTextField.text?.isEmpty)! || !((emailTextField.text?.contains("@"))!) || !((emailTextField.text?.contains(".com"))!) {
            emailTextField.text = nil
            emailTextField.attributedPlaceholder = NSAttributedString(string: "Please enter a valid Email", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        
        // Validate password text field
        if (passwordTextField.text?.isEmpty)!{
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "Please enter a valid Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        
        // Validate re-enter password text field
        if (reEnterPasswordTextField.text?.isEmpty)!{
            reEnterPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Please re-enter your Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        
        // Re-enter password and password text fields match
        if (reEnterPasswordTextField.text! != passwordTextField.text!){
            reEnterPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Password doesn't match", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        
        // Check for empty inputs (first name, last name, job title, department)
        if (firstNameTextField.text?.isEmpty)!{
            firstNameTextField.attributedPlaceholder = NSAttributedString(string: "Please enter your First Name", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (lastNameTextField.text?.isEmpty)!{
            lastNameTextField.attributedPlaceholder = NSAttributedString(string: "Please enter your Last Name", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (jobTitleTextField.text?.isEmpty)!{
            jobTitleTextField.attributedPlaceholder = NSAttributedString(string: "Please enter your Job Title", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (departmentTextField.text?.isEmpty)!{
            departmentTextField.attributedPlaceholder = NSAttributedString(string: "Please enter your Department", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        if (funFactTextField.text?.isEmpty)!{
            funFactTextField.attributedPlaceholder = NSAttributedString(string: "Please enter your Fun Fact", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 218.0/255.0, green: 73.0/255.0, blue: 82.0/255.0, alpha: 1.0)])
            valid = false
        }
        return valid
    }
    
    @IBAction func unwindToCreateNewAccount(segue:UIStoryboardSegue){
        dismiss(animated: false, completion: nil)
    }
    
}
