//
//  DependencyTests.swift
//  UnioTests
//
//  Created by marty-suzuki on 2019/03/22.
//  Copyright © 2019 tv.abema. All rights reserved.
//

import RxRelay
import RxSwift
import XCTest
@testable import Unio

final class DependencyTests: XCTestCase {

    private var dependency: Dependency!

    override func setUp() {

        dependency = Dependency()
    }

    func testInput_observable_relay() {

        let expected = "test-relay"
        let testTarget = dependency.testTarget
        let stack = BehaviorRelay<String?>(value: nil)

        #if swift(>=5.1)
        let disposable = testTarget.inputObservables.relay
            .bind(to: stack)
        #else
        let disposable = testTarget.inputObservable(for: \.relay)
            .bind(to: stack)
        #endif

        dependency.inputRelay.accept(expected)

        XCTAssertEqual(stack.value, expected)

        disposable.dispose()
    }

    func testInput_observable_subject() {

        let expected = "test-subject"
        let testTarget = dependency.testTarget
        let stack = BehaviorRelay<String?>(value: nil)

        #if swift(>=5.1)
        let disposable = testTarget.inputObservables.subject
            .bind(to: stack)
        #else
        let disposable = testTarget.inputObservable(for: \.subject)
            .bind(to: stack)
        #endif

        dependency.inputSubject.onNext(expected)

        XCTAssertEqual(stack.value, expected)

        disposable.dispose()
    }

    func testProperty_ValueAccessible() {

        let expected = "test-ValueAccessible"
        let testTarget = dependency.testTarget

        #if swift(>=5.1)
        let property = testTarget.properties(from: dependency.output).relay
        #else
        let property = testTarget.property(from: dependency.output, for: \.relay)
        #endif

        dependency.outputRelay.accept(expected)

        XCTAssertEqual(property.value, expected)
    }

    func testProperty_ThrowableValueAccessible() {

        let expected = "test-ThrowableValueAccessible"
        let testTarget = dependency.testTarget

        #if swift(>=5.1)
        let property = testTarget.properties(from: dependency.output).subject
        #else
        let property = testTarget.property(from: dependency.output, for: \.subject)
        #endif

        dependency.outputSubject.onNext(expected)

        XCTAssertEqual(try property.throwableValue(), expected)
    }

}

extension DependencyTests {

    private struct Input: InputType {
        let relay: PublishRelay<String>
        let subject: PublishSubject<String>
    }

    private struct Output: OutputType {
        let subject: BehaviorSubject<String?>
        let relay: BehaviorRelay<String?>
    }

    private struct Dependency {

        let testTarget: Unio.Dependency<Input, NoState, NoExtra>

        let output: Relay<Output>
        let inputSubject = PublishSubject<String>()
        let inputRelay = PublishRelay<String>()

        let outputSubject = BehaviorSubject<String?>(value: nil)
        let outputRelay = BehaviorRelay<String?>(value: nil)

        init() {
            let input = Input(relay: inputRelay, subject: inputSubject)
            self.output = Relay(Output(subject: outputSubject, relay: outputRelay))
            self.testTarget = Unio.Dependency(input: input, state: .init(), extra: .init())
        }
    }
}
