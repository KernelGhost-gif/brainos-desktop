#pragma once
#include <QQuickImageProvider>
class BrainOsIconProvider final : public QQuickImageProvider
{
public:
    BrainOsIconProvider();
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;
private:
    static QString resolveAlias(const QString &name);
};
