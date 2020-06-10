//
//  DetailViewModel.swift
//  Memo
//
//  Created by Soso on 2020/06/10.
//  Copyright © 2020 Soso. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class DetailViewModel {
    let disposeBag = DisposeBag()
    let memoService: MemoServiceType

    // inputs
    let titleText: BehaviorSubject<String>
    let contentText: BehaviorSubject<String>
    let updateTask = PublishSubject<Int>()
    let deleteTask = PublishSubject<Int>()
    let tapUpdate = PublishSubject<Void>()
    let tapDelete = PublishSubject<Void>()

    // outputs
    let isButtonUpdateEnabled = BehaviorSubject(value: true)
    let shouldPop = PublishSubject<Bool>()

    init(memoService: MemoServiceType, memo: Memo) {
        self.memoService = memoService

        let titleText = BehaviorSubject(value: memo.title)
        self.titleText = titleText

        let contentText = BehaviorSubject(value: memo.text ?? "")
        self.contentText = contentText

        let isTitleValid = titleText
            .distinctUntilChanged()
            .map { !$0.isEmpty }

        isTitleValid
            .bind(to: isButtonUpdateEnabled)
            .disposed(by: disposeBag)

        let titleContent = Observable.combineLatest(titleText, contentText) { ($0, $1) }

        tapUpdate
            .withLatestFrom(titleContent)
            .flatMap { memoService.updateMemo(memo: memo, title: $0, text: $1) }
            .map { _ in true }
            .subscribe(onNext: shouldPop.onNext)
            .disposed(by: disposeBag)

        tapDelete
            .flatMap { memoService.deleteMemo(memo: memo) }
            .map { _ in true }
            .subscribe(onNext: shouldPop.onNext)
            .disposed(by: disposeBag)

    }
}
