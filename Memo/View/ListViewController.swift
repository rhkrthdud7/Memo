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
import RxDataSources

import SnapKit
import SwiftyColor
import Then

typealias MemoListSection = AnimatableSectionModel<Int, Memo>

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
    
    lazy var dataSource: RxTableViewSectionedAnimatedDataSource<MemoListSection> = {
        let dataSource = RxTableViewSectionedAnimatedDataSource<MemoListSection>(configureCell: { [unowned self] _, tableView, indexPath, memo -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: self.identifier, for: indexPath)
            cell.textLabel?.text = memo.title
            cell.detailTextLabel?.text = memo.text
            cell.selectionStyle = .none
            return cell
        })
        dataSource.canEditRowAtIndexPath = { _, _ in true }
        return dataSource
    }()
    
    
    init(viewModel: ListViewModel) {
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
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view)
        }
    }
    
    func setupBindings() {
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
        
        tableView.rx.modelSelected(Memo.self)
            .subscribe(onNext: { [weak self] memo in
                guard let self = self else { return }
                let viewModel = DetailViewModel(memoService: self.viewModel.memoService, memo: memo)
                let detailViewController = DetailViewController(viewModel: viewModel)
                self.navigationController?.pushViewController(detailViewController, animated: true)
            }).disposed(by: disposeBag)
        
        viewModel.titleText
            .bind(to: textField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.isButtonAddEnabled
            .distinctUntilChanged()
            .bind(to: buttonAdd.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.memos
            .map { [MemoListSection(model: 0, items: $0)] }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                guard let self = self else { return }
                let bottom = max(height - self.view.safeAreaInsets.bottom, 0)
                self.tableView.contentInset.bottom = bottom
                self.tableView.verticalScrollIndicatorInsets.bottom = bottom
            }).disposed(by: disposeBag)
    }

}
