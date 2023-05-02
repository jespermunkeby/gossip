//
//  feedCardViewModel.swift
//  Gossip
//

import SwiftUI

class FeedCardViewModel: ObservableObject {
    @ObservedObject var viewModel: BLEViewModel
    @EnvironmentObject var coreDataViewModel: CoreDataViewModel
    @Published var messages: [FeedCard] = []
    @State private var isShowingSavedMessages = false
    
    init(viewModel: BLEViewModel, coreDataViewModel: CoreDataViewModel, messages: [FeedCard], isShowingSavedMessages: Bool = false) {
        self.viewModel = viewModel
        self.messages = messages
        self.isShowingSavedMessages = isShowingSavedMessages
    }
    
    /*func getmessages(messages: [String]) -> MessageCard{
        ForEach(messages.indices, id: \.self) { index in
            MessageCard(title: "Message \(index + 1) from hub", content: messages[index], action: {
                // Save the message when the "Save" button is tapped
                coreDataViewModel.saveMessage(title: "Message \(index + 1) from hub", content: messages[index])
            })
        }
    }*/
}
