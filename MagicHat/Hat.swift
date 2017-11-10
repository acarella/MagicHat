//
//  Hat.swift
//  MagicHat
//
//  Created by Antonio Carella on 10/28/17.
//  Copyright © 2017 Superflous Jazz Hands. All rights reserved.
//

import SceneKit

class Hat: SCNNode {
    
    static func loadNew() -> SCNNode {
        let url = Bundle.main.url(forResource: "art.scnassets/Hat", withExtension: ".scn")!
        let hatNodeReference = SCNReferenceNode(url: url)!
        hatNodeReference.load()
        return hatNodeReference
    }
}
