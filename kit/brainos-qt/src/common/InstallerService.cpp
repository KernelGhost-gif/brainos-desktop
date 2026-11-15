#include "InstallerService.h"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QSet>

InstallerService::InstallerService(QObject *parent) : QObject(parent)
{
    m_process.setProcessChannelMode(QProcess::MergedChannels);
    connect(&m_process, &QProcess::readyRead, this, [this] { parseOutput(QString::fromLocal8Bit(m_process.readAll())); });
    connect(&m_process, &QProcess::started, this, [this] { emit runningChanged(); });
    connect(&m_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
        const bool success = status == QProcess::NormalExit && exitCode == 0;
        m_progress = success ? 1.0 : m_progress;
        m_status = success ? QStringLiteral("Installation complete") : QStringLiteral("Installation failed");
        emit progressChanged(); emit statusChanged(); emit runningChanged(); emit finished(success);
    });
    refreshHardware();
}
QVariantList InstallerService::disks() const { return m_disks; }
bool InstallerService::efiDetected() const { return m_efiDetected; }
bool InstallerService::running() const { return m_process.state() != QProcess::NotRunning; }
qreal InstallerService::progress() const { return m_progress; }
QString InstallerService::status() const { return m_status; }
QString InstallerService::log() const { return m_log; }
void InstallerService::refreshHardware()
{
    m_efiDetected = QFileInfo::exists(QStringLiteral("/sys/firmware/efi")); emit hardwareChanged();
    QProcess lsblk; lsblk.start(QStringLiteral("lsblk"), {QStringLiteral("-J"), QStringLiteral("-b"), QStringLiteral("-o"), QStringLiteral("NAME,PATH,SIZE,MODEL,TYPE,MOUNTPOINTS,FSTYPE,PTTYPE")});
    if (!lsblk.waitForFinished(4000)) { m_disks.clear(); emit disksChanged(); return; }
    QSet<QString> systemDisks;
    const QStringList protectedMounts = {
        QStringLiteral("/"),
        QStringLiteral("/run/live/medium"),
        QStringLiteral("/cdrom")
    };
    for (const QString &mountPoint : protectedMounts) {
        QProcess sourceFinder;
        sourceFinder.start(QStringLiteral("findmnt"), {
            QStringLiteral("--evaluate"), QStringLiteral("-rn"),
            QStringLiteral("-o"), QStringLiteral("SOURCE"),
            QStringLiteral("--target"), mountPoint
        });
        if (!sourceFinder.waitForFinished(1500) || sourceFinder.exitCode() != 0)
            continue;

        QString source = QString::fromLocal8Bit(sourceFinder.readAllStandardOutput()).trimmed();
        const qsizetype subvolumeMarker = source.indexOf(QLatin1Char('['));
        if (subvolumeMarker >= 0)
            source.truncate(subvolumeMarker);
        if (!source.startsWith(QStringLiteral("/dev/")))
            continue;

        const QString canonicalSource = QFileInfo(source).canonicalFilePath();
        if (!canonicalSource.isEmpty())
            source = canonicalSource;

        QProcess ancestry;
        ancestry.start(QStringLiteral("lsblk"), {
            QStringLiteral("-s"), QStringLiteral("-n"),
            QStringLiteral("-p"), QStringLiteral("-o"),
            QStringLiteral("PATH,TYPE"), source
        });
        if (!ancestry.waitForFinished(2000) || ancestry.exitCode() != 0)
            continue;

        const QStringList lines = QString::fromLocal8Bit(ancestry.readAllStandardOutput()).split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            const QStringList columns = line.simplified().split(QLatin1Char(' '));
            if (columns.size() < 2 || columns.constLast() != QStringLiteral("disk"))
                continue;
            const QString canonicalDisk = QFileInfo(columns.constFirst()).canonicalFilePath();
            systemDisks.insert(canonicalDisk.isEmpty() ? columns.constFirst() : canonicalDisk);
        }
    }
    const QJsonDocument document = QJsonDocument::fromJson(lsblk.readAllStandardOutput());
    QVariantList detected;
    for (const QJsonValue &value : document.object().value(QStringLiteral("blockdevices")).toArray()) {
        const QJsonObject object = value.toObject();
        if (object.value(QStringLiteral("type")).toString() != QStringLiteral("disk")) continue;
        const QString path = object.value(QStringLiteral("path")).toString();
        QVariantMap disk;
        disk.insert(QStringLiteral("name"), object.value(QStringLiteral("name")).toString());
        disk.insert(QStringLiteral("path"), path);
        disk.insert(QStringLiteral("size"), object.value(QStringLiteral("size")).toVariant().toLongLong());
        disk.insert(QStringLiteral("model"), object.value(QStringLiteral("model")).toString().trimmed());
        disk.insert(QStringLiteral("partitionTable"), object.value(QStringLiteral("pttype")).toString());
        disk.insert(QStringLiteral("systemDisk"), systemDisks.contains(QFileInfo(path).canonicalFilePath().isEmpty() ? path : QFileInfo(path).canonicalFilePath()));
        disk.insert(QStringLiteral("partitions"), object.value(QStringLiteral("children")).toArray().size());
        detected.append(disk);
    }
    m_disks = detected; emit disksChanged();
}
QString InstallerService::installerProgram() const
{
    const QString installed = QStringLiteral("/opt/brainos/libexec/brainos-install");
    if (QFileInfo::exists(installed)) return installed;
    const QDir applicationDirectory(QCoreApplication::applicationDirPath());
    const QString development = applicationDirectory.absoluteFilePath(QStringLiteral("../packaging/scripts/brainos-install"));
    return QFileInfo(development).exists() ? QFileInfo(development).absoluteFilePath() : installed;
}
bool InstallerService::validateConfiguration(const QVariantMap &configuration, QString *error) const
{
    const QString device = configuration.value(QStringLiteral("device")).toString();
    const QString userName = configuration.value(QStringLiteral("userName")).toString();
    const QString hostName = configuration.value(QStringLiteral("hostName")).toString();
    const QString password = configuration.value(QStringLiteral("password")).toString();
    const QString confirmation = configuration.value(QStringLiteral("confirmation")).toString();
    bool knownDevice = false, systemDisk = false;
    for (const QVariant &value : m_disks) {
        const QVariantMap disk = value.toMap();
        if (disk.value(QStringLiteral("path")).toString() == device) { knownDevice = true; systemDisk = disk.value(QStringLiteral("systemDisk")).toBool(); break; }
    }
    if (!knownDevice || systemDisk) { *error = QStringLiteral("Select a detected non-system disk."); return false; }
    if (confirmation != QStringLiteral("ERASE ") + device) { *error = QStringLiteral("Type the exact erase confirmation."); return false; }
    static const QRegularExpression accountPattern(QStringLiteral("^[a-z_][a-z0-9_-]{0,30}$"));
    static const QRegularExpression hostPattern(QStringLiteral("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$"));
    if (!accountPattern.match(userName).hasMatch() || !hostPattern.match(hostName).hasMatch()) { *error = QStringLiteral("User or host name contains unsupported characters."); return false; }
    if (password.size() < 8 || password.contains(QLatin1Char(':')) ||
        password.contains(QLatin1Char('\n')) || password.contains(QLatin1Char('\r'))) {
        *error = QStringLiteral("Use at least 8 characters; colons and line breaks are not allowed.");
        return false;
    }
    return true;
}
bool InstallerService::startInstall(const QVariantMap &configuration)
{
    if (running()) return false;
    QString error;
    if (!validateConfiguration(configuration, &error)) { m_status = error; emit statusChanged(); return false; }
    const QString pkexec = QStandardPaths::findExecutable(QStringLiteral("pkexec"));
    if (pkexec.isEmpty()) { m_status = QStringLiteral("pkexec is required to start the installer."); emit statusChanged(); return false; }
    m_log.clear(); m_progress = 0; m_status = QStringLiteral("Requesting administrator access");
    emit logChanged(); emit progressChanged(); emit statusChanged();
    m_process.start(pkexec, {installerProgram(), QStringLiteral("--json-stdin")});
    if (!m_process.waitForStarted(3000)) { m_status = m_process.errorString(); emit statusChanged(); return false; }
    m_process.write(QJsonDocument(QJsonObject::fromVariantMap(configuration)).toJson(QJsonDocument::Compact));
    m_process.closeWriteChannel(); return true;
}
void InstallerService::cancel() { if (running()) m_process.terminate(); }
void InstallerService::appendLog(const QString &text) { m_log += text; emit logChanged(); }
void InstallerService::parseOutput(const QString &text)
{
    const QStringList lines = text.split('\n');
    static const QRegularExpression progressPattern(QStringLiteral("^PROGRESS\\s+(\\d+)\\s+(.*)$"));
    for (const QString &line : lines) {
        const auto match = progressPattern.match(line.trimmed());
        if (match.hasMatch()) { m_progress = qBound<qreal>(0, match.captured(1).toInt() / 100.0, 1); m_status = match.captured(2); emit progressChanged(); emit statusChanged(); }
        else if (!line.isEmpty()) appendLog(line + '\n');
    }
}
