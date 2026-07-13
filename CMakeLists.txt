cmake_minimum_required(VERSION 3.15)
project(EngineMetaProject)

# Force a consistent MSVC runtime across all subprojects to avoid
# linker mismatches (LNK2038) between static and dynamic CRTs.
if(MSVC)
	# Use dynamic CRT for Release and Debug (uses /MD for Release and /MDd for Debug)
	set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" CACHE STRING "MSVC runtime" FORCE)
endif()

# set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build all libraries as shared" FORCE)

add_subdirectory(FenixEngine)


add_subdirectory(Foxcraft)
add_subdirectory(Cake)
add_subdirectory(ShaderSavers)
add_subdirectory(Atmosphere)
