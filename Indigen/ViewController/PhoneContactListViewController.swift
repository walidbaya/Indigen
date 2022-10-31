//
//  PhoneContactListViewController.swift
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
import MessageUI
import IHProgressHUD

class PhoneContactListViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    let contactStore = CNContactStore()
    var contacts : [CNContact] = []
    var filtredContacts : [CNContact] = []
    var isSearchBarActive = false
    let keys = [
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        CNContactPhoneNumbersKey,
        CNContactEmailAddressesKey
    ] as [Any]
    
    var qrImage : UIImage?
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        fetchContact()
    }
    
    func initView() {
        tableView.register(UINib(nibName: "PhoneCell", bundle: nil), forCellReuseIdentifier: "PhoneCell")
        tableView.rowHeight = 60
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
    }
    
    //MARK: Function called when photo selected
    func fetchContact() {
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        do {
            IHProgressHUD.show()
            try contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                // Array containing all unified contacts from everywhere
                contacts.append(contact)
                for phoneNumber in contact.phoneNumbers {
                    if let label = phoneNumber.label {
                        let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
                        print("\(contact.givenName) \(contact.familyName) tel:\(localizedLabel) -- \(phoneNumber.value.stringValue), email: \(contact.emailAddresses)")
                    }
                }
            }
            IHProgressHUD.dismiss()
            contacts = contacts.sorted (by :{ $0.givenName.lowercased() < $1.givenName.lowercased() })
            tableView.reloadData()
        } catch {
            print("unable to fetch contacts")
        }
    }
    
    //MARK: This func add a selected contact to db
    func addContact(myUid:String, contact: CNContact) {
        let firstName = contact.givenName
        let lastName = contact.familyName
        let email = (contact.emailAddresses.first?.value ?? "") as String
        let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
        
        let values = ["firstName": firstName, "lastName": lastName, "email": email, "phoneNumber": phone]
        let ref = Database.database().reference()
        ref.child("users").child(myUid).child("contacts").queryOrdered(byChild: "firstName")
        let contactReference = ref.child("users").child(myUid).child("contacts").childByAutoId()
        contactReference.setValue(values)
    }
    
    //MARK: This func used to display the message sending window
    private func displayMessageInterface(contact: CNContact) {
        if MFMessageComposeViewController.canSendText() {
            let number = (contact.phoneNumbers.first?.value.stringValue ?? "").replacingOccurrences(of: " ", with: "")
            let composeViewController = MFMessageComposeViewController()
            composeViewController.messageComposeDelegate = self
            composeViewController.recipients = [number]
            
            if MFMessageComposeViewController.canSendAttachments() {
                let image = qrImage!
                let dataImage =  image.pngData()
                guard dataImage != nil else {
                    return
                }
                composeViewController.addAttachmentData(dataImage!, typeIdentifier: "image/png", filename: "ImageData.png")
            }
            self.present(composeViewController, animated: true)
            if let uid = Auth.auth().currentUser?.uid {
                self.addContact(myUid: uid, contact: contact)
            }
        } else {
            print("Can't send messages.")
        }
    }
}

extension PhoneContactListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (isSearchBarActive) {
              return filtredContacts.count
          } else {
              return contacts.count
          }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhoneCell") as! PhoneCell
        if (isSearchBarActive) {
            cell.titleLabel.text = "\(filtredContacts[indexPath.row].givenName) \(filtredContacts[indexPath.row].familyName)"
            cell.subTitleLabel.text = filtredContacts[indexPath.row].phoneNumbers.first?.value.stringValue
            return cell
        } else {
            cell.titleLabel.text = "\(contacts[indexPath.row].givenName) \(contacts[indexPath.row].familyName)"
            cell.subTitleLabel.text = contacts[indexPath.row].phoneNumbers.first?.value.stringValue
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = isSearchBarActive ? filtredContacts[indexPath.row] : contacts [indexPath.row]
        displayMessageInterface(contact: contact)
    }
}

extension PhoneContactListViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        if result == .failed {
            print("could not send message")
            presentSimpleAlert("Erreur", message: "impossible d'envoyer le message", buttonTitle: "Fermer")
        }
        self.dismiss(animated: true)
    }
}

extension PhoneContactListViewController: UISearchBarDelegate {
    private func searchBarTextDidEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchBarActive = true
        self.searchBar.showsCancelButton = true
        filtredContacts.removeAll(keepingCapacity: false)
        self.tableView.reloadData()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchBarActive = false
        filtredContacts.removeAll(keepingCapacity: false)
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filtredContacts = searchText.isEmpty ? contacts : contacts.filter { $0.givenName.lowercased().contains(searchText.lowercased()) || $0.familyName.lowercased().contains(searchText.lowercased()) ||
            $0.emailAddresses.filter { $0.value.lowercased.contains(searchText.lowercased()) }.count != 0 ||
            $0.phoneNumbers.filter { $0.value.stringValue.trimmingCharacters(in: .whitespaces).contains(searchText.trimmingCharacters(in: .whitespaces)) }.count != 0
        }
        tableView.reloadData()
    }
}
