#pragma once
#include <QObject>
#include <QStringList>
#include <QProcess>
class SystemState final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled NOTIFY wifiChanged)
    Q_PROPERTY(QString wifiSsid READ wifiSsid NOTIFY wifiChanged)
    Q_PROPERTY(int wifiSignal READ wifiSignal NOTIFY wifiChanged)
    Q_PROPERTY(int audioVolume READ audioVolume NOTIFY audioChanged)
    Q_PROPERTY(bool audioMuted READ audioMuted NOTIFY audioChanged)
public:
    explicit SystemState(QObject *parent = nullptr);
    bool wifiEnabled() const { return m_wifiEnabled; }
    QString wifiSsid() const { return m_wifiSsid; }
    int wifiSignal() const { return m_wifiSignal; }
    int audioVolume() const { return m_audioVolume; }
    bool audioMuted() const { return m_audioMuted; }
    Q_INVOKABLE void refresh(); Q_INVOKABLE void toggleWifi(); Q_INVOKABLE void setWifiEnabled(bool enabled); Q_INVOKABLE void setAudioVolume(int volume); Q_INVOKABLE void toggleMute();
signals:
    void wifiChanged(); void audioChanged();
private:
    QString runCapture(const QString &program, const QStringList &args) const;
    void refreshWifi(); void refreshAudio();
    bool m_wifiEnabled = false; QString m_wifiSsid; int m_wifiSignal = 0;
    int m_audioVolume = 50; bool m_audioMuted = false;
};
