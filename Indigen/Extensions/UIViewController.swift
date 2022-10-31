//
//  UIViewController.swift
//  Indigen
//
//  Created by Walid on 31/10/2022.
//

import Foundation
import UIKit

extension UIViewController {
    
    //MARK: This func to customize navigation bar
    func setupNavBar() {
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        if let navigationBar = self.navigationController?.navigationBar {
            [navigationBar].forEach {
                $0.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                $0.setBackgroundImage(UIImage(), for: .default)
                $0.shadowImage = UIImage()
                $0.backgroundColor = .clear
                $0.barTintColor = .white
                $0.tintColor = .white
                $0.backItem?.title = ""
                $0.titleTextAttributes = textAttributes
                $0.isTranslucent = true
                if #available(iOS 13.0, *) {
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundImage = UIImage()
                    appearance.backgroundColor = .clear
                    appearance.shadowColor = .clear
                    appearance.shadowImage = UIImage()
                    appearance.titleTextAttributes = textAttributes
                    $0.standardAppearance = appearance
                    $0.scrollEdgeAppearance = $0.standardAppearance
                }
            }
        }
    }

    
    //MARK: This func present an alert for a given title and message
    func presentSimpleAlert(_ title: String?, message: String?, buttonTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: This func hide keyboard when editing ended
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
