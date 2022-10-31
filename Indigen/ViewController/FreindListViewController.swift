//
//  FreindListViewController.swift
//  Indigen
//
//  Created by Walid on 31/10/2022.
//

import Foundation
import UIKit
import AVFoundation
import Contacts
import FirebaseAuth
import FirebaseDatabase
import IHProgressHUD

class FreindListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var emptyView: UIStackView!
    var contacts: [Contact] = []
    let refreshControl = UIRefreshControl()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchContact()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavBarButton()
        setUpTableView()
        updateView()
    }
    
    func setUpTableView() {
        tableView.register(UINib(nibName: "PhoneCell", bundle: nil), forCellReuseIdentifier: "PhoneCell")
        tableView.rowHeight = 60
        refreshControl.attributedTitle = NSAttributedString(string: "Tirer pour rafraîchir")
        refreshControl.addTarget(self, action: #selector(fetchContact), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    //MARK: This func add button to navigationBar
    func setUpNavBarButton() {
        let scan = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(goToScanner))
        scan.tintColor = .white
        
        let qrButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        qrButton.setBackgroundImage(UIImage(named: "qrcode"), for: .normal)
        qrButton.addTarget(self, action: #selector(goToQrCodeView), for: .touchUpInside)
        qrButton.tintColor = .white
        let qrCode = UIBarButtonItem(customView: qrButton)
        qrCode.customView?.widthAnchor.constraint(equalToConstant: 24).isActive = true
        qrCode.customView?.heightAnchor.constraint(equalToConstant: 24).isActive = true

        navigationItem.rightBarButtonItems = [scan, qrCode]
    }
    
    //MARK: This func used to retrieve database contact list
    @objc func fetchContact() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            let contactReference = ref.child("users").child(uid).child("contacts")
            contactReference.queryOrdered(byChild: "firstName").observeSingleEvent(of: .value, with: { snapshot  in
                self.contacts = []
                for snapChild in snapshot.children {
                    let child = snapChild as? DataSnapshot
                    if let value = child?.value as? [String: Any] {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: value)
                            let contact = try JSONDecoder().decode(Contact.self, from: data)
                            print(contact)
                            if self.contacts.contains(where: { $0.firstName == contact.firstName && $0.lastName == contact.lastName && $0.phoneNumber == contact.phoneNumber}) == false {
                                self.contacts.append(contact)
                            }
                        } catch let error {
                            print(error)
                        }
                    }
                }
                self.updateView()
            })
        } else {
            self.refreshControl.endRefreshing()
        }
    }
    
    func updateView() {
        self.refreshControl.endRefreshing()
        if contacts.isEmpty {
            tableView.isHidden = true
            emptyView.isHidden = false
        } else {
            tableView.isHidden = false
            emptyView.isHidden = true
            self.tableView.reloadData()
        }
    }
    
    @objc func goToScanner() {
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStory.instantiateViewController(withIdentifier: "ScanViewController") as! ScanViewController
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    @objc func goToQrCodeView() {
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStory.instantiateViewController(withIdentifier: "QRCodeViewController") as! QRCodeViewController
        vc.title = "Mon profil"
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension FreindListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhoneCell") as! PhoneCell
        cell.titleLabel.text = "\(contacts[indexPath.row].firstName ?? "") \(contacts[indexPath.row].lastName ?? "")"
        cell.subTitleLabel.text = contacts[indexPath.row].phoneNumber
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStory.instantiateViewController(withIdentifier: "ProfilViewController") as! ProfilViewController
        vc.userDetail = contacts[indexPath.row]
        vc.title = "\(contacts[indexPath.row].firstName ?? "") \(contacts[indexPath.row].lastName ?? "")"
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension FreindListViewController: QRSCannerDelegate {
    func didGetCode(_ code: String) {
        print(code)
        self.presentSimpleAlert("QRCode", message: code, buttonTitle: "Fermer")
    }
}
