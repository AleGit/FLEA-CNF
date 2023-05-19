import XCTest
@testable import Base

final class CommandLineTests: ATestCase {
    typealias CL = CommandLine
    func testName() {
        #if os(macOS)
        XCTAssertTrue(CL.name.hasPrefix("/Applications/Xcode"))
        XCTAssertTrue(CL.name.hasSuffix(".app/Contents/Developer/usr/bin/xctest"))
        #else
        XCTAssertTrue(CL.name.hasSuffix("FLEA-CNFPackageTests.xctest"))
        #endif
    }

    /**
    - CLion
        - ["-XCTest", "BaseTests.CommandLineTests/testParameters", "/Users/alm/UIBK/FLEA5/.build/debug/FLEA5PackageTests.xctest"]
        - ["-XCTest", "BaseTests.CommandLineTests", "/Users/alm/UIBK/FLEA5/.build/debug/FLEA5PackageTests.xctest"]
        - ["-XCTest", "BaseTests,BaseTests.StringTests,BaseTests.SyslogTests,BaseTests.ATestCase,BaseTests.SequenceTests,BaseTests.TimeTests,BaseTests.CollectionTests,BaseTests.CommandLineTests", "/Users/alm/UIBK/FLEA5/.build/debug/FLEA5PackageTests.xctest"]


    - swift test
      ["/Users/alm/UIBK/FLEA5/.build/x86_64-apple-macosx/debug/FLEA5PackageTests.xctest"]
    - swift test --filter BaseTests
      ["-XCTest", "BaseTests.CommandLineTests/testParameters", "/Users/alm/UIBK/FLEA5/.build/x86_64-apple-macosx/debug/FLEA5PackageTests.xctest"]

    */

    func testParameters() {
        print("πars", CL.parameters.count, CL.parameters)

        #if os(macOS)

        switch CL.parameters.count {
        case 3:
            XCTAssertEqual("-XCTest", CL.parameters.first)
            XCTAssertTrue(CL.parameters[1].contains("BaseTests.CommandLineTests"))
            fallthrough
        case 1:
            XCTAssertTrue(CL.parameters.last?.hasSuffix("/FLEA-CNFPackageTests.xctest") ?? false, CL.parameters.last ?? "n/a")
        default:
            XCTFail("\(CL.parameters.count) parameters.")
        }
        #endif
    }

    func testOptions() {
        print("πars", CL.parameters.count, CL.parameters)
        print("οpts", CL.options.count, CL.options)

        XCTAssertNotNil(CL.options[.problems])

    }

    func testInfoTopicSet() {
        XCTAssertEqual("header", CommandLine.InfoTopicSet.header.info)
        XCTAssertEqual("options", CommandLine.InfoTopicSet.options.info)
        XCTAssertEqual("shorts", CommandLine.InfoTopicSet.shorts.info)
        XCTAssertEqual("variables", CommandLine.InfoTopicSet.variables.info)
        XCTAssertEqual("topics", CommandLine.InfoTopicSet.topics.info)

        XCTAssertEqual("header options shorts variables topics", CommandLine.InfoTopicSet.all.info)
    }
}