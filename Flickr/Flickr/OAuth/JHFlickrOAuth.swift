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
    /**
     Read only permission. Can only be used to fetch data.
     */
    case Read = "read"
    /**
     Write permission. Can be used to read as well as write data. Cannot be used for deleting data.
     */
    case Write = "write"
    /**
     Can be used to Read Write and Delete data.
     */
    case Delete = "delete"
}

class JHFlickrOAuth: NSObject {
    
    // MARK: Constants.
    private let REQUEST_TOKEN_URL = "https://www.flickr.com/services/oauth/request_token"
    private let ACCESS_TOKEN_URL = "https://www.flickr.com/services/oauth/access_token"
    private let VERIFY_ACCESS_TOKEN_URL = "https://www.flickr.com/services/oauth/access_token"
    
    private let OAUTH_ERROR_MESSAGE = "An error occured while communicating with server. Please try again later."
    
    // MARK: Public methods
    
    /**
    Initialise the OAuth flow. The OAuth flow of Flickr comprises of 3 steps:
    1. Fetching a request token.
    2. Getting user authentication using the request token and fetching the request verifier.
    3. Exchanging the request token and request verifier for the access token and access secret.
    
    - parameter redirectURL: The URL to which the webview need to be redirected after the OAuth flow.
    - parameter accessLevel: The access level for API calls.
    - parameter completionHandler: The completion handler for OAuth.
     */
    func initializeOAuth(redirectURL redirectURL : String, accessLevel : AccessLevel, completionHandler: (status : Bool, accessToken : String?, accessSecret : String?, userNSID : String?, error : String?) -> Void) {
        self.completionHandler = completionHandler
        self.redirectURL = redirectURL
        self.accessLevel = accessLevel
        fetchRequestToken()
    }
    
    /**
     To be called when the user authorisation completes.
     
     - parameter url: The URL that was being redirected to.
     
     - returns: If the url scheme matches Flickr redirect URL's scheme.
     */
    func userAuthenticated(url : NSURL) -> Bool {
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
     Verify if the access token fetched is valid or not.
     
     - parameter accessToken: The access token to be validated.
     - parameter accessSecret: The access secret for validating the access token.
     - parameter completionHandler: The event closure that need to be called on completion of the verification call.
     */
    func verifyAccessToken(accessToken : String, accessSecret : String, completionHandler: (status : Bool) -> Void) {
        var requestUrl = JHUtils.FLICKR_BASE_URL + "?"
        let paramDictionary = verifyAccessTokenParams(accessToken)
        for (key, value) in paramDictionary {
            requestUrl = requestUrl + key + "=" + value + "&"
        }
        requestUrl = requestUrl + "oauth_signature=" + JHUtils.GetSignature(url: JHUtils.FLICKR_BASE_URL, params: paramDictionary, key: JHUtils.CONSUMER_SECRET + "&" + accessSecret)
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(NSURL(string: requestUrl)!) { (data, response, error) -> Void in
            if (error == nil) {
                do {
                    let result = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                    if result["stat"] != nil && (result["stat"] as! String) == "ok" {
                        completionHandler(status: true)
                    }
                }
                catch {
                    completionHandler(status: false)
                }
            }
            else {
                completionHandler(status: false)
            }
            }.resume()
    }
    
    // MARK: Private properties
    
    /**
    Completion handler for OAuth.
    
    - parameter status: If the OAuth was success or not.
    - parameter accessToken: The access token fetched in case of a successful OAuth.
    - parameter accessSecret: The access token secret fetched in case of a successful OAuth.
    - parameter userNSID: The user NSID fetched in case of a successful OAuth.
    - parameter username: The user's name fetched in case of a successful OAuth.
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
    
    /**
     The parameters to be passed along with the verification request.
     */
    private func verifyAccessTokenParams(accessToken : String) -> Dictionary<String, String> {
        var paramsDictionary = Dictionary<String, String>()
        paramsDictionary["oauth_nonce"] = JHUtils.RandomStringWithLength(14)
        paramsDictionary["oauth_timestamp"] = JHUtils.TimeStamp
        paramsDictionary["oauth_consumer_key"] = JHUtils.CONSUMER_KEY
        paramsDictionary["oauth_signature_method"] = "HMAC-SHA1"
        paramsDictionary["oauth_version"] = "1.0"
        paramsDictionary["nojsoncallback"] = "1"
        paramsDictionary["format"] = "json"
        paramsDictionary["method"] = "flickr.test.login"
        paramsDictionary["oauth_token"] = accessToken
        return paramsDictionary;
    }
}
