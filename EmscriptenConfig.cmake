# Protect against multiple inclusions
if(TARGET emscripten_wasm_settings)
    return()
endif()

if(EMSCRIPTEN)
    # Create a dummy "interface" target to hold all our shared compiler/linker settings
    add_library(emscripten_wasm_settings INTERFACE)

    # 1. Shared Compile Options
    target_compile_options(emscripten_wasm_settings INTERFACE
        -g
        -fdebug-compilation-dir="${CMAKE_SOURCE_DIR}"
    )

    # 2. Shared Link Options (Combining -g flags and all your -s Emscripten switches)
    target_link_options(emscripten_wasm_settings INTERFACE
        -g
        -gsource-map
        "-sUSE_WEBGL2=1"
        "-sFULL_ES3=1"
        "-sGL_ENABLE_GET_PROC_ADDRESS=1"
        "-sALLOW_MEMORY_GROWTH=1"
        "-sINITIAL_MEMORY=64MB"
        "-sNO_EXIT_RUNTIME=1"
        "-sEXIT_RUNTIME=0"
        "-sMAX_WEBGL_VERSION=2"
        "-sMIN_WEBGL_VERSION=2"
        "-sFORCE_FILESYSTEM=1"
        "-sEXPORTED_RUNTIME_METHODS=FS,ccall,cwrap"
        "-sEXPORTED_FUNCTIONS=_main,_emscripten_file_dialog_callback,_malloc,_free"
    )
endif()

# Reusable function to handle target-specific assets and extensions
function(configure_emscripten_target TARGET_NAME RESOURCE_DIR)
    if(EMSCRIPTEN)
        # Force the output to be an HTML file instead of .js or .wasm
        set_target_properties(${TARGET_NAME} PROPERTIES SUFFIX ".html")

        # Convert backslashes to forward slashes for Emscripten file packager on Windows
        file(TO_CMAKE_PATH "${RESOURCE_DIR}" _NORM_RES_DIR)
        target_link_options(${TARGET_NAME} PRIVATE 
            "--preload-file ${_NORM_RES_DIR}@resources"
        )
    endif()
endfunction()
