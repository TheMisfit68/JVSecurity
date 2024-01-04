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
	
	var itemClass: KeyChainItemClass
	
	// Attributes with enum keys that correspond to the keychain-application fields
	var attributes: [KeychainAttribute: Any] = [:]{
		didSet{
			// Copy the attributes to the query but with a String-type key
			self.query = Dictionary(uniqueKeysWithValues: attributes.map { ($0.key.queryKey, $0.value) })
		}
		
	}
	
	// Query with String keys that correspond to the native keychainItem attributes
	private var query: [String: Any] = [:]
	
	
	// Mirror the secureValue with the secureData and vice versa
	public var secureValue: String? = nil {
		didSet {
			// Prevent an infinite loop by checking if the value has changed
			guard secureValue != oldValue else { return }
			
			// Update the _secureData property
			secureData = secureValue?.data(using: .utf8)
		}
	}
	
	private var secureData: Data? = nil {
		didSet {
			// Prevent an infinite loop by checking if the value has changed
			guard secureData != oldValue else { return }
			
			// Update the secureValue property
			secureValue = String(data: secureData!, encoding: .utf8)
		}
	}
	private let logger = Logger(subsystem: "be.oneclick.JVSwift", category:"KeyChainItem")
	
	
	/// This inintializer will fail if the right combination for the type of KeyChainItem was not provided
	/// - Parameters: The type and attributes of the KeyChainItem
	public init?(type itemClass:KeyChainItemClass, attributes: [KeychainAttribute: Any]) {
		
		// Set the main attribute
		self.itemClass = itemClass
		self.attributes = attributes
		self.attributes[._class] = itemClass
		
		// Account is often a required attribute to work with a KeychainItem
		// but by setting the account parameter to "?" or ""
		// will provide us with an option to retreive the accountname based on a name
		if let accountName = attributes[.account] as? String, (accountName == "?" || accountName == ""){
			
			// To retrieve an accountName, typically a label is required.
			guard attributes[.name] != nil else { return nil }
			self.attributes.removeValue(forKey: .account)
			
			self.query[kSecReturnData as String] = false
			self.query[kSecReturnAttributes as String] = true
			self.query[kSecMatchLimit as String] = kSecMatchLimitAll
			
		}else{
			
			// Validate required attributes based on item class
			switch self.itemClass {
					
				case .genericPassword, .token:
					guard attributes[.account] != nil && attributes[.location] != nil else { return nil }
					
				case .internetPassword, .serverCredentials:
					guard attributes[.account] != nil && attributes[.server] != nil  else { return nil }
					
				case .certificate:
					// For a certificate, typically a label or some identifying attribute is required.
					// Modify as per your specific use case.
					guard attributes[.name] != nil else { return nil }
					
				case .key:
					// For keys, an application label or a general label is usually important.
					// Modify as per your specific use case.
					guard attributes[.name] != nil else { return nil }
					
				case .identity:
					// Identities are a combination of a certificate and a private key.
					// Exact requirements can vary, but typically include a label or an identifier.
					// Modify as per your specific use case.
					guard attributes[.name] != nil else { return nil }
			}
			
			self.query[kSecReturnData as String] = true
			self.query[kSecReturnAttributes as String] = true
			self.query[kSecMatchLimit as String] = kSecMatchLimitOne
			
		}
		
		
	}
	
	/// Update or Create the item in the keychain
	public func storeInKeychain() -> Bool{
		
		guard let secureData = secureData else {return false}
		
		var attributesToUpdate: [String: Any] = [
			KeychainAttribute.secureValueData.queryKey: secureData,
		]
		
		for (key, value) in query where key == KeychainAttribute.name.queryKey || key == KeychainAttribute.kind.queryKey || key == KeychainAttribute.comments.queryKey {
			attributesToUpdate[key] = value
		}
		
		let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
		
		if status == errSecItemNotFound {
			
			var addQuery = query
			addQuery[KeychainAttribute.secureValueData.queryKey] = secureData
			
			let status = SecItemAdd(addQuery as CFDictionary, nil)
			
			if status != errSecSuccess {
				logger.error("Error adding value to Keychain. Status: \(status.description)")
				return false
			}
		} else if status != errSecSuccess {
			logger.error("Error updating value in Keychain. Status: \(status.description)")
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
				let accountName = $0[KeychainAttribute.account.queryKey] as? String
				return (accountName != nil) && (accountName != "")
			})
		}else if let singleItem = result as? [String: Any]{
			item = singleItem
		}else{
			logger.error("Error retrieving value from Keychain.")
			return false
		}
		
		if let secureData = item?[KeychainAttribute.secureValueData.queryKey] as? Data{
			self.secureData = secureData
		}
		if let attributesOnly = item?.filter({ ($0.key != KeychainAttribute.secureValueData.queryKey) }) {
			self.attributes = Dictionary(uniqueKeysWithValues: attributesOnly.map { (KeychainAttribute(queryKey:$0.key)!, $0.value) })
		}
		
		return true
	}
	
	public func deleteFromKeychain() {
		let status = SecItemDelete(query as CFDictionary)
		
		if (status != errSecSuccess) && (status != errSecItemNotFound){
			let logger = Logger(subsystem: "be.oneclick.JVSwift", category:"KeyChainItem")
			logger.error("Error deleting value from Keychain. Status: \(status)")
		}
	}
	
}

// MARK: - KeychainItem Enum types

/// User friendly Enum representations of types used within KeychainItem
public enum KeyChainItemClass{
	
	/// Generic Password: Used for generic passwords.
	case genericPassword
	
	/// Internet Password: Used for passwords associated with an internet server.
	case internetPassword
	
	/// Certificates: Used for certificate items.
	case certificate
	
	/// Keys: Used for cryptographic keys.
	case key
	
	/// Identities: Combines a private key and a certificate.
	case identity
	
	/// Token: Alias for `genericPassword`, used for storing tokens like authentication tokens.
	case token
	
	/// ServerCredentials: Alias for `internetPassword`, used for storing server credentials.
	case serverCredentials
	
	var key: String {
		switch self {
			case .genericPassword, .token:
				return kSecClassGenericPassword as String
			case .internetPassword, .serverCredentials:
				return kSecClassInternetPassword as String
			case .certificate:
				return kSecClassCertificate as String
			case .key:
				return kSecClassKey as String
			case .identity:
				return kSecClassIdentity as String
		}
	}
}

public enum KeychainAttribute {
	
	case _class
	case server
	case port
	case name
	case kind
	case account
	case location
	case comments
	
	case secureValueData
	
	init?(queryKey: String){
		let cfStringKey = queryKey as CFString
		switch cfStringKey {
			case kSecClass: self = ._class
			case kSecAttrServer: self = .server
			case kSecAttrPort: self = .port
			case kSecAttrLabel: self = .name
			case kSecAttrDescription: self = .kind
			case kSecAttrAccount: self = .account
			case kSecAttrService: self = .location
			case kSecAttrComment: self = .comments
			case kSecValueData: self = .secureValueData
			default: return nil
		}
	}
	
	var queryKey: String {
		switch self {
			case ._class: return kSecClass as String
			case .server: return kSecAttrServer as String
			case .port: return kSecAttrPort as String
			case .name: return kSecAttrLabel as String
			case .kind: return kSecAttrDescription as String
			case .account: return kSecAttrAccount as String
			case .location: return kSecAttrService as String
			case .comments: return kSecAttrComment as String
			case .secureValueData: return kSecValueData as String
		}
	}

}

