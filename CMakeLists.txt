cmake_minimum_required(VERSION 3.26)
project(SocketAddress LANGUAGES Swift C)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Resolve the Swift module triple (used in installed swiftmodule paths).
if(NOT Swift_MODULE_TRIPLE)
  execute_process(
    COMMAND ${CMAKE_Swift_COMPILER} -print-target-info
    OUTPUT_VARIABLE _swift_target_info_json)
  string(JSON Swift_MODULE_TRIPLE GET "${_swift_target_info_json}" "target" "moduleTriple")
  set(Swift_MODULE_TRIPLE "${Swift_MODULE_TRIPLE}"
    CACHE STRING "swift module triple used for installed swiftmodule/swiftinterface files")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
  set(SWIFT_OS_DIR macosx)
else()
  string(TOLOWER "${CMAKE_SYSTEM_NAME}" SWIFT_OS_DIR)
endif()

# Centralize the swiftmodule build output so consumers in the same build can
# find SocketAddress.swiftmodule.
set(CMAKE_Swift_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/swift")

find_package(SwiftSystem REQUIRED)

# C interop target wrapping the kernel header includes used by SocketAddress.
add_library(CLinuxSockAddr INTERFACE)
target_include_directories(CLinuxSockAddr INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Sources/CLinuxSockAddr>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/CLinuxSockAddr>)

# Swift library.
add_library(SocketAddress SHARED
  Sources/SocketAddress/SocketAddress.swift
  Sources/SocketAddress/Utils.swift)
target_link_libraries(SocketAddress
  PUBLIC
    SwiftSystem::SystemPackage
    CLinuxSockAddr)
set_target_properties(SocketAddress PROPERTIES
  SOVERSION 0
  INTERFACE_INCLUDE_DIRECTORIES
    "$<BUILD_INTERFACE:${CMAKE_Swift_MODULE_DIRECTORY}>;$<INSTALL_INTERFACE:${CMAKE_INSTALL_LIBDIR}/swift/${SWIFT_OS_DIR}>")

# Install layout.
install(TARGETS SocketAddress CLinuxSockAddr
  EXPORT SocketAddressTargets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(FILES
  Sources/CLinuxSockAddr/CLinuxSockAddr.h
  Sources/CLinuxSockAddr/module.modulemap
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/CLinuxSockAddr)

install(FILES "${CMAKE_Swift_MODULE_DIRECTORY}/SocketAddress.swiftmodule"
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/swift/${SWIFT_OS_DIR}/SocketAddress.swiftmodule
  RENAME ${Swift_MODULE_TRIPLE}.swiftmodule)
install(FILES "${CMAKE_Swift_MODULE_DIRECTORY}/SocketAddress.swiftdoc"
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/swift/${SWIFT_OS_DIR}/SocketAddress.swiftmodule
  RENAME ${Swift_MODULE_TRIPLE}.swiftdoc)

# Find-package config so downstream `find_package(SocketAddress REQUIRED)` works
# from the install tree.
install(EXPORT SocketAddressTargets
  FILE SocketAddressTargets.cmake
  NAMESPACE SocketAddress::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/SocketAddress)

configure_package_config_file(
  cmake/SocketAddressConfig.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/SocketAddressConfig.cmake"
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/SocketAddress)

install(FILES
  "${CMAKE_CURRENT_BINARY_DIR}/SocketAddressConfig.cmake"
  cmake/FindSwiftSystem.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/SocketAddress)
