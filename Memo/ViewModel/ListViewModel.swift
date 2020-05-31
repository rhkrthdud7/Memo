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
            .subscribe(onNext: memos.accept)
            .disposed(by: disposeBag)
        
        deleteTask
            .map { memos.value[$0] }
            .flatMap(memoService.deleteMemo)
            .subscribe(onNext: memos.accept)
            .disposed(by: disposeBag)
        
    }
}
