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
    let expectedSize = MemoryLayout<sockaddr_in>.size
    let roundTripBytes: [UInt8] = withUnsafeBytes(of: storage) { Array($0.prefix(expectedSize)) }

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
    let expectedSize = MemoryLayout<sockaddr_in6>.size
    let roundTripBytes: [UInt8] = withUnsafeBytes(of: storage) { Array($0.prefix(expectedSize)) }

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
    let expectedSize = MemoryLayout<sockaddr_un>.size
    let roundTripBytes: [UInt8] = withUnsafeBytes(of: storage) { Array($0.prefix(expectedSize)) }

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

  // MARK: - presentationAddressNoPort Tests

  func testIPv4PresentationAddressNoPortWithPort() throws {
    let sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "192.168.1.1:8080"
    )
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "192.168.1.1")
  }

  func testIPv4PresentationAddressNoPortWithoutPort() throws {
    let sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "10.0.0.1"
    )
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "10.0.0.1")
  }

  func testIPv6PresentationAddressNoPortWithPort() throws {
    let sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[2001:db8::1]:8080"
    )
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "2001:db8::1")
  }

  func testIPv6PresentationAddressNoPortWithoutPortBracketed() throws {
    let sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[::1]"
    )
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "::1")
  }

  func testIPv6PresentationAddressNoPortBareAddress() throws {
    let sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "2001:db8:85a3::8a2e:370:7334"
    )
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "2001:db8:85a3::8a2e:370:7334")
  }

  func testUnixPresentationAddressNoPort() throws {
    let path = "/tmp/test.sock"
    let sockAddr = try sockaddr_un(family: sa_family_t(AF_LOCAL), presentationAddress: path)
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, path)
  }

  #if os(Linux)
  func testPacketPresentationAddressNoPort() throws {
    let macAddress = "aa:bb:cc:dd:ee:ff"
    let sockAddr = try sockaddr_ll(family: sa_family_t(AF_PACKET), presentationAddress: macAddress)
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, macAddress)
  }

  func testNetlinkPresentationAddressNoPort() throws {
    let pid = "1234"
    let sockAddr = try sockaddr_nl(family: sa_family_t(AF_NETLINK), presentationAddress: pid)
    let addressNoPort = try sockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, pid)
  }
  #endif

  func testSockaddrStoragePresentationAddressNoPortIPv4() throws {
    let storage = try sockaddr_storage(
      family: sa_family_t(AF_INET),
      presentationAddress: "203.0.113.1:9999"
    )
    let addressNoPort = try storage.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "203.0.113.1")
  }

  func testSockaddrStoragePresentationAddressNoPortIPv6() throws {
    let storage = try sockaddr_storage(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[fe80::1]:5432"
    )
    let addressNoPort = try storage.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "fe80::1")
  }

  func testSockaddrStoragePresentationAddressNoPortUnix() throws {
    let path = "/var/run/daemon.socket"
    let storage = try sockaddr_storage(family: sa_family_t(AF_LOCAL), presentationAddress: path)
    let addressNoPort = try storage.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, path)
  }

  func testAnySocketAddressPresentationAddressNoPortIPv4() throws {
    let anyAddr = try AnySocketAddress(
      family: sa_family_t(AF_INET),
      presentationAddress: "198.51.100.42:8443"
    )
    let addressNoPort = try anyAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "198.51.100.42")
  }

  func testAnySocketAddressPresentationAddressNoPortIPv6() throws {
    let anyAddr = try AnySocketAddress(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[2001:db8:85a3::8a2e:370:7334]:8080"
    )
    let addressNoPort = try anyAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "2001:db8:85a3::8a2e:370:7334")
  }

  func testGenericSocketAddressPresentationAddressNoPort() throws {
    let sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "127.0.0.1:3000"
    )

    let genericSockAddr: sockaddr = sockAddr.withSockAddr { sa, _ in sa.pointee }
    let addressNoPort = try genericSockAddr.presentationAddressNoPort
    XCTAssertEqual(addressNoPort, "127.0.0.1")
  }

  func testUnixPresentationAddressLongPath() throws {
    // Test with a path that fills most of the sun_path buffer to verify
    // the capacity calculation is using the sun_path size, not pointer size
    let longPath = "/tmp/" + String(repeating: "x", count: 90)
    let sockAddr = try sockaddr_un(family: sa_family_t(AF_LOCAL), presentationAddress: longPath)
    let recoveredPath = try sockAddr.presentationAddress
    XCTAssertEqual(recoveredPath, longPath)
  }

  // MARK: - withMutableSockAddr Tests

  func testWithMutableSockAddrIPv4() throws {
    var sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "192.168.1.1:8080"
    )

    // Test reading via mutable pointer and verify size
    let (family, size) = sockAddr.withMutableSockAddr { sa, size in
      (sa.pointee.sa_family, size)
    }
    XCTAssertEqual(family, sa_family_t(AF_INET))
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))

    // Test mutation
    sockAddr.withMutableSockAddr { sa, _ in
      sa.pointee.sa_family = sa_family_t(AF_INET)
    }
    XCTAssertEqual(sockAddr.sin_family, sa_family_t(AF_INET))
  }

  func testWithMutableSockAddrIPv6() throws {
    var sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[::1]:8080"
    )

    let (family, size) = sockAddr.withMutableSockAddr { sa, size in
      (sa.pointee.sa_family, size)
    }
    XCTAssertEqual(family, sa_family_t(AF_INET6))
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in6>.size))
  }

  func testWithMutableSockAddrUnix() throws {
    var sockAddr = try sockaddr_un(family: sa_family_t(AF_LOCAL), presentationAddress: "/tmp/test")

    let (family, size) = sockAddr.withMutableSockAddr { sa, size in
      (sa.pointee.sa_family, size)
    }
    XCTAssertEqual(family, sa_family_t(AF_LOCAL))
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_un>.size))
  }

  func testWithMutableSockAddrStorage() throws {
    var storage = try sockaddr_storage(
      family: sa_family_t(AF_INET),
      presentationAddress: "10.0.0.1:3000"
    )

    let (family, size) = storage.withMutableSockAddr { sa, size in
      (sa.pointee.sa_family, size)
    }
    XCTAssertEqual(family, sa_family_t(AF_INET))
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))
  }

  func testWithMutableSockAddrAnySocketAddress() throws {
    var anyAddr = try AnySocketAddress(
      family: sa_family_t(AF_INET),
      presentationAddress: "127.0.0.1:5000"
    )

    let (family, size) = anyAddr.withMutableSockAddr { sa, size in
      (sa.pointee.sa_family, size)
    }
    XCTAssertEqual(family, sa_family_t(AF_INET))
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))
  }

  #if os(Linux)
  func testWithMutableSockAddrPacket() throws {
    var sockAddr = try sockaddr_ll(
      family: sa_family_t(AF_PACKET),
      presentationAddress: "aa:bb:cc:dd:ee:ff"
    )

    let (family, size) = sockAddr.withMutableSockAddr { sa, size in
      (sa.pointee.sa_family, size)
    }
    XCTAssertEqual(family, sa_family_t(AF_PACKET))
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_ll>.size))
  }

  func testWithMutableSockAddrNetlink() throws {
    var sockAddr = try sockaddr_nl(family: sa_family_t(AF_NETLINK), presentationAddress: "1234")

    let (family, size) = sockAddr.withMutableSockAddr { sa, size in
      (sa.pointee.sa_family, size)
    }
    XCTAssertEqual(family, sa_family_t(AF_NETLINK))
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_nl>.size))
  }
  #endif

  // MARK: - withSockAddr Size Parameter Tests

  func testWithSockAddrIPv4Size() throws {
    let sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "192.168.1.1:8080"
    )

    sockAddr.withSockAddr { sa, size in
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_INET))
      XCTAssertEqual(Int(size), MemoryLayout<sockaddr_in>.size)
    }
  }

  func testWithSockAddrIPv6Size() throws {
    let sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[::1]:9000"
    )

    sockAddr.withSockAddr { sa, size in
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in6>.size))
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_INET6))
      XCTAssertEqual(Int(size), MemoryLayout<sockaddr_in6>.size)
    }
  }

  func testWithSockAddrUnixSize() throws {
    let sockAddr = try sockaddr_un(
      family: sa_family_t(AF_LOCAL),
      presentationAddress: "/var/run/test.sock"
    )

    sockAddr.withSockAddr { sa, size in
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_un>.size))
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_LOCAL))
      XCTAssertEqual(Int(size), MemoryLayout<sockaddr_un>.size)
    }
  }

  func testWithSockAddrStorageSize() throws {
    let storage = try sockaddr_storage(
      family: sa_family_t(AF_INET),
      presentationAddress: "10.0.0.1:5000"
    )

    storage.withSockAddr { sa, size in
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_INET))
    }
  }

  func testWithSockAddrAnySocketAddressSize() throws {
    let anyAddr = try AnySocketAddress(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[2001:db8::1]:443"
    )

    anyAddr.withSockAddr { sa, size in
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in6>.size))
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_INET6))
    }
  }

  #if os(Linux)
  func testWithSockAddrPacketSize() throws {
    let sockAddr = try sockaddr_ll(
      family: sa_family_t(AF_PACKET),
      presentationAddress: "01:23:45:67:89:ab"
    )

    sockAddr.withSockAddr { sa, size in
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_ll>.size))
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_PACKET))
      XCTAssertEqual(Int(size), MemoryLayout<sockaddr_ll>.size)
    }
  }

  func testWithSockAddrNetlinkSize() throws {
    let sockAddr = try sockaddr_nl(
      family: sa_family_t(AF_NETLINK),
      pid: 5678,
      groups: 1
    )

    sockAddr.withSockAddr { sa, size in
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_nl>.size))
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_NETLINK))
      XCTAssertEqual(Int(size), MemoryLayout<sockaddr_nl>.size)
    }
  }
  #endif

  // MARK: - Integration Tests with Size Parameter

  func testAsStorageUsesCorrectSizeWithNewAPI() throws {
    let sin = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "203.0.113.1:22"
    )
    let storage = sin.asStorage()

    storage.withSockAddr { sa, size in
      XCTAssertEqual(sa.pointee.sa_family, sa_family_t(AF_INET))
      XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))
    }
  }

  func testWithSockAddrCanCompareAddresses() throws {
    let sin1 = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "1.2.3.4:80"
    )
    let sin2 = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "1.2.3.4:80"
    )

    let match = sin1.withSockAddr { sa1, len1 in
      sin2.withSockAddr { sa2, len2 in
        len1 == len2 && memcmp(sa1, sa2, Int(len1)) == 0
      }
    }

    XCTAssertTrue(match)
  }

  func testWithSockAddrDetectsDifferentAddresses() throws {
    let sin1 = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "1.2.3.4:80"
    )
    let sin2 = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "1.2.3.5:80"
    )

    let match = sin1.withSockAddr { sa1, len1 in
      sin2.withSockAddr { sa2, len2 in
        len1 == len2 && memcmp(sa1, sa2, Int(len1)) == 0
      }
    }

    XCTAssertFalse(match)
  }

  func testWithSockAddrSizeMatchesSizeProperty() throws {
    let sockAddr = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "8.8.8.8:53"
    )

    let sizeFromWithSockAddr = sockAddr.withSockAddr { _, size in size }
    XCTAssertEqual(sizeFromWithSockAddr, sockAddr.size)
  }

  func testWithMutableSockAddrSizeMatchesSizeProperty() throws {
    var sockAddr = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[::1]:443"
    )

    let sizeFromWithMutableSockAddr = sockAddr.withMutableSockAddr { _, size in size }
    XCTAssertEqual(sizeFromWithMutableSockAddr, sockAddr.size)
  }

  // MARK: - sockaddr Cast Tests (verifying correct size after cast)

  func testSockAddrCastFromIPv4HasCorrectSize() throws {
    let sin = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "192.168.1.1:8080"
    )

    // Cast sockaddr_in to sockaddr
    let genericSockAddr: sockaddr = sin.withSockAddr { sa, _ in sa.pointee }

    // Verify that withSockAddr on the generic sockaddr returns sockaddr_in size
    let size = genericSockAddr.withSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))
    // Note: On Linux, sockaddr and sockaddr_in happen to be the same size (16 bytes)
  }

  func testMutableSockAddrCastFromIPv4HasCorrectSize() throws {
    let sin = try sockaddr_in(
      family: sa_family_t(AF_INET),
      presentationAddress: "10.0.0.1:3000"
    )

    // Cast sockaddr_in to sockaddr
    var genericSockAddr: sockaddr = sin.withSockAddr { sa, _ in sa.pointee }

    // Verify that withMutableSockAddr on the generic sockaddr returns sockaddr_in size
    let size = genericSockAddr.withMutableSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in>.size))
    // Note: On Linux, sockaddr and sockaddr_in happen to be the same size (16 bytes)
  }

  func testSockAddrCastFromIPv6HasCorrectSize() throws {
    let sin6 = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[::1]:9000"
    )

    // Cast sockaddr_in6 to sockaddr
    let genericSockAddr: sockaddr = sin6.withSockAddr { sa, _ in sa.pointee }

    // Verify that withSockAddr on the generic sockaddr returns sockaddr_in6 size
    let size = genericSockAddr.withSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in6>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }

  func testMutableSockAddrCastFromIPv6HasCorrectSize() throws {
    let sin6 = try sockaddr_in6(
      family: sa_family_t(AF_INET6),
      presentationAddress: "[2001:db8::1]:443"
    )

    // Cast sockaddr_in6 to sockaddr
    var genericSockAddr: sockaddr = sin6.withSockAddr { sa, _ in sa.pointee }

    // Verify that withMutableSockAddr on the generic sockaddr returns sockaddr_in6 size
    let size = genericSockAddr.withMutableSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_in6>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }

  func testSockAddrCastFromUnixHasCorrectSize() throws {
    let sun = try sockaddr_un(
      family: sa_family_t(AF_LOCAL),
      presentationAddress: "/tmp/test.sock"
    )

    // Cast sockaddr_un to sockaddr
    let genericSockAddr: sockaddr = sun.withSockAddr { sa, _ in sa.pointee }

    // Verify that withSockAddr on the generic sockaddr returns sockaddr_un size
    let size = genericSockAddr.withSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_un>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }

  func testMutableSockAddrCastFromUnixHasCorrectSize() throws {
    let sun = try sockaddr_un(
      family: sa_family_t(AF_LOCAL),
      presentationAddress: "/var/run/daemon.sock"
    )

    // Cast sockaddr_un to sockaddr
    var genericSockAddr: sockaddr = sun.withSockAddr { sa, _ in sa.pointee }

    // Verify that withMutableSockAddr on the generic sockaddr returns sockaddr_un size
    let size = genericSockAddr.withMutableSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_un>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }

  #if os(Linux)
  func testSockAddrCastFromPacketHasCorrectSize() throws {
    let sll = try sockaddr_ll(
      family: sa_family_t(AF_PACKET),
      presentationAddress: "aa:bb:cc:dd:ee:ff"
    )

    // Cast sockaddr_ll to sockaddr
    let genericSockAddr: sockaddr = sll.withSockAddr { sa, _ in sa.pointee }

    // Verify that withSockAddr on the generic sockaddr returns sockaddr_ll size
    let size = genericSockAddr.withSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_ll>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }

  func testMutableSockAddrCastFromPacketHasCorrectSize() throws {
    let sll = try sockaddr_ll(
      family: sa_family_t(AF_PACKET),
      presentationAddress: "11:22:33:44:55:66"
    )

    // Cast sockaddr_ll to sockaddr
    var genericSockAddr: sockaddr = sll.withSockAddr { sa, _ in sa.pointee }

    // Verify that withMutableSockAddr on the generic sockaddr returns sockaddr_ll size
    let size = genericSockAddr.withMutableSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_ll>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }

  func testSockAddrCastFromNetlinkHasCorrectSize() throws {
    let snl = try sockaddr_nl(
      family: sa_family_t(AF_NETLINK),
      pid: 1234,
      groups: 0
    )

    // Cast sockaddr_nl to sockaddr
    let genericSockAddr: sockaddr = snl.withSockAddr { sa, _ in sa.pointee }

    // Verify that withSockAddr on the generic sockaddr returns sockaddr_nl size
    let size = genericSockAddr.withSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_nl>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }

  func testMutableSockAddrCastFromNetlinkHasCorrectSize() throws {
    let snl = try sockaddr_nl(
      family: sa_family_t(AF_NETLINK),
      pid: 5678,
      groups: 1
    )

    // Cast sockaddr_nl to sockaddr
    var genericSockAddr: sockaddr = snl.withSockAddr { sa, _ in sa.pointee }

    // Verify that withMutableSockAddr on the generic sockaddr returns sockaddr_nl size
    let size = genericSockAddr.withMutableSockAddr { _, size in size }
    XCTAssertEqual(size, socklen_t(MemoryLayout<sockaddr_nl>.size))
    XCTAssertNotEqual(size, socklen_t(MemoryLayout<sockaddr>.size))
  }
  #endif
}
