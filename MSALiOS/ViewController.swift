//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

import UIKit
import MSAL

/// 😃 A View Controller that will respond to the events of the Storyboard.

class ViewController: UIViewController, UITextFieldDelegate, URLSessionDelegate {

    var accessToken = String()
    var applicationContext : MSALPublicClientApplication?
    var webViewParamaters : MSALWebviewParameters?

    @IBOutlet var loggingText: UITextView!
    @IBOutlet var tokenInteractivelyButton: UIButton!
    @IBOutlet var tokenSilentlyButton: UIButton!
    @IBOutlet var signOutButton: UIButton!
    @IBOutlet var callAPIButton: UIButton!
    @IBOutlet var usernameLabel: UILabel!
    
    var currentAccount: MSALAccount?
    
    var currentDeviceMode: MSALDeviceMode?

    /**
        Setup public client application in viewDidLoad
    */

    override func viewDidLoad() {

        super.viewDidLoad()
        
        do {
            try self.initMSAL()
        } catch let error {
            self.updateLogging(text: "Unable to create Application Context \(error)")
        }
        
        self.refreshDeviceMode()
        self.platformViewDidLoadSetup()
    }
    
    func platformViewDidLoadSetup() {
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appCameToForeGround(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateCurrentAccount(account: nil)
        
        self.loadCurrentAccount { [weak self] account in
            if let self = self, let account = account {
                self.acquireTokenSilently(account)
            } else {
                self?.updateLogging(text: "")
            }
        }
    }
    
    @objc func appCameToForeGround(notification: Notification) {
        self.loadCurrentAccount()
    }
}


// MARK: Initialization

extension ViewController {
    
    /**
     
     Initialize a MSALPublicClientApplication with a given clientID and authority
     
     - clientId:            The clientID of your application, you should get this from the app portal.
     - redirectUri:         A redirect URI of your application, you should get this from the app portal.
     If nil, MSAL will create one by default. i.e./ msauth.<bundleID>://auth
     - authority:           A URL indicating a directory that MSAL can use to obtain tokens. In Microsoft Entra
     it is of the form https://<tenantSubdomain>.ciamlogin.com, where <tenantSubdomain> is a
     identifier within the directory itself (e.g. a domain associated to the tenant, such as contoso.ciamlogin.com)
     - error                The error that occurred creating the application object, if any, if you're
     not interested in the specific error pass in nil.
     */
    func initMSAL() throws {
        
        guard let authorityURL = URL(string: Configuration.kAuthority) else {
            self.updateLogging(text: "Unable to create authority URL")
            return
        }
        
        let authority = try MSALCIAMAuthority(url: authorityURL)
        
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: Configuration.kClientID,
                                                                  redirectUri: Configuration.kRedirectUri,
                                                                  authority: authority)
        self.applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
        self.initWebViewParams()
    }
    
    func initWebViewParams() {
        self.webViewParamaters = MSALWebviewParameters(authPresentationViewController: self)
    }
}

// MARK: Acquiring and using token

extension ViewController {
    
    /**
     This will invoke the authorization flow.
     */
    
    @IBAction func acquireTokenInteractively() {
        guard let applicationContext = self.applicationContext else { return }
        guard let webViewParameters = self.webViewParamaters else { return }
        
        updateLogging(text: "Acquiring token interactively...")

        let parameters = MSALInteractiveTokenParameters(scopes: Configuration.kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        
        applicationContext.acquireToken(with: parameters) { (result, error) in
            
            if let error = error {
                
                self.updateLogging(text: "Could not acquire token: \(error)")
                return
            }
            
            guard let result = result else {
                
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "Access token is \(self.accessToken)")
            self.updateCurrentAccount(account: result.account)
        }
    }
    
    @IBAction func acquireTokenSilently() {
        self.loadCurrentAccount { (account) in
            
            guard let currentAccount = account else {
                
                self.updateLogging(text: "No token found, try to acquire a token interactively first")
                return
            }
            
            self.acquireTokenSilently(currentAccount)
        }
    }
    
    @IBAction func callProtectedAPI(_ sender: UIButton) {
        getContentWithToken()
    }
    
    func acquireTokenSilently(_ account : MSALAccount) {
        guard let applicationContext = self.applicationContext else { return }
        
        /**
         
         Acquire a token for an existing account silently
         
         - forScopes:           Permissions you want included in the access token received
         in the result in the completionBlock. Not all scopes are
         guaranteed to be included in the access token returned.
         - account:             An account object that we retrieved from the application object before that the
         authentication flow will be locked down to.
         - completionBlock:     The completion block that will be called when the authentication
         flow completes, or encounters an error.
         */
        
        updateLogging(text: "Acquiring token silently...")
        
        let parameters = MSALSilentTokenParameters(scopes: Configuration.kScopes, account: account)
        
        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            
            if let error = error {
                
                let nsError = error as NSError
                
                // interactionRequired means we need to ask the user to sign-in. This usually happens
                // when the user's Refresh Token is expired or if the user has changed their password
                // among other possible reasons.
                
                if (nsError.domain == MSALErrorDomain) {
                    
                    if (nsError.code == MSALError.interactionRequired.rawValue) {
                        
                        DispatchQueue.main.async {
                            self.acquireTokenInteractively()
                        }
                        return
                    }
                }
                
                self.updateLogging(text: "Could not acquire token silently: \(error)")
                return
            }
            
            guard let result = result else {
                
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "Refreshed Access token is \(self.accessToken)")
            self.updateSignOutButton(enabled: true)
        }
    }
    
    /**
     This will invoke the call to the Microsoft Graph API. It uses the
     built in URLSession to create a connection.
     */
    
    func getContentWithToken() {
        // Specify the API endpoint
        guard let url = URL(string: Configuration.kProtectedAPIEndpoint) else {
            let errorMessage = "Invalid API url"
            print(errorMessage)
            updateLogging(text: errorMessage)
            return
        }
        var request = URLRequest(url: url)
        
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        
        self.updateLogging(text: "Performing request...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                self.updateLogging(text: "Couldn't get API result: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                print("Unsuccessful response found when accessing the API")
                return
            }
            
            guard let data = data, let result = try? JSONSerialization.jsonObject(with: data, options: []) else {
                self.updateLogging(text: "Couldn't deserialize result JSON")
                return
            }
            
            self.updateLogging(text: """
                                Accessed API successfully using access token.
                                HTTP response code: \(httpResponse.statusCode)
                                HTTP response body: \(result)
                                """)
            
            }.resume()
    }

}


// MARK: Get account and removing cache

extension ViewController {
    
    typealias AccountCompletion = (MSALAccount?) -> Void

    func loadCurrentAccount(completion: AccountCompletion? = nil) {
        
        guard let applicationContext = self.applicationContext else { return }
        
        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
                
        // Note that this sample showcases an app that signs in a single account at a time
        applicationContext.getCurrentAccount(with: msalParameters, completionBlock: { (currentAccount, previousAccount, error) in
            
            if let error = error {
                self.updateLogging(text: "Couldn't query current account with error: \(error)")
                return
            }
            
            if let currentAccount = currentAccount {
                
                self.updateCurrentAccount(account: currentAccount)
                self.acquireTokenSilently(currentAccount)
                
                if let completion = completion {
                    completion(self.currentAccount)
                }
                
                return
            }
            
            // If testing with Microsoft's shared device mode, see the account that has been signed out from another app. More details here:
            // https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-ios-shared-devices
            if let previousAccount = previousAccount {
                
                self.updateLogging(text: "The account with username \(String(describing: previousAccount.username)) has been signed out.")
                
            } else {
                
                self.updateLogging(text: "")
            }
            
            self.accessToken = ""
            self.updateCurrentAccount(account: nil)
            
            if let completion = completion {
                completion(nil)
            }
        })
    }
    
    /**
     This action will invoke the remove account APIs to clear the token cache
     to sign out a user from this application.
     */
    @IBAction func signOut(_ sender: UIButton) {
        
        guard let applicationContext = self.applicationContext else { return }
        
        guard let account = self.currentAccount else { return }
        
        guard let webViewParamaters = self.webViewParamaters else { return }
        
        updateLogging(text: "Signing out...")
        
        do {
            
            /**
             Removes all tokens from the cache for this application for the provided account
             
             - account:    The account to remove from the cache
             */
            
            let signoutParameters = MSALSignoutParameters(webviewParameters: webViewParamaters)
            
            // If testing with Microsoft's shared device mode, trigger signout from browser. More details here:
            // https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-ios-shared-devices
            
            if (self.currentDeviceMode == .shared) {
                signoutParameters.signoutFromBrowser = true
            } else {
                signoutParameters.signoutFromBrowser = false
            }
            
            applicationContext.signout(with: account, signoutParameters: signoutParameters, completionBlock: {(success, error) in
                
                if let error = error {
                    self.updateLogging(text: "Couldn't sign out account with error: \(error)")
                    return
                }
                
                self.updateLogging(text: "Sign out completed successfully")
                self.accessToken = ""
                self.updateCurrentAccount(account: nil)
            })
            
        }
    }
}

// MARK: Shared Device Helpers

extension ViewController {
    
    func refreshDeviceMode() {
        self.applicationContext?.getDeviceInformation(with: nil, completionBlock: { (deviceInformation, error) in
            
            guard let deviceInfo = deviceInformation else {
                return
            }
            
            self.currentDeviceMode = deviceInfo.deviceMode
        })
    }
}

// MARK: UI Helpers

extension ViewController {
    
    func updateLogging(text : String) {
        
        if Thread.isMainThread {
            loggingText.text = text
        } else {
            DispatchQueue.main.async {
                self.loggingText.text = text
            }
        }
    }
    
    func updateSignOutButton(enabled : Bool) {
        if Thread.isMainThread {
            signOutButton.isEnabled = enabled
        } else {
            DispatchQueue.main.async {
                self.signOutButton.isEnabled = enabled
            }
        }
    }
    
    func updateAPIButton(enabled : Bool) {
        if Thread.isMainThread {
            callAPIButton.isEnabled = enabled
        } else {
            DispatchQueue.main.async {
                self.callAPIButton.isEnabled = enabled
            }
        }
    }
    
    func updateAccountLabel() {
        guard let currentAccount = self.currentAccount else {
            usernameLabel.text = "Signed out"
            return
        }
        
        usernameLabel.text = currentAccount.username
    }
    
    func updateCurrentAccount(account: MSALAccount?) {
        currentAccount = account
        updateAccountLabel()
        updateSignOutButton(enabled: account != nil)
        updateAPIButton(enabled: account != nil)
    }
}
