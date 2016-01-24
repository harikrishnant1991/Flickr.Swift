# Flickr.Swift

This is a library written entirely in swift for working with Flickr OAuth APIs.

#### Important Notes:
- The Flickr API requires an HMAC-SHA1 signature. For this purpose, you need to create a Bridging Header file for objective-C(in case you already don't have one) and do the following import in that:
```swift
#import <CommonCrypto/CommonHMAC.h>
```
- The redirect URL set in the Flickr Developer console need to have a custom URL Scheme unique to your application and it must be registered in the `plist` file.

## How to use
The Flickr API authentication and calls are controlled using a single instance of the singleton class `JHFlickr`, which can be accessed using:

```swift
JHFlickr.Session
```
To initialise the Flickr Session, you need to call the following function of `JHFlickr` in the `application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool` function of `AppDelegate`:

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    JHFlickr.Session.initialize(consumerKey: "[YOUR_API_KEY_HERE]", consumerSecret: "[YOUR_API_SECRET_HERE]", redirectURL: NSURL(string: "[YOUR_REDIRECT_URL_HERE]")!, accessLevel: .Delete)
    return true
}
```

This will initialise the Flickr Session with your Consumer Key, Consumer Secret and Redirect URL. The last parameter is the access level required by the App. This can be `Read`, `Write` or `Delete` as per your requirements.

#### User Authentication

The user authentication can be verified using this call to determine if an active and valid session already exists before starting a new authentication flow.

```swift
JHFlickr.Session.checkFlickrStatus(onCompletion: { (status) -> Void in
})
```

The status in the above call shows if the flickr already has an active session or not. It is advisable to always check for an active session before starting a new authentication flow since the OAuth flow can be pretty heavy and time consuming. If there is no active session, use the following code to start with Flickr's OAuth flow and implement the `JHFlickrAuthenticationDelegate` in your `ViewController` as shown below to get the OAuth response.

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    JHFlickr.Session.checkFlickrStatus(onCompletion: { (status) -> Void in
        if !status {
            JHFlickr.Session.oAuthDelegate = self
            JHFlickr.Session.startAuthentication()
        }
    })
}
    
func authenticationComplete() {
    //Successful authentication
}
    
func authenticationFailed(error : String) {
    //Authentication failed
}
```

You can start calling Flickr API's methods once you get a successful callback.