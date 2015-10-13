//
//  Vec3.swift
//  PitchPerfect
//
//  Created by Ryan Shackleton on 10/13/15.
//  Copyright © 2015 Shackleton Computing. All rights reserved.
//

import Foundation


// handles 3d vectors for some simple calculations
class Vec3: NSObject {
    var x: Double!
    var y: Double!
    var z: Double!
    
    // angle between two vectors
    // from:http://stackoverflow.com/questions/16606989/angle-between-two-vectors-in-3d-space 
    // and many other sources
    func radiansBetween(o: Vec3) -> Double {
        let d = len() * o.len()
        if( d > 0.0 ) {
             // dot product / (length * other length)
            return (x*o.x + y*o.y + z*o.z) / d
        }
       return 0.0
    }
    
    // vector length in 3D
    func len() -> Double {
        return sqrt(x*x + y*y + z*z)
    }
}
