import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class PyramidDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new PyramidSettings(), new PyramidMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onTap(clickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();

        // Deck
        if (state == 1) {
            if (inbox(deckXY,cardWH,xy)) {
                if (deck.size() == 0) {
                    if (tried < tries) {
                        deck = play.slice(0,null);
                        play = [];
                        tried++;
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    }
                    return false;
                } else {
                    draw();
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
            }
        }

        // Play stack
        if (state == 1) {
            if (inbox(playXY,cardWH,xy)) {
                if (play.size() == 0) { return false; }
                if (val(play[play.size()-1]) == 13) {
                    play = play.slice(0,-1);
                    sel = -1;
                } else if (sel == 28) {
                    sel = -1;
                } else if (sel == -1) {
                    sel = 28;
                } else {
                    if (val(play[play.size()-1]) + val(pyr[sel]) == 13) {
                        play = play.slice(0,-1);
                        pyr[sel] = null;
                        sel = -1;
                        checkfree();
                    } else {
                        sel = 28;
                    }
                }
                savegame();
                WatchUi.requestUpdate();
                return true;
            }
        }

        // Pyramid cards
        if (state == 1) {
            for (var i=0;i<pyr.size();i++) {
                if (inbox(pyrXY[i],cardWH,xy) and pyr[i] != null) {
                    if (pfree[i]) {
                        if (val(pyr[i]) == 13) {
                            pyr[i] = null;
                            checkfree();
                            sel = -1;
                        } else if (sel == i) {
                            sel = -1;
                        } else if (sel == -1) {
                            sel = i;
                        } else {
                            if (sel == 28) { 
                                if (val(play[play.size()-1]) + val(pyr[i]) == 13) {
                                    play = play.slice(0,-1);
                                    pyr[i] = null;
                                    sel = -1;
                                    checkfree();
                                } else {
                                    sel = i;
                                }
                            }else { 
                                if (val(pyr[sel]) + val(pyr[i]) == 13) {
                                    pyr[sel] = null;
                                    pyr[i] = null;
                                    sel = -1;
                                    checkfree();
                                } else {
                                    sel = i;
                                }
                            }
                        }
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    } else if (selfree(i,sel)) {
                        if (val(pyr[sel]) + val(pyr[i]) == 13) {
                            pyr[sel] = null;
                            pyr[i] = null;
                            sel = -1;
                            checkfree();
                            savegame();
                            WatchUi.requestUpdate();
                            return true;
                        }
                    }
                }
            }
        }

        // New button
        if (inbox(newXY,newWH,xy)) {
            newgame();
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }

    // Check if a point is within a box
    // boxxy = [x,y] coordinates of upper left corner of box
    // boxwh = [w,h] width and height of box
    // point = [x,y] coordinates of point to check
    function inbox(boxxy,boxwh,point) as Boolean {
        if (point[0]<boxxy[0]) {return false;}
        if (point[0]>boxxy[0]+boxwh[0]) {return false;}
        if (point[1]<boxxy[1]) {return false;}
        if (point[1]>boxxy[1]+boxwh[1]) {return false;}
        return true;
    }

}