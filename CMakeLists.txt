# Cmake的命令不区分大小写，例如message，set等命令；但Cmake的变量区分大小写
# 为统一风格，本项目的Cmake命令全部采用小写，变量全部采用大写加下划线组合。

cmake_minimum_required(VERSION 3.5)

set(SARIBBON_VERSION_MAJOR 2)
set(SARIBBON_VERSION_MINOR 6)
set(SARIBBON_VERSION_PATCH 2)

set(SARIBBON_VERSION "${SARIBBON_VERSION_MAJOR}.${SARIBBON_VERSION_MINOR}.${SARIBBON_VERSION_PATCH}")
message(STATUS "SARibbon v${SARIBBON_VERSION}")
project(SARibbon VERSION ${SARIBBON_VERSION} LANGUAGES CXX)

option(SARIBBON_BUILD_STATIC_LIBS "build the SARibbonBar in static lib mode" OFF)
option(SARIBBON_BUILD_EXAMPLES "build the examples" ON)
# frameless能提供windows的窗口特效，如边缘吸附，且对高分屏多屏幕的支持更好,默认开启
option(SARIBBON_USE_FRAMELESS_LIB "Using the QWindowKit library as a frameless solution" OFF)
# frameless能提供windows的窗口特效，如边缘吸附，且对高分屏多屏幕的支持更好,默认开启
option(SARIBBON_ENABLE_SNAPLAYOUT "Whether to enable the Snap Layout effect in Windows 11, this option only takes effect when SARIBBON_USE_FRAMELESS_LIB=ON" OFF)
# 在当前目录安装，此操作会让库安装在当前目录下，新建类似bin_qt5.14.2_msvc_x64这样的文件夹，否则就安装到默认位置，windows的默认位置一般位于C:\Program Files
if(WIN32)
    option(SARIBBON_INSTALL_IN_CURRENT_DIR "Whether to install in the current directory" ON)
else()
    option(SARIBBON_INSTALL_IN_CURRENT_DIR "Whether to install in the current directory" OFF)
endif()

# load Qt library, minimum version required is 5.12
# cn:Qt库加载,最低版本要求为5.12
set(SARIBBON_MIN_QT_VERSION 5.12)
find_package(QT NAMES Qt6 Qt5 COMPONENTS Core REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} ${SARIBBON_MIN_QT_VERSION} COMPONENTS
    Core
    Gui
    Widgets
    REQUIRED
)
message(STATUS "current Qt version is Qt${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}.${QT_VERSION_PATCH}")

# 根据qt版本确认能否使用frameless库，目前frameless库支持qt5.14,qt5.15,qt6.1+,除了上诉版本，都使用不了
# 上述版本的qt如果设置SARIBBON_USE_FRAMELESS_LIB=ON也会改为OFF
set(_SARIBBON_USE_FRAMELESS_LIB ${SARIBBON_USE_FRAMELESS_LIB})
if(SARIBBON_USE_FRAMELESS_LIB)
    if(${QT_VERSION_MAJOR} EQUAL 5)
        # qt版本为5，判断是否小版本小于14，小于14无法使用
        if(${QT_VERSION_MINOR} LESS 14)
            #5.14和5.15可以使用frameless
            set(_SARIBBON_USE_FRAMELESS_LIB OFF)
            message(WARNING "QT_VERSION = Qt${QT_VERSION} QT version minor is ${QT_VERSION_MINOR},less 14,will set SARIBBON_USE_FRAMELESS_LIB OFF")
        endif()
    elseif(${QT_VERSION_MAJOR} EQUAL 6)
        # qt版本为6，判断是否小版本大于6.1
        if(${QT_VERSION_MINOR} LESS_EQUAL 1)
            #6.0及bug多多无法使用frameless
            set(_SARIBBON_USE_FRAMELESS_LIB OFF)
            message(WARNING "QT_VERSION = Qt${QT_VERSION} QT version minor is ${QT_VERSION_MINOR},less 1,will set SARIBBON_USE_FRAMELESS_LIB OFF")
        endif()
    endif()
endif()

# 如果是使用frameless库，需要c++17，否则c++14
if(_SARIBBON_USE_FRAMELESS_LIB)
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    if(MSVC)
        # CMAKE_CXX_STANDARD对有些版本的msvc无效
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17")
    endif()
    message(STATUS "The current QT version can use the frameless library and enable C++17")
else()
    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    if(MSVC)
        # CMAKE_CXX_STANDARD对有些版本的msvc无效
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++14")
    endif()
    message(STATUS "The current qt version cannot use the frameless library, enable C++14")
endif()

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "add a postfix, usually d on windows")
set(CMAKE_RELEASE_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")
set(CMAKE_RELWITHDEBINFO_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")
set(CMAKE_MINSIZEREL_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")
# Set the build postfix extension according to what configuration is being built.

if(CMAKE_BUILD_TYPE MATCHES "Release")
    set(CMAKE_BUILD_POSTFIX "${CMAKE_RELEASE_POSTFIX}")
elseif (CMAKE_BUILD_TYPE MATCHES "MinSizeRel")
    set(CMAKE_BUILD_POSTFIX "${CMAKE_MINSIZEREL_POSTFIX}")
elseif(CMAKE_BUILD_TYPE MATCHES "RelWithDebInfo")
    set(CMAKE_BUILD_POSTFIX "${CMAKE_RELWITHDEBINFO_POSTFIX}")
elseif(CMAKE_BUILD_TYPE MATCHES "Debug")
    set(CMAKE_BUILD_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
else()
    set(CMAKE_BUILD_POSTFIX "")
endif()

if(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4819")
endif()

if(MSVC)
    # 启用 Visual Studio 多处理器编译，加快 C++ 源文件的并行构建速度
    add_compile_options(/utf-8)
    add_compile_options(/MP)
endif()


# 平台判断
if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "4")
    set(SARIBBON_PLATFORM "x86")
else()
    set(SARIBBON_PLATFORM "x64")
endif()

# The local install root is one level above the current directory,
# matching the OgreNext-style Bin/<platform> layout.
get_filename_component(SARIBBON_PARENT_DIR ${CMAKE_CURRENT_LIST_DIR} DIRECTORY)
get_filename_component(SARIBBON_PROJECT_NAME ${CMAKE_CURRENT_LIST_DIR} NAME)
set(SARIBBON_LOCAL_INSTALL_ROOT ${SARIBBON_PARENT_DIR}/Bin/${SARIBBON_PLATFORM})
message(STATUS "SARIBBON_LOCAL_INSTALL_ROOT set to: ${SARIBBON_LOCAL_INSTALL_ROOT}")

if(CMAKE_CONFIGURATION_TYPES)
    set(SARIBBON_INSTALL_CONFIG_DIR "$<CONFIG>")
elseif(CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "")
    set(SARIBBON_INSTALL_CONFIG_DIR "${CMAKE_BUILD_TYPE}")
else()
    set(SARIBBON_INSTALL_CONFIG_DIR "Release")
endif()

# Match OgreNext-style local installs: by default install into the sibling Bin tree.
if(SARIBBON_INSTALL_IN_CURRENT_DIR AND (WIN32 OR APPLE))
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        set(CMAKE_INSTALL_PREFIX
            "${SARIBBON_LOCAL_INSTALL_ROOT}" CACHE PATH "SARibbon install prefix" FORCE
        )
    endif()
endif()

# Set binary output directories to a Bin folder that is a sibling of ThirdParty-SARibbon
# Output layout: <parent>/Bin/<Platform>/<Configuration>
set(SARIBBON_BIN_ROOT ${SARIBBON_PARENT_DIR}/Bin)
message(STATUS "SARIBBON_BIN_ROOT set to: ${SARIBBON_BIN_ROOT}")

# Set temporary/intermediate root: <parent>/tmp/<ProjectName>/<Platform>/<Configuration>
set(SARIBBON_TMP_ROOT ${SARIBBON_PARENT_DIR}/tmp)
message(STATUS "SARIBBON_TMP_ROOT set to: ${SARIBBON_TMP_ROOT}")

# Ensure we have a list of configurations for multi-config generators
if(NOT DEFINED CMAKE_CONFIGURATION_TYPES)
    # Default common MSVC configurations
    set(CMAKE_CONFIGURATION_TYPES "Debug;Release;RelWithDebInfo;MinSizeRel")
endif()

# For multi-config generators like Visual Studio set per-configuration output directories
foreach(cfg IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER "${cfg}" CFG_UP)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CFG_UP} "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${cfg}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CFG_UP} "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${cfg}")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CFG_UP} "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${cfg}")
    # PDB output (for MSVC)
    set(CMAKE_PDB_OUTPUT_DIRECTORY_${CFG_UP} "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${cfg}")
    # Intermediate directory used by VS (IntDir). CMake uses CMAKE_INTDIR in generator expressions; set for downstream use.
    set(CMAKE_INTDIR_${CFG_UP} "${SARIBBON_TMP_ROOT}/${SARIBBON_PROJECT_NAME}/${SARIBBON_PLATFORM}/${cfg}")
endforeach()

# For single-config generators, fall back to CMAKE_BUILD_TYPE if set
if(DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "")
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${CMAKE_BUILD_TYPE}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${CMAKE_BUILD_TYPE}")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${CMAKE_BUILD_TYPE}")
    set(CMAKE_PDB_OUTPUT_DIRECTORY "${SARIBBON_BIN_ROOT}/${SARIBBON_PLATFORM}/${CMAKE_BUILD_TYPE}")
    set(CMAKE_INTDIR "${SARIBBON_TMP_ROOT}/${SARIBBON_PROJECT_NAME}/${SARIBBON_PLATFORM}/${CMAKE_BUILD_TYPE}")
endif()

# Expose generator-specific variables for Visual Studio by mapping CMAKE_INTDIR when configuring targets
# Note: Some generators may ignore CMAKE_INTDIR; Visual Studio uses <IntDir> set by CMake automatically.

# QWindowKit的依赖
# QWindowKit的查找顺序：
# 1. 用户通过-DQWindowKit_DIR指定的路径
# 2. 项目本地安装目录 (bin_qtX.X.X_compiler_platform/lib/cmake/QWindowKit)
# 3. 系统默认安装路径
# 对于开发者，可以在配置时指定路径：
# cmake -DQWindowKit_DIR={path-to-qwindowkit/lib/cmake/QWindowKit}
if(_SARIBBON_USE_FRAMELESS_LIB)
    # 明确记录尝试查找的路径
    set(_qwk_search_paths)

    # 如果用户已指定QWindowKit_DIR，优先使用
    if(QWindowKit_DIR)
        list(APPEND _qwk_search_paths ${QWindowKit_DIR})
        message(STATUS "Using user-specified QWindowKit_DIR: ${QWindowKit_DIR}")
    endif()

    # 添加项目本地安装目录作为备选路径
    if(CMAKE_CONFIGURATION_TYPES)
        set(_local_qwk_config_candidates Release Debug RelWithDebInfo MinSizeRel)
    else()
        set(_local_qwk_config_candidates ${SARIBBON_INSTALL_CONFIG_DIR})
    endif()
    foreach(_local_qwk_config IN LISTS _local_qwk_config_candidates)
        set(_local_qwk_dir ${SARIBBON_LOCAL_INSTALL_ROOT}/${_local_qwk_config}/lib/cmake/QWindowKit)
        if(EXISTS "${_local_qwk_dir}")
            list(APPEND _qwk_search_paths ${_local_qwk_dir})
            message(STATUS "Adding local install path for QWindowKit: ${_local_qwk_dir}")
        endif()
    endforeach()

    # 尝试查找QWindowKit包
    find_package(QWindowKit QUIET
        PATHS ${_qwk_search_paths}
        NO_DEFAULT_PATH  # 禁止在系统默认路径查找
    )

    # 如果未找到，尝试系统路径作为最后手段
    if(NOT QWindowKit_FOUND)
        message(STATUS "QWindowKit not found in specified paths, trying system default...")
        find_package(QWindowKit QUIET)
    endif()

    # 最终确认是否找到
    if(QWindowKit_FOUND)
        message(STATUS "QWindowKit found at: ${QWindowKit_DIR}")
    else()
        set(_SARIBBON_USE_FRAMELESS_LIB OFF)
        message(WARNING "QWindowKit not found - disabling frameless support. Searched paths:\n  ${_qwk_search_paths}")
    endif()
endif()



include(cmake/WinResource.cmake)

########################################################
# 自动化生成配置头文件
########################################################
configure_file (
  "${CMAKE_CURRENT_LIST_DIR}/src/SARibbonBar/SARibbonBarVersionInfo.h.in"
  "${CMAKE_CURRENT_LIST_DIR}/src/SARibbonBar/SARibbonBarVersionInfo.h"
)

##################################
# 代码目录
##################################

# 根据 SARIBBON_BUILD_STATIC_LIBS 的值来设置 BUILD_SHARED_LIBS
# 如果 SARIBBON_BUILD_STATIC_LIBS 为 ON，则 BUILD_SHARED_LIBS 应为 OFF
# 如果 SARIBBON_BUILD_STATIC_LIBS 为 OFF，则 BUILD_SHARED_LIBS 应为 ON
# 注意：option() 命令不会覆盖已存在的变量值，所以需要使用 set() 和 FORCE
if(SARIBBON_BUILD_STATIC_LIBS)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries (DLLs)" FORCE)
    message(STATUS "SARIBBON_BUILD_STATIC_LIBS is ON. Setting BUILD_SHARED_LIBS to OFF (Static Library mode).")
else()
    set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries (DLLs)" FORCE)
    message(STATUS "SARIBBON_BUILD_STATIC_LIBS is OFF. Setting BUILD_SHARED_LIBS to ON (Shared Library/DLL mode).")
endif()

add_subdirectory(src)

if(SARIBBON_BUILD_EXAMPLES)
    message(STATUS "build example")
    add_subdirectory(example)
endif()


##################################
# install
##################################

# document-文档
set(SARIBBON_DOC_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/readme.md
    ${CMAKE_CURRENT_SOURCE_DIR}/readme-cn.md
    ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE
    )


# 把针对cmake安装的两个pri文件复制到根目录下
set(SARIBBON_QMAKE_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common.pri
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/SARibbonBar.pri
    )
install(FILES
    ${SARIBBON_QMAKE_FILES}
    DESTINATION lib/qmake/SARibbonBar
    COMPONENT qmake
)
