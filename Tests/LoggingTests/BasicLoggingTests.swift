import Logging
import XCTest

class BasicLoggingTests: ATestCase {
  func testHelloWorld() {
    var logger = Logger(label: "at.maringele.FLEA")

    for s in ["◀️", "▶️"] {

      print("0️⃣ Hello, World! \(s)")
      logger.trace("1️⃣ Hello, World!")  //0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢
      logger.debug("2️⃣ Hello, World!")
      logger.info("3️⃣ Hello, World!")
      logger.notice("4️⃣ Hello, World!")
      logger.warning("5️⃣ Hello, World!")
      logger.error("6️⃣ Hello, World!")
      logger.critical("7️⃣ Hello, World!")
      print("8️⃣ Hello, World! \(s)")
      logger.logLevel = .trace

    }
    XCTAssertEqual(0, 1 - 1)

  }
}
