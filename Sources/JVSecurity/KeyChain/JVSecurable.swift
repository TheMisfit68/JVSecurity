//
//  JVSecurable.swift
//
//
//  Created by Jan Verrept on 03/10/2021.
//

import Foundation

public protocol Securable{
        
    func storePasswordInKeyChain(serverAndPort:(String, Int?)?, name:String, account:String, location:String, passWord:String) -> Bool
    func passwordFromKeyChain(serverAndPort:(String, Int?)?, name:String, account:String, location:String) -> String?
    func accountFromKeyChain(serverAndPort:(String, Int?)?, name:String, location:String) -> String?
    
    func storeValueInKeyChain(serverAndPort: (String, Int?)?, name:String?, kind: String?, account: String, location: String, comments: String?, secureValue:String) -> Bool
    func valueFromKeyChain(serverAndPort: (String, Int?)?, name:String?, kind: String?, account: String, location: String, comments: String?) -> String?

}


public extension Securable{
    
    // MARK: - Passwords and accounts
    
    func storePasswordInKeyChain(serverAndPort:(String, Int?)? = nil, name:String, account:String, location:String, passWord:String) -> Bool{
        
        return storeValueInKeyChain(serverAndPort: serverAndPort, name: name, kind: "Application Password", account: account, location: location, secureValue: passWord)
    }
    
    func passwordFromKeyChain(serverAndPort:(String, Int?)? = nil, name:String, account:String, location:String) -> String?{
        
        return valueFromKeyChain(serverAndPort: serverAndPort, name: name, kind:"Application Password", account: account, location: location)
    }
    
    func accountFromKeyChain(serverAndPort:(String, Int?)? = nil, name:String, location:String) -> String?{
        
        var accountItem = KeyChainItem(serverAndPort:serverAndPort, name:name, account: "", location: location)
        _ = accountItem.readFromKeychain()
        return accountItem.attributes?[KeychainAttribute.account.key] as? String
        
    }
    
    // MARK: - Complete KeyChainItems

    func storeValueInKeyChain(serverAndPort: (String, Int?)? = nil, name:String? = nil, kind: String? = nil, account: String, location: String, comments: String? = nil, secureValue:String) -> Bool{
        
        var genericItem = KeyChainItem(serverAndPort:serverAndPort, name:name, kind:kind, account: account, location:location)
        genericItem.secureValue = secureValue
        
        return genericItem.storeInKeychain()
    }
    
    func valueFromKeyChain(serverAndPort: (String, Int?)? = nil, name:String? = nil, kind: String? = nil, account: String, location: String, comments: String? = nil) -> String?{
        
        var genericItem = KeyChainItem(serverAndPort:serverAndPort, name:name, kind:kind, account: account, location: location)
        _ = genericItem.readFromKeychain()
        return genericItem.secureValue
        
    }


    
}
