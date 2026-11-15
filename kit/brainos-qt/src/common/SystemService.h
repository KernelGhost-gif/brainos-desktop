#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QStringList>

class SystemService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString homePath READ homePath CONSTANT)
    Q_PROPERTY(QString userName READ userName CONSTANT)
    Q_PROPERTY(QString hostName READ hostName CONSTANT)
    Q_PROPERTY(QString packageBackend READ packageBackend CONSTANT)
    Q_PROPERTY(bool wineAvailable READ wineAvailable CONSTANT)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY metricsChanged)
    Q_PROPERTY(qreal cpuUsage READ cpuUsage NOTIFY metricsChanged)
    Q_PROPERTY(qreal memoryUsage READ memoryUsage NOTIFY metricsChanged)
    Q_PROPERTY(qreal diskUsage READ diskUsage NOTIFY metricsChanged)
    Q_PROPERTY(qreal networkDownKbps READ networkDownKbps NOTIFY metricsChanged)
    Q_PROPERTY(bool mediaAvailable READ mediaAvailable NOTIFY metricsChanged)
    Q_PROPERTY(bool mediaPlaying READ mediaPlaying NOTIFY metricsChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY metricsChanged)
    Q_PROPERTY(QString mediaArtist READ mediaArtist NOTIFY metricsChanged)
public:
    explicit SystemService(QObject *parent = nullptr);
    QString homePath() const;
    QString userName() const;
    QString hostName() const;
    QString packageBackend() const;
    bool wineAvailable() const;
    int batteryLevel() const;
    qreal cpuUsage() const;
    qreal memoryUsage() const;
    qreal diskUsage() const;
    qreal networkDownKbps() const;
    bool mediaAvailable() const;
    bool mediaPlaying() const;
    QString mediaTitle() const;
    QString mediaArtist() const;
    Q_INVOKABLE QString fileUrl(const QString &path) const;
    Q_INVOKABLE bool pathExists(const QString &path) const;
    Q_INVOKABLE bool directoryExists(const QString &path) const;
    Q_INVOKABLE QString resolvePath(const QString &path, const QString &base = {}) const;
    Q_INVOKABLE QVariantList listDirectory(const QString &path) const;
    Q_INVOKABLE bool openPath(const QString &path) const;
    Q_INVOKABLE QString readTextFile(const QString &path) const;
    Q_INVOKABLE bool writeTextFile(const QString &path, const QString &content) const;
    Q_INVOKABLE void runCommand(const QString &command, const QString &workingDirectory = {});
    Q_INVOKABLE void installPackage(const QString &name);
    Q_INVOKABLE void mediaAction(const QString &action);
signals:
    void commandOutput(int requestId, const QString &text);
    void commandFinished(int requestId, int exitCode);
    void metricsChanged();
private:
    void refresh();
    QTimer m_refreshTimer;
    int m_batteryLevel = -1;
    int m_cpuUsage = 0;
    int m_memoryUsage = 0;
    int m_diskUsage = 0;
    qreal m_networkDownKbps = 0;
    bool m_mediaAvailable = false;
    bool m_mediaPlaying = false;
    QString m_mediaTitle;
    QString m_mediaArtist;
    quint64 m_lastCpuTotal = 0;
    quint64 m_lastCpuIdle = 0;
    qint64 m_lastNetworkTime = 0;
    quint64 m_lastNetworkBytes = 0;
    int m_requestId = 0;
};
