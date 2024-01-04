//
//  JVSecurable.swift
//
//
//  Created by Jan Verrept on 03/10/2021.
//

import Foundation

public protocol Securable{
	
	// MARK: - Convenience write methods
	func storeUserCredentialsInKeyChain(name:String, account:String, location:String, password:String) -> Bool
	func storeServerCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), account:String, location:String,  password:String) -> Bool
	func storeInternetCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), account:String, location:String,  password:String) -> Bool
	
	// MARK: - Convenience read methods
	func userCredentialsFromKeyChain(name:String, location:String) -> (account:String, password:String)?
	func serverCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?
	func internetCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?
	
	// MARK: - Generic write methods
	func storeSecureValueInKeyChain(type:KeyChainItemClass ,withAttributes attributes:[KeychainAttribute:Any], secureValue:String) -> Bool
	// MARK: - Generic read methods
	func secureValueFromKeyChain(type:KeyChainItemClass ,withAttributes attributes:[KeychainAttribute:Any]) -> String?
	func credentialsFromKeyChain(type:KeyChainItemClass, name:String, location:String) -> (account:String, password:String)?
	func attributesFromKeyChain(type:KeyChainItemClass ,withAttributes attributes:[KeychainAttribute:Any], attributeType:KeychainAttribute?) -> Any?
	
}


public extension Securable{
	
	// MARK: - Convenience write methods
	
	func storeUserCredentialsInKeyChain(name:String, account:String, location:String,  password:String) -> Bool{
		
		let attributes:[KeychainAttribute:Any] = [.name : name, .account : account, .location : location]
		return storeSecureValueInKeyChain(type: .genericPassword, withAttributes: attributes, secureValue: password)
		
	}
	
	func storeServerCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), account:String, location:String,  password:String) -> Bool{
		
		let attributes:[KeychainAttribute:Any] = [.name : name, .server: serverAndPort.0, .port: serverAndPort.1 ?? "", .account : account, .location : location]
		return storeSecureValueInKeyChain(type: .serverCredentials, withAttributes: attributes, secureValue: password)
		
	}
	
	func storeInternetCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), account:String, location:String,  password:String) -> Bool{
		
		let attributes:[KeychainAttribute:Any] = [.name : name, .server: serverAndPort.0, .port: serverAndPort.1 ?? "", .account : account, .location : location]
		return storeSecureValueInKeyChain(type: .internetPassword, withAttributes: attributes, secureValue: password)
		
	}
	
	// MARK: - Convenience read methods
	
	func userCredentialsFromKeyChain(name:String, location:String) -> (account:String, password:String)?{
		return credentialsFromKeyChain(type: .genericPassword, name: name, location: location)
	}
	
	func serverCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?{
		let credentials = credentialsFromKeyChain(type: .serverCredentials, name: name, location: location)
		let attributes = attributesFromKeyChain(type: .serverCredentials, withAttributes: [.name : name, .location : location]) as? [KeychainAttribute:Any]
		if let server = attributes?[.server] as? String, let account = credentials?.account, let password = credentials?.password{
			let port:Int? = attributes?[.port] as? Int
			return (server, port, account, password)
		}else{
			return nil
		}
	}
	
	func internetCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?{
		let credentials = credentialsFromKeyChain(type: .internetPassword, name: name, location: location)
		let attributes = attributesFromKeyChain(type: .internetPassword, withAttributes: [.name : name, .location : location]) as? [KeychainAttribute:Any]
		if let server = attributes?[.server] as? String, let account = credentials?.account, let password = credentials?.password{
			let port:Int? = attributes?[.port] as? Int
			return (server, port, account, password)
		}else{
			return nil
		}
	}
	
	// MARK: - Generic write methods
	
	func storeSecureValueInKeyChain(type:KeyChainItemClass ,withAttributes attributes:[KeychainAttribute:Any], secureValue:String) -> Bool{
		
		var genericItem = KeyChainItem(type:type,attributes: attributes)
		guard genericItem != nil else {return false}
		
		genericItem?.attributes = attributes
		genericItem!.secureValue = secureValue
		return genericItem!.storeInKeychain()
	}
	
	// MARK: - Generic read methods
	
	func secureValueFromKeyChain(type:KeyChainItemClass ,withAttributes attributes:[KeychainAttribute:Any]) -> String?{
		
		var genericItem = KeyChainItem(type:type,attributes: attributes)
		guard genericItem != nil else {return ""}
		
		_ = genericItem!.readFromKeychain()
		return genericItem!.secureValue
	}
	
	func credentialsFromKeyChain(type:KeyChainItemClass, name:String, location:String) -> (account:String, password:String)?{
		
		var attributes:[KeychainAttribute:Any]
		attributes = [.name : name, .account : "?"]
		
		// Get the userName for this key first
		if let storedUserName = attributesFromKeyChain(type: type, withAttributes: attributes, attributeType: .account) as? String{
			// Then get the password for this key
			attributes = [.name : name, .account : storedUserName, .location : location]
			// and its associated password
			if let storedpassword = secureValueFromKeyChain(type: type, withAttributes: attributes) {
				return (account:storedUserName, password:storedpassword)
			}else{
				return nil
			}
		}else{
			return nil
		}
	}
	
	func attributesFromKeyChain(type:KeyChainItemClass ,withAttributes attributes:[KeychainAttribute:Any], attributeType:KeychainAttribute? = nil) -> Any?{
		
		var genericItem = KeyChainItem(type:type,attributes: attributes)
		guard genericItem != nil else {return ""}
		
		_ = genericItem!.readFromKeychain()
		let allAttributes = genericItem!.attributes
		
		if let attributeKey = attributeType{
			return allAttributes[attributeKey]
		}else{
			return allAttributes
		}
		
	}
	
}
