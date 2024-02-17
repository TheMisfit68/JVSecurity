//
//  JVSecurable.swift
//
//
//  Created by Jan Verrept on 03/10/2021.
//

import Foundation

public protocol Securable{
	
	// MARK: - Convenience write methods
	func storeUserCredentialsInKeyChain(name:String, location:String, account:String, password:String, extraInfo:[KeychainAttribute:Any]?) -> Bool
	func storeServerCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), location:String, account:String,  password:String, extraInfo:[KeychainAttribute:Any]?) -> Bool
	func storeInternetCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), location:String, account:String,  password:String, extraInfo:[KeychainAttribute:Any]?) -> Bool
	func storeTokenInKeyChain(name:String, location:String, account:String, token:String, extraInfo:[KeychainAttribute:Any]?) -> Bool
	
	// MARK: - Convenience read methods
	func userCredentialsFromKeyChain(name:String, location:String) -> (account:String, password:String)?
	func serverCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?
	func internetCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?
	func tokenFromKeyChain(name:String, location:String) -> String?
	
}


public extension Securable{
	
	// MARK: - Convenience write methods
	func storeUserCredentialsInKeyChain(name:String, location:String, account:String,  password:String, extraInfo:[KeychainAttribute:Any]? = nil) -> Bool{
		
		if let genericPasswordKeychainItem = KeyChainItem(type: .genericPassword, name: name, location: location, account:account, optionalAttributes:extraInfo){
			genericPasswordKeychainItem.secureValue = password
			return genericPasswordKeychainItem.storeInKeychain()
			
		}
		
		return false
	}
	
	func storeServerCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), location:String, account:String,  password:String, extraInfo:[KeychainAttribute:Any]? = nil) -> Bool{
		
		// Thise method is an alias for storeInternetCredentialsInKeyChain
		return storeInternetCredentialsInKeyChain(name: name, serverAndPort: serverAndPort, location: location, account: account, password: password, extraInfo: extraInfo)
		
	}
	
	func storeInternetCredentialsInKeyChain(name:String, serverAndPort:(String, Int?), location:String, account:String,  password:String, extraInfo:[KeychainAttribute:Any]? = nil) -> Bool{
		
		if let internetPasswordKeychainItem = KeyChainItem(type: .internetPassword, name: name, server:serverAndPort.0, location: location, account:account, optionalAttributes:extraInfo){
			internetPasswordKeychainItem.attributes[.port] = serverAndPort.1
			internetPasswordKeychainItem.secureValue = password
			return internetPasswordKeychainItem.storeInKeychain()
			
		}
		
		return false
	}
	
	func storeTokenInKeyChain(name:String, location:String, account:String,  token:String, extraInfo:[KeychainAttribute:Any]? = nil) -> Bool{
		
		if let tokenKeychainItem = KeyChainItem(type: .token, name: name, location: location, account:account, optionalAttributes:extraInfo){
			
			tokenKeychainItem.secureValue = token
			return tokenKeychainItem.storeInKeychain()
			
		}
		return false
	}
	
	
	// MARK: - Convenience read methods
	
	func userCredentialsFromKeyChain(name:String, location:String) -> (account:String, password:String)?{
		
		if let genericPassWordKeychainItem = KeyChainItem(type: .internetPassword, name: name, location: location){
			
			_ = genericPassWordKeychainItem.readFromKeychain()
					
			let account = genericPassWordKeychainItem.attributes[.account] as? String

			if let account:String = account, let password:String = genericPassWordKeychainItem.secureValue{
				return (account, password)
			}
			
		}
		
		return nil
	}
	
	func serverCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?{
		
		// This method is an alias for internetCredentialsInKeyChain
		return internetCredentialsFromKeyChain(name:name, location:location)
		
	}
		
	func internetCredentialsFromKeyChain(name:String, location:String) -> (server:String, port:Int?, account:String, password:String)?{
		
		if let internetCredentialsKeyChainItem = KeyChainItem(type: .internetPassword, name: name, location: location){
			
			_ = internetCredentialsKeyChainItem.readFromKeychain()
			
			let server = internetCredentialsKeyChainItem.attributes[.server] as? String
			let port = internetCredentialsKeyChainItem.attributes[.port] as? Int
			let account = internetCredentialsKeyChainItem.attributes[.account] as? String
			
			if let server:String = server, let account:String = account, let password:String = internetCredentialsKeyChainItem.secureValue{
				return (server:server, port:port, account:account, password:password)
			}
		}
		
		return nil
	}
	
	func tokenFromKeyChain(name:String, location:String) -> String?{
		
		if let tokenKeychainItem = KeyChainItem(type: .token, name: name, location: location){
			
			_ = tokenKeychainItem.readFromKeychain()
			
			if let token:String = tokenKeychainItem.secureValue{
				return token
			}
		}
		
		return nil
	}
	
	
}
