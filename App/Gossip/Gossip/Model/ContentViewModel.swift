import Foundation
import SwiftUI
import Combine

enum ViewMode {
    case feed
    case create
    case saved
    case settings
}

class ContentViewModel: ObservableObject{
    private var coreDataViewModel: CoreDataViewModel = CoreDataViewModel()
    private var bluetoothManager: BluetoothManager = BluetoothManager()
    var cancellableMessages: AnyCancellable?
    var cancellableReady: AnyCancellable?
    
    //ordered on pickuptime
    @Published private(set) var savedMessages: [Message] = []
    @Published private(set) var feedMessages: [Message] = []
    @Published private(set) var viewMode: ViewMode = ViewMode.feed
    
    init(){
        //
        savedMessages = getOrderedSavedMessages()
        cancellableMessages = bluetoothManager.$messages.sink { messages in
            self.feedMessages = Array(messages).sorted(by: {m1,m2 in
                return m1.pickupTime < m2.pickupTime
            })
        }
        cancellableReady = bluetoothManager.$initialized_peripheral.sink { ready in
            if ready {self.bluetoothManager.cycle()}
        }
    }
    
    private func getOrderedSavedMessages() -> [Message] {
        return coreDataViewModel.fetchMessages().enumerated().map {_,message in
            return Message(messageModel: message)
        }.sorted(by: {m1,m2 in
            return m1.pickupTime < m2.pickupTime
        })
    }
    
    private func updateSavedMessages(){
        savedMessages = getOrderedSavedMessages()
    }
    
    func setViewMode(viewMode: ViewMode){
        /* if observer logic becomes more complex, this might  be prefereable?
         switch viewMode {
         case ViewMode.create:
         self.viewMode = ViewMode.create
         
         case ViewMode.feed:
         self.viewMode = ViewMode.feed
         
         case ViewMode.saved:
         updateSavedMessages()
         self.viewMode = ViewMode.saved
         
         case ViewMode.settings:
         self.viewMode = ViewMode.settings
         
         }*/
        
        if(viewMode == ViewMode.saved){
            updateSavedMessages()
        }
        
        self.viewMode = viewMode
    }
    
    func isSaved(message: Message) -> Bool{
        return savedMessages.contains(message)
    }
    
    //TODO: implement these. Look at existing core data stuff
    func saveMessage(message : Message){
        coreDataViewModel.saveMessage(title: "", content: String(data: message.content, encoding: .utf8)!)
    }
    
    func deleteMessage(message: Message){
        let toRemove = coreDataViewModel
            .fetchMessages()
            .first(where: {$0.content == String(data: message.content, encoding: .utf8)! })
        
        if toRemove != nil {
            coreDataViewModel.deleteMessage(toRemove!)
        }
    }
}
