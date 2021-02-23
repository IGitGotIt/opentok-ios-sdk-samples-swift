//
//  ViewController.swift
//  7.Multiparty-UICollectionView
//
//  Created by Roberto Perez Cubero on 17/04/2017.
//  Copyright © 2017 tokbox. All rights reserved.
//

import UIKit
import OpenTok
import Darwin
let operationQueue = OperationQueue.main
// *** Fill the following variables using your own Project info  ***
// ***            https://tokbox.com/account/#/                  ***
// Replace with your OpenTok API key
let kApiKey = "100"
// Replace with your generated session ID
let kSessionId = "2_MX4xMDB-fjE2MTI4MjY0MDkzODl-RXk3VEJjZ3lySHNCaVZ5UDViSDI2Q2pIfn4"
// Replace with your generated token
let kToken = "T1==cGFydG5lcl9pZD0xMDAmc2RrX3ZlcnNpb249dGJwaHAtdjAuOTEuMjAxMS0wNy0wNSZzaWc9MzZmODZkOTIzNTA2NTBhYmJmMTQ3ZmRhNTRmZjAwOGIyNmQwMDdlMzpzZXNzaW9uX2lkPTJfTVg0eE1EQi1makUyTVRJNE1qWTBNRGt6T0RsLVJYazNWRUpqWjNseVNITkNhVlo1VURWaVNESTJRMnBJZm40JmNyZWF0ZV90aW1lPTE2MTI4MzQzMDgmcm9sZT1tb2RlcmF0b3Imbm9uY2U9MTYxMjgzNDMwOC4xMDY0Njk5NDAzMTk2JmV4cGlyZV90aW1lPTE2MTU0MjYzMDg="

class ChatViewController: UICollectionViewController {
    var count = 0
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()

    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()

    var subscribers: [OTSubscriber] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        doConnect()
    }

    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }

        session.connect(withToken: kToken, error: &error)
    }

    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        
       
        
        var error: OTError?
        defer {
            processError(error)
        }
        session.publish(publisher, error: &error)

        collectionView?.reloadData()
    }
   
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        
        count += 1
//        var error: OTError?
//                defer {
//                    processError(error)
//                }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(count)) { [self] in
//                    // your code here
//                    guard let subscriber = OTSubscriber(stream: stream, delegate: self)
//                        else {
//                            print("Error while subscribing")
//                            return
//                    }
//
//                    self.session.subscribe(subscriber, error: &error)
//
//                    self.subscribers.append(subscriber)
//                    //collectionView?.reloadData()
//                }
        
        
        
        var error: OTError?
            defer {
                processError(error)
            }
            operationQueue.maxConcurrentOperationCount = 1
            let blockOperation = BlockOperation { [weak self] in
                guard let subscriber = OTSubscriber(stream: stream, delegate: self)
                    else {
                        print("Error while subscribing")
                        return
                }
                self?.session.subscribe(subscriber, error: &error)
                self?.subscribers.append(subscriber)
              //  self?.collectionView?.reloadData()
            }
            operationQueue.addOperation(blockOperation)
        
        
        
        
//        var error: OTError?
//        defer {
//            processError(error)
//        }
//        guard let subscriber = OTSubscriber(stream: stream, delegate: self)
//            else {
//                print("Error while subscribing")
//                return
//        }
//        session.subscribe(subscriber, error: &error)
//        subscribers.append(subscriber)
//      //  collectionView?.reloadData()
    }

    fileprivate func cleanupSubscriber(_ stream: OTStream) {
        subscribers = subscribers.filter { $0.stream?.streamId != stream.streamId }
        collectionView?.reloadData()
    }

    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            showAlert(errorStr: err.localizedDescription)
        }
    }

    fileprivate func showAlert(errorStr err: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }

    // MARK: - UICollectionView methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subscribers.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath)
        let videoView: UIView? = {
            if (indexPath.row == 0) {
                return publisher.view
            } else {
                let sub = subscribers[indexPath.row - 1]
                return sub.view
            }
        }()

        if let viewToAdd = videoView {
            viewToAdd.frame = cell.bounds
            cell.addSubview(viewToAdd)
        }
        return cell
    }
}

// MARK: - OTSession delegate callbacks
extension ChatViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }

    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        doSubscribe(stream)
    }

    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        cleanupSubscriber(stream)
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
}

// MARK: - OTPublisher delegate callbacks
extension ChatViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
    }

    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
    }

    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ChatViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        
        print("Subscriber connected \(count)")
    }

    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }

    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}
