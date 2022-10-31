//
//  ProfilViewController.swift
//  Indigen
//
//  Created by Walid on 31/10/2022.
//

import Foundation
import UIKit

class ProfilViewController: UIViewController {
    
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var phoneTextView: UITextView!
    @IBOutlet weak var emailTextView: UITextView!

    var userDetail: Contact?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        setupNavBar()
        initView()
    }
    
    func initView() {
        firstNameTextField.text = userDetail?.firstName
        lastNameTextField.text = userDetail?.lastName
        phoneTextView.text = userDetail?.phoneNumber
        emailTextView.text = userDetail?.email
        
        var tap = UITapGestureRecognizer(target: self, action: #selector(call))
        phoneTextView.addGestureRecognizer(tap)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(sendMail))
        emailTextView.addGestureRecognizer(tap)
    }
    
    //MARK: This func allow to call a number when clicked
    @objc func call() {
        if let number = userDetail?.phoneNumber?.trimmingCharacters(in: .whitespaces) {
            guard let callURL = URL(string: "tel://\(number)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
                return }
            if UIApplication.shared.canOpenURL(callURL) {
                UIApplication.shared.open(callURL)
            }
        }
    }
    
    //MARK: This func allow to send email when clicked
    @objc func sendMail() {
        if let email = userDetail?.email {
            let subject = "[Indigen] "
            let body = "Email body."
            let url = "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            guard let mailURL = URL(string: url!) else { return }
            if UIApplication.shared.canOpenURL(mailURL) {
                UIApplication.shared.open(mailURL)
            }
        }
    }
}
