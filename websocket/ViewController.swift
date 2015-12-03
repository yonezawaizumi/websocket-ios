//
//  ViewController.swift
//  websocket
//
//  Created by yonezawaizumi on 2015/11/29.
//  Copyright © 2015年 yonezawaizumi. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WebSocketDelegate {
    
    private var socket: WebSocket?
    private var alertMessage: String?
    private var isActive = false

    private let uri = "ws://echo.websocket.org"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tryConnect()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        isActive = true
        if alertMessage != nil {
            alert(alertMessage!, pendingWhenInactive: false)
            alertMessage = nil
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        isActive = false
    }
    
    deinit {
        disconnect()
    }
    
    @IBAction func didPushedSendButton(sender: NSObject) {
        alert("Pushed", pendingWhenInactive: false)
    }
    
    private func alert(message: String, pendingWhenInactive: Bool) {
        if isActive {
            let alertController = UIAlertController(
                title: NSLocalizedString("WebSocket Error", comment: ""),
                message: message,
                preferredStyle: .Alert
            )
            alertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("OK", comment: ""),
                    style: .Default
                ) { (action) -> Void in
                    self.tabBarController?.selectedIndex = 0
                }
            )
            self.presentViewController(alertController, animated: true, completion: nil)
        } else if pendingWhenInactive && alertMessage == nil {
            alertMessage = message
        }
    }
    
    private func getCookies() -> [NSHTTPCookie] {
        return []
    }
    
    private func tryConnect() {
        if socket == nil {
            connect(uri, cookies: getCookies())
        }
    }
    
    private func connect(uri: String, cookies: [NSHTTPCookie]) {
        socket = WebSocket(url: NSURL(string: uri)!)
        let headers = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies)
        for (key, value) in headers {
            socket!.headers[key] = value
        }
        socket!.delegate = self
        socket!.connect()
    }
    
    func sendQuery(value: String) {
        print("sendQuery " + value)
        socket?.writeString(value)
    }
    
    func sendSettingsQuery() {
        socket?.writeString("get")
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("connect")
        sendSettingsQuery()
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("disconnect")
        socket.delegate = nil
        self.socket = nil
        alert(NSLocalizedString("Server Disconnected\nPlease Retry After", comment: ""), pendingWhenInactive: true)
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("message: " + text)
        switch text {
        case let ___ where ___.hasPrefix("{"):
            let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String: AnyObject]
                Preferences.update(json)
                for viewController in viewControllers {
                    (viewController as? UITableViewController)?.tableView?.reloadData()
                }
            } catch let error as NSError {
                print("failed to load json string")
                print(error.description)
            }
        case "e":
            disconnect()
            alert(NSLocalizedString("Server Unavailable\nPlease Retry After", comment: ""), pendingWhenInactive: true)
        case "n":
            disconnect()
            alert(NSLocalizedString("Authentication Failed\nPlease Re-Login", comment: ""), pendingWhenInactive: true)
        case "x":
            disconnect()
            alert(NSLocalizedString("Settings Not Exist In App Server\nPlease Delete And Reinstall App", comment: ""), pendingWhenInactive: true)
            //case "k":
        default:
            break
        }
    }
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("data")
    }
    
    private func disconnect() {
        if socket != nil {
            socket!.disconnect()
            socket = nil
        }
    }
}

