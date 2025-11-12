@testable import SocketAddress
import SystemPackage
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

  func testIPv6PresentationAddressInitializerBareAddress() throws {
    let address = "2001:db8::1"
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

  func testAnySocketAddressInitializerIPv6WithPort() throws {
    let address = "[::1]:8080"
    let sockAddr = try AnySocketAddress(family: sa_family_t(AF_INET6), presentationAddress: address)
    XCTAssertEqual(sockAddr.family, sa_family_t(AF_INET6))
    XCTAssertEqual(try sockAddr.port, 8080)
  }

  func testAnySocketAddressInitializerIPv6BareAddress() throws {
    let address = "2001:db8::1"
    let sockAddr = try AnySocketAddress(family: sa_family_t(AF_INET6), presentationAddress: address)
    XCTAssertEqual(sockAddr.family, sa_family_t(AF_INET6))
    XCTAssertEqual(try sockAddr.port, 0)
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

  func testSockaddrStorageFromIPv4Bytes() throws {
    let originalSockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "192.168.1.100:8080"
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)

    XCTAssertEqual(storage.family, sa_family_t(AF_INET))
    XCTAssertEqual(try storage.port, 8080)
    XCTAssertTrue(try storage.presentationAddress.contains("192.168.1.100"))
  }

  func testSockaddrStorageFromIPv6Bytes() throws {
    let originalSockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[2001:db8::1]:9090"
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)

    XCTAssertEqual(storage.family, sa_family_t(AF_INET6))
    XCTAssertEqual(try storage.port, 9090)
  }

  func testSockaddrStorageFromUnixBytes() throws {
    let path = "/tmp/test/a/long/path"
    let originalSockAddr = try sockaddr_un(
      family: sa_family_t(AF_LOCAL),
      presentationAddress: path
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)

    XCTAssertEqual(storage.family, sa_family_t(AF_LOCAL))
    XCTAssertEqual(try storage.presentationAddress, path)
  }

  #if os(Linux)
  func testSockaddrStorageFromPacketBytes() throws {
    let macAddress = "de:ad:be:ef:ca:fe"
    let originalSockAddr = try sockaddr_ll(
      family: sa_family_t(AF_PACKET),
      presentationAddress: macAddress
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)

    XCTAssertEqual(storage.family, sa_family_t(AF_PACKET))
  }
  #endif

  func testSockaddrStorageRoundTripIPv4() throws {
    let originalSockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "10.0.0.1:3000"
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)
    let roundTripBytes: [UInt8] = withUnsafeBytes(of: storage) { Array($0) }

    let expectedSize = MemoryLayout<sockaddr_in>.size
    XCTAssertEqual(bytes.prefix(expectedSize), roundTripBytes.prefix(expectedSize))

    let finalStorage = try sockaddr_storage(bytes: roundTripBytes)
    XCTAssertEqual(try originalSockAddr.presentationAddress, try finalStorage.presentationAddress)
    XCTAssertEqual(try originalSockAddr.port, try finalStorage.port)
  }

  func testSockaddrStorageRoundTripIPv6() throws {
    let originalSockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[::1]:5432"
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)
    let roundTripBytes: [UInt8] = withUnsafeBytes(of: storage) { Array($0) }

    let expectedSize = MemoryLayout<sockaddr_in6>.size
    XCTAssertEqual(bytes.prefix(expectedSize), roundTripBytes.prefix(expectedSize))

    let finalStorage = try sockaddr_storage(bytes: roundTripBytes)
    XCTAssertEqual(try originalSockAddr.port, try finalStorage.port)
  }

  func testSockaddrStorageRoundTripUnix() throws {
    let path = "/tmp/test"
    let originalSockAddr = try sockaddr_un(
      family: sa_family_t(AF_LOCAL),
      presentationAddress: path
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)
    let roundTripBytes: [UInt8] = withUnsafeBytes(of: storage) { Array($0) }

    let expectedSize = MemoryLayout<sockaddr_un>.size
    XCTAssertEqual(bytes.prefix(expectedSize), roundTripBytes.prefix(expectedSize))

    let finalStorage = try sockaddr_storage(bytes: roundTripBytes)
    XCTAssertEqual(try originalSockAddr.presentationAddress, try finalStorage.presentationAddress)
  }

  #if os(Linux)
  func testSockaddrStorageRoundTripPacket() throws {
    let macAddress = "01:23:45:67:89:ab"
    let originalSockAddr = try sockaddr_ll(
      family: sa_family_t(AF_PACKET),
      presentationAddress: macAddress
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let storage = try sockaddr_storage(bytes: bytes)
    let roundTripBytes: [UInt8] = withUnsafeBytes(of: storage) { Array($0) }

    let expectedSize = MemoryLayout<sockaddr_ll>.size
    XCTAssertEqual(bytes.prefix(expectedSize), roundTripBytes.prefix(expectedSize))
  }
  #endif

  func testSockaddrStorageFromBytesInvalidFamily() throws {
    var invalidBytes = [UInt8](repeating: 0, count: 128)
    invalidBytes[0] = 255

    XCTAssertThrowsError(try sockaddr_storage(bytes: invalidBytes)) { error in
      XCTAssertEqual(error as? Errno, Errno.addressFamilyNotSupported)
    }
  }

  func testSockaddrStorageFromBytesTooShort() throws {
    var shortBytes = [UInt8](repeating: 0, count: 16)
    shortBytes[0] = UInt8(AF_INET6)

    XCTAssertThrowsError(try sockaddr_storage(bytes: shortBytes)) { error in
      #if canImport(Darwin)
      XCTAssertEqual(error as? Errno, Errno.addressFamilyNotSupported)
      #else
      XCTAssertEqual(error as? Errno, Errno.outOfRange)
      #endif
    }
  }

  func testAnySocketAddressFromBytes() throws {
    let originalSockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "203.0.113.42:12345"
    )

    let bytes: [UInt8] = withUnsafeBytes(of: originalSockAddr) { Array($0) }
    let anyAddr = try AnySocketAddress(bytes: bytes)

    XCTAssertEqual(anyAddr.family, sa_family_t(AF_INET))
    XCTAssertEqual(try anyAddr.port, 12345)
    XCTAssertTrue(try anyAddr.presentationAddress.contains("203.0.113.42"))
  }
}
