//
// Copyright (c) 2023-2025 PADL Software Pty Ltd
//
// Licensed under the Apache License, Version 2.0 (the License);
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if canImport(Glibc)
#if os(Linux)
import CLinuxSockAddr
#endif
import Glibc
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Android)
import Android
#endif
import SystemPackage

private func parseIPv4PresentationAddress(_ presentationAddress: String) -> (String, UInt16?) {
  var port: UInt16?
  let addressPort = presentationAddress.split(separator: ":", maxSplits: 2)
  if addressPort.count > 1 {
    port = UInt16(addressPort[1])
  }

  return (String(addressPort.first!), port)
}

public func parseIPv6PresentationAddress(_ presentationAddress: String) throws
  -> (String, UInt16?)
{
  let ipv6Regex: Regex = #/\[([0-9a-fA-F:]+)\](:(\d+))?/#
  let port: UInt16?
  let addressPort = presentationAddress.firstMatch(of: ipv6Regex)

  guard let address = addressPort?.1 else { throw Errno(rawValue: EINVAL) }
  if let portString = addressPort?.3 { port = UInt16(portString) }
  else { port = nil }

  return (String(address), port)
}

public protocol SocketAddress: Sendable {
  static var family: sa_family_t { get }

  init(family: sa_family_t, presentationAddress: String) throws
  func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T
  var presentationAddress: String { get throws }
  var port: UInt16 { get throws }
  var size: socklen_t { get }
}

public extension SocketAddress {
  var family: sa_family_t {
    withSockAddr { $0.pointee.sa_family }
  }
}

public extension SocketAddress {
  func asStorage() -> sockaddr_storage {
    var ss = sockaddr_storage()
    withSockAddr {
      _ = memcpy(&ss, $0, Int(size))
    }
    return ss
  }
}

extension sockaddr: SocketAddress, @retroactive @unchecked Sendable {
  public static var family: sa_family_t {
    sa_family_t(AF_UNSPEC)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    throw Errno.invalidArgument
  }

  public var size: socklen_t {
    switch Int32(sa_family) {
    case AF_INET:
      return socklen_t(MemoryLayout<sockaddr_in>.size)
    case AF_INET6:
      return socklen_t(MemoryLayout<sockaddr_in6>.size)
    case AF_LOCAL:
      return socklen_t(MemoryLayout<sockaddr_un>.size)
    #if os(Linux)
    case AF_PACKET:
      return socklen_t(MemoryLayout<sockaddr_ll>.size)
    case AF_NETLINK:
      return socklen_t(MemoryLayout<sockaddr_nl>.size)
    #endif
    default:
      return 0
    }
  }

  private var _storage: sockaddr_storage {
    var storage = sockaddr_storage()
    let size = Int(size)
    withUnsafePointer(to: self) { _ = memcpy(&storage, $0, size) }
    return storage
  }

  public var presentationAddress: String {
    get throws {
      let storage = _storage

      return try withUnsafePointer(to: storage) {
        switch Int32(sa_family) {
        case AF_INET:
          try $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
            try $0.pointee.presentationAddress
          }
        case AF_INET6:
          try $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
            try $0.pointee.presentationAddress
          }
        case AF_LOCAL:
          try $0.withMemoryRebound(to: sockaddr_un.self, capacity: 1) {
            try $0.pointee.presentationAddress
          }
        #if os(Linux)
        case AF_PACKET:
          try $0.withMemoryRebound(to: sockaddr_ll.self, capacity: 1) {
            try $0.pointee.presentationAddress
          }
        case AF_NETLINK:
          try $0.withMemoryRebound(to: sockaddr_nl.self, capacity: 1) {
            try $0.pointee.presentationAddress
          }
        #endif
        default:
          throw Errno.addressFamilyNotSupported
        }
      }
    }
  }

  public var port: UInt16 {
    get throws {
      let storage = _storage

      return try withUnsafePointer(to: storage) {
        switch Int32(sa_family) {
        case AF_INET:
          try $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
            try $0.pointee.port
          }
        case AF_INET6:
          try $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
            try $0.pointee.port
          }
        default:
          throw Errno.addressFamilyNotSupported
        }
      }
    }
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try withUnsafePointer(to: self) { sa in
      try body(sa)
    }
  }
}

extension sockaddr_in: SocketAddress, @retroactive @unchecked Sendable {
  public static var family: sa_family_t {
    sa_family_t(AF_INET)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    guard family == AF_INET else { throw Errno.invalidArgument }
    self = sockaddr_in()
    let (address, port) = parseIPv4PresentationAddress(presentationAddress)
    var sin_port = UInt16()
    var sin_addr = in_addr()
    let result = try Errno.throwingErrno {
      if let port { sin_port = port.bigEndian }
      return inet_pton(AF_INET, address, &sin_addr)
    }
    if result != 1 {
      throw Errno.invalidArgument
    }
    sin_family = family
    self.sin_port = sin_port
    self.sin_addr = sin_addr
    #if canImport(Darwin)
    sin_len = UInt8(size)
    #endif
  }

  public var size: socklen_t {
    socklen_t(MemoryLayout<Self>.size)
  }

  public var presentationAddress: String {
    get throws {
      var sin = self
      var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
      let size = socklen_t(buffer.count)
      guard let result = inet_ntop(AF_INET, &sin.sin_addr, &buffer, size) else {
        throw Errno.lastError
      }
      let port = UInt16(bigEndian: sin.sin_port)
      return "\(String(cString: result)):\(port)"
    }
  }

  public var port: UInt16 {
    get throws {
      UInt16(bigEndian: sin_port)
    }
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try withUnsafePointer(to: self) { sin in
      try sin.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
        try body(sa)
      }
    }
  }
}

extension sockaddr_in6: SocketAddress, @retroactive @unchecked Sendable {
  public static var family: sa_family_t {
    sa_family_t(AF_INET6)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    guard family == AF_INET6 else { throw Errno.invalidArgument }
    self = sockaddr_in6()
    let (address, port) = try parseIPv6PresentationAddress(presentationAddress)
    var sin6_port = UInt16()
    var sin6_addr = in6_addr()
    let result = try Errno.throwingErrno {
      if let port { sin6_port = port.bigEndian }
      return inet_pton(AF_INET6, address, &sin6_addr)
    }
    if result != 1 {
      throw Errno.invalidArgument
    }
    sin6_family = family
    self.sin6_port = sin6_port
    self.sin6_addr = sin6_addr
    #if canImport(Darwin)
    sin6_len = UInt8(size)
    #endif
  }

  public var size: socklen_t {
    socklen_t(MemoryLayout<Self>.size)
  }

  public var presentationAddress: String {
    get throws {
      var sin6 = self
      var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
      let size = socklen_t(buffer.count)
      guard let result = inet_ntop(AF_INET6, &sin6.sin6_addr, &buffer, size) else {
        throw Errno.lastError
      }
      let port = UInt16(bigEndian: sin6.sin6_port)
      return "[\(String(cString: result))]:\(port)"
    }
  }

  public var port: UInt16 {
    get throws {
      UInt16(bigEndian: sin6_port)
    }
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try withUnsafePointer(to: self) { sin6 in
      try sin6.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
        try body(sa)
      }
    }
  }
}

extension sockaddr_un: SocketAddress, @retroactive @unchecked Sendable {
  public static var family: sa_family_t {
    sa_family_t(AF_LOCAL)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    guard family == AF_LOCAL else { throw Errno.invalidArgument }

    self = sockaddr_un()
    var sun = self
    sun.sun_family = family
    var capacity = 0

    try withUnsafeMutablePointer(to: &sun.sun_path) { path in
      let start = path.propertyBasePointer(to: \.0)!
      capacity = MemoryLayout.size(ofValue: path.pointee)
      if capacity <= presentationAddress.utf8.count {
        throw Errno.outOfRange
      }
      start.withMemoryRebound(to: CChar.self, capacity: capacity) { dst in
        _ = memcpy(
          UnsafeMutableRawPointer(mutating: dst),
          presentationAddress,
          presentationAddress.utf8.count + 1
        )
      }
    }
    #if os(FreeBSD) || canImport(Darwin)
    sun
      .sun_len = UInt8(
        MemoryLayout<sockaddr_un>.offset(of: \.sun_path)! + presentationAddress.utf8
          .count + 1
      )
    #endif
    self = sun
  }

  public var size: socklen_t {
    socklen_t(MemoryLayout<Self>.size)
  }

  public var presentationAddress: String {
    get throws {
      var sun = self
      return withUnsafeMutablePointer(to: &sun.sun_path) { path in
        let start = path.propertyBasePointer(to: \.0)!
        let capacity = MemoryLayout.size(ofValue: path)
        return start
          .withMemoryRebound(to: CChar.self, capacity: capacity) { dst in
            String(cString: dst)
          }
      }
    }
  }

  public var port: UInt16 {
    get throws {
      throw Errno.addressFamilyNotSupported
    }
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try withUnsafePointer(to: self) { sun in
      try sun.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
        try body(sa)
      }
    }
  }
}

#if os(Linux)
extension sockaddr_ll: SocketAddress, @retroactive @unchecked Sendable {
  public static var family: sa_family_t {
    sa_family_t(AF_PACKET)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    guard family == AF_PACKET else { throw Errno.invalidArgument }

    var sll = sockaddr_ll()
    sll.sll_family = family

    let bytes = try presentationAddress.split(separator: ":").map {
      guard let byte = UInt8($0, radix: 16) else { throw Errno.invalidArgument }
      return byte
    }

    guard bytes.count == ETH_ALEN else { throw Errno.invalidArgument }

    withUnsafeMutablePointer(to: &sll.sll_addr) { addr in
      let start = addr.propertyBasePointer(to: \.0)!
      let capacity = MemoryLayout.size(ofValue: addr.pointee)
      precondition(capacity >= ETH_ALEN)
      _ = start.withMemoryRebound(to: UInt8.self, capacity: capacity) { dst in
        memcpy(UnsafeMutableRawPointer(mutating: dst), bytes, Int(ETH_ALEN))
      }
    }
    sll.sll_halen = UInt8(ETH_ALEN)
    self = sll
  }

  public var size: socklen_t {
    socklen_t(MemoryLayout<Self>.size)
  }

  public var presentationAddress: String {
    get throws {
      var sll = self
      return withUnsafeMutablePointer(to: &sll.sll_addr) { addr in
        let start = addr.propertyBasePointer(to: \.0)!
        let capacity = MemoryLayout.size(ofValue: addr.pointee)
        return start.withMemoryRebound(to: UInt8.self, capacity: capacity) { dst in
          UnsafeBufferPointer(start: dst, count: Int(ETH_ALEN)).map { String($0, radix: 16) }
            .joined(separator: ":")
        }
      }
    }
  }

  public var port: UInt16 {
    get throws {
      throw Errno.addressFamilyNotSupported
    }
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try withUnsafePointer(to: self) { sun in
      try sun.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
        try body(sa)
      }
    }
  }
}

extension sockaddr_nl: SocketAddress, @retroactive @unchecked Sendable {
  public static var family: sa_family_t {
    sa_family_t(AF_NETLINK)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    guard let pid = UInt32(presentationAddress) else { throw Errno.invalidArgument }
    try self.init(family: family, pid: pid, groups: 0)
  }

  public init(family: sa_family_t, pid: UInt32, groups: UInt32) throws {
    guard family == AF_NETLINK else { throw Errno.invalidArgument }

    self.init()
    nl_family = family
    nl_pid = pid
    nl_groups = groups
  }

  public var size: socklen_t {
    socklen_t(MemoryLayout<Self>.size)
  }

  public var presentationAddress: String {
    get throws {
      String(describing: nl_pid)
    }
  }

  public var port: UInt16 {
    get throws {
      throw Errno.addressFamilyNotSupported
    }
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try withUnsafePointer(to: self) { sun in
      try sun.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
        try body(sa)
      }
    }
  }
}
#endif

extension sockaddr_storage: SocketAddress, @retroactive @unchecked Sendable {
  public static var family: sa_family_t {
    sa_family_t(AF_UNSPEC)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    var ss = Self()
    switch Int32(family) {
    case AF_INET:
      var sin = try sockaddr_in(family: family, presentationAddress: presentationAddress)
      _ = memcpy(&ss, &sin, Int(sin.size))
    case AF_INET6:
      var sin6 = try sockaddr_in6(family: family, presentationAddress: presentationAddress)
      _ = memcpy(&ss, &sin6, Int(sin6.size))
    case AF_LOCAL:
      var sun = try sockaddr_un(family: family, presentationAddress: presentationAddress)
      _ = memcpy(&ss, &sun, Int(sun.size))
    #if os(Linux)
    case AF_PACKET:
      var sll = try sockaddr_ll(family: family, presentationAddress: presentationAddress)
      _ = memcpy(&ss, &sll, Int(sll.size))
    case AF_NETLINK:
      var snl = try sockaddr_nl(family: family, presentationAddress: presentationAddress)
      _ = memcpy(&ss, &snl, Int(snl.size))
    #endif
    default:
      throw Errno.addressFamilyNotSupported
    }
    self = ss
  }

  public var size: socklen_t {
    socklen_t(MemoryLayout<Self>.size)
  }

  public var presentationAddress: String {
    get throws {
      try withSockAddr { sa in
        try sa.pointee.presentationAddress
      }
    }
  }

  public var port: UInt16 {
    get throws {
      try withSockAddr { sa in
        try sa.pointee.port
      }
    }
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try withUnsafePointer(to: self) { ss in
      try ss.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
        try body(sa)
      }
    }
  }
}

public extension sockaddr_storage {
  init(bytes: [UInt8]) throws {
    guard bytes.count >= MemoryLayout<sockaddr>.size else {
      throw Errno.outOfRange
    }

    let family = bytes.withUnsafeBytes { $0.loadUnaligned(as: sockaddr.self).sa_family }
    var ss = Self()
    let bytesRequired: Int

    switch Int32(family) {
    case AF_INET:
      bytesRequired = MemoryLayout<sockaddr_in>.size
    case AF_INET6:
      bytesRequired = MemoryLayout<sockaddr_in6>.size
    case AF_LOCAL:
      bytesRequired = MemoryLayout<sockaddr_un>.size
    #if os(Linux)
    case AF_PACKET:
      bytesRequired = MemoryLayout<sockaddr_ll>.size
    case AF_NETLINK:
      bytesRequired = MemoryLayout<sockaddr_nl>.size
    #endif
    default:
      throw Errno.addressFamilyNotSupported
    }
    guard bytes.count >= bytesRequired else {
      throw Errno.outOfRange
    }
    memcpy(&ss, bytes, bytesRequired)
    self = ss
  }
}

public struct AnySocketAddress: Sendable {
  private var storage: sockaddr_storage

  public init(_ sa: any SocketAddress) {
    storage = sa.asStorage()
  }

  public init(bytes: [UInt8]) throws {
    storage = try sockaddr_storage(bytes: bytes)
  }
}

extension AnySocketAddress: Equatable {
  public static func == (lhs: AnySocketAddress, rhs: AnySocketAddress) -> Bool {
    var lhs = lhs
    var rhs = rhs
    return lhs.storage.size == rhs.storage.size &&
      memcmp(&lhs.storage, &rhs.storage, Int(lhs.storage.size)) == 0
  }
}

extension AnySocketAddress: SocketAddress {
  public static var family: sa_family_t {
    sa_family_t(AF_UNSPEC)
  }

  public init(family: sa_family_t, presentationAddress: String) throws {
    storage = try sockaddr_storage(family: family, presentationAddress: presentationAddress)
  }

  public func withSockAddr<T>(_ body: (_ sa: UnsafePointer<sockaddr>) throws -> T) rethrows -> T {
    try storage.withSockAddr(body)
  }

  public var presentationAddress: String {
    get throws {
      try storage.presentationAddress
    }
  }

  public var port: UInt16 {
    get throws {
      try storage.port
    }
  }

  public var size: socklen_t {
    storage.size
  }
}

extension AnySocketAddress: Hashable {
  public func hash(into hasher: inout Hasher) {
    withUnsafeBytes(of: storage) {
      hasher.combine(bytes: $0)
    }
  }
}
