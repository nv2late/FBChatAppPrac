//
//  ChatViewController.swift
//  FBChatAppPrac
//
//  Created by Reese on 2022/07/15.
//

import UIKit
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    // The kind of message and its underlying kind
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    
    private let selfSender = Sender(photoURL: "",
                                    senderId: "1",
                                    displayName: "Anakin Skywalker")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello World message")))
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello World message. Hello World message. Hello World message")))
        
        view.backgroundColor = .blue
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    // who the current sender is
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // section 쓰는 이유: messagekit framework uses sections to seperate every single message
        // Why? 메시지는 여러 조각으로 나뉘어져 있음(메시지 아래에 시간 표시나, 다른 데이터 등). 그래서 단일 섹션으로 구현하는게 좋다.
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
