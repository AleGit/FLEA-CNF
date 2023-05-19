#if os(OSX)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

import Foundation
import XCTest
@testable import Base

class SyslogTests: ATestCase {
    func testError() {
        XCTAssertEqual(Syslog.minimalLogLevel, .error)

        #if os(macOS)
        XCTAssertEqual(Syslog.maximalLogLevel, .debug)
        XCTAssertEqual(Syslog.defaultLogLevel, .info)
        XCTAssertEqual(Syslog.logLevel(), .error)
        #else 
        XCTAssertEqual(Syslog.maximalLogLevel, .notice)
        XCTAssertEqual(Syslog.defaultLogLevel, .warning)
        XCTAssertEqual(Syslog.logLevel(), .warning)
        #endif
    }

    func testWarning() {
        XCTAssertEqual(Syslog.minimalLogLevel, .error)
        #if os(macOS)
        XCTAssertEqual(Syslog.maximalLogLevel, .debug)
        XCTAssertEqual(Syslog.defaultLogLevel, .info)
        #else
        XCTAssertEqual(Syslog.maximalLogLevel, .notice)
        XCTAssertEqual(Syslog.defaultLogLevel, .warning)
        #endif
        XCTAssertEqual(Syslog.logLevel(), .warning)
    }

    func testMultiple() {
        XCTAssertEqual(Syslog.minimalLogLevel, .error)
        #if os(macOS)
        XCTAssertEqual(Syslog.maximalLogLevel, .debug)
        XCTAssertEqual(Syslog.defaultLogLevel, .info)
        XCTAssertEqual(Syslog.logLevel(), .info)
        #else 
        XCTAssertEqual(Syslog.maximalLogLevel, .notice)
        XCTAssertEqual(Syslog.defaultLogLevel, .warning)
        XCTAssertEqual(Syslog.logLevel(), .warning)
        #endif


        // create new error and log it
        let newerror = open("/fictitious_file", O_RDONLY, 0) // sets errno to ENOENT

        Syslog.multiple(errcode: newerror) { "min=\(Syslog.minimalLogLevel) max=\(Syslog.maximalLogLevel) default=\(Syslog.defaultLogLevel)" }
    }
}
