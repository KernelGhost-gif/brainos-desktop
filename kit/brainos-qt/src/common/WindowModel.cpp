#include "WindowModel.h"
#include <QGuiApplication>
#include <QScreen>
#include <QWaylandXdgSurface>
#include <QWaylandXdgToplevel>
WindowModel::WindowModel(QObject *parent) : QAbstractListModel(parent) {}
int WindowModel::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_windows.size(); }
QVariant WindowModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_windows.size()) return {};
    const auto &w = m_windows[index.row()];
    switch (role) {
    case ShellSurfaceRole: return QVariant::fromValue(w.shellSurface.data());
    case TitleRole: return w.title; case AppIdRole: return w.appId;
    case XRole: return w.geometry.x(); case YRole: return w.geometry.y();
    case WRole: return w.geometry.width(); case HRole: return w.geometry.height();
    case ActiveRole: return w.active; case MinimizedRole: return w.minimized; case MaximizedRole: return w.maximized;
    default: return {};
    }
}
QHash<int, QByteArray> WindowModel::roleNames() const
{
    return {{ShellSurfaceRole,"shellSurface"},{TitleRole,"title"},{AppIdRole,"appId"},{XRole,"windowX"},{YRole,"windowY"},{WRole,"windowWidth"},{HRole,"windowHeight"},{ActiveRole,"active"},{MinimizedRole,"minimized"},{MaximizedRole,"maximized"}};
}
int WindowModel::indexOfSurface(QObject *surface) const { for (int i=0;i<m_windows.size();++i) if(m_windows[i].shellSurface==surface) return i; return -1; }
void WindowModel::addWindow(QObject *surface, QObject *toplevel)
{
    if (!surface || indexOfSurface(surface)>=0) return;
    const QRect screen = QGuiApplication::primaryScreen() ? QGuiApplication::primaryScreen()->availableGeometry() : QRect(0,0,1920,1080);
    const int baseW=qMin(1200,qMax(860,screen.width()-280)), baseH=qMin(760,qMax(580,screen.height()-180));
    const int baseX=screen.x()+(screen.width()-baseW)/2+(m_nextOffset%5)*18, baseY=screen.y()+74+(m_nextOffset%5)*16;
    WindowEntry entry; entry.shellSurface=surface; entry.toplevel=toplevel; entry.geometry=QRectF(baseX,baseY,baseW,baseH); entry.restoreGeometry=entry.geometry; entry.active=true;
    if (toplevel) {
        auto *top=qobject_cast<QWaylandXdgToplevel *>(toplevel);
        if(top) {
            entry.title=top->title(); entry.appId=top->appId();
            QObject::connect(top,&QWaylandXdgToplevel::titleChanged,this,[this,surface]{int row=indexOfSurface(surface);if(row>=0)refreshFromToplevel(row);});
            QObject::connect(top,&QWaylandXdgToplevel::appIdChanged,this,[this,surface]{int row=indexOfSurface(surface);if(row>=0)refreshFromToplevel(row);});
        }
    }
    QObject::connect(surface,&QObject::destroyed,this,[this,surface]{removeWindow(surface);});
    beginInsertRows({},m_windows.size(),m_windows.size()); m_windows.push_back(entry); endInsertRows();
    m_active=m_windows.size()-1; m_nextOffset++;
    for(int i=0;i<m_windows.size();++i)m_windows[i].active=(i==m_active);
    if(!m_windows.isEmpty())emit dataChanged(index(0,0),index(m_windows.size()-1,0),{ActiveRole});
}
void WindowModel::removeWindow(QObject *surface)
{
    int row=indexOfSurface(surface); if(row<0)return;
    beginRemoveRows({},row,row);m_windows.removeAt(row);endRemoveRows();
    if(m_windows.isEmpty()){m_active=-1;return;}
    if(m_active>=m_windows.size())m_active=m_windows.size()-1;
    for(int i=0;i<m_windows.size();++i)m_windows[i].active=(i==m_active);
    emit dataChanged(index(0,0),index(m_windows.size()-1,0),{ActiveRole});
}
void WindowModel::activateWindow(int i)
{
    if(i<0||i>=m_windows.size())return;m_active=i;m_windows[i].minimized=false;
    for(int j=0;j<m_windows.size();++j)m_windows[j].active=(j==m_active);
    emit dataChanged(index(0,0),index(m_windows.size()-1,0),{ActiveRole,MinimizedRole});
}
void WindowModel::moveWindow(int i,qreal x,qreal y)
{
    if(i<0||i>=m_windows.size())return;m_windows[i].geometry.moveTo(x,y);if(!m_windows[i].maximized)m_windows[i].restoreGeometry=m_windows[i].geometry;
    emit dataChanged(index(i,0),index(i,0),{XRole,YRole});
}
void WindowModel::setGeometry(int i,qreal x,qreal y,qreal w,qreal h)
{
    if(i<0||i>=m_windows.size())return;m_windows[i].geometry=QRectF(x,y,w,h);if(!m_windows[i].maximized)m_windows[i].restoreGeometry=m_windows[i].geometry;
    emit dataChanged(index(i,0),index(i,0),{XRole,YRole,WRole,HRole});
}
void WindowModel::closeWindow(int i)
{
    if(i<0||i>=m_windows.size())return;
    if(auto *top=qobject_cast<QWaylandXdgToplevel *>(m_windows[i].toplevel.data()))top->sendClose();else if(m_windows[i].shellSurface)m_windows[i].shellSurface->deleteLater();
}
void WindowModel::raiseWindow(int i)
{
    if(i<0||i>=m_windows.size()||i==m_windows.size()-1)return;
    beginMoveRows({},i,i,{},m_windows.size());auto entry=m_windows.takeAt(i);m_windows.push_back(entry);endMoveRows();m_active=m_windows.size()-1;
    for(int j=0;j<m_windows.size();++j)m_windows[j].active=(j==m_active);
    emit dataChanged(index(0,0),index(m_windows.size()-1,0),{ActiveRole});
}
void WindowModel::minimizeWindow(int i)
{
    if(i<0||i>=m_windows.size())return;m_windows[i].minimized=true;m_windows[i].active=false;emit dataChanged(index(i,0),index(i,0),{ActiveRole,MinimizedRole});
}
void WindowModel::toggleMaximize(int i,qreal width,qreal height)
{
    if(i<0||i>=m_windows.size())return;auto &w=m_windows[i];
    if(w.maximized){w.geometry=w.restoreGeometry;w.maximized=false;}else{w.restoreGeometry=w.geometry;w.geometry=QRectF(10,8,qMax<qreal>(640,width-20),qMax<qreal>(480,height-16));w.maximized=true;w.minimized=false;}
    emit dataChanged(index(i,0),index(i,0),{XRole,YRole,WRole,HRole,MinimizedRole,MaximizedRole});
}
void WindowModel::refreshFromToplevel(int row)
{
    if(row<0||row>=m_windows.size())return;auto &w=m_windows[row];
    if(auto *top=qobject_cast<QWaylandXdgToplevel *>(w.toplevel.data())){w.title=top->title();w.appId=top->appId();emit dataChanged(index(row,0),index(row,0),{TitleRole,AppIdRole});}
}
