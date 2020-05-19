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
    
    // inputs
    var titleText: BehaviorSubject<String>
    var addTask = PublishSubject<Void>()
    var deleteTask = PublishSubject<Int>()
    
    // outputs
    var isButtonAddEnabled = BehaviorSubject(value: false)
    var memos: BehaviorRelay<[String]>
    
    init() {
        let titleText = BehaviorSubject(value: "")
        self.titleText = titleText
        let memos = BehaviorRelay<[String]>(value: [])
        self.memos = memos

        titleText
            .distinctUntilChanged()
            .map { !$0.isEmpty }
            .bind(to: isButtonAddEnabled)
            .disposed(by: disposeBag)
        
        addTask
            .withLatestFrom(titleText)
            .filter { $0.isEmpty == false }
            .do(onNext: { [weak self] _ in self?.titleText.onNext("") })
            .map { [$0] + memos.value }
            .subscribe(onNext: memos.accept)
            .disposed(by: disposeBag)
        
        deleteTask
            .map({ index in
                var current = memos.value
                current.remove(at: index)
                return current
            }).subscribe(onNext: memos.accept)
            .disposed(by: disposeBag)
    }
}
