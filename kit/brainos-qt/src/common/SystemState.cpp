#include "SystemState.h"
#include <QRegularExpression>

SystemState::SystemState(QObject *parent) : QObject(parent) { refresh(); }
QString SystemState::runCapture(const QString &program, const QStringList &args) const
{
    QProcess p; p.start(program, args); if (!p.waitForFinished(2500)) return {};
    return QString::fromUtf8(p.readAllStandardOutput()).trimmed();
}
void SystemState::refresh() { refreshWifi(); refreshAudio(); }
void SystemState::refreshWifi()
{
    const QString wifiState = runCapture("nmcli", {"-t", "-f", "WIFI", "g"});
    const QStringList active = runCapture("nmcli", {"-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"}).split('\n', Qt::SkipEmptyParts);
    const bool enabled = wifiState.contains("enabled", Qt::CaseInsensitive);
    QString ssid; int signal = 0;
    for (const QString &line : active) { const QStringList parts = line.split(':'); if (parts.size() >= 3 && parts.first() == "yes") { ssid = parts.value(1); signal = parts.value(2).toInt(); break; } }
    if (enabled != m_wifiEnabled || ssid != m_wifiSsid || signal != m_wifiSignal) { m_wifiEnabled = enabled; m_wifiSsid = ssid; m_wifiSignal = signal; emit wifiChanged(); }
}
void SystemState::refreshAudio()
{
    const QString vol = runCapture("pactl", {"get-sink-volume", "@DEFAULT_SINK@"});
    const QString mute = runCapture("pactl", {"get-sink-mute", "@DEFAULT_SINK@"});
    int newVolume = m_audioVolume; bool newMuted = m_audioMuted;
    const QRegularExpression re(R"(\/\s+(\d+)%)"); const auto match = re.match(vol);
    if (match.hasMatch()) newVolume = match.captured(1).toInt();
    if (mute.contains("yes", Qt::CaseInsensitive)) newMuted = true;
    else if (mute.contains("no", Qt::CaseInsensitive)) newMuted = false;
    if (newVolume != m_audioVolume || newMuted != m_audioMuted) { m_audioVolume = newVolume; m_audioMuted = newMuted; emit audioChanged(); }
}
void SystemState::toggleWifi() { setWifiEnabled(!m_wifiEnabled); }
void SystemState::setWifiEnabled(bool enabled) { QProcess::execute("nmcli", {"radio", "wifi", enabled ? "on" : "off"}); refreshWifi(); }
void SystemState::setAudioVolume(int volume) { volume = qBound(0, volume, 150); QProcess::execute("pactl", {"set-sink-volume", "@DEFAULT_SINK@", QString::number(volume) + "%"}); refreshAudio(); }
void SystemState::toggleMute() { QProcess::execute("pactl", {"set-sink-mute", "@DEFAULT_SINK@", m_audioMuted ? "0" : "1"}); refreshAudio(); }
