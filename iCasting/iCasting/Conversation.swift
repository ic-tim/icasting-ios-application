//
//  Negotiation.swift
//  iCasting
//
//  Created by Tim van Steenoven on 06/05/15.
//  Copyright (c) 2015 T. van Steenoven. All rights reserved.
//

import Foundation

typealias JSONResponeType = (request: NSURLRequest, response: NSURLResponse?, json:AnyObject?, error:NSError?)->()
typealias MessageCommunicationCallBack = (error: ICErrorInfo?)->()



protocol ContractState {
    func hasBothAccepted() -> Bool
}

class ContractAcceptedState: ContractState {
   
    func hasBothAccepted() -> Bool {
        return true
    }
}

class ContractUnacceptedState: ContractState {

    func hasBothAccepted() -> Bool {
        return false
    }
}



struct ConversationToken : Printable {
    
    let token: String
    let client: String
    let url: String
    var description: String {
        return "token: \(token) client: \(client) url: \(url)"
    }
}





class Conversation: NSObject {
    
    private var contractState: ContractState?
    
//    var contractBothAccepted: Bool? {
//        return contractState.hasBothAccepted()
//    }
    
    let matchID: String
    let messageList: MessageListExtractor = MessageListExtractor()
    var socketCommunicationHandler: SocketCommunicationHandler?

    
    dynamic var incommingUser: Bool = false // Indicates whether the chat partner of the client is available
    dynamic var authenticated: Bool = false // Indicates whether the client user has been authenticated by the socket server
    
    var messages: [Message] {
        return messageList.list
    }
    
    private var conversationToken: ConversationToken?

    init(matchID:String) {
        self.matchID = matchID
    }
}






// The extension adds responsibilities for communicating with a socket library, the list below specifies what the extension does:
// it creates the socket with the conversation token and sets the delegate
// It creates handlers for the socket to receive feedback if specific things are happening, it is similar to the command pattern
// It handles actions according to feedback

extension Conversation : SocketCommunicationHandlerDelegate {
    
    
    private func createSocketCommunicationHandler() {
        
        self.socketCommunicationHandler = SocketCommunicationHandler(conversationToken: self.conversationToken!.token)
        self.socketCommunicationHandler?.delegate = self
    }
    

    // MARK: Socket communication handler delegate
    
    func handlersForSocketListeners() -> SocketHandlers {
        
        
        
        var handlers: SocketHandlers = SocketHandlers()
        
        handlers.authenticated = { data in
            
            println("--- Conversation: AUTHENTICATED")
            
            // This should be the moment that the user can start typing and receiving messages
            self.authenticated = true
        }
        
        handlers.userjoined = { data in
            
            if let d = data {
                self.decideUserPresent(d, present: true)
            }
        }
        
        handlers.userleft = { data in
            
            if let d = data {
                self.decideUserPresent(d, present: false)
            }
        }
        
        handlers.receivedMessage = { data in
            
            println("--- Conversation: RECIEVED MESSAGE")
            if let d = data {
                
                let factory = SocketMessageFactory()
                let message = factory.createNormalMessage(d)
                self.messageList.addItem(message)
                
            }
            
            // TODO: Handle error message, for when message == nil
        }
        
        handlers.receivedOffer = { data in
         
            println("--- Conversation: RECIEVED OFFER")
            if let d = data {
            
                self.messageList.addOffer(fromArray: d)
                
            }
            
        }

        return handlers
    }
    
    
    private func decideUserPresent(data: NSArray, present: Bool) {
        let userID = data[0] as! String
        let role = Role.getRole(userID)
        if role == Role.Incomming {
            self.incommingUser = present
        }
    }
    
}





protocol MessageCommunicationProtocol {
    
    func sendMessage(text: String, callBack: MessageCommunicationCallBack)
    func acceptOffer(message: Message, callBack: MessageCommunicationCallBack)
    func rejectOffer(message: Message, callBack: MessageCommunicationCallBack)
}





extension Conversation: MessageCommunicationProtocol {
    

    func sendMessage(text: String, callBack: MessageCommunicationCallBack) {
     
        let m: Message = Message(id: "", owner: Auth.auth.user_id!, role: Role.Outgoing, type: TextType.Text)
        m.body = text


        self.socketCommunicationHandler?.sendMessage(m.body!, acknowledged: { (data) -> () in

            println(data)

            self.messageList.addItem(m)

            //return //String error	String message_id
            
        })
    }
    
    
    func acceptOffer(message: Message, callBack: MessageCommunicationCallBack) {

        self.socketCommunicationHandler?.acceptOffer(message.id, acknowledged: { (data) -> () in
            
            if let d = data {
                let error: ICErrorInfo? = self.decideOfferAcceptRejection(d, withMessageToUpdate: message)
                callBack(error: error)
            }
        })
    }
    
    
    func rejectOffer(message: Message, callBack: MessageCommunicationCallBack) {
        
        self.socketCommunicationHandler?.rejectOffer(message.id, acknowledged: { (data) -> () in
            
            if let d = data {
                let error: ICErrorInfo? = self.decideOfferAcceptRejection(d, withMessageToUpdate: message)
                callBack(error: error)
            }
        })
    }
    
    
    private func decideOfferAcceptRejection(data: NSArray, withMessageToUpdate message: Message) -> ICErrorInfo? {
    
        let error: ICErrorInfo? = ICError(string: data[0] as? String).getErrors()
        if error == nil {
            var accepted: Bool? = (data[1] as! Int).toBool()
            var byWho: [String:Int] = (data[2] as! [String:Int])
            var hasAcceptTalent = (byWho["acceptTalent"] ?? 0).toBool()
            message.offer!.accepted = hasAcceptTalent
        }
        return error
    }
}







extension Conversation : ModelRequest {
    
    func get(callBack: RequestClosure) {
        
        // This is a two step request, first get the conversation, and for instant sending and receiving messages, we need a conversation token
        
        let url: String = APIMatch.MatchConversation(self.matchID).value
        let access_token: AnyObject = Auth.auth.access_token as! AnyObject
        let params: [String : AnyObject] = ["access_token":access_token]
        
        request(Method.GET, url, parameters: params, encoding: ParameterEncoding.URL).responseJSON() { (request, response, json, error) -> Void in
                
            // Network or general errors?
            if let errors = ICError(error: error).getErrors() {
                callBack(failure: errors)
            }
            
            // No network errors, extract json
            if let _json: AnyObject = json {
                
                let messagesJSON = JSON(_json)
                
                // API Errors?
                if let errors = ICError(json: messagesJSON).getErrors() {
                    println(error)
                    callBack(failure: errors)
                    return
                }
                
                
                // There are no errors, perform the next request
                self.performRequestConversationToken(messagesJSON, callBack: callBack)

            }
        }
    }
    
    
    private func performRequestConversationToken(messagesJSON: JSON, callBack: RequestClosure) {

        // Request the conversation token
        self.requestConversationToken { (request, response, json, error) -> () in
            
            // Network or general errors?
            if let errors = ICError(error: error).getErrors() {
                callBack(failure: errors)
            }
            
            // No network errors, extract json
            if let _json: AnyObject = json {
                
                let tokenJSON = JSON(_json)
                
                // API Errors?
                if let errors = ICError(json: tokenJSON).getErrors() {
                    println(errors)
                    callBack(failure: errors)
                    return
                }
                
                // There are no errors, get everything to work
                self.setToken(tokenJSON)
                self.messageList.buildList(fromJSON: messagesJSON)
                
                // First, create a socket service, it wil set the delegate as well.
                self.createSocketCommunicationHandler()
                
                // Then let the controller know the first get request is ready, so it can prepare the view and observers.
                callBack(failure: nil)
                
                // After that, add the listeners, this method will call the delegate for the handlers
                self.socketCommunicationHandler?.addListeners()
                
                // If everything is ready, start the socket
                self.socketCommunicationHandler?.start()
                
            }
        }
    }
    
    
    private func requestConversationToken(callBack: JSONResponeType) {
        
        let url: String = APIMatch.MatchConversationToken(self.matchID).value
        let access_token: AnyObject = Auth.auth.access_token as! AnyObject
        let params: [String : AnyObject] = ["access_token":access_token]
        
        request(Method.GET, url, parameters: params, encoding: ParameterEncoding.URL)
            .responseJSON() { (request, response, json, error) -> Void in
                callBack(request: request, response: response, json: json, error: error)
        }
    }
    
    
    private func setToken(json: JSON) {
        
        // TEST: if necessary, test all the values at once before create an instant of conversation token
        let values = [
            json["token"].stringValue,
            json["client"].stringValue,
            json["url"].stringValue]
        conversationToken = ConversationToken(token: values[0], client: values[1], url: values[2])
    }
}

