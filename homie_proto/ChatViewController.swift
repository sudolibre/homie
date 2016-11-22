//
//  ChatViewController.swift
//  homie_proto
//
//  Created by Jonathon Day on 11/4/16.
//  Copyright © 2016 dayj. All rights reserved.
//

import UIKit
import TwilioCommon
import TwilioIPMessagingClient
import SwiftyJSON
import SlackTextViewController
import SwiftOverlays
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ChatViewController: SLKTextViewController {
    
    var client: TwilioIPMessagingClient?
    var generalChannel: TWMChannel?
    var identity: String?
    var messages = [TWMMessage]()
    var users: [String] = []
    var searchResults: [String] = []

    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SwiftOverlays.showCenteredWaitOverlayWithText(self.tableView!, text: "Loading...")

        //performSelector(inBackground: #selector(loginToChatServer), with: nil)
        loginToChatServer()
        self.tableView?.register(MessageTableViewCell.self, forCellReuseIdentifier: "MessageTableViewCell")
        self.isInverted = false
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.tableView?.estimatedRowHeight = 66.0
        self.tableView?.separatorStyle = .none
        self.tableView?.backgroundColor = UIColor.lightGray
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as! MessageTableViewCell
        let message = self.messages[indexPath.row]
        
        cell.nameLabel.text = message.author
        print(message.author)
        let isOwner = message.author == self.identity
        if isOwner { // should this go in the tableviewcell class? How would I do that?
            cell.nameLabel.textAlignment = .right
            cell.nameLabel.textColor = UIColor(red: 127, green: 0, blue: 0, alpha: 1)
            cell.bodyLabel.textAlignment = .right
        }
        cell.bodyLabel.text = message.body
        print(message.body)
        cell.backgroundColor = UIColor.lightGray // this is not the right way to do this. if you pull past the content you can see whitespace. 
        cell.selectionStyle = .none
        return cell
    }
    
    override func didPressRightButton(_ sender: Any?) {
        self.textView.refreshFirstResponder()
        
        //keep crashing here when trying due to nil in optional - need to reconsider this and ensure theuser cannot send a message before this is exists
        let message = self.generalChannel?.messages.createMessage(withBody: self.textView.text)
        self.generalChannel?.messages.send(message){
            (result) -> Void in
            print(String(describing: result))
                self.textView.text = ""
        }
    }
    
    func loginToChatServer() {
        let deviceId = UUID().uuidString
        let urlString = "http://localhost:8000/token.php?device=\(deviceId)"
        
        // Get JSON from server
        let session = URLSession.shared
        let url = URL(string: urlString)//NSURL(string: urlString)
        let request  = URLRequest(url: url!)
        
        session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            if (data != nil) {
                // Parse result JSON
                let json = JSON(data: data!)
                self.identity = json["identity"].stringValue
                let token: String = json["token"].stringValue
                // Set up Twilio IPM client
                let accessManager = TwilioAccessManager.init(token: token, delegate: nil)
                self.client = TwilioIPMessagingClient(accessManager: accessManager, properties: nil, delegate: self)
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.navigationItem.prompt = "Logged in as \"\(self.identity)\""
                    print("Logged in as \"\(self.identity)\"")
                }
            } else {
                print("Error fetching token :\(error)")
            }
        }).resume()
    }
    
     func loadMessages() {
        if self.messages.count == 0 {
        }
        self.messages.removeAll()
        self.generalChannel?.messages.getLastWithCount(30, completion: { (result, newMessages) in
            print(String(describing: result))
            let messages = newMessages
            self.addMessages(messages!)
            SwiftOverlays.removeAllBlockingOverlays()
        })
    }
    
    func addMessages(_ messages: [TWMMessage]) {
        self.messages.append(contentsOf: messages)
        self.messages.sorted { $1.timestamp > $0.timestamp }
        
        DispatchQueue.main.async {
            () -> Void in
            self.tableView?.reloadData()
            if self.messages.count > 0 {
                self.scrollToBottomMessage()
            }
        }
    }
    
    func scrollToBottomMessage() {
        if self.messages.count == 0 {
            return
        }
        let bottomMessageIndex = IndexPath(row: tableView!.numberOfRows(inSection: 0) - 1, section: 0)
        self.tableView!.scrollToRow(at: bottomMessageIndex, at: .bottom,
                                              animated: true)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

extension ChatViewController: TwilioAccessManagerDelegate {
    public func accessManagerTokenExpired(_ accessManager: TwilioAccessManager!) {
        return
    }
    

    public func accessManager(_ accessManager: TwilioAccessManager!, error: Error!) {
        print(error)
    }
}

extension ChatViewController: TwilioIPMessagingClientDelegate {
    func ipMessagingClient(_ client: TwilioIPMessagingClient!, synchronizationStatusChanged status: TWMClientSynchronizationStatus) {
        if status == .completed {
            let defaultChannel = "general"
            
            self.generalChannel = client.channelsList().channel(withUniqueName: defaultChannel)
            if let generalChannel = self.generalChannel {
                generalChannel.join(completion: { result in
                    print("Channel joined with result \(result)")
                    self.loadMessages()

                })
            } else {
                client.channelsList().createChannel(options: [TWMChannelOptionFriendlyName: "General Chat Channel", TWMChannelOptionType: TWMChannelType.public.rawValue], completion: { (result, channel) in
                    if (result?.isSuccessful())! {
                        self.generalChannel = channel
                        self.generalChannel?.join(completion: { result in
                            self.generalChannel?.setUniqueName(defaultChannel, completion: { result in
                                print("Channel unique name set")
                                self.loadMessages()
                            })
                        })
                        
                    }
                })
            }
        }
    }
    
    func ipMessagingClient(_ client: TwilioIPMessagingClient!, channel: TWMChannel!, messageAdded message: TWMMessage!) {
        loadMessages()
        //self.messages.append(message)
        //self.tableView?.reloadData()
    }
    
}


