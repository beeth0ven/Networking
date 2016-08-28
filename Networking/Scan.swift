//
//  Scan.swift
//  Networking
//
//  Created by luojie on 16/8/26.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct Scan<Element> {
    
    typealias Update = ((Element) -> Element)
    typealias Updated = ((inout Element) -> Void)
    
    let update: Variable<Update> = Variable { $0 }
    let updated: Variable<Updated> = Variable { _ in }
    
    let seed: Element
    
    func asDriver() -> Driver<Element> {
        
        let rx_update = update.asDriver().map(Updation.update)
        let rx_updated = updated.asDriver().map(Updation.updated)
        
        return Driver.of(rx_update, rx_updated)
            .merge()
            .skip(1)
            .scan(seed) { (element, updation) -> Element in
                switch updation {
                case .initial:
                    abort()
                case let .update(closure):
                    return closure(element)
                case let .updated(closure):
                    var element = element
                    closure(&element)
                    return element
                }
            }

    }
    
}

private enum Updation<Element> {
    case initial(Element)
    case update((Element -> Element))
    case updated(((inout Element) -> Void))
}

struct FlatScan<Element> {
    
    typealias Update = ((Element) -> Element)
    typealias Updated = ((inout Element) -> Void)
    typealias Seed = (element: Element?, isInitial: Bool)
    
    let update: Variable<Update> = Variable { $0 }
    let updated: Variable<Updated> = Variable { _ in }
    
    let rx_seed: Observable<Element>
    
    func asObservable() -> Observable<Element> {
        
        let rx_initial = rx_seed.map(Updation.initial)
        let rx_update = update.asObservable().map(Updation.update)
        let rx_updated = updated.asObservable().map(Updation.updated)
        
        return Observable.of(rx_initial, rx_update, rx_updated)
            .merge()
            .scan((nil, false), accumulator: { (seed: Seed, updation) in
                var seed = seed
                switch updation {
                case let .initial(element):
                    seed.element = element; seed.isInitial = true
                    
                case let .update(closure):
                    seed.element != nil ? seed.element = closure(seed.element!) : ()
                    
                case let .updated(closure):
                    seed.element != nil ? closure(&seed.element!) : ()
                }
                
                return seed
            })
            .filter { $0.isInitial == true }
            .map { $0.element! }
    }
}

extension Observable {
    
    func asScan() -> FlatScan<Element> {
        return FlatScan(rx_seed: self)
    }
}


