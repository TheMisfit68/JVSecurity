//
//  KeyChainItem.swift
//
//
//  Created by Jan Verrept on 07/10/2021.
//

import Foundation
import Security
import OSLog

public struct KeyChainItem{
        
    private var query: [String: Any]
    
    public var secureValue: String? = nil {
        didSet {
            // Prevent an infinite loop by checking if the value has changed
            guard secureValue != oldValue else {
                return
            }
            
            // Update the _secureData property
            secureData = secureValue?.data(using: .utf8)
        }
    }
    
    private var secureData: Data? = nil {
        didSet {
            // Prevent an infinite loop by checking if the value has changed
            guard secureData != oldValue else {
                return
            }
            
            // Update the secureValue property
            secureValue = String(data: secureData!, encoding: .utf8)
        }
    }
    public var attributes: [String: Any]?
    
    private let logger = Logger(subsystem: "be.oneclick.JVSwift", category:"KeyChainItem")

    
    public init(serverAndPort: (String, Int?)? = nil, name label: String? = nil, kind description: String? = nil, account: String, location service: String, comments comment: String? = nil) {
        
        var attributes:[KeychainAttribute:Any] = [:]
        
        if let server = serverAndPort?.0, let portNumber = serverAndPort?.1 {
            attributes[KeychainAttribute._class] = KeychainPasswordType.internetPassword.key
            attributes[KeychainAttribute.server] = server
            attributes[KeychainAttribute.port] = portNumber
        } else if let server = serverAndPort?.0 {
            attributes[KeychainAttribute._class] = KeychainPasswordType.internetPassword.key
            attributes[KeychainAttribute.server] = server
        } else {
            attributes[KeychainAttribute._class] = KeychainPasswordType.genericPassword.key
        }
        
        // Account is a required attribute to work with any KeychainItem
        // but setting the account parameter ""
        // will provide us with an option to search for the first keychainItem that has an account
        // so it can be retrieved on first access
        if (account != ""){
            attributes[KeychainAttribute.account] = account
        }
        attributes[KeychainAttribute.service] = service
        
        if let label = label {
            attributes[KeychainAttribute.label] = label
        }
        
        
        
        // Add optional attributes if provided
        if let label = label {
            attributes[KeychainAttribute.label] = label
        }
        
        if let description = description {
            attributes[KeychainAttribute.description] = description
        }
        
        if let comment = comment {
            attributes[KeychainAttribute.comment] = comment
        }
        
        self.query = Dictionary(uniqueKeysWithValues:attributes.map{($0.key, $1)})

        if attributes[.account] == nil{
            self.query[kSecReturnData as String] = false
            self.query[kSecReturnAttributes as String] = true
            self.query[kSecMatchLimit as String] = kSecMatchLimitAll
        }else{
            self.query[kSecReturnData as String] = true
            self.query[kSecReturnAttributes as String] = true
            self.query[kSecMatchLimit as String] = kSecMatchLimitOne
        }
    }
    
    
    /// Update or Creat the item in the keychain
    public func storeInKeychain() -> Bool{
        
        guard let secureData = secureData else {return false}
        
        var attributesToUpdate: [String: Any] = [
            KeychainAttribute.secureValueData.key: secureData,
        ]
        
        for (key, value) in query where key == KeychainAttribute.label.key || key == KeychainAttribute.description.key || key == KeychainAttribute.comment.key {
            attributesToUpdate[key] = value
        }
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        if status == errSecItemNotFound {
            
            var addQuery = query
            addQuery[KeychainAttribute.secureValueData.key] = secureData
            
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            
            if status != errSecSuccess {
                logger.error("Error adding value to Keychain. Status: \(status)")
                return false
            }
        } else if status != errSecSuccess {
            logger.error("Error updating value in Keychain. Status: \(status)")
            return false
        }
        
        return true
    }
    
    public mutating func readFromKeychain() -> Bool{
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            logger.error("Error retrieving value from Keychain. Status: \(status)")
            return false
        }
        
        // Capture one or more KeychainItems
        let item:[String:Any]?
        if var multipleItems = result as? [[String: Any]]{
            // Sort by modification date
            multipleItems.sort { (dict1, dict2) -> Bool in
                if let modDate1 = dict1["mdat"] as? Date, let modDate2 = dict2["mdat"] as? Date {
                    return modDate1 > modDate2
                }
                return false
            }
            item = multipleItems.first(where: {
                let accountName = $0[KeychainAttribute.account.key] as? String
                return (accountName != nil) && (accountName != "")
            })
        }else if let singleItem = result as? [String: Any]{
            item = singleItem
        }else{
            logger.error("Error retrieving value from Keychain.")
            return false
        }
        
        if let secureData = item?[KeychainAttribute.secureValueData.key] as? Data{
            self.secureData = secureData
        }
        if let attributes = item?.filter({ ($0.key != KeychainAttribute.secureValueData.key) }) {
            self.attributes = attributes
        }
        
        return true
    }
    
    public func deleteFromKeychain() {
        let status = SecItemDelete(query as CFDictionary)
        
        if (status != errSecSuccess) && (status != errSecItemNotFound){
            let logger = Logger(subsystem: "be.oneclick.JVSwift", category:"KeyChainItem")
            logger.error("Error deletin value from Keychain. Status: \(status)")
        }
    }
    
}


// MARK: - KeychainItem Enum types
/// User friendly Enum representations of types used within KeychainItem
public enum KeychainPasswordType {
    case internetPassword
    case genericPassword
    
    var key:String {
        switch self{
            
        case .internetPassword:
            return kSecClassInternetPassword as String
        case .genericPassword:
            return kSecClassGenericPassword as String
        }
    }
}

public enum KeychainAttribute {
    
    case _class
    
    case server
    case port
    case name, label
    case kind, description
    case account
    case location, service
    case comments, comment
    
    case secureValueData
    
    
    var key: String {
        switch self {
        case ._class: return kSecClass as String
        case .server: return kSecAttrServer as String
        case .port: return kSecAttrPort as String
        case .name, .label: return kSecAttrLabel as String
        case .kind, .description: return kSecAttrDescription as String
        case .account: return kSecAttrAccount as String
        case .location, .service: return kSecAttrService as String
        case .comments, .comment: return kSecAttrComment as String
        case .secureValueData: return kSecValueData as String
        }
    }
}
