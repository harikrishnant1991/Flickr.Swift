//
//  JHFlickr.swift
//  Flickr
//
//  Created by Harikrishnan T on 24/01/16.
//  Copyright © 2016 FyrWeel Infolabz. All rights reserved.
//

import UIKit

class JHFlickr: NSObject {
    
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
     The instance of JHFlickrOAuth that handles the OAuth flow of JHFlickr library.
     */
    var oAuth = JHFlickrOAuth()
    
    // MARK: Public methods
    /**
    Initialize the flickr session with consumer key and consumer secret obtained from developer console and redirect URL set in the developer console.
    
    - parameter consumerKey: The consumer key obtained when creating an app in Flickr developer console.
    - parameter consumerSecret: The consumer secret obtained when creating an app in Flickr developer console.
    - parameter redirectURL: The redirect URL set when the app is created in the Flickr developer console.
    - parameter accessLevel: The access level for the API calls.
    */
    func initialize(consumerKey consumerKey : String, consumerSecret : String, redirectURL : NSURL, accessLevel : AccessLevel) {
        JHUtils.CONSUMER_KEY = consumerKey
        JHUtils.CONSUMER_SECRET = consumerSecret
        self.redirectURL = redirectURL
        self.accessLevel = accessLevel
    }
    
    /**
     Start the OAuth flow of flickr.
     
     It is adivasble always to check for active sessions before starting a new OAuth flow as shown below:
     ```
     JHFlickr.Session.oAuth.verifyAccessToken { (status) -> Void in
        if !status {
            JHFlickr.Session.oAuth.oAuthDelegate = self
            JHFlickr.Session.startAuthentication()
        }
     }
     ```
     */
    func startAuthentication() {
        oAuth.initializeOAuth(redirectURL: redirectURL.absoluteString, accessLevel: accessLevel)
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
    
    // MARK: Private Methods
}
