import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ChatModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - ChatSession Operations
    
    func createChatSession(id: String, email: String, title: String) -> ChatSession {
        let session = ChatSession(context: context)
        session.id = id
        session.email = email
        session.title = title
        session.time = Date()
        saveContext()
        return session
    }
    
    func fetchChatSessions(for email: String) -> [ChatSession] {
        let request: NSFetchRequest<ChatSession> = ChatSession.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching chat sessions: \(error)")
            return []
        }
    }
    
    // MARK: - ChatMessage Operations
    
    private func getNextMessageId(for sessionId: String) -> Int64 {
        let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "session.id == %@", sessionId)
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let messages = try context.fetch(request)
            return (messages.first?.id ?? 0) + 1
        } catch {
            print("Error fetching max message id: \(error)")
            return 1
        }
    }
    
    func createChatMessage(content: String, isUser: Bool, session: ChatSession) -> ChatMessage {
        let message = ChatMessage(context: context)
        message.id = getNextMessageId(for: session.id!)  // 手动设置自增ID
        message.content = content
        message.isUser = isUser
        message.time = Date()
        message.session = session
        saveContext()
        return message
    }
    
    func fetchChatMessages(for sessionId: String) -> [ChatMessage] {
        let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "session.id == %@", sessionId)
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching chat messages: \(error)")
            return []
        }
    }
    
    func deleteChatSession(_ session: ChatSession) {
        context.delete(session)
        saveContext()
    }
    
    func deleteAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        entities.forEach { entity in
            if let name = entity.name {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: name)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
                } catch {
                    print("Error deleting all data: \(error)")
                }
            }
        }
    }
} 
