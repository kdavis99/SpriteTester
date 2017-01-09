//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by Kylee Davis on 1/3/17.
//  Copyright © 2017 Kylee Davis. All rights reserved.
//

import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    // calculates hypotenuse
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self/length()
    }
}

struct PhysicsCategory {
    static let None         : UInt32 = 0
    static let All          : UInt32 = UInt32.max
    static let Answer       : UInt32 = 0b1
    static let Projectile   : UInt32 = 0b10
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var startPoint  : CGPoint?
    private var endPoint    : CGPoint?
    private var multilineQues: [SKLabelNode] = []
    // TODO(kylee): make this multiline ans
    private var multilineAns: [CustomSpriteNode] = []

    
    var items: [QuestionData] = []
    
    var ques = QuestionData(question: "What is the charge on an electron?",
        answers: ["Negative": true, "Positive": false, "Neutral": false])
    var flag = false
    
    let question = SKLabelNode(fontNamed: "Arial")
    
    override func didMove(to view: SKView) {

        backgroundColor = SKColor.white
        
        addQuestionAndAnswer()
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
    }
    
    func addQuestionAndAnswer() {
        for line in multilineQues {
            line.removeFromParent()
        }
        
        for a in multilineAns {
            a.label_answer?.removeFromParent()
            a.removeFromParent()
        }
        
        multilineQues.removeAll()
        multilineAns.removeAll()
        
        if flag {
            ques.question = "What is the charge on an electron? What is the charge on an electron? What is the charge on an electron? What is the charge on an electron? What is the charge on an electron?"
            ques.answers = ["One": false, "Two": false, "Three": true, "Four": false]
        }
        
        _ = addMultilineText(str: ques.question, isQues: true,
                             numChars: 45, val: size.height/1.2)
        
        // Creates the first question in the starting scene
        
        
        // creates initial answers to questions
        var i = CGFloat(0.5)
        let width = self.size.width / CGFloat(ques.answers.count)
        for (ans, correct) in ques.answers {
            
            // answer with letters
            let new_answer = SKLabelNode(fontNamed: "Arial")
            new_answer.fontName = "Arial"
            new_answer.text = ans
            new_answer.fontColor = UIColor.black
            new_answer.fontSize = 30
            new_answer.position = CGPoint(x: width * i, y: self.size.height/2.3)
            
            // background image behind the words.
            // TODO(kylee): change imageNamed to plain background
            let ans_background = CustomSpriteNode(color: .white, size: CGSize(
                width: width, height: 20))
            
            ans_background.label_answer = new_answer
            ans_background.physicsBody = SKPhysicsBody(rectangleOf: ans_background.size)
            ans_background.physicsBody?.isDynamic = true
            ans_background.physicsBody?.categoryBitMask = PhysicsCategory.Answer
            ans_background.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
            ans_background.physicsBody?.collisionBitMask = PhysicsCategory.None
            ans_background.position = CGPoint(x: width * i, y: self.size.height/2.1)
            
            
            multilineAns.append(ans_background)
            
            if correct == true {
                ans_background.correct_answer = true
            }
            
            i += 1
            addChild(new_answer)
            addChild(ans_background)
        }
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        let monster = CustomSpriteNode(imageNamed: "monster")
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        monster.physicsBody?.isDynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Answer
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None

        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        addChild(monster)
        
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        
        let actionMoveDone = SKAction.removeFromParent()
        
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        startPoint = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // guard is a conditional that forces out of scope
        guard let touch = touches.first else {
            return
        }
        
        
        // let touchLocation = touch.location(in: self)
        endPoint = touch.location(in: self)
        
        // create projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Answer
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        projectile.position = startPoint!
        
        // let offset = touchLocation - projectile.position
        print(endPoint! + startPoint!)
        
        let offset = (endPoint!) - (startPoint!)
        
        addChild(projectile)
        
        let direction = offset.normalized()
        
        let shootAmount = direction * 1000
        
        let realDest = shootAmount + projectile.position
        
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func projectileDidCollideWithAnswer(answer: CustomSpriteNode, projectile: SKSpriteNode) {
        if answer.correct_answer {
            flag = true
            // change color to green, if answer is right
            answer.label_answer?.fontColor = UIColor(
                red: 0.0, green: 0.858, blue: 0.529, alpha: 1.0)
            // TODO(kylee): call new question here and randomize
        } else {
            // change color to red, if answer is right
            answer.label_answer?.fontColor = UIColor.red
        }
        
        // make answer blink/pulse
        let actionFadeOut = SKAction.fadeOut(withDuration: 1.0)
        let actionFadeIn = SKAction.fadeIn(withDuration: 1.0)
        answer.label_answer?.run(SKAction.sequence([actionFadeOut, actionFadeIn,
                                                     actionFadeOut, actionFadeIn,
                                                     SKAction.run(addQuestionAndAnswer)]))
        projectile.removeFromParent()
        // answer.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody : SKPhysicsBody
        var secondBody : SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Answer != 0) &&
            ((secondBody.categoryBitMask & PhysicsCategory.Projectile != 0))) {
            projectileDidCollideWithAnswer(answer: firstBody.node as! CustomSpriteNode,
                                           projectile: secondBody.node as! SKSpriteNode)
        }
    }
    
    // val is the starting y location for the first line
    func addMultilineText(str: String, isQues: Bool, numChars: Int, val: CGFloat)-> CGFloat
    {
        var Returnval = val
       
        // parse through the string and put each words into an array.
        let separators = NSCharacterSet.whitespacesAndNewlines
        let words = str.components(separatedBy: separators)
        let len = str.characters.count
        let width = numChars; // specify your own width to fit the device screen
        // get the number of labelnode we need.
        let numLines = (len/width) + 1
        var cnt = 0; // used to parse through the words array
        // here is the for loop that create all the SKLabelNode that we need to
        // display the string.
        for i in 0...numLines {
            var lenPerLine = 0
            var lineStr = ""
            while lenPerLine < width {
                if cnt > words.count - 1 {
                    break
                } else {
                    lineStr = NSString(format: "%@ %@", lineStr, words[cnt]) as String
                    lenPerLine = lineStr.characters.count
                    cnt += 1
                }
            }
            // creation of the SKLabelNode itself
            let multiLineLabel = SKLabelNode(fontNamed: "Light")
            multiLineLabel.text = lineStr;
            // name each label node so you can animate it if u wish
            // the rest of the code should be self-explanatory
            multiLineLabel.name = NSString(format: "line%d", i) as String
            multiLineLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
            multiLineLabel.fontSize = 25;
            multiLineLabel.fontColor = UIColor.black
            let top = val-30*CGFloat(i)
            multiLineLabel.position = CGPoint(x: self.size.width/2 , y: top)
            // self.sharedInstance.addChildFadeIn(_multiLineLabel, target: self)
            addChild(multiLineLabel)
            if isQues {
                multilineQues.append(multiLineLabel)
            }
            Returnval = top;
        }
        // return last y pos sp we can add stuff under it  
        return Returnval  
    }  
}
