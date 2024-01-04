// JVServerCredentialsSection.swift
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

import SwiftUI
import JVUI

/// A subview to enter a server and its port
/// The view will notify any subscribers of any changes made
/// - parameters: hostName: The hostName to store (often an @state variable of the superview)
/// - parameters: portNumber: The portNumber to store (often an @state variable of the superview)
///   when the portnumber is set to nil, it will not be shown!
/// - Parameters: onCommitMethod: A method to be called when the user commits (often a callback method defined in the superview)
/// - Parameters: notificationKey: The key that is used to notify the subscribers through the NotificationCenter
public struct ServerCredentialsSection: View, SettingsView, Securable {
	
	@Binding private var hostName: String
	@Binding private var portNumber: Int?
	
	private let onCommitMethod: () -> Void
	public let notificationKey: String
	
	// An explicit public initializer is required to make the view available for other modules
	public init(hostName: Binding<String>, portNumber: Binding<Int?>, onCommitMethod: @escaping () -> Void, notificationKey: String) {
		self._hostName = hostName
		self._portNumber = portNumber
		self.onCommitMethod = onCommitMethod
		self.notificationKey = notificationKey
	}
	
	public var body: some View {
		
		Section(header: Label("Server Settings", systemImage: "server.rack")) {
			
			HStack {
				Text(String(localized: "Server", bundle: .module))
					.frame(width: 100, alignment: .trailing)
				TextField("", text: Binding(
					get: { String(self.hostName) },
					set: { newValue in
						let digitsAndDotsOnly = newValue.filter { "0123456789.".contains($0) }
						self.hostName = digitsAndDotsOnly
					}
				),
						  onCommit: { onCommitMethod(); postNotification() }
				)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			if self.portNumber != nil {
				HStack {
					Text(String(localized: "Port Number", bundle: .module))
						.frame(width: 100, alignment: .trailing)
					TextField("", text:Binding(
						get: { String(self.portNumber!)  },
						set: { newValue in
							let digitsOnly = newValue.filter { "0123456789".contains($0) }
							if digitsOnly != "", let intValue = Int(digitsOnly) {
								self.portNumber = intValue
							} else {
								self.portNumber = 0
							}
						}
					), onCommit: { onCommitMethod(); postNotification() })
					.frame(maxWidth: .infinity, alignment: .leading)
					.textFieldStyle(RoundedBorderTextFieldStyle())
				}
			}
			
		}
	}
}


#Preview {
	ServerCredentialsSection(
		hostName: Binding.constant("127.0.0.1"),
		portNumber: Binding.constant(80),
		onCommitMethod: {},
		notificationKey: "ServerSettingsDidChange")
}

