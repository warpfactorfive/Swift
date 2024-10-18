//  
//  Created by Terry Grossman.
//
//  This class is part of the Swift infrastructure implementation project.  It provides
//  the code typically required in world-class apps such as Tik-Tok or Instagram:
//    *A/B Testing support based on (anonymized) user id.
//    *Call monitoring 
//    *Crash Diagnostics
//    *Anonymizing users
//
//  This class implements a subclass for URLComponents so that 
//  users do not specify the scheme or host.
//

import Foundation

class APIURLComponents: URLComponents {
    
    // Constants for scheme and host
    private static let defaultScheme = "https"
    private static let defaultHost = "example.com"
    
    // Custom initializer that fills in scheme and host
    override init() {
        super.init()
        self.scheme = APIURLComponents.defaultScheme
        self.host = APIURLComponents.defaultHost
    }
    
    // Required initializer for NSCoding protocol (needed for subclasses)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

