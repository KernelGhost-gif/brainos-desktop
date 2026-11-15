#pragma once

#include <QObject>
#include <QProcess>
#include <QString>

class SzhTerminalService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QString shellName READ shellName NOTIFY shellChanged)

public:
    explicit SzhTerminalService(QObject *parent = nullptr);

    bool running() const;
    QString shellName() const;

    Q_INVOKABLE bool startSzh();
    Q_INVOKABLE bool startHost();
    Q_INVOKABLE bool sendInput(const QString &text);
    Q_INVOKABLE void sendInterrupt();
    Q_INVOKABLE void sendEof();
    Q_INVOKABLE void stop();

signals:
    void terminalOutput(const QString &text);
    void runningChanged();
    void shellChanged();
    void sessionFinished(int exitCode);

private:
    bool startSession(const QString &name, const QString &command);
    void setRunning(bool running);
    void setShellName(const QString &name);

    QProcess m_process;
    bool m_running = false;
    QString m_shellName = QStringLiteral("Stopped");
};
