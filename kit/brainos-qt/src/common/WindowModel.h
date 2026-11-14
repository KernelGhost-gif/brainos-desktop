#pragma once
#include <QAbstractListModel>
#include <QPointer>
#include <QRectF>
#include <QVector>
class QWaylandXdgSurface;
class QWaylandXdgToplevel;
class WindowModel final : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles { ShellSurfaceRole=Qt::UserRole+1,TitleRole,AppIdRole,XRole,YRole,WRole,HRole,ActiveRole,MinimizedRole,MaximizedRole };
    Q_ENUM(Roles)
    explicit WindowModel(QObject *parent=nullptr);
    int rowCount(const QModelIndex &parent=QModelIndex()) const override;
    QVariant data(const QModelIndex &index,int role=Qt::DisplayRole) const override;
    QHash<int,QByteArray> roleNames() const override;
    Q_INVOKABLE void addWindow(QObject *shellSurface,QObject *toplevel);
    Q_INVOKABLE void removeWindow(QObject *shellSurface);
    Q_INVOKABLE void activateWindow(int index);
    Q_INVOKABLE void moveWindow(int index,qreal x,qreal y);
    Q_INVOKABLE void setGeometry(int index,qreal x,qreal y,qreal w,qreal h);
    Q_INVOKABLE void closeWindow(int index);
    Q_INVOKABLE void raiseWindow(int index);
    Q_INVOKABLE void minimizeWindow(int index);
    Q_INVOKABLE void toggleMaximize(int index,qreal availableWidth,qreal availableHeight);
private:
    struct WindowEntry { QPointer<QObject> shellSurface; QPointer<QObject> toplevel; QString title; QString appId; QRectF geometry; QRectF restoreGeometry; bool active=false; bool minimized=false; bool maximized=false; };
    int indexOfSurface(QObject *shellSurface) const;
    void refreshFromToplevel(int row);
    QVector<WindowEntry> m_windows;
    int m_nextOffset=0;
    int m_active=-1;
};
