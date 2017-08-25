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


var XAPPDELEGATE : AppDelegate {
    return UIApplication.shared.delegate! as! AppDelegate
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func showLogin() -> UIViewController {
        
        let vc = GKLoginHomeController()
        let nav = GKNavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        self.window?.rootViewController = nav
        self.window?.makeKeyAndVisible()
        
        return vc
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
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
        
        YKClient.shareInstance.config(client_id: "qDFdSoMJtm6Yb2gAmaigmisc", client_secret: "5QdJ0zqAP1ICDCUGrcxtyloKKQ")
        
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
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

}

