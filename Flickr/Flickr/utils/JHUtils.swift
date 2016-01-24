//
//  JHUtils.swift
//  Flickr
//
//  Created by Harikrishnan T on 24/01/16.
//  Copyright © 2016 FyrWeel Infolabz. All rights reserved.
//

import UIKit

extension String {
    
    func hmacsha1(key: String) -> NSData {
        let dataToDigest = self.dataUsingEncoding(NSUTF8StringEncoding)
        let secretKey = key.dataUsingEncoding(NSUTF8StringEncoding)
        
        let digestLength = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), secretKey!.bytes, secretKey!.length, dataToDigest!.bytes, dataToDigest!.length, result)
        
        return NSData(bytes: result, length: digestLength)
    }
}

class JHUtils: NSObject {
    
    static let FLICKR_BASE_URL = "https://api.flickr.com/services/rest"
    
    /**
     The consumer key obtained from Flickr developer console.
     */
    static var CONSUMER_KEY : String!
    
    /**
     The consumer secret obtained from Flickr developer console.
     */
    static var CONSUMER_SECRET : String!
    
    /**
     Unix time stamp.
     */
    static var TimeStamp: String {
        return "\(NSDate().timeIntervalSince1970 * 1000)"
    }
    
    /**
     Returns the HMAC-SHA1 signature for OAuth requests.
     
     - parameter url: The URL to which the request is made.
     - parameter params: The dictionary that contains the parameters as key value pairs to make the request.
     
     - returns: HMAC-SHA1 signature for the input signature.
     */
    static func GetSignature(url url : String, params : Dictionary<String, String>, key : String) -> String {
        var rawString = "GET&"
        rawString = rawString + url.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        rawString = rawString + "&"
        let sortedParams = params.sort({$0.0 < $1.0})
        var paramsString = ""
        var i = 0;
        for (key, value) in sortedParams {
            i++;
            paramsString = paramsString + String(format: "%@=%@", key, value)
            if i < sortedParams.count {
                paramsString = paramsString + "&"
            }
        }
        paramsString = paramsString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        paramsString = paramsString.stringByReplacingOccurrencesOfString("&", withString: "%26")
        paramsString = paramsString.stringByReplacingOccurrencesOfString("=", withString: "%3D")
        rawString = rawString + paramsString
        let signatureData = rawString.hmacsha1(key)
        let base64Encoded = signatureData.base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
        return NSString(data: base64Encoded, encoding: NSUTF8StringEncoding) as! String
    }
    
    /**
     Generates a random string with the mentioned length.
     
     - parameter length: The length of the random string to be generated.
     
     - returns: The random string that is generated.
     */
    static func RandomStringWithLength(length : Int) -> String {
        let letters : String = "0123456789"
        var randomString : String = String()
        for _ in 0...length {
            let length = letters.characters.count
            let rand = arc4random_uniform(UInt32(length))
            let index = letters.startIndex.advancedBy(Int(rand))
            randomString.append(letters[index])
        }
        return randomString
    }
}
