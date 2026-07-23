cmake_minimum_required(VERSION 3.15)
project(EngineMetaProject)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# set(FE_INCLUDE_OPENVR ON CACHE BOOL "Include OpenVR" FORCE)

# Force a consistent MSVC runtime across all subprojects to avoid
# linker mismatches (LNK2038) between static and dynamic CRTs.
if(MSVC)
	# Use dynamic CRT for Release and Debug (uses /MD for Release and /MDd for Debug)
	set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" CACHE STRING "MSVC runtime" FORCE)
endif()

# set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build all libraries as shared" FORCE)

# Don't add FenixEngine directly here — each project adds it via if(NOT TARGET Engine),
# so the first project to run controls whether Jolt is included.

add_subdirectory(Foxcraft)
add_subdirectory(Cake)
add_subdirectory(ShaderSavers)
add_subdirectory(Atmosphere)
add_subdirectory(Labyrinth)
add_subdirectory(FoxRacing)
if(Qt6_FOUND)
	add_subdirectory(FenixEditor)
else()
	message(WARNING "Qt6 was not found. Skipping the Qt-dependent project, but configuring everything else.")
endif()
# add_subdirectory(Tunnel)
