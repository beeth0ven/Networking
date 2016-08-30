//
//  FlatVariable.swift
//  Networking
//
//  Created by luojie on 16/8/26.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class FlatVariable<Element> {
    
    private let _subject: BehaviorSubject<Element?>
    private var _seed: Observable<Element>
    private var _disposeBag: DisposeBag!

    init(_ seed: Observable<Element>) {
        _seed = seed
        _subject = BehaviorSubject(value: nil)
        refresh()
    }
    
    var value: Element! {
        get {
            do {
               return try _subject.value()
            } catch let error {
                print(error)
                return nil
            }
        }
        set(newValue) {
            _subject.on(.Next(newValue))
        }
    }
    
    func refresh() {
        
        _disposeBag = DisposeBag()
        
        _seed
            .doOnError { [unowned self] in self._subject.onError($0) }
            .subscribeNext { [unowned self] in self._subject.onNext($0) }
            .addDisposableTo(_disposeBag)
    }
    
    func asObservable() -> Observable<Element> {
        return _subject
            .skip(1)
            .map { $0! }
    }
    
}