
// JVUserCredentialsSection.swift
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

import SwiftUI
import JVUI

/// A Section-subview to enter a server and its port
/// Meant to be used as part of a Form
/// The view will notify any subscribers of any changes made
/// - parameters: accountName: The accountName to store (often an @state variable of the superview)
/// - parameters: password: The password to store (often an @state variable of the superview)
/// - Parameters: onCommitMethod: A method to be called when the user commits (often a callback method defined in the superview)
/// - Parameters: notificationKey: The key that is used to notify the subscribers through the NotificationCenter
public struct UserCredentialsSection: View, SettingsView, Securable {
	
	@Binding private var userName: String
	@Binding private var password: String
	@State private var passwordButtonIsPressed: Bool = false
	
	private let onCommitMethod: () -> Void
	public let notificationKey: String
	
	// An explicit public initializer is required to make the view available for other modules
	public init(userName: Binding<String>, password: Binding<String>, onCommitMethod: @escaping () -> Void, notificationKey: String) {
		self._userName = userName
		self._password = password
		self.onCommitMethod = onCommitMethod
		self.notificationKey = notificationKey
	}
	
	public var body: some View {
		Section(header: Label(String(localized: "Account info", bundle: .module), systemImage: "person.fill")) {
			HStack {
				Text(String(localized: "Username", bundle: .module))
					.frame(width: 100, alignment: .trailing)
				TextField("", text: $userName,
						  onCommit: {
					onCommitMethod()
					postNotification()
				}
				)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			HStack {
				Text(String(localized: "Password", bundle: .module))
					.frame(width: 100, alignment: .trailing)
				Group {
					if passwordButtonIsPressed {
						TextField("", text: $password,
								  onCommit: {
							onCommitMethod()
							postNotification()
						}
						)
					} else {
						SecureField("", text: $password,
									onCommit: {
							onCommitMethod()
							postNotification()
						}
						)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				
				Button(action: {}) {
					Image(systemName: passwordButtonIsPressed ? "eye.fill" : "eye.slash.fill")
				}
				.buttonStyle(PlainButtonStyle())
				.padding(.leading, 5)
				.onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
					passwordButtonIsPressed = pressing
				}, perform: {})
			}
		}
		.padding(.vertical, 5)}
}

// Preview using #Preview macro
#Preview {
	UserCredentialsSection(
		userName: Binding.constant("myUserName"),
		password: Binding.constant("myPassWord"),
		onCommitMethod: {},
		notificationKey: "UserCredentialsDidChange")
}
