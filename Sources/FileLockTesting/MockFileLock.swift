//
//  File.swift
//
//
//  Created by Benjamin Garrigues on 18/10/2023.
//

import Foundation

/// MocKFileLock doesn't lock anything
public class MockFileLock {
    public var onPerformInLock: ((_ debugInfos: String) -> Void)?
    public func performInLock<T>(debugInfos: String, _ closure: () throws -> T) throws -> T {
        onPerformInLock?(debugInfos)
        return try closure()
    }

    public init(onPerformInLock: ((_ debugInfos: String) -> Void)?) {
        self.onPerformInLock = onPerformInLock
    }
}
