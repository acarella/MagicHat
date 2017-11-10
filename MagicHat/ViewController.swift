//
//  ViewController.swift
//  MagicHat
//
//  Created by Antonio Carella on 10/22/17.
//  Copyright © 2017 Superflous Jazz Hands. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

final class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var magicButton: UIButton!
    @IBOutlet weak var ballButton: UIButton!
    
    private var cameraTransform: matrix_float4x4? {
        let camera = sceneView.session.currentFrame?.camera
        return camera?.transform
    }
    
    private var trackingTimer: Timer?
    private var hatNode: SCNNode?
    private var hatFloorNode: SCNNode {
        let node = SCNNode()
        node.physicsBody = SCNPhysicsBody.dynamic()
        sceneView.scene.rootNode.addChildNode(node)
        return node
    }
    private var hatNodePlaneAnchor: ARPlaneAnchor?
    
    private var currentBall: SCNNode?
    private var balls = [SCNNode]()
    
    private let currentBallTranslation = SCNVector3Make(0, 0, -0.2)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self                                
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func ballButtonPressed(_ sender: UIButton) {
        let ballNode = Ball.loadNew()
        currentBall = ballNode
        balls.append(ballNode)
        setPosition(on: ballNode)
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    @IBAction func magicButtonPressed(_ sender: UIButton) {
        guard let hatNode = hatNode?.presentation else { return }
        for ball in balls {
            if hatNode.boundingBoxContains(point: ball.presentation.position) {
                ball.removeFromParentNode()
            }
        }
    }
    
    private func setPosition(on currentBall: SCNNode) {
        if let cameraTransform = cameraTransform {
            currentBall.simdTransform = cameraTransform
            currentBall.localTranslate(by: currentBallTranslation)
        }
    }
    
    @IBAction func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
        guard sender.state == .ended else { return }
        let velocity = sender.velocity(in: view)
        let zForce: Float = abs(Float(velocity.y) / 1000)
        if let currentBall = currentBall {
            currentBall.simdTransform = cameraTransform!
            let cameraRoll = sceneView.session.currentFrame?.camera.eulerAngles.x
            let degrees = cameraRoll! * 180.0 / Float.pi
            let height = tan(degrees) * zForce
            guard let ball = currentBall.childNode(withName: "ball", recursively: true) else { return }
            ball.physicsBody?.isAffectedByGravity = true
            ball.physicsBody?.applyForce(SCNVector3Make(0.0, height, zForce * -1), asImpulse: true)
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Create an SCNNode for a detect ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor, hatNode == nil else {
            return nil
        }
        hatNodePlaneAnchor = planeAnchor
        let position = SCNVector3Make(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
        hatNode = Hat.loadNew()
        hatNode?.position = position
        
        return hatNode
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.center == hatNodePlaneAnchor?.center || hatNodePlaneAnchor == nil else {
            return
        }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.y))
        hatFloorNode.geometry = plane
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
            hatNode?.light?.intensity = lightEstimate.ambientIntensity
            balls.forEach { $0.light?.intensity = lightEstimate.ambientIntensity }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
        // display error to user
            break
        case .limited:
            print("Limited tracking available")
            trackingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { [weak self] _ in
                session.run(AROrientationTrackingConfiguration())
                self?.trackingTimer?.invalidate()
                self?.trackingTimer = nil
            })
        case .normal:
            if trackingTimer != nil {
                trackingTimer!.invalidate()
                trackingTimer = nil
            }
        }
    }
}
