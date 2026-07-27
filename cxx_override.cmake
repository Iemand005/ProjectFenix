if(WIN32 AND NOT EMSCRIPTEN)
    # Nuclear override: replace CMake's default MSVC library list with pure legacy Win32 libs
    # This strips out onecore, onecoreuap, mincore, and all api-ms-win-* umbrella libs.
    set(CMAKE_CXX_STANDARD_LIBRARIES
        "kernel32.lib;user32.lib;gdi32.lib;winspool.lib;comdlg32.lib;advapi32.lib;shell32.lib;ole32.lib;oleaut32.lib;uuid.lib;odbc32.lib;odbccp32.lib"
        CACHE STRING "" FORCE
    )
    set(CMAKE_C_STANDARD_LIBRARIES
        "kernel32.lib;user32.lib;gdi32.lib;winspool.lib;comdlg32.lib;advapi32.lib;shell32.lib;ole32.lib;oleaut32.lib;uuid.lib;odbc32.lib;odbccp32.lib"
        CACHE STRING "" FORCE
    )
endif()