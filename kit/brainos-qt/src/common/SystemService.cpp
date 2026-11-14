#include "SystemService.h"
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QSysInfo>
#include <QUrl>

SystemService::SystemService(QObject *parent) : QObject(parent)
{
    m_refreshTimer.setInterval(2500);
    connect(&m_refreshTimer, &QTimer::timeout, this, &SystemService::refresh);
    m_refreshTimer.start();
    refresh();
}
QString SystemService::homePath() const { return QDir::homePath(); }
QString SystemService::userName() const { return qEnvironmentVariable("USER", QStringLiteral("user")); }
QString SystemService::hostName() const { return QSysInfo::machineHostName(); }
QString SystemService::packageBackend() const
{
    if (QFileInfo::exists(QStringLiteral("/usr/bin/apt"))) return QStringLiteral("APT");
    if (QFileInfo::exists(QStringLiteral("/usr/bin/dnf"))) return QStringLiteral("DNF");
    if (QFileInfo::exists(QStringLiteral("/usr/bin/pacman"))) return QStringLiteral("Pacman");
    if (QFileInfo::exists(QStringLiteral("/usr/bin/apk"))) return QStringLiteral("APK");
    return QStringLiteral("Unknown");
}
bool SystemService::wineAvailable() const { return !QStandardPaths::findExecutable(QStringLiteral("wine")).isEmpty(); }
int SystemService::batteryLevel() const { return m_batteryLevel; }
qreal SystemService::cpuUsage() const { return qreal(m_cpuUsage) / 100.0; }
qreal SystemService::memoryUsage() const { return qreal(m_memoryUsage) / 100.0; }
qreal SystemService::diskUsage() const { return qreal(m_diskUsage) / 100.0; }
qreal SystemService::networkDownKbps() const { return m_networkDownKbps; }
bool SystemService::mediaAvailable() const { return m_mediaAvailable; }
bool SystemService::mediaPlaying() const { return m_mediaPlaying; }
QString SystemService::mediaTitle() const { return m_mediaTitle; }
QString SystemService::mediaArtist() const { return m_mediaArtist; }
QString SystemService::fileUrl(const QString &path) const { return QUrl::fromLocalFile(resolvePath(path)).toString(); }
bool SystemService::pathExists(const QString &path) const { return QFileInfo::exists(resolvePath(path)); }
bool SystemService::directoryExists(const QString &path) const { return QFileInfo(resolvePath(path)).isDir(); }
QString SystemService::resolvePath(const QString &path, const QString &base) const
{
    const QString value = path.trimmed();
    if (value.isEmpty()) return QDir(base.isEmpty() ? homePath() : base).absolutePath();
    if (value == QStringLiteral("~")) return homePath();
    if (value.startsWith(QStringLiteral("~/"))) return QDir(homePath()).absoluteFilePath(value.mid(2));
    const QDir root(base.isEmpty() ? homePath() : base);
    return QDir::cleanPath(QDir::isAbsolutePath(value) ? value : root.absoluteFilePath(value));
}
QVariantList SystemService::listDirectory(const QString &path) const
{
    QVariantList result; const QFileInfoList entries = QDir(resolvePath(path)).entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden, QDir::DirsFirst | QDir::Name);
    for (const QFileInfo &info : entries) {
        QVariantMap item; item.insert(QStringLiteral("name"), info.fileName()); item.insert(QStringLiteral("path"), info.absoluteFilePath());
        item.insert(QStringLiteral("isDir"), info.isDir()); item.insert(QStringLiteral("size"), info.size());
        item.insert(QStringLiteral("modified"), info.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm"))); item.insert(QStringLiteral("suffix"), info.suffix().toLower()); result.append(item);
    }
    return result;
}
bool SystemService::openPath(const QString &path) const { return QProcess::startDetached(QStringLiteral("xdg-open"), {resolvePath(path)}); }
QString SystemService::readTextFile(const QString &path) const
{
    QFile file(resolvePath(path)); if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return {};
    return QString::fromUtf8(file.read(2 * 1024 * 1024));
}
bool SystemService::writeTextFile(const QString &path, const QString &content) const
{
    const QString resolved = resolvePath(path); QDir().mkpath(QFileInfo(resolved).absolutePath()); QFile file(resolved);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) return false;
    const QByteArray data = content.toUtf8(); if (data.size() > 2 * 1024 * 1024) return false;
    return file.write(data) == data.size();
}
void SystemService::runCommand(const QString &command, const QString &workingDirectory)
{
    static const QRegularExpression unsafe(QStringLiteral("(^|[;&|<>`$\\n])\\s*(sudo|su|pkexec|reboot|poweroff|shutdown|mkfs|fdisk|parted|dd|wipefs)\\b"));
    if (command.size() > 4096 || unsafe.match(command).hasMatch()) { emit commandOutput(-1, QStringLiteral("Blocked command; destructive/admin commands require the dedicated system flow.\\n")); emit commandFinished(-1, 126); return; }
    const int requestId = ++m_requestId; auto *process = new QProcess(this); process->setWorkingDirectory(resolvePath(workingDirectory)); process->setProcessChannelMode(QProcess::MergedChannels);
    connect(process, &QProcess::readyRead, this, [this, process, requestId] { emit commandOutput(requestId, QString::fromLocal8Bit(process->readAll())); });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this, [this, process, requestId](int code, QProcess::ExitStatus status) { emit commandFinished(requestId, status == QProcess::NormalExit ? code : 128); process->deleteLater(); });
    process->start(QStringLiteral("/bin/sh"), {QStringLiteral("-lc"), command});
}
void SystemService::installPackage(const QString &name)
{
    static const QRegularExpression valid(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9.+:_@/-]{0,127}$"));
    if (!valid.match(name).hasMatch()) { emit commandOutput(-1, QStringLiteral("Invalid package identifier.\\n")); emit commandFinished(-1, 2); return; }
    QString program; QStringList args; const QString backend = packageBackend();
    if (backend == QStringLiteral("APT")) { program = QStringLiteral("pkexec"); args = {QStringLiteral("apt"), QStringLiteral("install"), QStringLiteral("-y"), name}; }
    else if (backend == QStringLiteral("DNF")) { program = QStringLiteral("pkexec"); args = {QStringLiteral("dnf"), QStringLiteral("install"), QStringLiteral("-y"), name}; }
    else if (backend == QStringLiteral("Pacman")) { program = QStringLiteral("pkexec"); args = {QStringLiteral("pacman"), QStringLiteral("-S"), QStringLiteral("--noconfirm"), name}; }
    else { emit commandOutput(-1, QStringLiteral("No supported package manager is installed.\\n")); emit commandFinished(-1, 127); return; }
    auto *process = new QProcess(this); process->setProcessChannelMode(QProcess::MergedChannels); const int requestId = ++m_requestId;
    connect(process, &QProcess::readyRead, this, [this, process, requestId] { emit commandOutput(requestId, QString::fromLocal8Bit(process->readAll())); });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this, [this, process, requestId](int code, QProcess::ExitStatus status) { emit commandFinished(requestId, status == QProcess::NormalExit ? code : 128); process->deleteLater(); });
    process->start(program, args);
}
void SystemService::mediaAction(const QString &action)
{
    const QString playerctl = QStandardPaths::findExecutable(QStringLiteral("playerctl"));
    static const QStringList allowed = {QStringLiteral("PlayPause"), QStringLiteral("Next"), QStringLiteral("Previous")};
    if (!allowed.contains(action) || playerctl.isEmpty()) return;
    QProcess::startDetached(playerctl, {action.toLower()});
}
void SystemService::refresh()
{
    const int oldBattery=m_batteryLevel, oldCpu=m_cpuUsage, oldMemory=m_memoryUsage, oldDisk=m_diskUsage; const qreal oldNetwork=m_networkDownKbps;
    const bool oldAvailable=m_mediaAvailable, oldPlaying=m_mediaPlaying; const QString oldTitle=m_mediaTitle, oldArtist=m_mediaArtist;
    QDir power(QStringLiteral("/sys/class/power_supply")); m_batteryLevel=-1;
    for (const QString &entry : power.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const QString base=power.filePath(entry); QFile type(base+QStringLiteral("/type")); if (!type.open(QIODevice::ReadOnly)) continue;
        if (QString::fromLatin1(type.readAll()).trimmed()!=QStringLiteral("Battery")) continue;
        QFile capacity(base+QStringLiteral("/capacity")); if (capacity.open(QIODevice::ReadOnly)) m_batteryLevel=capacity.readAll().trimmed().toInt(); break;
    }
    QFile meminfo(QStringLiteral("/proc/meminfo"));
    if (meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) { const QString data=QString::fromLatin1(meminfo.readAll()); QRegularExpression total(QStringLiteral("MemTotal:\\s+(\\d+)")), available(QStringLiteral("MemAvailable:\\s+(\\d+)")); auto t=total.match(data), a=available.match(data); if(t.hasMatch()&&a.hasMatch()){qint64 all=t.captured(1).toLongLong(),free=a.captured(1).toLongLong();m_memoryUsage=all>0?int(100*(all-free)/all):0;} }
    QStorageInfo storage(QStringLiteral("/")); m_diskUsage=storage.isValid()&&storage.bytesTotal()>0?int(100*(storage.bytesTotal()-storage.bytesAvailable())/storage.bytesTotal()):0;
    QFile stat(QStringLiteral("/proc/stat"));
    if (stat.open(QIODevice::ReadOnly | QIODevice::Text)) { const QList<QByteArray> parts=stat.readLine().simplified().split(' '); if(parts.size()>=5){quint64 idle=parts[4].toULongLong(),total=0;for(int i=1;i<parts.size();++i)total+=parts[i].toULongLong();if(m_lastCpuTotal>0&&total>m_lastCpuTotal)m_cpuUsage=qBound(0,int(100*(1.0-double(idle-m_lastCpuIdle)/double(total-m_lastCpuTotal))),100);m_lastCpuIdle=idle;m_lastCpuTotal=total;} }
    QFile netdev(QStringLiteral("/proc/net/dev"));
    if (netdev.open(QIODevice::ReadOnly | QIODevice::Text)) { const QList<QByteArray> lines=netdev.readAll().split('\n'); quint64 received=0; for(int i=2;i<lines.size();++i){QByteArray line=lines[i].trimmed();if(line.isEmpty())continue;int colon=line.indexOf(':');if(colon<0)continue;QByteArray iface=line.left(colon).trimmed();if(iface=="lo")continue;QList<QByteArray> cols=line.mid(colon+1).simplified().split(' ');if(!cols.isEmpty())received+=cols[0].toULongLong();} qint64 now=QDateTime::currentMSecsSinceEpoch();if(m_lastNetworkTime>0&&now>m_lastNetworkTime)m_networkDownKbps=double(received-m_lastNetworkBytes)*1000.0/double(now-m_lastNetworkTime)/1024.0;m_lastNetworkBytes=received;m_lastNetworkTime=now; }
    const QString playerctl=QStandardPaths::findExecutable(QStringLiteral("playerctl"));
    if (!playerctl.isEmpty()) { auto query=[playerctl](const QStringList &args){QProcess p;p.start(playerctl,args);if(!p.waitForFinished(700))return QString();return QString::fromUtf8(p.readAllStandardOutput()).trimmed();};m_mediaTitle=query({QStringLiteral("metadata"),QStringLiteral("--format"),QStringLiteral("{{title}}")});m_mediaArtist=query({QStringLiteral("metadata"),QStringLiteral("--format"),QStringLiteral("{{artist}}")});m_mediaPlaying=query({QStringLiteral("status")})==QStringLiteral("Playing");m_mediaAvailable=!m_mediaTitle.isEmpty(); }
    else { m_mediaAvailable=false; m_mediaPlaying=false; m_mediaTitle.clear(); m_mediaArtist.clear(); }
    if(oldBattery!=m_batteryLevel||oldCpu!=m_cpuUsage||oldMemory!=m_memoryUsage||oldDisk!=m_diskUsage||!qFuzzyCompare(oldNetwork+1,m_networkDownKbps+1)||oldAvailable!=m_mediaAvailable||oldPlaying!=m_mediaPlaying||oldTitle!=m_mediaTitle||oldArtist!=m_mediaArtist)emit metricsChanged();
}
