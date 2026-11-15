#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QUrl>
#include <QtQuick/QQuickWindow>

#include "common/BrainState.h"
#include "common/InstallerService.h"
#include "common/SystemService.h"
#include "common/SystemState.h"
#include "common/WindowModel.h"

int main(int argc, char **argv)
{
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("BrainOS"));
    app.setOrganizationName(QStringLiteral("BrainOS"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("BrainOS desktop shell"));
    parser.addHelpOption();

    const QCommandLineOption socketOption(
        QStringLiteral("socket-name"),
        QStringLiteral("Wayland socket name."),
        QStringLiteral("name"),
        QStringLiteral("brainos"));
    const QCommandLineOption screenshotOption(
        QStringLiteral("screenshot"),
        QStringLiteral("Save a desktop screenshot and exit."),
        QStringLiteral("path"));
    const QCommandLineOption screenshotDelayOption(
        QStringLiteral("screenshot-delay"),
        QStringLiteral("Screenshot delay in milliseconds."),
        QStringLiteral("milliseconds"),
        QStringLiteral("4200"));
    const QCommandLineOption qaWindowsOption(
        QStringLiteral("qa-windows"),
        QStringLiteral("Open Files and Terminal for visual QA."));

    parser.addOption(socketOption);
    parser.addOption(screenshotOption);
    parser.addOption(screenshotDelayOption);
    parser.addOption(qaWindowsOption);
    parser.process(app);

    BrainState brain;
    InstallerService installer;
    SystemService system;
    WindowModel windows;
    SystemState systemState;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(QStringLiteral("systemState"), &systemState);
    engine.rootContext()->setContextProperty(QStringLiteral("brain"), &brain);
    engine.rootContext()->setContextProperty(QStringLiteral("installer"), &installer);
    engine.rootContext()->setContextProperty(QStringLiteral("system"), &system);
    engine.rootContext()->setContextProperty(QStringLiteral("windows"), &windows);
    engine.rootContext()->setContextProperty(QStringLiteral("waylandSocketName"), parser.value(socketOption));
    engine.rootContext()->setContextProperty(QStringLiteral("qaOpenWindows"), parser.isSet(qaWindowsOption));

    // loadFromModule() was added after Qt 6.4; this resource URL works on Ubuntu 24.04.
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/BrainOS/qml/Compositor.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    if (parser.isSet(screenshotOption)) {
        const QString screenshotPath = parser.value(screenshotOption);
        const int screenshotDelay = qMax(250, parser.value(screenshotDelayOption).toInt());

        QTimer::singleShot(screenshotDelay, &app, [&app, &engine, screenshotPath] {
            QQuickWindow *window = nullptr;
            for (QObject *root : engine.rootObjects()) {
                window = root->findChild<QQuickWindow *>();
                if (window)
                    break;
            }
            if (window)
                window->grabWindow().save(screenshotPath);
            app.quit();
        });
    }

    return app.exec();
}
