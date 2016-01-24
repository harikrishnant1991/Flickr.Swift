//
//  JHFlickr.swift
//  Flickr
//
//  Created by Harikrishnan T on 24/01/16.
//  Copyright © 2016 FyrWeel Infolabz. All rights reserved.
//

import UIKit

protocol JHFlickrAuthenticationDelegate {
    /**
     The user authentication has completed successfully.
     */
    func authenticationComplete()
    
    /**
     The user authentication has failed.
     
     - parameter error: The error message due to which the authentication failed.
     */
    func authenticationFailed(error : String)
}

class JHFlickr: NSObject {
    
    // MARK: User Defaults and Keys
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    private let ACCESS_TOKEN_DEFAULTS_KEY = "ACCESS_TOKEN_DEFAULTS_KEY"
    private let ACCESS_SECRET_DEFAULTS_KEY = "ACCESS_SECRET_DEFAULTS_KEY"
    private let USER_NSID_DEFAULTS_KEY = "USER_NSID_DEFAULTS_KEY"
    
    private override init() {
        super.init()
    }
    
    // MARK: Static variables
    /**
     The singleton instance of the JHFlickr library. This instance is required to access the entire functionality of the library.
     */
    static let Session = JHFlickr()
    
    // MARK: Public Properties
    
    /**
    Delegate for handling OAuth flow of Flickr.
    */
    var oAuthDelegate : JHFlickrAuthenticationDelegate?
    
    /**
    The instance of JHFlickrOAuth that handles the OAuth flow of JHFlickr library.
    */
    var oAuth : JHFlickrOAuth?
    
    // MARK: Public methods
    /**
     Initialize the flickr session with consumer key and consumer secret obtained from developer console and redirect URL set in the developer console.
     
     - parameter consumerKey: The consumer key obtained when creating an app in Flickr developer console.
     - parameter consumerSecret: The consumer secret obtained when creating an app in Flickr developer console.
     - parameter redirectURL: The redirect URL set when the app is created in the Flickr developer console.
     */
    func initialize(consumerKey consumerKey : String, consumerSecret : String, redirectURL : NSURL, accessLevel : AccessLevel) {
        JHUtils.CONSUMER_KEY = consumerKey
        JHUtils.CONSUMER_SECRET = consumerSecret
        self.redirectURL = redirectURL
        self.accessLevel = accessLevel
    }
    
    /**
     Start the OAuth flow of flickr.
     */
    func startAuthentication() {
        oAuth = JHFlickrOAuth()
        oAuth?.initializeOAuth(redirectURL.absoluteString, accessLevel: accessLevel, completionHandler: { (status, accessToken, accessSecret, userNSID, error) -> Void in
            //Completion handler of Flickr OAuth
            if status {
                self.accessToken = accessToken
                self.accessSecret = accessSecret
                self.userNSID = userNSID
                self.oAuthDelegate?.authenticationComplete()
            }
            else {
                self.oAuthDelegate?.authenticationFailed(error!)
            }
        })
    }
    
    // MARK: Private Properties
    
    /**
     The redirect URL set when the app is created in the Flickr developer console.
     */
    private var redirectURL : NSURL!
    
    /**
     The access level required for the application.
     */
    private var accessLevel : AccessLevel!
    
    /**
     The access token obtained after the OAuth is complete. This is stored and accessed from NSUserDefaults.
     */
    private var accessToken : String! {
        get {
            return defaults.stringForKey(ACCESS_TOKEN_DEFAULTS_KEY)
        }
        set {
            defaults.setObject(newValue, forKey: ACCESS_TOKEN_DEFAULTS_KEY)
            defaults.synchronize()
        }
    }
    
    /**
     The access token secret obtained after the OAuth is complete. This is stored and accessed from NSUserDefaults.
     */
    private var accessSecret : String! {
        get {
            return defaults.stringForKey(ACCESS_SECRET_DEFAULTS_KEY)
        }
        set {
            defaults.setObject(newValue, forKey: ACCESS_SECRET_DEFAULTS_KEY)
            defaults.synchronize()
        }
    }
    
    /**
     The user NSID obtained after the OAuth is complete. This is stored and accessed from NSUserDefaults.
     */
    private var userNSID : String! {
        get {
            return defaults.stringForKey(USER_NSID_DEFAULTS_KEY)
        }
        set {
            defaults.setObject(newValue, forKey: USER_NSID_DEFAULTS_KEY)
            defaults.synchronize()
        }
    }
    
    // MARK: Private Methods
}
