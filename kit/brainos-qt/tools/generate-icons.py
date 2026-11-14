from pathlib import Path

OUT = Path("qml/assets/icons")
OUT.mkdir(parents=True, exist_ok=True)

def svg(body: str) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">\n{body}\n</svg>\n'''

icons = {
    "browser": '<rect x="3" y="4" width="18" height="16" rx="4"/><path d="M3 8h18"/><circle cx="12" cy="12" r="3.8"/><path d="M12 8.2v7.6M8.2 12h7.6"/>',
    "store": '<path d="M4 10h16M5 10v8a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-8M6 7.5 8 4h8l2 3.5M8.2 14.2h7.6M10 14.2v3.1M14 14.2v3.1"/>',
    "calculator": '<rect x="5" y="3.5" width="14" height="17" rx="3.5"/><rect x="7" y="5.5" width="10" height="4" rx="1.2"/><path d="M8 13h0M12 13h0M16 13h0M8 16.5h0M12 16.5h0M16 16.5h0M8 19h0M12 19h0M16 19h0"/>',
    "wifi": '<path d="M5 9.5a12 12 0 0 1 14 0M7.8 12.3a8 8 0 0 1 8.4 0M10.6 15.1a4 4 0 0 1 2.8 0"/><circle cx="12" cy="18" r="1.2"/>',
    "volume": '<path d="M5 10.5h3l4-3.5v9l-4-3.5H5zM14.5 9a4 4 0 0 1 0 6M16.8 6.7a7 7 0 0 1 0 10.6"/>',
    "mute": '<path d="M5 10.5h3l4-3.5v9l-4-3.5H5zM16 9l3 3M19 9l-3 3"/>',
    "files": '<path d="M4.5 7.5V18a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V8.5a2 2 0 0 0-2-2h-5l-1.5-1.5h-4a2 2 0 0 0-2 2z"/>',
    "folder": '<path d="M4 7.5h5l1.6 1.7H20a1.5 1.5 0 0 1 1.5 1.5V18a2 2 0 0 1-2 2H4.5A2 2 0 0 1 2.5 18V9.5A2 2 0 0 1 4.5 7.5z"/>',
    "terminal": '<rect x="3.5" y="4.5" width="17" height="15" rx="3"/><path d="M6.5 9l3 3-3 3M11 15h5"/>',
    "settings": '<circle cx="12" cy="12" r="2.3"/><path d="M19 12a7 7 0 0 0-.1-1l1.7-1.3-1.5-2.6-2 .8a7 7 0 0 0-1.7-1L15 4h-3l-.4 2a7 7 0 0 0-1.7 1l-2-.8L6.4 8.7 8 10a7 7 0 0 0-.1 1A7 7 0 0 0 8 13l-1.6 1.3 1.5 2.6 2-.8a7 7 0 0 0 1.7 1L12 20h3l.4-2a7 7 0 0 0 1.7-1l2 .8 1.5-2.6L18.9 13c.1-.3.1-.7.1-1z"/>',
    "search": '<circle cx="10.5" cy="10.5" r="5.8"/><path d="M15 15l4 4"/>',
    "trash": '<path d="M5 7h14M9 7V5.8A1.8 1.8 0 0 1 10.8 4h2.4A1.8 1.8 0 0 1 15 5.8V7M7.2 7l.8 12A1.8 1.8 0 0 0 9.8 20h4.4a1.8 1.8 0 0 0 1.8-1.8l.8-11.2M10 10.2v5.6M14 10.2v5.6"/>',
    "download": '<path d="M12 4v9M8.5 10.5 12 14l3.5-3.5M5 18h14"/>',
    "image": '<rect x="4" y="5" width="16" height="14" rx="3"/><circle cx="9" cy="10" r="1.2"/><path d="M5.5 16l3.8-3.8 2.8 2.8 2.8-3 4.1 4"/>',
    "music": '<path d="M9 17a2.5 2.5 0 1 1 0-5 2.5 2.5 0 0 1 0 5zM11.5 15V6l8-1v9M19.5 14a2.5 2.5 0 1 1 0-5 2.5 2.5 0 0 1 0 5z"/>',
    "bell": '<path d="M12 4a4 4 0 0 0-4 4v2c0 .9-.4 2.1-.9 2.8L6 14h12l-1.1-1.2c-.5-.7-.9-1.9-.9-2.8V8a4 4 0 0 0-4-4zM10 18a2 2 0 0 0 4 0"/>',
    "close": '<path d="M6 6l12 12M18 6 6 18"/>',
    "play": '<path d="M8 5.5v13l10-6.5z"/>',
    "pause": '<path d="M7 5.5v13M17 5.5v13"/>',
    "next": '<path d="M6 6.5v11l7-5.5zM13 6.5v11l5.5-5.5z"/>',
    "previous": '<path d="M18 6.5v11l-7-5.5zM11 6.5v11L5.5 12z"/>',
    "cpu": '<rect x="7" y="7" width="10" height="10" rx="2"/><path d="M10 4.5v2.5M14 4.5v2.5M10 17v2.5M14 17v2.5M4.5 10h2.5M4.5 14h2.5M17 10h2.5M17 14h2.5"/>',
    "memory": '<rect x="6" y="6.5" width="12" height="11" rx="2"/><path d="M9 9.5h6M9 12h6M9 14.5h3"/>',
    "network": '<circle cx="12" cy="18" r="1"/><path d="M6 10.5a9 9 0 0 1 12 0M8.5 13a5 5 0 0 1 7 0M10.8 15.3a2 2 0 0 1 2.4 0"/>',
    "battery": '<rect x="5" y="8" width="14" height="8" rx="2"/><path d="M19 10v4M8 12h5"/>',
    "browser-window": '<rect x="3" y="4" width="18" height="16" rx="4"/><path d="M3 8h18M7 12h10M7 15.5h7"/>',
    "store-bag": '<path d="M6 9h12l-1 10H7L6 9zM9 9a3 3 0 0 1 6 0"/>',
}
for name, body in icons.items():
    (OUT / f"{name}.svg").write_text(svg(body), encoding="utf-8")
print(f"Wrote {len(icons)} icons to {OUT}")
