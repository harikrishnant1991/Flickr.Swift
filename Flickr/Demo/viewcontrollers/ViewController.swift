//
//  ViewController.swift
//  Flickr
//
//  Created by Harikrishnan T on 24/01/16.
//  Copyright © 2016 FyrWeel Infolabz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, JHFlickrAuthenticationDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        JHFlickr.Session.oAuth.verifyAccessToken { (status) -> Void in
            if !status {
                JHFlickr.Session.oAuth.oAuthDelegate = self
                JHFlickr.Session.startAuthentication()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func authenticationComplete() {
        
    }
    
    func authenticationFailed(error : String) {
        
    }
}

