#pragma once

#include <QObject>
#include <QSettings>
#include <QTimer>
#include <QDateTime>

class BrainState final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString clockText READ clockText NOTIFY clockChanged)
    Q_PROPERTY(QString dateText READ dateText NOTIFY clockChanged)
    Q_PROPERTY(QString bootMessage READ bootMessage NOTIFY bootMessageChanged)
    Q_PROPERTY(qreal bootProgress READ bootProgress NOTIFY bootProgressChanged)
    Q_PROPERTY(bool desktopReady READ desktopReady NOTIFY desktopReadyChanged)
    Q_PROPERTY(int wallpaperIndex READ wallpaperIndex WRITE setWallpaperIndex NOTIFY wallpaperIndexChanged)
    Q_PROPERTY(bool animationsEnabled READ animationsEnabled WRITE setAnimationsEnabled NOTIFY shellSettingsChanged)
    Q_PROPERTY(bool widgetsEnabled READ widgetsEnabled WRITE setWidgetsEnabled NOTIFY shellSettingsChanged)
    Q_PROPERTY(bool translucencyEnabled READ translucencyEnabled WRITE setTranslucencyEnabled NOTIFY shellSettingsChanged)
    Q_PROPERTY(QString quickNote READ quickNote WRITE setQuickNote NOTIFY quickNoteChanged)
public:
    explicit BrainState(QObject *parent = nullptr);
    QString clockText() const;
    QString dateText() const;
    QString bootMessage() const;
    qreal bootProgress() const;
    bool desktopReady() const;
    int wallpaperIndex() const;
    bool animationsEnabled() const;
    bool widgetsEnabled() const;
    bool translucencyEnabled() const;
    QString quickNote() const;
    void setWallpaperIndex(int index);
    void setAnimationsEnabled(bool enabled);
    void setWidgetsEnabled(bool enabled);
    void setTranslucencyEnabled(bool enabled);
    void setQuickNote(const QString &note);
    Q_INVOKABLE void setDesktopReady(bool ready);
    Q_INVOKABLE void cycleWallpaper();
    Q_INVOKABLE void resetBoot();
signals:
    void clockChanged();
    void bootMessageChanged();
    void bootProgressChanged();
    void desktopReadyChanged();
    void wallpaperIndexChanged();
    void shellSettingsChanged();
    void quickNoteChanged();
private:
    void updateClock();
    void updateBoot();
    QTimer m_clockTimer;
    QTimer m_bootTimer;
    QDateTime m_now;
    QSettings m_settings;
    QString m_clockText;
    QString m_dateText;
    QString m_bootMessage;
    qreal m_bootProgress = 0.0;
    bool m_desktopReady = false;
    int m_wallpaperIndex = 0;
    bool m_animationsEnabled = true;
    bool m_widgetsEnabled = true;
    bool m_translucencyEnabled = true;
    QString m_quickNote;
};
