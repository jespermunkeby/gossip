import Foundation
import CoreData
import SwiftUI

class CoreDataViewModel: ObservableObject {
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "MessageModel")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }


    func saveMessage(title: String, content: String, time: Date, latitude: Double, longitude: Double) {
        let context = container.viewContext
        let message = MessageModel(context: context)
        message.title = title
        message.content = content
        message.timestamp = time
        message.latitude = latitude
        message.longitude = longitude

        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    // Example function to fetch all messages
    func fetchMessages() -> [MessageModel] {
        let request: NSFetchRequest<MessageModel> = MessageModel.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let messages = try container.viewContext.fetch(request)
            return messages
        } catch {
            print("Failed to fetch messages: \(error)")
            return []
        }
    }

    // Example function to delete a message
    func deleteMessage(_ message: MessageModel) {
        let context = container.viewContext
        context.delete(message)

        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
