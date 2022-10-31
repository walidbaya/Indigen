//
//  Utilities.swift
//  Indigen
//
//  Created by Walid on 31/10/2022.
//

import Foundation
import UIKit

struct Utilities {
    
    //MARK: This func generate a user profile qrCode
    static func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.utf8)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            guard let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }

            filter.setValue(data, forKey: "inputMessage")

            filter.setValue("H", forKey: "inputCorrectionLevel")
            colorFilter.setValue(filter.outputImage, forKey: "inputImage")
            colorFilter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1") // Background white
            colorFilter.setValue(CIColor(color: .black), forKey: "inputColor0")
 
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            if let output = colorFilter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    //MARK: This func create a user profile format MECARD
    static func createContactFrom(fName: String,
                              lName: String,
                              email: String,
                              phone: String,
                              photo: String) -> String {
        
        return "MECARD:N:\(lName),\(fName);TEL:\(phone);EMAIL:\(email);URL:\(photo);;"
    }
}
