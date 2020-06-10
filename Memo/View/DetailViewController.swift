//
//  DetailViewController.swift
//  Memo
//
//  Created by Soso on 2020/06/10.
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

class DetailViewController: UIViewController {
    let disposeBag = DisposeBag()
    let viewModel: DetailViewModel

    private enum Metric {
        static let textFieldOffsetViewFrame = CGRect(x: 0, y: 0, width: 5, height: 0)
    }

    let scrollView = UIScrollView().then {
        $0.backgroundColor = .clear
    }

    let textField = UITextField().then {
        $0.backgroundColor = .quaternaryLabel
        $0.leftView = UIView(frame: Metric.textFieldOffsetViewFrame)
        $0.leftViewMode = .always
        $0.clearButtonMode = .whileEditing
        $0.returnKeyType = .next
        $0.font = UIFont.systemFont(ofSize: 17)
    }
    let textView = UITextView().then {
        $0.backgroundColor = .quaternaryLabel
        $0.font = UIFont.systemFont(ofSize: 17)
    }

    let buttonUpdate = UIButton(type: .system).then {
        $0.layer.cornerRadius = 15
        $0.backgroundColor = $0.tintColor
        $0.setTitle("저장", for: .normal)
        $0.setTitleColor(.white, for: .normal)
    }
    let buttonDelete = UIButton(type: .system).then {
        $0.tintColor = .red
        $0.layer.cornerRadius = 15
        $0.backgroundColor = $0.tintColor
        $0.setTitle("삭제", for: .normal)
        $0.setTitleColor(.white, for: .normal)
    }

    init(viewModel: DetailViewModel) {
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

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        let viewContent = UIView().then {
            $0.backgroundColor = .clear
        }
        scrollView.addSubview(viewContent)
        viewContent.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        let labelTitle = UILabel().then {
            $0.text = "제목"
        }
        viewContent.addSubview(labelTitle)
        labelTitle.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
        }
        viewContent.addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalTo(labelTitle.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        let labelContent = UILabel().then {
            $0.text = "내용"
        }
        viewContent.addSubview(labelContent)
        labelContent.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(16)
        }
        viewContent.addSubview(textView)
        textView.snp.makeConstraints {
            $0.top.equalTo(labelContent.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(300)
        }

        let stackViewButton = UIStackView().then {
            $0.axis = .horizontal
            $0.alignment = .fill
            $0.distribution = .fillEqually
            $0.spacing = 8
            $0.addArrangedSubview(buttonUpdate)
            $0.addArrangedSubview(buttonDelete)
        }
        viewContent.addSubview(stackViewButton)
        stackViewButton.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

    }

    func setupBindings() {
        textField.rx.controlEvent(.editingChanged)
            .withLatestFrom(textField.rx.text.orEmpty)
            .bind(to: viewModel.titleText)
            .disposed(by: disposeBag)

        textView.rx.text.orEmpty
            .skip(1)
            .bind(to: viewModel.contentText)
            .disposed(by: disposeBag)

        buttonUpdate.rx.tap
            .bind(to: viewModel.tapUpdate)
            .disposed(by: disposeBag)

        buttonDelete.rx.tap
            .bind(to: viewModel.tapDelete)
            .disposed(by: disposeBag)

        viewModel.titleText
            .take(1)
            .bind(to: textField.rx.text)
            .disposed(by: disposeBag)

        viewModel.contentText
            .take(1)
            .bind(to: textView.rx.text)
            .disposed(by: disposeBag)

        viewModel.isButtonUpdateEnabled
            .do(onNext: { [weak self] isEnabled in
                guard let self = self else { return }
                if isEnabled {
                    self.buttonUpdate.backgroundColor = self.buttonUpdate.tintColor
                } else {
                    self.buttonUpdate.backgroundColor = .lightGray
                }
            })
            .bind(to: buttonUpdate.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.shouldPop
            .subscribe(onNext: { [weak self] shouldPop in
                self?.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)

        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                guard let self = self else { return }
                let bottom = max(height - self.view.safeAreaInsets.bottom, 0)
                self.scrollView.contentInset.bottom = bottom
                self.scrollView.verticalScrollIndicatorInsets.bottom = bottom
            }).disposed(by: disposeBag)
    }


}
