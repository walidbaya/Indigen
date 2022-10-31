//
//  QRCodeViewController.swift
//  Indigen
//
//  Created by Walid on 31/10/2022.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase
import Contacts

class QRCodeViewController: UIViewController {

    @IBOutlet weak var qrImageView: UIImageView!
    
    let userID = Auth.auth().currentUser?.uid
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generateUserQrCode(from: userID)
    }
  
    func showShareButton() {
        let shareBar: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem:.action, target: self, action: #selector(userDidTapShare))
        shareBar.tintColor = .white
        self.navigationItem.rightBarButtonItem = shareBar
    }
    
    @objc func userDidTapShare() {
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStory.instantiateViewController(withIdentifier: "PhoneContactListViewController") as! PhoneContactListViewController
        vc.title = "Contact"
        vc.qrImage = self.qrImageView.image
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: This func create a user profile and generate the qrCode
    func generateUserQrCode(from userId: String?) {
        if let uid = userId {
            let ref = Database.database().reference()
            let usersReference = ref.child("users").child(uid)
            usersReference.observe(.value, with: { snapshot in
                if let value = snapshot.value as? [String: Any] {
                    let firstName = value["firstName"] as? String ?? ""
                    let lastName = value["lasttName"] as? String ?? ""
                    let email = value["email"] as? String ?? ""
                    let phone = value["phoneNumber"] as? String ?? ""
                    let photoUrl = value["photoURL"] as? String ?? ""
                    
                    let mContact = Utilities.createContactFrom(fName: firstName, lName: lastName, email: email, phone: phone, photo: photoUrl)
                    self.qrImageView.image = Utilities.generateQRCode(from: mContact)
                }
                self.showShareButton()
            })
        }
    }
    
}
