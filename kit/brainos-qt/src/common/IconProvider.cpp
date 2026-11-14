#include "IconProvider.h"

#include <QHash>
#include <QIcon>
#include <QPixmap>

BrainOsIconProvider::BrainOsIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

QString BrainOsIconProvider::resolveAlias(const QString &name)
{
    static const QHash<QString, QString> map = {
        {"browser", "applications-internet"}, {"store", "applications-software"},
        {"calculator", "accessories-calculator"}, {"files", "system-file-manager"},
        {"folder", "folder"}, {"terminal", "utilities-terminal"},
        {"settings", "preferences-system"}, {"download", "folder-download"},
        {"trash", "user-trash"}, {"image", "image-x-generic"},
        {"music", "multimedia-player"}, {"cpu", "utilities-system-monitor"},
        {"memory", "utilities-system-monitor"}, {"network", "network-wireless"},
        {"wifi", "network-wireless"}, {"battery", "battery"},
        {"volume", "audio-volume-high"}, {"mute", "audio-volume-muted"},
        {"play", "media-playback-start"}, {"pause", "media-playback-pause"},
        {"next", "media-skip-forward"}, {"previous", "media-skip-backward"},
        {"bell", "notifications"}, {"close", "window-close"},
        {"search", "edit-find"}, {"back", "go-previous"}, {"forward", "go-next"},
        {"browser-window", "applications-internet"}, {"store-bag", "applications-software"}
    };
    return map.value(name, name);
}

QPixmap BrainOsIconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    const QString alias = resolveAlias(id);
    const int extent = requestedSize.isValid() ? qMax(requestedSize.width(), requestedSize.height()) : 32;
    QIcon icon = QIcon::fromTheme(alias);
    if (icon.isNull() && alias != id)
        icon = QIcon::fromTheme(id);
    QPixmap pixmap = icon.pixmap(extent, extent);
    if (pixmap.isNull()) {
        QPixmap fallback(extent, extent);
        fallback.fill(Qt::transparent);
        pixmap = fallback;
    }
    if (size)
        *size = pixmap.size();
    return pixmap;
}
