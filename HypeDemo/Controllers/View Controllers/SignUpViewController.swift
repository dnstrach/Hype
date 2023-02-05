//
//  SignUpViewController.swift
//  HypeDemo
//
//  Created by Dominique Strachan on 2/4/23.
//

import UIKit

class SignUpViewController: UIViewController {

    //MARK: Properties
    var profilePhoto: UIImage?
    
    //MARK: - Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var photoContainerView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        fetchUser()
    }
    
    //MARK: - Actions
    @IBAction func signUpButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text, !username.isEmpty,
              let bio = bioTextField.text
        else { return }
        
        UserController.shared.createUser(with: username, bio: bio, profilePhoto: profilePhoto) { (success) in
            if success {
                self.presentHypeListVC()
            }
        }
    }
    
    //MARK: Helpers
    func setUpViews() {
        photoContainerView.layer.cornerRadius = photoContainerView.frame.height / 2
        photoContainerView.clipsToBounds = true
    }
    
    func fetchUser() {
        UserController.shared.fetchUser { (success) in
            if success {
                //Jump to the list view
                self.presentHypeListVC()
            }
        }
    }
    
    func presentHypeListVC() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "HypeList", bundle: nil)
            guard let viewController = storyboard.instantiateInitialViewController() else { return }
            viewController.modalPresentationStyle = .fullScreen
            self.present(viewController, animated: true)
        }
    }
    
    //assigning delegate to embedded segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoPickerVC" {
            let destinationVC = segue.destination as? PhotoPickerViewController
            destinationVC?.delegate = self
        }
    }
    
}//end of class

extension SignUpViewController: PhotoPickerDelegate {
    func photoPickerSelected(image: UIImage) {
        self.profilePhoto = image
    }
}//end of extension
