# FindSwiftSystem.cmake
#
# Locates an installed Apple swift-system package (apple/swift-system) that has
# been built and installed with its upstream CMake build.
#
# Upstream swift-system installs:
#   ${prefix}/lib/libSystemPackage.so
#   ${prefix}/lib/swift/<os>/SystemPackage.swiftmodule/<triple>.swiftmodule
#   ${prefix}/lib/swift/<os>/SystemPackage.swiftmodule/<triple>.swiftdoc
#   ${prefix}/include/CSystem/{module.modulemap,CSystemLinux.h,CSystemWindows.h}
#
# Upstream does NOT install a usable Config.cmake, so this shim provides one.
#
# Produces imported targets:
#   SwiftSystem::CSystem        INTERFACE target with -I .../include/CSystem
#   SwiftSystem::SystemPackage  SHARED imported, links libSystemPackage.so and
#                               adds the swiftmodule search dir to INTERFACE
#                               INCLUDE_DIRECTORIES so Swift consumers find it.

if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
  set(_swift_os macosx)
else()
  string(TOLOWER "${CMAKE_SYSTEM_NAME}" _swift_os)
endif()

find_library(SwiftSystem_LIBRARY
  NAMES SystemPackage
  PATH_SUFFIXES lib)

find_path(SwiftSystem_MODULE_DIR
  NAMES SystemPackage.swiftmodule
  PATH_SUFFIXES lib/swift/${_swift_os})

find_path(SwiftSystem_CSYSTEM_INCLUDE_DIR
  NAMES module.modulemap
  PATH_SUFFIXES include/CSystem)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SwiftSystem
  REQUIRED_VARS
    SwiftSystem_LIBRARY
    SwiftSystem_MODULE_DIR
    SwiftSystem_CSYSTEM_INCLUDE_DIR)

if(SwiftSystem_FOUND)
  if(NOT TARGET SwiftSystem::CSystem)
    add_library(SwiftSystem::CSystem INTERFACE IMPORTED)
    set_target_properties(SwiftSystem::CSystem PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${SwiftSystem_CSYSTEM_INCLUDE_DIR}")
  endif()

  if(NOT TARGET SwiftSystem::SystemPackage)
    add_library(SwiftSystem::SystemPackage SHARED IMPORTED)
    set_target_properties(SwiftSystem::SystemPackage PROPERTIES
      IMPORTED_LOCATION "${SwiftSystem_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${SwiftSystem_MODULE_DIR}"
      INTERFACE_LINK_LIBRARIES "SwiftSystem::CSystem")
  endif()
endif()

mark_as_advanced(
  SwiftSystem_LIBRARY
  SwiftSystem_MODULE_DIR
  SwiftSystem_CSYSTEM_INCLUDE_DIR)
