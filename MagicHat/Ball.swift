//
//  Ball.swift
//  MagicHat
//
//  Created by Antonio Carella on 10/28/17.
//  Copyright © 2017 Superflous Jazz Hands. All rights reserved.
//

import SceneKit

class Ball: SCNNode {
    
    static func loadNew() -> SCNNode {
        let url = Bundle.main.url(forResource: "art.scnassets/Ball", withExtension: ".scn")!
        let ballNodeReference = SCNReferenceNode(url: url)!
        ballNodeReference.load()
        return ballNodeReference
    }
}
