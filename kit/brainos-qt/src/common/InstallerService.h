#pragma once
#include <QObject>
#include <QProcess>
#include <QVariantList>
class InstallerService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList disks READ disks NOTIFY disksChanged)
    Q_PROPERTY(bool efiDetected READ efiDetected NOTIFY hardwareChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString log READ log NOTIFY logChanged)
public:
    explicit InstallerService(QObject *parent = nullptr);
    QVariantList disks() const; bool efiDetected() const; bool running() const;
    qreal progress() const; QString status() const; QString log() const;
    Q_INVOKABLE void refreshHardware();
    Q_INVOKABLE bool startInstall(const QVariantMap &configuration);
    Q_INVOKABLE void cancel();
signals:
    void disksChanged(); void hardwareChanged(); void runningChanged();
    void progressChanged(); void statusChanged(); void logChanged(); void finished(bool success);
private:
    QString installerProgram() const;
    bool validateConfiguration(const QVariantMap &configuration, QString *error) const;
    void appendLog(const QString &text); void parseOutput(const QString &text);
    QVariantList m_disks; bool m_efiDetected = false; qreal m_progress = 0;
    QString m_status = QStringLiteral("Ready"); QString m_log; QProcess m_process;
};
