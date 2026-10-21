#!/usr/bin/env python3
"""Eventos do Google Calendar para o calendario do Hub.

Le os enderecos secretos iCal de ~/.config/noctalia/gcal.urls (um por linha),
guarda cada .ics em cache por 10 minutos e imprime os eventos do mes pedido:
uma linha JSON {"date": "AAAA-MM-DD", "time": "HH:MM" ou "", "title": ...} por dia.
O endereco nunca vai para argv nem para a saida: ele da acesso a agenda.
"""
import json
import os
import sys
import time
import urllib.request
from datetime import date, datetime, timedelta
from pathlib import Path

import icalendar
import recurring_ical_events

URLS = Path.home() / ".config/noctalia/gcal.urls"
CACHE = Path.home() / ".cache/noctalia-hub"
MAX_AGE = 600


def calendars():
    if not URLS.exists():
        return
    CACHE.mkdir(parents=True, exist_ok=True, mode=0o700)
    lines = [l.strip() for l in URLS.read_text().splitlines() if l.strip() and not l.startswith("#")]
    for i, url in enumerate(lines):
        path = CACHE / f"gcal-{i}.ics"
        if not path.exists() or time.time() - path.stat().st_mtime > MAX_AGE:
            try:
                with urllib.request.urlopen(url, timeout=10) as r:
                    data = r.read()
                fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
                with os.fdopen(fd, "wb") as f:
                    f.write(data)
            except OSError:
                pass  # sem rede: usa o cache antigo, se houver
        if path.exists():
            yield icalendar.Calendar.from_ical(path.read_bytes())


def events(year, month):
    first = date(year, month, 1)
    after = date(year + month // 12, month % 12 + 1, 1)
    out = []
    for cal in calendars():
        for ev in recurring_ical_events.of(cal).between(first, after):
            start = ev["DTSTART"].dt
            end = ev["DTEND"].dt if "DTEND" in ev else start
            title = str(ev.get("SUMMARY", "Sem título"))
            if isinstance(start, datetime):
                start = start.astimezone() if start.tzinfo else start
                out.append({"date": start.date().isoformat(), "time": start.strftime("%H:%M"), "title": title})
                continue
            # Dia inteiro: DTEND e exclusivo; eventos de varios dias aparecem em cada dia
            day = start
            while day < max(end, start + timedelta(days=1)):
                if first <= day < after:
                    out.append({"date": day.isoformat(), "time": "", "title": title})
                day += timedelta(days=1)
    out.sort(key=lambda e: (e["date"], e["time"] != "", e["time"]))
    return out


if __name__ == "__main__":
    for e in events(int(sys.argv[1]), int(sys.argv[2])):
        print(json.dumps(e, ensure_ascii=False))
