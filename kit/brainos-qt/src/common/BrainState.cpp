#include "BrainState.h"

#include <QStringList>

BrainState::BrainState(QObject *parent)
    : QObject(parent)
    , m_settings(QStringLiteral("BrainOS"), QStringLiteral("BrainOS"))
{
    m_wallpaperIndex = m_settings.value(QStringLiteral("desktop/wallpaper"), 0).toInt();
    m_animationsEnabled = m_settings.value(QStringLiteral("shell/animations"), true).toBool();
    m_widgetsEnabled = m_settings.value(QStringLiteral("shell/widgets"), true).toBool();
    m_translucencyEnabled = m_settings.value(QStringLiteral("shell/translucency"), true).toBool();
    m_quickNote = m_settings.value(QStringLiteral("desktop/quickNote")).toString();
    m_bootMessage = QStringLiteral("Preparing BrainOS");
    m_now = QDateTime::currentDateTime();
    m_clockTimer.setInterval(1000);
    m_clockTimer.setSingleShot(false);
    QObject::connect(&m_clockTimer, &QTimer::timeout, this, [this] { updateClock(); });
    m_clockTimer.start();
    m_bootTimer.setInterval(16);
    m_bootTimer.setSingleShot(false);
    QObject::connect(&m_bootTimer, &QTimer::timeout, this, [this] { updateBoot(); });
    m_bootTimer.start();
    updateClock();
}
QString BrainState::clockText() const { return m_clockText; }
QString BrainState::dateText() const { return m_dateText; }
QString BrainState::bootMessage() const { return m_bootMessage; }
qreal BrainState::bootProgress() const { return m_bootProgress; }
bool BrainState::desktopReady() const { return m_desktopReady; }
int BrainState::wallpaperIndex() const { return m_wallpaperIndex; }
bool BrainState::animationsEnabled() const { return m_animationsEnabled; }
bool BrainState::widgetsEnabled() const { return m_widgetsEnabled; }
bool BrainState::translucencyEnabled() const { return m_translucencyEnabled; }
QString BrainState::quickNote() const { return m_quickNote; }
void BrainState::setWallpaperIndex(int index)
{
    index = qBound(0, index, 2);
    if (m_wallpaperIndex == index) return;
    m_wallpaperIndex = index;
    m_settings.setValue(QStringLiteral("desktop/wallpaper"), index);
    emit wallpaperIndexChanged();
}
void BrainState::setAnimationsEnabled(bool enabled)
{
    if (m_animationsEnabled == enabled) return;
    m_animationsEnabled = enabled; m_settings.setValue(QStringLiteral("shell/animations"), enabled); emit shellSettingsChanged();
}
void BrainState::setWidgetsEnabled(bool enabled)
{
    if (m_widgetsEnabled == enabled) return;
    m_widgetsEnabled = enabled; m_settings.setValue(QStringLiteral("shell/widgets"), enabled); emit shellSettingsChanged();
}
void BrainState::setTranslucencyEnabled(bool enabled)
{
    if (m_translucencyEnabled == enabled) return;
    m_translucencyEnabled = enabled; m_settings.setValue(QStringLiteral("shell/translucency"), enabled); emit shellSettingsChanged();
}
void BrainState::setQuickNote(const QString &note)
{
    if (m_quickNote == note) return;
    m_quickNote = note.left(4000); m_settings.setValue(QStringLiteral("desktop/quickNote"), m_quickNote); emit quickNoteChanged();
}
void BrainState::setDesktopReady(bool ready)
{
    if (m_desktopReady == ready) return;
    m_desktopReady = ready; emit desktopReadyChanged();
}
void BrainState::cycleWallpaper() { setWallpaperIndex((m_wallpaperIndex + 1) % 3); }
void BrainState::resetBoot()
{
    m_bootProgress = 0.0; m_desktopReady = false; m_bootMessage = QStringLiteral("Preparing BrainOS"); m_bootTimer.start();
    emit bootProgressChanged(); emit bootMessageChanged(); emit desktopReadyChanged();
}
void BrainState::updateClock()
{
    m_now = QDateTime::currentDateTime();
    const QString newClock = m_now.time().toString(QStringLiteral("hh:mm"));
    const QString newDate = m_now.date().toString(QStringLiteral("ddd, dd MMM")) + QStringLiteral(" · ") + m_now.timeZoneAbbreviation();
    bool changed = false;
    if (m_clockText != newClock) { m_clockText = newClock; changed = true; }
    if (m_dateText != newDate) { m_dateText = newDate; changed = true; }
    if (changed) emit clockChanged();
}
void BrainState::updateBoot()
{
    if (m_desktopReady) return;
    m_bootProgress += 0.0075; m_bootMessage = QStringLiteral("Preparing BrainOS");
    if (m_bootProgress >= 1.0) { m_bootProgress = 1.0; m_desktopReady = true; m_bootTimer.stop(); emit desktopReadyChanged(); }
    emit bootProgressChanged(); emit bootMessageChanged();
}
