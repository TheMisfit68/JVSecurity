// JVServerCredentialsView.swift
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

import SwiftUI
import JVUI

/// A View to enter a server and its port and the usercredentials associated with it
/// The view will notifify any subscribers of any changes made
/// - parameters:keyChainItemName: The name to store all information under in the KeyChain
/// - parameters:hostName: The hostName to store
/// - parameters:portNumber: The portNumber to store
/// - Parameters:userName: The userName to store
/// - Parameters:password: The password to store
/// - Parameters:onCommitMethod: A method to be called when the user commits
/// - Parameters: notificationKey: The key that is used to notify the subscribers through the NotificationCenter
public struct ServerCredentialsView: View, SettingsView, Securable {
	
	private let keyChainItemName:String

	@State private var hostName: String
	@State private var portNumber: Int?
	@State private var userName: String
	@State private var password: String
	
	public let notificationKey: String
	
	// An explicit public initializer is required to make the view available for other modules
	public init(keyChainItemName:String, hostName: String, portNumber: Int?, userName: String, password: String, notificationKey: String) {
		self.keyChainItemName = keyChainItemName
		self._hostName = State(initialValue: hostName)
		self._portNumber = State(initialValue: portNumber)
		self._userName = State(initialValue: userName)
		self._password = State(initialValue: password)
		self.notificationKey = notificationKey
	}
	
	
	public var body: some View {
		
		Form {
			ServerCredentialsSection(hostName: $hostName, portNumber: $portNumber,  
									 onCommitMethod: storeServerCredentials, notificationKey: self.notificationKey)
			UserCredentialsSection(userName: $userName, password: $password,
								   onCommitMethod: storeServerCredentials, notificationKey: self.notificationKey)
		}
		.padding(20)
		.onAppear {
			loadServerCredentials()
		}
	}
	
	private func loadServerCredentials() {
		
		if let serverCredentials = serverCredentialsFromKeyChain(name: self.hostName, location: ""){
			self.hostName = serverCredentials.server
			self.portNumber = serverCredentials.port
			self.userName = serverCredentials.account
			self.password = serverCredentials.password
		}
		
	}
	
	private func storeServerCredentials(){
		
		_ = storeServerCredentialsInKeyChain(name: self.hostName, serverAndPort: (self.hostName, self.portNumber), account: self.userName, location: "", password: self.password)
		
	}
	
}

// MARK: - Preview
#Preview {
	ServerCredentialsView(
		keyChainItemName: "PreviewOfServer",
		hostName: "127.0.0.1",
		portNumber: 80,
		userName: "myUserName",
		password: "myPassword",
		notificationKey: "ServerCredentialsDidChange")
}
