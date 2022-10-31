//
//  LoginViewController.swift
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

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.addTarget(self, action: #selector(validateForm), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(goToRegister), for: .touchUpInside)
        emailTextField.delegate = self
    }
    
    //MARK: This func check form
    @objc func validateForm() {
        if  emailTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == true ||
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
        
        login(withEmail: emailTextField.text!, password: passwordTextField.text!)
    }
    
    //MARK: This func check if mail is valid
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    //MARK: This func check if pass is valid
    func isValidPassword(password: String) -> Bool {
        let password = password.trimmingCharacters(in: CharacterSet.whitespaces)
        let passwordRegx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordCheck = NSPredicate(format: "SELF MATCHES %@",passwordRegx)
        return passwordCheck.evaluate(with: password)
    }
    
    func login(withEmail email: String, password: String){
        self.view.isUserInteractionEnabled = false
        IHProgressHUD.show()
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            self.view.isUserInteractionEnabled = true
            IHProgressHUD.dismiss()
            if let e = error{
                print(e)
                self.presentSimpleAlert("Erreur", message: e.localizedDescription, buttonTitle: "Ok")
                return
            }
            self.goToMainMenu()
        }
    }
    
    func goToMainMenu() {
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStory.instantiateViewController(withIdentifier: "mainView") as! UINavigationController
        self.view.window?.rootViewController = viewController
        self.view.window?.makeKeyAndVisible()
    }
    
    @objc func goToRegister() {
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStory.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        vc.title = "Inscription"
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        return string == string.components(separatedBy: " ").joined(separator: "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch textField {
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        default:
            textField.endEditing(true)
            break
        }
        return true
    }
}
