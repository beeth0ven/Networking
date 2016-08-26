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
            .scan(seed) { (element, updation) -> Element in
                switch updation {
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
    case update((Element -> Element))
    case updated(((inout Element) -> Void))
}
