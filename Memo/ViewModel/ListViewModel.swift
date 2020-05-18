//
//  ListViewModel.swift
//  Memo
//
//  Created by Soso on 2020/05/18.
//  Copyright © 2020 Soso. All rights reserved.
//

import Foundation

import RxSwift

struct ListViewModel {
    let disposeBag = DisposeBag()
    
    // inputs
    var titleText = BehaviorSubject(value: "")
    var addTask = PublishSubject<Void>()
    
    // outputs
    var isButtonAddEnabled = BehaviorSubject(value: false)
    var memos = BehaviorSubject<[String]>(value: [])
    
    init() {
        titleText
            .distinctUntilChanged()
            .map { !$0.isEmpty }
            .bind(to: isButtonAddEnabled)
            .disposed(by: disposeBag)
        
        addTask
            .withLatestFrom(titleText)
            .map { value -> [String] in [value] }
            .subscribe(onNext: memos.onNext)
            .disposed(by: disposeBag)
    }
}
