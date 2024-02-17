// KeyChainItem.swift
//
// Refactored by Jan Verrept and assisted by ChatGPT.
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

import Foundation
import Security
import OSLog

public class KeyChainItem {
	
	private let logger = Logger(subsystem: "be.oneclick.JVSecurity", category:"KeyChainItem")
	
	var attributes: [KeychainAttribute: Any] = [:]
	
	var identityKeys: [KeychainAttribute] = [._class, .name, .server, .location, .account]
	
	var identityAttributes: [KeychainAttribute: Any] {
		return attributes.filter { identityKeys.contains($0.key)}
	}
	
	var readAttributes: [KeychainAttribute: Any] {
		var readAttributes:[KeychainAttribute:Any] = [:]
		
		readAttributes[.returnData] = true
		readAttributes[.returnAttributes] = true
		readAttributes[.maxResults] = kSecMatchLimitOne
		
		readAttributes = identityAttributes.merging(readAttributes)  { dict1, dict2 in dict1 }
		return readAttributes
	}
	
	var addAttributes:[KeychainAttribute: Any] {
		
		let addAttributes:[KeychainAttribute:Any]  = identityAttributes.merging(updateAttributes)  { dict1, dict2 in dict1 }
		return addAttributes
	}
	
	var updateAttributes:[KeychainAttribute: Any] {
		
		let updateAttributes = attributes.filter{ !identityKeys.contains($0.key) }
		return updateAttributes
		
	}
	
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
	
	// Initializer
	public init?(type itemClass: KeyChainItemClass, name:String, server:String? = nil, location:String? = nil, account:String? = nil, optionalAttributes:[KeychainAttribute:Any]? = nil) {
		
		attributes[._class] = itemClass
		attributes[.name] = name
		if let server = server{
			attributes[.server] = server
		}
		if let location = location{
			attributes[.location] = location
		}
		if let account = account{
			attributes[.account] = account
		}
		let requiredAttribusValid = !name.isEmpty && ( ((server != nil) && !server!.isEmpty) || ((location != nil) && !location!.isEmpty) || ((account != nil) && !account!.isEmpty) )
		guard requiredAttribusValid else { return nil }
	}
	
	private func attributesDictionary(_ attributes: [KeychainAttribute: Any]) -> CFDictionary {
		let castedDictionary = attributes.reduce(into: [String: Any]()) { (result, attribute) in
			let stringKey: String = attribute.key.queryKey as String
			if let enumValue = attribute.value as? KeyChainItemClass{
				result[stringKey] = enumValue.queryKey
			}else{
				result[stringKey] = attribute.value
			}
		}
		return castedDictionary as CFDictionary
	}
	
	// Update or Create the item in the keychain
	public func storeInKeychain() -> Bool {
		
		guard let secureData = self.secureData else { return false }
		attributes[.secureValueData] = secureData
		
		let updateQuery = attributesDictionary(identityAttributes)
		let updateAttributes = attributesDictionary(self.updateAttributes)
		let status = SecItemUpdate(updateQuery, updateAttributes)
		
		if status == errSecItemNotFound {
			let addAttributes = attributesDictionary(self.addAttributes)
			let addStatus = SecItemAdd(addAttributes, nil)
			return handleKeychainStatus(addStatus)
		} else {
			return handleKeychainStatus(status)
		}
	}
	
	// Read from keychain
	public func readFromKeychain() -> Bool {
		var result: AnyObject?
		let query = attributesDictionary(readAttributes)
		
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		
		guard status == errSecSuccess else {
			_ = handleKeychainStatus(status)
			return false
		}
		
		if let item = result as? [String: Any] {
			for (key, value) in item {
				if let attribute = KeychainAttribute(queryKey: key as CFString) {
					if attribute == .secureValueData{
						secureData = value as? Data
					}else{
						attributes[attribute] = value
					}
				}
			}
			
			// At this point, keychainData is populated with the latest Keychain item attributes
			return true
		}
		
		return false
	}
	
	
	// Delete from keychain
	public func deleteFromKeychain() -> Bool {
		let deleteQuery = attributesDictionary(identityAttributes)
		let status = SecItemDelete(deleteQuery)
		return handleKeychainStatus(status)
	}
	
	// Handle keychain status
	private func handleKeychainStatus(_ status: OSStatus) -> Bool {
		if status != errSecSuccess {
			if let statusMessage = SecCopyErrorMessageString(status, nil) {
				logger.error("Keychain operation failed. Status: \(statusMessage)")
			}
			return false
		}
		return true
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
	
	/// Used to prefetch only the username before getting the associated password or other secure item
	case accountOnly
	
	init?(queryKey: CFString) {
		switch queryKey {
			case kSecClassGenericPassword: self = .genericPassword
			case kSecClassInternetPassword: self = .internetPassword
			case kSecClassCertificate: self = .certificate
			case kSecClassKey: self = .key
			case kSecClassIdentity: self = .identity
			default: return nil
		}
	}
	
	var queryKey: CFString {
		switch self {
			case .genericPassword, .token:
				return kSecClassGenericPassword
			case .internetPassword, .serverCredentials:
				return kSecClassInternetPassword
			case .certificate:
				return kSecClassCertificate
			case .key:
				return kSecClassKey
			case .identity:
				return kSecClassIdentity
			default:
				return "" as CFString
		}
	}
}

public enum KeychainAttribute{
	
	case _class
	case name
	case kind
	case account
	case location
	case comments
	case secureValueData
	
	case server
	case port
	case path
	case accessGroup
	
	case returnData
	case returnAttributes
	case maxResults
	case modificationDate
	
	init?(queryKey: CFString) {
		switch queryKey {
			case kSecClass: self = ._class
			case kSecAttrLabel: self = .name
			case kSecAttrDescription: self = .kind
			case kSecAttrAccount: self = .account
			case kSecAttrService: self = .location
			case kSecAttrComment: self = .comments
			case kSecValueData: self = .secureValueData
				
			case kSecAttrServer: self = .server
			case kSecAttrPort: self = .port
			case kSecAttrPath: self = .path
			case kSecAttrAccessGroup: self = .accessGroup
				
			case kSecReturnData: self = .returnData
			case kSecReturnAttributes: self = .returnAttributes
			case kSecMatchLimit: self = .maxResults
			case kSecAttrModificationDate: self = .modificationDate
			default:
				return nil
		}
	}
	var queryKey: CFString {
		switch self {
			case ._class: return kSecClass
			case .name: return kSecAttrLabel
			case .kind: return kSecAttrDescription
			case .account: return kSecAttrAccount
			case .location: return kSecAttrService
			case .comments: return kSecAttrComment
			case .secureValueData: return kSecValueData
				
			case .server: return kSecAttrServer
			case .port: return kSecAttrPort
			case .path: return kSecAttrPath
			case .accessGroup: return kSecAttrAccessGroup
				
			case .returnData: return kSecReturnData
			case .returnAttributes: return kSecReturnAttributes
			case .maxResults: return kSecMatchLimit
			case .modificationDate: return kSecAttrModificationDate
		}
	}
}
