//
//  MemoService.swift
//  Memo
//
//  Created by Soso on 2020/05/25.
//  Copyright © 2020 Soso. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

enum MemoEvent {
  case create(Memo)
  case update(Memo)
  case delete(String)
}

protocol MemoServiceType {
    var event: PublishSubject<MemoEvent> { get }
    func fetchMemo() -> Observable<[Memo]>
    func createMemo(title: String, text: String?) -> Observable<Memo>
    func deleteMemo(memo: Memo) -> Observable<Memo>
}

class MemoService: MemoServiceType {
    let appDelegate: AppDelegate
    let context: NSManagedObjectContext
    
    let entityName: String = "Memo"

    let event = PublishSubject<MemoEvent>()
    
    init(delegate: AppDelegate) {
        appDelegate = delegate
        context = delegate.persistentContainer.viewContext
    }
    
    func fetchMemo() -> Observable<[Memo]> {
        var memos: [Memo] = []
        do {
            memos = try context.fetch(Memo.fetchRequest()) as! [Memo]
        } catch {
            NSLog(error.localizedDescription)
        }
        
        return .just(memos.sorted(by: { $0.createdAt > $1.createdAt }))
    }
    
    func createMemo(title: String, text: String?) -> Observable<Memo> {
        let date = Date()
        let memo = Memo(context: context)
        memo.setValue(UUID().uuidString, forKey: "id")
        memo.id = UUID().uuidString
        memo.title = title
        memo.text = text
        memo.createdAt = date
        memo.modifiedAt = date
        
        do {
            try context.save()
        } catch {
            NSLog(error.localizedDescription)
        }
        
        return Observable.just(memo)
            .do(onNext: { _ in self.event.onNext(.create(memo)) })
    }
    
    func deleteMemo(memo: Memo) -> Observable<Memo> {
        context.delete(memo)
        
        do {
            try context.save()
        } catch {
            NSLog(error.localizedDescription)
        }
        
        return Observable.just(memo)
            .do(onNext: { _ in self.event.onNext(.delete(memo.id)) })
    }
    
}
