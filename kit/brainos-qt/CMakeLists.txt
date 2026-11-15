cmake_minimum_required(VERSION 3.22)
project(BrainOS LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(Qt6 REQUIRED COMPONENTS Core DBus Gui Qml Quick QuickControls2 WaylandCompositor WebEngineQuick)
qt_standard_project_setup()
qt_add_executable(brainos-desktop)
set_source_files_properties(qml/theme/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
file(GLOB BRAINOS_ICON_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" CONFIGURE_DEPENDS "qml/assets/icons/*.svg")
qt_add_qml_module(brainos-desktop URI BrainOS VERSION 1.0
    QML_FILES
        qml/Compositor.qml qml/theme/Theme.qml
        qml/components/BootSplash.qml qml/components/AppIcon.qml qml/components/IconButton.qml qml/components/SectionCard.qml qml/components/WindowChrome.qml
        qml/desktop/DesktopSurface.qml qml/desktop/DesktopIcon.qml qml/desktop/Wallpaper.qml qml/dock/Dock.qml qml/windows/AppWindow.qml
        qml/system/TopBar.qml qml/system/ApplicationMenu.qml qml/system/NotificationCenter.qml qml/system/QuickSettings.qml
        qml/widgets/ClockCalendarWidget.qml qml/widgets/WeatherWidget.qml qml/widgets/SystemMonitorWidget.qml qml/widgets/MusicWidget.qml qml/widgets/QuickNotesWidget.qml
        qml/pages/HomePage.qml qml/pages/FilesPage.qml qml/pages/SettingsPage.qml qml/pages/InstallerPage.qml qml/pages/TerminalPage.qml qml/pages/AboutPage.qml
        qml/pages/MediaPlayerPage.qml qml/pages/TextEditorPage.qml qml/pages/ImageViewerPage.qml qml/pages/PackageManagerPage.qml qml/pages/AppStorePage.qml qml/pages/CalculatorPage.qml qml/pages/BrowserPage.qml
    RESOURCES qml/assets/brainos-mark.svg qml/assets/wallpapers/aurora.svg qml/assets/wallpapers/horizon.svg qml/assets/wallpapers/glass.svg ${BRAINOS_ICON_FILES}
    SOURCES src/main.cpp src/common/BrainState.h src/common/BrainState.cpp src/common/InstallerService.h src/common/InstallerService.cpp src/common/SystemService.h src/common/SystemService.cpp src/common/SystemState.h src/common/SystemState.cpp src/common/SzhTerminalService.h src/common/SzhTerminalService.cpp src/common/WindowModel.h src/common/WindowModel.cpp src/common/IconProvider.cpp src/common/IconProvider.h
)
install(TARGETS brainos-desktop RUNTIME DESTINATION opt/brainos/bin)
install(PROGRAMS packaging/scripts/brainos-session DESTINATION opt/brainos/bin)
install(PROGRAMS packaging/scripts/brainos-install packaging/scripts/bundle-qt-runtime.sh DESTINATION opt/brainos/libexec)
install(FILES packaging/systemd/brainos-shell.service DESTINATION lib/systemd/system)
target_link_libraries(brainos-desktop PRIVATE Qt6::Core Qt6::DBus Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::WaylandCompositor Qt6::WebEngineQuick)
