#include "SzhTerminalService.h"

#include <QDir>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QStandardPaths>

namespace {
constexpr auto SzhLauncher = "/opt/brainos/szh/szh-shell";
}

SzhTerminalService::SzhTerminalService(QObject *parent)
    : QObject(parent)
{
    m_process.setProcessChannelMode(QProcess::MergedChannels);

    connect(&m_process, &QProcess::started, this, [this] {
        setRunning(true);
    });

    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this] {
        const QByteArray data = m_process.readAllStandardOutput();
        if (!data.isEmpty())
            emit terminalOutput(QString::fromUtf8(data));
    });

    connect(&m_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus status) {
        setRunning(false);
        emit sessionFinished(status == QProcess::NormalExit ? exitCode : 128);
    });

    connect(&m_process, &QProcess::errorOccurred, this,
            [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            setRunning(false);
            emit terminalOutput(QStringLiteral("[terminal] Could not start the PTY session. Is util-linux 'script' installed?\n"));
        }
    });
}

bool SzhTerminalService::running() const
{
    return m_running;
}

QString SzhTerminalService::shellName() const
{
    return m_shellName;
}

bool SzhTerminalService::startSzh()
{
    if (!QFileInfo(QString::fromLatin1(SzhLauncher)).isExecutable()) {
        emit terminalOutput(QStringLiteral("[SZH] Runtime is not installed. Rebuild BrainOS with the SZH runtime bundle.\n"));
        return false;
    }

    return startSession(QStringLiteral("SZH"), QString::fromLatin1(SzhLauncher));
}

bool SzhTerminalService::startHost()
{
    return startSession(QStringLiteral("Host"), QStringLiteral("/bin/sh -i"));
}

bool SzhTerminalService::startSession(const QString &name, const QString &command)
{
    const QString script = QStandardPaths::findExecutable(QStringLiteral("script"));
    if (script.isEmpty()) {
        emit terminalOutput(QStringLiteral("[terminal] util-linux 'script' is required for a pseudo-terminal. Install util-linux and restart BrainOS.\n"));
        return false;
    }

    if (m_process.state() != QProcess::NotRunning)
        stop();

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("TERM"), QStringLiteral("xterm-256color"));
    environment.insert(QStringLiteral("COLORTERM"), QStringLiteral("truecolor"));
    environment.insert(QStringLiteral("LANG"),
                       environment.value(QStringLiteral("LANG"), QStringLiteral("C.UTF-8")));
    if (!environment.contains(QStringLiteral("HOME")))
        environment.insert(QStringLiteral("HOME"), QDir::homePath());
    if (name == QStringLiteral("SZH")) {
        environment.insert(QStringLiteral("SZH_ROOT"), QStringLiteral("/opt/brainos/szh"));
        environment.insert(QStringLiteral("HISTFILE"),
                           QDir::home().filePath(QStringLiteral(".szh_history")));
    }

    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(QDir::homePath());
    setShellName(name);

    // util-linux script supplies a PTY so readline, Ctrl+C and shell input use
    // terminal line discipline rather than one-shot /bin/sh command processes.
    m_process.start(script, {
        QStringLiteral("-q"),
        QStringLiteral("-f"),
        QStringLiteral("-e"),
        QStringLiteral("-c"),
        command,
        QStringLiteral("/dev/null")
    });

    if (!m_process.waitForStarted(3000)) {
        emit terminalOutput(QStringLiteral("[terminal] Failed to start the PTY process: ")
                            + m_process.errorString() + QLatin1Char('\n'));
        setRunning(false);
        return false;
    }

    setRunning(true);
    return true;
}

bool SzhTerminalService::sendInput(const QString &text)
{
    if (!m_running || m_process.state() == QProcess::NotRunning)
        return false;

    const QByteArray data = text.toUtf8();
    return m_process.write(data) == data.size();
}

void SzhTerminalService::sendInterrupt()
{
    if (m_running)
        m_process.write(QByteArray(1, char(3)));
}

void SzhTerminalService::sendEof()
{
    if (m_running)
        m_process.write(QByteArray(1, char(4)));
}

void SzhTerminalService::stop()
{
    if (m_process.state() == QProcess::NotRunning) {
        setRunning(false);
        return;
    }

    m_process.write("exit\n");
    if (!m_process.waitForFinished(1000)) {
        m_process.terminate();
        if (!m_process.waitForFinished(800)) {
            m_process.kill();
            m_process.waitForFinished(800);
        }
    }
    setRunning(false);
}

void SzhTerminalService::setRunning(bool running)
{
    if (m_running == running)
        return;
    m_running = running;
    emit runningChanged();
}

void SzhTerminalService::setShellName(const QString &name)
{
    if (m_shellName == name)
        return;
    m_shellName = name;
    emit shellChanged();
}
