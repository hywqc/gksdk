//
//  AppDelegate.swift
//  testsw
//
//  Created by wqc on 2017/7/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gkutility
import YunkuSDK
import AVFoundation


var XAPPDELEGATE : AppDelegate {
    return UIApplication.shared.delegate! as! AppDelegate
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var backStop = false
    var backFile = ""
    var backTime = 0
    var avplayer: AVAudioPlayer?
    
    var backTaskID: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    func showLogin() -> UIViewController {
        
        let vc = GKLoginHomeController()
        let nav = GKNavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        self.window?.rootViewController = nav
        self.window?.makeKeyAndVisible()
        
        return vc
    }
    
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        YKClient.shareInstance.config(host:"yk3.gokuai.com", client_id: "qDFdSoMJtm6Yb2gAmaigmisc", client_secret: "5QdJ0zqAP1ICDCUGrcxtyloKKQ", https: true, groupID: "group.com.gokuai.wqc.extension")
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        
        if YKClient.shareInstance.checkFastLogin() {
            print("fast login")
            MainViewController.show()
            YKClient.shareInstance.fastLogin(completion: nil)
        } else {
            let _  = self.showLogin()
        }
        
        
        print(gkutility.docPath())
        
        NotificationCenter.default.addObserver(self, selector: #selector(onForceLogout(notification:)), name: NSNotification.Name(YKNotification_ForceLogout), object: nil)
        
        
        
        return true
    }
    
    func onForceLogout(notification:Notification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(YKNotification_ForceLogout), object: nil)
        let vc = self.showLogin()
        var msg = "授权已失效"
        if let s = notification.object as? String {
            msg = s
        }
        AlertUtility.showAlert(message: msg, vc: vc)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        //self.backFile = gkutility.docPath().gkAddLastSlash
        //self.backFile += "test.txt"
        
        self.backtask()

    }
    
    func backtask() {
        self.backTaskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backTaskID)
            self.backTaskID = UIBackgroundTaskInvalid
        }
        
        DispatchQueue.global().async {
            self.playsound()
            
            Thread.sleep(forTimeInterval: 2)
            if self.backTaskID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(self.backTaskID)
                self.backTaskID = UIBackgroundTaskInvalid
            }
        }
    }
    
    func playsound() {
        
        let audiosession = AVAudioSession.sharedInstance()
        do {
            try audiosession.setCategory(AVAudioSessionCategoryPlayback)
        } catch  {
            
        }
        do {
            try audiosession.setActive(true)
        } catch  {
            
        }
        //UIApplication.shared.beginReceivingRemoteControlEvents()
        if let url = Bundle.main.url(forResource: "bbb", withExtension: "mp3") {
            if let player = try? AVAudioPlayer(contentsOf: url) {
                self.avplayer = player
                player.numberOfLoops = -1
                //player.volume = 0.0
                player.prepareToPlay()
                if player.play() {
                    print("is playing!!")
                }
            }
        }
        
    }
    
    func stopPlay() {
        
        if self.avplayer != nil {
            self.avplayer!.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
        }
        self.avplayer = nil
    }
    

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        self.stopPlay()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if FileManager.default.fileExists(atPath: url.path) {
            
            YKClient.shareInstance.showSaveSelect(url: url, fromVC: (app.keyWindow?.rootViewController!)!)
            
        }
        return true
    }

}

