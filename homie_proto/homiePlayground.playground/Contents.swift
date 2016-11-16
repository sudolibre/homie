//: Playground - noun: a place where people can play

//
//  FirstViewController.swift
//  homie_proto
//
//  Created by Jonathon Day on 11/4/16.
//  Copyright © 2016 dayj. All rights reserved.
//

import UIKit
import SwiftyJSON
import SlackTextViewController
import SwiftOverlays
import TwilioCommon
import TwilioIPMessagingClient


class ChatViewController: SLKTextViewController {
    
    // let testArray = ["first message", "second message", "third message", "etc"]
    var client: TwilioIPMessagingClient?
    var generalChannel: TWMChannel?
    var identity: String?
    var messages = [TWMMessage]()
    
    override func viewDidAppear(_ animated: Bool) {
        SwiftOverlays.showBlockingWaitOverlayWithText("Connecting...")
        self.view.superview!.backgroundColor = UIColor.lightGray
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch Access Token form the server and initialize IPM Client - this assumes you are running
        // the PHP starter app on your local machine, as instructed in the quick start guide
        let deviceId = UUID().uuidString
        let urlString = "http://localhost:8000/token.php?device=\(deviceId)"
        
        // Get JSON from server
        let session = URLSession.shared
        let url = URL(string: urlString)//NSURL(string: urlString)
        let request  = URLRequest(url: url!)
        
        // Make HTTP request
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
                    SwiftOverlays.removeAllBlockingOverlays()
                }
            } else {
                print("Error fetching token :\(error)")
                SwiftOverlays.removeAllBlockingOverlays()
            }
        }).resume()
        print("after resume")
        self.tableView?.register(MessageTableViewCell.self, forCellReuseIdentifier: "MessageTableViewCell")
        self.isInverted = false
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.tableView?.estimatedRowHeight = 66.0
        self.tableView?.separatorStyle = .none
        
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
    
    func loadMessages() {
        if self.messages.count == 0 {
            SwiftOverlays.showBlockingWaitOverlayWithText("Loading Messages...")
        }
        self.messages.removeAll()
        self.generalChannel?.messages.getLastWithCount(30, completion: { (result, newMessages) in
            print(String(describing: result))
            let messages = newMessages
            self.addMessages(messages: messages!)
        })
    }
    
    func addMessages(messages: [TWMMessage]) {
        self.messages.append(contentsOf: messages)
        self.messages.sort { $1.timestamp > $0.timestamp }
        
        DispatchQueue.main.async {
            () -> Void in
            self.tableView?.reloadData()
            SwiftOverlays.removeAllBlockingOverlays()
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




var ctrl = ChatViewController()
// ctrl.viewDidLoad() //Not needed
PlaygroundPage.current.liveView = UINavigationController(rootViewController: ctrl)


//XCPShowView(identifier: "Playground VC", view: ctrl.view)



//
//let requestURL = URL(string: signedURLTest)
//let data = try? Data(contentsOf: requestURL!)


//    SignedRequestsHelper helper;
//    
//    try {
//    helper = SignedRequestsHelper.getInstance(ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_KEY);
//    } catch (Exception e) {
//    e.printStackTrace();
//    return;
//    }
//    
//    String requestUrl = null;
//    
//    Map<String, String> params = new HashMap<String, String>();
//    
//    params.put("Service", "AWSECommerceService");
//    params.put("Operation", "ItemSearch");
//    params.put("AWSAccessKeyId", "");
//    params.put("AssociateTag", "");
//    params.put("SearchIndex", "All");
//    params.put("Keywords", "paper towels");
//    params.put("ResponseGroup", "Images,ItemAttributes,Offers");
//    
//    requestUrl = helper.sign(params);
//    
//    System.out.println("Signed URL: \"" + requestUrl + "\"");

 
