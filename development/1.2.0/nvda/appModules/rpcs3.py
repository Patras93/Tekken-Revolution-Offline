# -*- coding: UTF-8 -*-
import os
import threading
import time

import appModuleHandler
import queueHandler
import ui
from scriptHandler import script

_EVENT_DIR = os.path.join(os.environ.get("LOCALAPPDATA", os.path.expanduser("~")), "TekkenRevolutionAccess")
_EVENT_FILE = os.path.join(_EVENT_DIR, "event.txt")


class AppModule(appModuleHandler.AppModule):
    scriptCategory = "Tekken Revolution Access"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._stopEvent = threading.Event()
        self._lastEvent = ""
        try:
            os.makedirs(_EVENT_DIR, exist_ok=True)
        except Exception:
            pass
        self._thread = threading.Thread(target=self._watchEvents, name="TekkenRevolutionAccess", daemon=True)
        self._thread.start()

    def terminate(self):
        self._stopEvent.set()
        super().terminate()

    def _speak(self, text):
        if text:
            queueHandler.queueFunction(queueHandler.eventQueue, ui.message, text)

    def _watchEvents(self):
        while not self._stopEvent.wait(0.15):
            try:
                if not os.path.isfile(_EVENT_FILE):
                    continue
                with open(_EVENT_FILE, "r", encoding="utf-8-sig") as f:
                    text = f.read().strip()
                if text and text != self._lastEvent:
                    self._lastEvent = text
                    self._speak(text)
            except Exception:
                time.sleep(0.5)

    @script(description="Test Tekken Revolution Access", gesture="kb:NVDA+alt+t")
    def script_testAccess(self, gesture):
        self._speak("Tekken Revolution Access działa.")

    @script(description="Powtórz ostatni komunikat Tekken Revolution", gesture="kb:NVDA+alt+r")
    def script_repeatLast(self, gesture):
        if self._lastEvent:
            self._speak(self._lastEvent)
        else:
            self._speak("Brak komunikatu Tekken Revolution.")
