//
//  ListViewController.swift
//  Memo
//
//  Created by Soso on 2020/05/17.
//  Copyright © 2020 Soso. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxGesture
import RxOptional
import RxKeyboard

import SnapKit
import SwiftyColor
import Then

class ListViewController: UIViewController {
    let disposeBag = DisposeBag()
    let viewModel: ListViewModel
    
    let identifier = "UITableViewCell"
    
    private enum Metric {
        static let textFieldOffsetViewFrame = CGRect(x: 0, y: 0, width: 20, height: 0)
    }
    
    let textField = UITextField().then {
        $0.placeholder = "태스크를 추가 해주세요"
        $0.leftView = UIView(frame: Metric.textFieldOffsetViewFrame)
        $0.leftViewMode = .always
        $0.clearButtonMode = .whileEditing
        $0.returnKeyType = .done
    }
    let buttonAdd = UIButton(type: .system).then {
        $0.setTitle("추가", for: .normal)
    }
    lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
    }
    
    init(viewModel: ListViewModel = ListViewModel()) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupBindings()
    }
    
    func setupViews() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(50)
        }
        
        view.addSubview(buttonAdd)
        buttonAdd.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(textField.snp.trailing)
            $0.bottom.equalTo(textField)
            $0.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.width.equalTo(70)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func setupBindings() {
        view.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [unowned self] gesture in
                self.textField.resignFirstResponder()
            }).disposed(by: disposeBag)
        
        textField.rx.controlEvent(.editingChanged)
            .withLatestFrom(textField.rx.text)
            .filterNil()
            .bind(to: viewModel.titleText)
            .disposed(by: disposeBag)
        
        Observable.of(
            buttonAdd.rx.controlEvent(.touchUpInside),
            textField.rx.controlEvent(.editingDidEndOnExit)).merge()
            .bind(to: viewModel.addTask)
            .disposed(by: disposeBag)
        
        tableView.rx.itemDeleted
            .map { $0.row }
            .bind(to: viewModel.deleteTask)
            .disposed(by: disposeBag)
        
        viewModel.titleText
            .bind(to: textField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.isButtonAddEnabled
            .distinctUntilChanged()
            .bind(to: buttonAdd.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.memos
            .bind(to: tableView.rx.items(cellIdentifier: identifier, cellType: UITableViewCell.self)) { row, element, cell in
                cell.textLabel?.text = element
            }.disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                self?.tableView.contentInset.bottom = height
                self?.tableView.verticalScrollIndicatorInsets.bottom = height
            }).disposed(by: disposeBag)
    }

}
