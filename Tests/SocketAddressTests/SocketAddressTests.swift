@testable import SocketAddress
import XCTest
#if os(Linux)
import CLinuxSockAddr
#endif

final class SocketAddressTests: XCTestCase {
  func testIPv4PresentationAddressInitializer() throws {
    let address = "192.168.1.1:8080"
    let sockAddr = try sockaddr_in(family: sa_family_t(AF_INET), presentationAddress: address)
    XCTAssertEqual(sockAddr.sin_family, sa_family_t(AF_INET))
    XCTAssertEqual(try sockAddr.port, 8080)
  }

  func testIPv4PresentationAddressInitializerWithoutPort() throws {
    let address = "192.168.1.1"
    let sockAddr = try sockaddr_in(family: sa_family_t(AF_INET), presentationAddress: address)
    XCTAssertEqual(sockAddr.sin_family, sa_family_t(AF_INET))
    XCTAssertEqual(try sockAddr.port, 0)
  }

  func testIPv6PresentationAddressInitializer() throws {
    let address = "[::1]:8080"
    let sockAddr = try sockaddr_in6(family: sa_family_t(AF_INET6), presentationAddress: address)
    XCTAssertEqual(sockAddr.sin6_family, sa_family_t(AF_INET6))
    XCTAssertEqual(try sockAddr.port, 8080)
  }

  func testIPv6PresentationAddressInitializerWithoutPort() throws {
    let address = "[2001:db8::1]"
    let sockAddr = try sockaddr_in6(family: sa_family_t(AF_INET6), presentationAddress: address)
    XCTAssertEqual(sockAddr.sin6_family, sa_family_t(AF_INET6))
    XCTAssertEqual(try sockAddr.port, 0)
  }

  func testUnixPresentationAddressInitializer() throws {
    let path = "/tmp/test.sock"
    let sockAddr = try sockaddr_un(family: sa_family_t(AF_LOCAL), presentationAddress: path)
    XCTAssertEqual(sockAddr.sun_family, sa_family_t(AF_LOCAL))
  }

  func testAnySocketAddressInitializer() throws {
    let address = "127.0.0.1:3000"
    let sockAddr = try AnySocketAddress(family: sa_family_t(AF_INET), presentationAddress: address)
    XCTAssertEqual(sockAddr.family, sa_family_t(AF_INET))
    XCTAssertEqual(try sockAddr.port, 3000)
  }

  func testIPv4PresentationAddressProperty() throws {
    let sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "10.0.0.1:9090"
    )
    let presentationAddress = try sockAddr.presentationAddress
    XCTAssertTrue(presentationAddress.contains("10.0.0.1"))
    XCTAssertTrue(presentationAddress.contains("9090"))
  }

  func testIPv6PresentationAddressProperty() throws {
    let sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[fe80::1]:5432"
    )
    let presentationAddress = try sockAddr.presentationAddress
    XCTAssertTrue(presentationAddress.hasPrefix("["))
    XCTAssertTrue(presentationAddress.contains(":5432"))
  }

  func testUnixPresentationAddressProperty() throws {
    let path = "/var/run/test.socket"
    let sockAddr = try sockaddr_un(family: sa_family_t(AF_LOCAL), presentationAddress: path)
    let presentationAddress = try sockAddr.presentationAddress
    XCTAssertEqual(presentationAddress, path)
  }

  func testIPv4RoundTrip() throws {
    let originalAddress = "203.0.113.1:1234"
    let sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: originalAddress
    )
    let recoveredAddress = try sockAddr.presentationAddress
    XCTAssertEqual(recoveredAddress, originalAddress)
  }

  func testIPv6RoundTrip() throws {
    let originalAddress = "[2001:db8:85a3::8a2e:370:7334]:8080"
    let sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: originalAddress
    )
    let recoveredAddress = try sockAddr.presentationAddress
    XCTAssertEqual(recoveredAddress, originalAddress)
  }

  func testUnixRoundTrip() throws {
    let originalPath = "/tmp/socket_test_path"
    let sockAddr = try sockaddr_un(family: sa_family_t(AF_LOCAL), presentationAddress: originalPath)
    let recoveredPath = try sockAddr.presentationAddress
    XCTAssertEqual(recoveredPath, originalPath)
  }

  func testAnySocketAddressRoundTrip() throws {
    let originalAddress = "198.51.100.42:8443"
    let sockAddr = try AnySocketAddress(
      family: sa_family_t(AF_INET),
      presentationAddress: originalAddress
    )
    let recoveredAddress = try sockAddr.presentationAddress
    XCTAssertEqual(recoveredAddress, originalAddress)
  }

  #if os(Linux)
  func testPacketSocketAddressInitializer() throws {
    let macAddress = "aa:bb:cc:dd:ee:ff"
    let sockAddr = try sockaddr_ll(family: sa_family_t(AF_PACKET), presentationAddress: macAddress)
    XCTAssertEqual(sockAddr.sll_family, sa_family_t(AF_PACKET))
  }

  func testPacketSocketAddressRoundTrip() throws {
    let originalMac = "12:34:56:78:9a:bc"
    let sockAddr = try sockaddr_ll(family: sa_family_t(AF_PACKET), presentationAddress: originalMac)
    let recoveredMac = try sockAddr.presentationAddress
    XCTAssertEqual(recoveredMac, originalMac)
  }

  func testNetlinkSocketAddressInitializer() throws {
    let pid = "1234"
    let sockAddr = try sockaddr_nl(family: sa_family_t(AF_NETLINK), presentationAddress: pid)
    XCTAssertEqual(sockAddr.nl_family, sa_family_t(AF_NETLINK))
    XCTAssertEqual(sockAddr.nl_pid, 1234)
  }

  func testNetlinkSocketAddressRoundTrip() throws {
    let originalPid = "5678"
    let sockAddr = try sockaddr_nl(
      family: sa_family_t(AF_NETLINK),
      presentationAddress: originalPid
    )
    let recoveredPid = try sockAddr.presentationAddress
    XCTAssertEqual(recoveredPid, originalPid)
  }
  #endif

  func testInvalidFamilyThrows() throws {
    XCTAssertThrowsError(try sockaddr_in(
      family: sa_family_t(AF_INET6),
      presentationAddress: "192.168.1.1:80"
    ))
    XCTAssertThrowsError(try sockaddr_in6(
      family: sa_family_t(AF_INET),
      presentationAddress: "[::1]:80"
    ))
    XCTAssertThrowsError(try sockaddr_un(
      family: sa_family_t(AF_INET),
      presentationAddress: "/tmp/test"
    ))
  }

  func testInvalidAddressThrows() throws {
    XCTAssertThrowsError(try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "not.an.ip.address:80"
    ))
    XCTAssertThrowsError(try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[gggg::1]:80"
    ))
  }
}
