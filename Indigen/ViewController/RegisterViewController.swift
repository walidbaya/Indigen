//
//  RegisterViewController.swift
//  Indigen
//
//  Created by Walid on 31/10/2022.
//

import Foundation
import IHProgressHUD
import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class RegisterViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var chooseImgBuuton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    var profilPic: UIImage? = nil
    var imagePicker = UIImagePickerController()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideKeyboardWhenTappedAround()
        setupNavBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    func initView() {
        registerButton.addTarget(self, action: #selector(validateForm), for: .touchUpInside)
        chooseImgBuuton.addTarget(self, action: #selector(selectPicture), for: .touchUpInside)
        imageView.layer.borderWidth = 1.0
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
    }
    
    //MARK: This func create a user profile in firebase
    func createUser() {
        self.view.isUserInteractionEnabled = false
        IHProgressHUD.show()
        if let email = emailTextField.text, let password = passwordTextField.text {
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                IHProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
                if let e = error{
                    print(e)
                    self.presentSimpleAlert("Erreur lors de l'inscription", message: e.localizedDescription, buttonTitle: "OK")
                    return
                }
                if let u = user {
                    
                    let imageName = u.user.uid
                    let storageRef = Storage.storage().reference().child("Pictures").child("\(imageName).jpg")
                    
                    let uid = u.user.uid
                    
                    if let uploadData = self.profilPic?.jpegData(compressionQuality: 0.1) {
                        let metaData = StorageMetadata()
                        metaData.contentType = "image/jpg"
                        storageRef.putData(uploadData, metadata: metaData, completion: { (_, error) in
                            if let e = error {
                                print(e)
                                self.presentSimpleAlert("Erreur lors de l'inscription", message: e.localizedDescription, buttonTitle: "OK")
                                return
                            }
                            storageRef.downloadURL(completion: { (url, error) in
                                if let photoUrl = url{
                                    self.registerUserIntoDatabaseWithUID(uid: uid, photoUrl: photoUrl.absoluteString)
                                } else {
                                    return
                                }
                            })
                        })
                    }
                }
            }
        }
    }
    
    //MARK: This func save a user profile to dataBase with photo
    func registerUserIntoDatabaseWithUID(uid:String, photoUrl: String) {
        let firstName = self.firstNameTextField.text ?? ""
        let lastName = self.lastNameTextField.text ?? ""
        let phone = self.phoneTextField.text ?? ""
        let email = self.emailTextField.text ?? ""
        let values = ["firstName": firstName, "lastName": lastName, "email": email, "phoneNumber": phone, "photoURL": photoUrl]
        let ref = Database.database().reference()
        let usersReference = ref.child("users").child(uid)
        usersReference.updateChildValues(values) { error, dbRef in
            if let e = error {
                self.presentSimpleAlert("Erreur lors de l'inscription", message: e.localizedDescription, buttonTitle: "OK")
                return
            }
            self.presentSimpleAlert("Inscription", message: "Inscription réussie", buttonTitle: "OK")
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func selectPicture() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func validateForm() {
        if emailTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == true ||
            firstNameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == true || lastNameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == true ||
            phoneTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == true ||
            passwordTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            presentSimpleAlert("", message: "Veuillez renseigner tout les champs.", buttonTitle: "OK")
            return
        }
        
        if isValidEmail(emailTextField.text!) == false {
            presentSimpleAlert("", message: "Email non valide", buttonTitle: "OK")
            return
        }
        
        if isValidPassword(password: passwordTextField.text!) == false {
            presentSimpleAlert("", message: "Mot de passe non valide", buttonTitle: "OK")
            return
        }
        
        if profilPic == nil {
            presentSimpleAlert("", message: "Veuillez choisir une photo", buttonTitle: "OK")
            return
        }
        
        createUser()
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidPassword(password: String) -> Bool {
        let password = password.trimmingCharacters(in: CharacterSet.whitespaces)
        let passwordRegx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordCheck = NSPredicate(format: "SELF MATCHES %@",passwordRegx)
        return passwordCheck.evaluate(with: password)
    }
    
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch textField {
        case lastNameTextField:
            firstNameTextField.becomeFirstResponder()
        case firstNameTextField:
            phoneTextField.becomeFirstResponder()
        case phoneTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            validateForm()
        default:
            textField.endEditing(true)
            break
        }
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate {
    //MARK: Function called when photo selected
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.originalImage]! as! UIImage
        self.imageView.image = image
        self.profilPic = image
    }
}
