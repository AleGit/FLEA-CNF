import Base
import Utile
import XCTest

public class ATestCase: XCTestCase {
  /// set up logging once _before_ all tests of a test class
  public override class func setUp() {
    super.setUp()
    Syslog.openLog(options: .console, .pid, .perror, verbosely: false)
  }

  /// teardown logging once _after_ all tests of a test class
  public override class func tearDown() {
    Syslog.closeLog()
    super.tearDown()
  }

  public func testTest() {
    print("*️⃣ ", type(of: self))
  }

  typealias Σ = [Node: Node]

  lazy var x = Node.variable("x")
  lazy var y = Node.variable("y")
  lazy var z = Node.variable("z")
  lazy var a = Node.constant("a")
  lazy var b = Node.constant("b")
  lazy var c = Node.constant("c")

  lazy var fx = Node.function("f", nodes: [x])
  lazy var gx = Node.function("f", nodes: [x])
  lazy var fa = fx * [x: a]
  lazy var fb = fx * [x: b]
  lazy var ga = gx * [x: a]
  lazy var gb = gx * [x: b]

  lazy var fxy = Node.function("f", nodes: [x, y])
  lazy var gxy = Node.function("g", nodes: [x, y])
  lazy var fab = fxy * [x: a, y: b]
  lazy var fax = fxy * [x: a, y: x]
  lazy var fxa = fxy * [y: a]
  lazy var fxx = fxy * [y: x]
  lazy var gxa = gxy * [y: a]
}

extension ATestCase {

  enum `Type` {
    case variable, function, predicate, equation, connective
  }

  final class Node: Utile.Term {
    static var variable = `Type`.variable
    static var function = `Type`.function
    static var predicate = `Type`.predicate
    static var equational = `Type`.equation
    static var connective = `Type`.connective

    let symbol: String
    var key: String { return symbol }
    let type: `Type`
    let nodes: [Node]?

    private init(symbol: String, type: `Type`, nodes: [Node]?) {
      self.symbol = symbol
      self.type = type
      self.nodes = nodes
    }

    static func term(_ type: `Type`, _ symbol: String, nodes: [Node]?) -> Node {
      return Node(symbol: symbol, type: type, nodes: nodes)
    }

    var description: String {
      guard let args = nodes?.map({ $0.description }), args.count > 0 else {
        return symbol
      }

      return "\(symbol)(\(args.joined(separator: ",")))"
    }
  }

  typealias N = ATestCase.Node
}

extension ATestCase.Node {
  typealias N = ATestCase.Node
  typealias Σ = [N: N]

  static var x = N.variable("x")
  static var y = N.variable("y")
  static var a = N.constant("a")
  static var b = N.constant("b")

  static var fx = N.function("f", nodes: [x])
  static var gx = N.function("f", nodes: [x])
  static var fa = fx * [x: a]
  static var fb = fx * [x: b]
  static var ga = gx * [x: a]
  static var gb = gx * [x: b]

  static var fxy = N.function("f", nodes: [x, y])
  static var gxy = N.function("g", nodes: [x, y])
  static var fab = fxy * [x: a, y: b]
  static var fax = fxy * [x: a, y: x]
  static var fxa = fxy * [y: a]
  static var fxx = fxy * [y: x]
  static var gxa = gxy * [y: a]
}
