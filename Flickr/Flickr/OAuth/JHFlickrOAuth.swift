//
//  JHFlickrOAuth.swift
//  Flickr
//
//  Created by Harikrishnan T on 24/01/16.
//  Copyright © 2016 FyrWeel Infolabz. All rights reserved.
//

import UIKit
import SafariServices

enum AccessLevel : String {
    case Read = "read"
    case Write = "write"
    case Delete = "delete"
}

class JHFlickrOAuth: NSObject {
    
    // MARK: Constants.
    private let REQUEST_TOKEN_URL = "https://www.flickr.com/services/oauth/request_token"
    private let ACCESS_TOKEN_URL = "https://www.flickr.com/services/oauth/access_token"
    
    private let OAUTH_ERROR_MESSAGE = "An error occured while communicating with server. Please try again later."
    
    // MARK: Public methods
    
    /**
    Initialise the OAuth flow. The OAuth flow of Flickr comprises of 3 steps:
    1. Fetching a request token.
    2. Getting user authentication using the request token and fetching the request verifier.
    3. Exchanging the request token and request verifier for the access token and access secret.
     */
    func initializeOAuth(redirectURL : String, accessLevel : AccessLevel, completionHandler: (status : Bool, accessToken : String?, accessSecret : String?, userNSID : String?, error : String?) -> Void) {
        self.completionHandler = completionHandler
        self.redirectURL = redirectURL
        self.accessLevel = accessLevel
        fetchRequestToken()
    }
    
    // MARK: Private properties
    
    /**
    Completion handler for OAuth.
    */
    private var completionHandler : ((status : Bool, accessToken : String?, accessSecret : String?, userNSID : String?, error : String?) -> Void)!
    
    /**
     The redirect URL set when the app is created in the Flickr developer console.
     */
    private var redirectURL : String!
    
    /**
     The access level required for the application.
     */
    private var accessLevel : AccessLevel!
    
    /**
    The request token for retrieving the access token. This request token is exchanged for access token.
    */
    private var requestToken : String!
    
    /**
     The request token secret for retrieving the access token.
     */
    private var requestSecret : String!
    
    /**
     The request verifier for retrieving the access token.
     */
    private var requestVerifier : String!
    
    /**
     The safari web view controller to get user authorisation from the user.
     */
    var safariViewController : SFSafariViewController!
    
    // MARK: Private Methods
    
    /**
    Fetch the request token which will later be exchanged for access token.
    */
    private func fetchRequestToken() {
        var requestUrl = REQUEST_TOKEN_URL + "?"
        let paramDictionary = requestTokenParams()
        for (key, value) in paramDictionary {
            requestUrl = requestUrl + key + "=" + value + "&"
        }
        requestUrl = requestUrl + "oauth_signature=" + JHUtils.GetSignature(url: REQUEST_TOKEN_URL, params: paramDictionary, key: JHUtils.CONSUMER_SECRET + "&")
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(NSURL(string: requestUrl)!) { (data, response, error) -> Void in
            if (error == nil) {
                let result = String(data: data!, encoding: NSUTF8StringEncoding)
                let parts = result?.componentsSeparatedByString("&")
                if parts?.count == 3 {
                    self.requestToken = parts![1].stringByReplacingOccurrencesOfString("oauth_token=", withString: "")
                    self.requestSecret = parts![2].stringByReplacingOccurrencesOfString("oauth_token_secret=", withString: "")
                    self.getUserAuthorisation()
                }
                else {
                    self.completionHandler(status: false, accessToken: nil, accessSecret: nil, userNSID: nil, error: self.OAUTH_ERROR_MESSAGE)
                }
            }
            else {
                self.completionHandler(status: false, accessToken: nil, accessSecret: nil, userNSID: nil, error: error?.localizedDescription)
            }
            }.resume()
    }
    
    /**
     Loads the Flickr login page in SFSafariViewController and gets user authentication.
     */
    private func getUserAuthorisation() {
        safariViewController = SFSafariViewController(URL: userAuthURL())
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(safariViewController, animated: true, completion: nil)
    }
    
    /**
     To be called when the user authorisation completes.
     
     - returns: If the url scheme matches Flickr redirect URL's scheme.
     */
    internal func userAuthenticated(url : NSURL) -> Bool {
        if url.scheme != NSURL(string: redirectURL)?.scheme {
            return false
        }
        safariViewController.dismissViewControllerAnimated(true, completion: nil)
        safariViewController = nil
        let parts = url.query?.componentsSeparatedByString("&")
        if parts?.count == 2 {
            requestVerifier = parts![1].stringByReplacingOccurrencesOfString("oauth_verifier=", withString: "")
            fetchAccessToken()
        }
        return true
    }
    
    /**
     The request for exchanging the request token for access token.
     */
    private func fetchAccessToken() {
        var requestUrl = ACCESS_TOKEN_URL + "?"
        let paramDictionary = accessTokenParams()
        for (key, value) in paramDictionary {
            requestUrl = requestUrl + key + "=" + value + "&"
        }
        requestUrl = requestUrl + "oauth_signature=" + JHUtils.GetSignature(url: ACCESS_TOKEN_URL, params: paramDictionary, key: JHUtils.CONSUMER_SECRET + "&" + requestSecret)
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(NSURL(string: requestUrl)!) { (data, response, error) -> Void in
            if (error == nil) {
                let result = String(data: data!, encoding: NSUTF8StringEncoding)
                let parts = result?.componentsSeparatedByString("&")
                if parts?.count == 5 {
                    let accessToken = parts![1].stringByReplacingOccurrencesOfString("oauth_token=", withString: "")
                    let accessSecret = parts![2].stringByReplacingOccurrencesOfString("oauth_token_secret=", withString: "")
                    let userNSID = parts![3].stringByReplacingOccurrencesOfString("user_nsid=", withString: "")
                    self.completionHandler(status: true, accessToken: accessToken, accessSecret: accessSecret, userNSID: userNSID, error: nil)
                }
                else {
                    self.completionHandler(status: false, accessToken: nil, accessSecret: nil, userNSID: nil, error: self.OAUTH_ERROR_MESSAGE)
                }
            }
            else {
                self.completionHandler(status: false, accessToken: nil, accessSecret: nil, userNSID: nil, error: error?.localizedDescription)
            }
            }.resume()
    }
    
    /**
     The url for loading the website for user authentication.
     
     - returns: The login URL for getting Flickr authorisation from user.
     */
    private func userAuthURL() -> NSURL {
        let requestURL = "https://www.flickr.com/services/oauth/authorize?oauth_token=" + requestToken + "&perms=" + accessLevel.rawValue
        return NSURL(string: requestURL)!
    }
    
    /**
     The parameters to be passed along with the request token request.
     */
    private func requestTokenParams() -> Dictionary<String, String> {
        var paramsDictionary = Dictionary<String, String>()
        paramsDictionary["oauth_nonce"] = JHUtils.RandomStringWithLength(14)
        paramsDictionary["oauth_timestamp"] = JHUtils.TimeStamp
        paramsDictionary["oauth_consumer_key"] = JHUtils.CONSUMER_KEY
        paramsDictionary["oauth_signature_method"] = "HMAC-SHA1"
        paramsDictionary["oauth_version"] = "1.0"
        let escapedRedirectURL = redirectURL.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        paramsDictionary["oauth_callback"] = escapedRedirectURL
        return paramsDictionary;
    }
    
    /**
     The parameters to be passed along with the access token request.
     */
    private func accessTokenParams() -> Dictionary<String, String> {
        var paramsDictionary = Dictionary<String, String>()
        paramsDictionary["oauth_nonce"] = JHUtils.RandomStringWithLength(14)
        paramsDictionary["oauth_timestamp"] = JHUtils.TimeStamp
        paramsDictionary["oauth_consumer_key"] = JHUtils.CONSUMER_KEY
        paramsDictionary["oauth_signature_method"] = "HMAC-SHA1"
        paramsDictionary["oauth_version"] = "1.0"
        paramsDictionary["oauth_verifier"] = requestVerifier
        paramsDictionary["oauth_token"] = requestToken
        return paramsDictionary;
    }
}
