//
//  ListViewModel.swift
//  Memo
//
//  Created by Soso on 2020/05/18.
//  Copyright © 2020 Soso. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class ListViewModel {
    let disposeBag = DisposeBag()
    let memoService: MemoServiceType
    
    // inputs
    var titleText: BehaviorSubject<String>
    var addTask = PublishSubject<Void>()
    var deleteTask = PublishSubject<Int>()
    
    // outputs
    var isButtonAddEnabled = BehaviorSubject(value: false)
    var memos: BehaviorRelay<[Memo]>
    
    init(memoService: MemoServiceType) {
        self.memoService = memoService
        
        let titleText = BehaviorSubject(value: "")
        self.titleText = titleText
        let memos = BehaviorRelay<[Memo]>(value: [])
        self.memos = memos
        
        memoService.event
            .subscribe(onNext: { event in
                var newMemos = memos.value
                switch event {
                case .create(let memo):
                    memos.accept([memo] + newMemos)
                case .update(let memo):
                    if let index = newMemos.firstIndex(of: memo) {
                        newMemos[index] = memo
                        memos.accept(newMemos)
                    }
                case .delete(let id):
                    newMemos.removeAll(where: { $0.id == id })
                    memos.accept(newMemos)
                }
            }).disposed(by: disposeBag)
        
        memoService.fetchMemo()
            .take(1)
            .subscribe(onNext: memos.accept)
            .disposed(by: disposeBag)

        titleText
            .distinctUntilChanged()
            .map { !$0.isEmpty }
            .bind(to: isButtonAddEnabled)
            .disposed(by: disposeBag)
        
        addTask
            .withLatestFrom(titleText)
            .filter { $0.isEmpty == false }
            .do(onNext: { _ in titleText.onNext("") })
            .flatMap { memoService.createMemo(title: $0, text: nil) }
            .map { [$0] + memos.value }
            .subscribe(onNext: { memo in
                
            }).disposed(by: disposeBag)
        
        deleteTask
            .map { memos.value[$0] }
            .flatMap(memoService.deleteMemo)
            .subscribe(onNext: { memo in
                
            }).disposed(by: disposeBag)
        
    }
}
