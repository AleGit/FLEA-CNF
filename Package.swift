// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/// __Dependency directed down graph:__
/// ```
///         flea -> (swift argument parser)
///            \
///        solver -> CYices, CZ3Api
///       /  /   \
///    z3 yices  tptp -> CTptpParsing
///             /  \
///      parsing  utile
///                  \
///                  base
/// ```
let package: Package = Package(
  name: "FLEA-CNF",
  platforms: [ // platforms are evaluated on Apple platforms only and ignored on Linux platforms
    .macOS(.v12), // support macOS Monterey 12 (2021) and newer macOS Ventura 13 (2022)
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/AleGit/CTptpParsing.git", branch: "develop"),
    .package(url: "https://github.com/AleGit/CYices.git", branch: "develop"),
    .package(url: "https://github.com/AleGit/CZ3API.git", branch: "develop"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.

    .target(module: .base, dependencies: []), 
    // .target(name: "Base", dependencies: []),
    
    .target(module: .utile, dependencies: [.base]),
    .target(module: .tptp, dependencies: [.utile, .parsing]),
    
    .target(module: .solver, dependencies: [.tptp, .yices, .z3]),
    // .target(name: "Solver", dependencies: ["Tptp"]),
    
    .executableTarget(module: .flea, dependencies: [.solver]),
    // .target(module: .flea, dependencies: [.solver, .swiftArgumentParser]),
    // .target(name: "Flea", dependencies: [ "Solver", .product(name: "ArgumentParser", package: "swift-argument-parser")]),

    // implicit test suite names and dependencies

    // .testTarget(module: .swiftLogging),
    // .testTarget(module: .swiftArgumentParser),
    // .testTarget(module: .swiftAlgorithms),
    .testTarget(module: .base),
    .testTarget(module: .utile),
    .testTarget(module: .tptp),
    .testTarget(module: .solver),
    .testTarget(module: .flea)
  ]
)

extension Target {
  /// Since string literals are used multiple times for names and dependencies
  /// we introduce module enum values for all our modules and test suits
  /// for avoiding typos and enabling easier renaming.
  enum Module: String {
    case parsing = "CTptpParsing"
    case yices = "CYices"
    case z3 = "CZ3Api,CZ3API"
    case base = "Base"  // extensions of Foundation and swift standard library
    case utile = "Utile"  // protocols and structs ("abstract data types")
    case tptp = "Tptp"  // parsing and data structures for tptp files
    case solver = "Solver"  // proving with yices and z3
    case flea = "Flea"  // command line program definition
    case swiftLogging = "Logging,swift-log" // not used yet
    case swiftArgumentParser = "ArgumentParser,swift-argument-parser" // not used yet
    case swiftAlgorithms = "Algorithms,swift-algorithms" // not used yet

    /// the name of this module
    var targetName: String {
      assert(self.rawValue.split(separator: ",").count == 1, "\(self) must not be a target")
      return self.rawValue
    }
    /// the name of the test suite for this module
    var testTargetName: String {
      let names = self.rawValue.split(separator: ",").map { String($0) }
      assert(0 < names.count && names.count < 3)
      return names[0] + "Tests"
    }

    /// a dependency on this module (by an other module or test suite)
    var dependency: Dependency {
      let names = self.rawValue.split(separator: ",").map { String($0) }
      assert(0 < names.count && names.count < 3)

      if names.count == 1 {
        return .byName(name: names[0])
      } else {
        return .product(name: names[0], package: names[1])
      }
    }
  }

  /// Factory method that uses module enum values for name and dependencies of a module.
  /// - Parameters:
  ///   - module: the module enum value
  ///   - dependencies: the packages the module is dependent on
  /// - Returns: a target package description
  static func target(module: Module, dependencies: [Module]) -> PackageDescription.Target {
    return .target(name: module.targetName, dependencies: dependencies.map { $0.dependency })
  }

  /// Factory method that uses module enum values for name and dependencies of a module.
  /// - Parameters:
  ///   - module: the module enum value
  ///   - dependencies: the packages the module is dependent on
  /// - Returns: an executable target package description
  static func executableTarget(module: Module, dependencies: [Module]) -> PackageDescription.Target {
    return .executableTarget(name: module.targetName, dependencies: dependencies.map { $0.dependency })
  }

  /// Factory method that uses module enum values for name and dependencies of a test suite.
  /// By default a test suite "FooTests" is created with dependency on module "Foo".
  /// A test suite must not depend on other test suites.
  /// - Parameters:
  ///   - module: the module enum value the test suite is for
  ///   - dependencies: the packages the test suite is dependent on
  /// - Returns: a test target package descriptions
  static func testTarget(module: Module, dependencies: [Module]? = nil) -> PackageDescription.Target {
    guard let dependencies = dependencies else {
      // implicit test suit name, implicit dependency on one module, e.g. FooTests -> [Foo]
      return .testTarget(name: module.testTargetName, dependencies: [module.dependency])
    }
    // implicit test suite name, explicit dependency none, one or more modules, e.g. FooTests -> [Foo, Bar]
    return .testTarget(
      name: module.testTargetName, dependencies: dependencies.map { $0.dependency })
  }
}
