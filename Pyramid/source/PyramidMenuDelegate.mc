import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application.Storage;

class PyramidMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
        switch (item.getId()) {
            case "theme":
                theme = (theme + 1) % themes.size();
                Storage.setValue("theme",theme);
                item.setSubLabel(themes[theme]);
                break;
            case "retries":
                retries = (retries + 1) % retriess.size();
                Storage.setValue("retries",retries);
                item.setSubLabel(retriess[retries]);
                break;
            case "deckpos":
                deckpos = (deckpos + 1) % deckposs.size();
                Storage.setValue("deckpos",deckpos);
                item.setSubLabel(deckposs[deckpos]);
                break;
            case "stats":
                showstats();
                break;
        }
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

}