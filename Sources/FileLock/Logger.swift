//
//  Logger.swift
//  FileLock
//
//  Created by Thibaud David on 11/10/2024.
//


public typealias Logger = (_ caller: Any?, LogLevel, String) -> Void
public enum LogLevel {
    case error, warning, debug, trace
}
