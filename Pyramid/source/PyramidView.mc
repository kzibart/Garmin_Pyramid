import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Application.Storage;

var DS = System.getDeviceSettings();
var SW = DS.screenWidth;
var SH = DS.screenHeight;
var center = Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER;

var game,state,pyr,deck,play,pfree,sel;
var tries,tried;
var pyrXY,deckXY,playXY,newXY,newWH,overXY,overWH;
var cardWH,cardR;
var solid,shadow,so,soh,buttonR;
var mydc,tmp,tmp2,tmp3;

var themes = ["Outlines", "Outlines with shadows", "Solids", "Solids with shadows"];
var theme = 3;
var retriess = ["None", "Once", "Twice", "Unlimited"];
var retries = 2;
var deckposs = ["Left", "Right"];
var deckpos = 0;

var shadowcolor = 0x555555;
var suitF;

// Add settings menu with theme and number of deck retries
// allow unlimited retries?  If so, need to revise end of game check (check all play cards, not just top one)
// Count number of cards left at end of game and save in stats array (0,1,2,3,4,5,6,7,8,9,10+)
// Add Show Stats to settings menu, like Hangman


class PyramidView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {

        cardWH = [SW/9,SH/10*3/2];
        cardR = cardWH[0]/10;
        buttonR = (SW*.015).toNumber();
        so = buttonR/2;
        soh = so/2;
        pyrXY = new [28];
        tmp = -1;
        tmp2 = SH/(cardWH[1]*2/3)+cardWH[1]*3/4;
        for (var r=0;r<7;r++) {
            tmp3 = SW/2-r*cardWH[0]/2;
            for (var c=0;c<r+1;c++) {
                tmp++;
                pyrXY[tmp] = [tmp3+c*cardWH[0]-cardWH[0]/2,tmp2+r*(cardWH[1]*2/3)-cardWH[1]*2/3];
            }
        }
        deckXY = [pyrXY[27][0],pyrXY[3][1]];
        playXY = [pyrXY[21][0],pyrXY[3][1]];

        overWH = [SW*5/7, SW*1/10];
        overXY = [(SW-overWH[0])/2, SH*73/100];

        newWH = [cardWH[0]*2,cardWH[1]*2/3];
        newXY = [(SW-newWH[0])/2,SH*85/100];

        game = Storage.getValue("game");
        if (game == null) { newgame(); }
        state = game.get("state");
        deck = game.get("deck");
        pyr = game.get("pyr");
        play = game.get("play");
        pfree = game.get("pfree");
        sel = game.get("sel");
        tried = game.get("tried");

        if (SW < 270) { suitF = WatchUi.loadResource(Rez.Fonts.suits20); }
        else if (SW < 360) { suitF = WatchUi.loadResource(Rez.Fonts.suits30); }
        else if (SW < 390) { suitF = WatchUi.loadResource(Rez.Fonts.suits35); }
        else { suitF = WatchUi.loadResource(Rez.Fonts.suits40); }
        
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        mydc = dc;
        mydc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        mydc.clear();

        theme = Storage.getValue("theme");
        if (theme == null) { theme = 3; Storage.setValue("theme",theme); }
        switch (theme) {
            case 0:
                solid = false;
                shadow = false;
                break;
            case 1:
                solid = false;
                shadow = true;
                break;
            case 2:
                solid = true;
                shadow = false;
                break;
            case 3:
                solid = true;
                shadow = true;
                break;
        }

        retries = Storage.getValue("retries");
        if (retries == null) { retries = 2; Storage.setValue("retries",retries); }
        switch (retries) {
            case 0:
                tries = 0;
                break;
            case 1:
                tries = 1;
                break;
            case 2:
                tries = 2;
                break;
            case 3:
                tries = 1000;
                break;
        }

        deckpos = Storage.getValue("deckpos");
        if (deckpos == null) { deckpos = 0; Storage.setValue("deckpos",deckpos); }
        switch (deckpos) {
            case 1:
                deckXY = [pyrXY[27][0],pyrXY[3][1]];
                playXY = [pyrXY[21][0],pyrXY[3][1]];
                break;
            default:
                deckXY = [pyrXY[21][0],pyrXY[3][1]];
                playXY = [pyrXY[27][0],pyrXY[3][1]];
                break;
        }


        tmp = deck.size();
        if (tmp == 0) {
            if (tried < tries) {
                tmp = "<";
            } else {
                tmp = "X";
            }
        } else {
            tmp = tmp.toString();
        }
        drawcard(deckXY,tmp,false);

        if (play.size() > 0) {
            drawcard(playXY,play[play.size()-1],(sel == 28));
        }

        for (var i=0;i<28;i++) {
            if (pyr[i] != null) {
                drawcard(pyrXY[i],pyr[i],(sel == i));
            }
        }

        if (state == 2) {
            dc.setColor(Graphics.COLOR_BLACK,-1);
            dc.fillRoundedRectangle(overXY[0], overXY[1], overWH[0], overWH[1], cardR);
            dc.setColor(Graphics.COLOR_WHITE,-1);
            dc.drawText(overXY[0]+overWH[0]/2,overXY[1]+overWH[1]/2,Graphics.FONT_SMALL,"No More Moves",center);
        }

        if (state == 3) {
            if (shadow) {
                dc.setColor(shadowcolor,-1);
                dc.drawText(SW/2+so,SH/2+so,Graphics.FONT_LARGE,"YOU\nWON!",center);
            }
            dc.setColor(Graphics.COLOR_GREEN,-1);
            dc.drawText(SW/2,SH/2,Graphics.FONT_LARGE,"YOU\nWON!",center);
        }

        drawbutton(newXY,newWH,Graphics.COLOR_YELLOW,"New",center);
    }

    function drawcard(xy as Array, val as String, sel as Boolean) {
        var x = xy[0]+1;
        var y = xy[1]+1;
        var w = cardWH[0]-2;
        var h = cardWH[1]-2;
        var fc,tc;
        var font = suitF;
        switch (val.substring(1,2)) {
            case "s":
            case "c":
                fc = Graphics.COLOR_WHITE;
                if (solid) { tc = Graphics.COLOR_BLACK; }
                else { tc = Graphics.COLOR_WHITE; }
                break;
            case "d":
            case "h":
                fc = Graphics.COLOR_WHITE;
                tc = Graphics.COLOR_RED;
                break;
            default:
                fc = Graphics.COLOR_BLUE;
                if (solid) { tc = Graphics.COLOR_BLACK; }
                else { tc = Graphics.COLOR_WHITE; }
                break;
        }

        if (solid) {
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.fillRoundedRectangle(x+so, y+so, w, h, cardR);
            }
            if (sel) {
                mydc.setColor(Graphics.COLOR_YELLOW,-1);
            } else {
                mydc.setColor(fc,-1);
            }
            mydc.fillRoundedRectangle(x, y, w, h, cardR);
            mydc.setColor(Graphics.COLOR_DK_GRAY,-1);
            mydc.setPenWidth(2);
            mydc.drawRoundedRectangle(x, y, w, h, cardR);
            if (shadow) {
                mydc.setColor(Graphics.COLOR_LT_GRAY,-1);
                mydc.drawText(x+w/2-soh,y+h/3-soh,suitF,val,center);
            }
            mydc.setColor(tc,-1);
            mydc.drawText(x+w/2,y+h/3,suitF,val,center);
        } else {
            mydc.setPenWidth(2);
            mydc.setColor(Graphics.COLOR_BLACK,-1);
            mydc.fillRoundedRectangle(x,y,w,h,cardR);
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.drawRoundedRectangle(x+so, y+so, w, h, cardR);
                mydc.drawText(x+w/2+soh,y+h/3+soh,suitF,val,center);
            }
            if (sel) {
                mydc.setColor(Graphics.COLOR_YELLOW,-1);
                mydc.setPenWidth(3);
            } else {
                mydc.setColor(fc,-1);
            }
            mydc.drawRoundedRectangle(x, y, w, h, cardR);
            mydc.setColor(tc,-1);
            mydc.drawText(x+w/2,y+h/3,suitF,val,center);
        }
    }

    function drawbutton(xy,wh,col,text,pos) {
        if (solid) {
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.fillRoundedRectangle(xy[0]+so, xy[1]+so, wh[0], wh[1], buttonR);
            }
            mydc.setColor(col,-1);
            mydc.fillRoundedRectangle(xy[0], xy[1], wh[0], wh[1], buttonR);
            if (shadow) {
                mydc.setColor(Graphics.COLOR_LT_GRAY,-1);
                mydc.drawText(xy[0]+wh[0]/2-soh, xy[1]+wh[1]/2-soh, Graphics.FONT_TINY, text, pos);
            }
            mydc.setColor(Graphics.COLOR_BLACK,-1);
            mydc.drawText(xy[0]+wh[0]/2, xy[1]+wh[1]/2, Graphics.FONT_TINY, text, pos);
        } else {
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.drawRoundedRectangle(xy[0]+so, xy[1]+so, wh[0], wh[1], buttonR);
                mydc.drawText(xy[0]+wh[0]/2+so, xy[1]+wh[1]/2+so, Graphics.FONT_TINY, text, pos);
            }
            mydc.setColor(col,-1);
            mydc.drawRoundedRectangle(xy[0], xy[1], wh[0], wh[1], buttonR);
            mydc.drawText(xy[0]+wh[0]/2, xy[1]+wh[1]/2, Graphics.FONT_TINY, text, pos);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }
}


function newgame() {
    state = 1;
    deck = ["As","2s","3s","4s","5s","6s","7s","8s","9s","Ts","Js","Qs","Ks",
            "Ac","2c","3c","4c","5c","6c","7c","8c","9c","Tc","Jc","Qc","Kc",
            "Ad","2d","3d","4d","5d","6d","7d","8d","9d","Td","Jd","Qd","Kd",
            "Ah","2h","3h","4h","5h","6h","7h","8h","9h","Th","Jh","Qh","Kh"];
    for (var i=0;i<1000;i++) {
        tmp = Math.rand() % 52;
        tmp2 = Math.rand() % 52;
        tmp3 = deck[tmp];
        deck[tmp] = deck[tmp2];
        deck[tmp2] = tmp3;
    }
    pyr = deck.slice(0,28);
    deck = deck.slice(28,null);
    play = [];
    pfree = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,true,true,true,true,true,true,true];
    sel = -1;
    tried = 0;
    savegame();
}

function savegame() {
    // Any cards left?
    var cards = false;
    if (state == 1) {
        for (var i=0;i<28;i++) {
            if (pyr[i] != null) {
                cards = true;
                break;
            }
        }
    } else { cards = true; }
    if (!cards) {
        state = 3;
        addstats();
    }

    // Any moves left?
    var moves = false;
    if (deck.size() == 0 and (tried >= tries or tries == 1000) and state == 1) {
        if (play.size() > 0) {
            if (tries == 1000) { tmp = 0; }
            else { tmp = play.size()-1; }
            for (var j=tmp;j<play.size();j++) {
                tmp2 = val(play[j]);
                for (var i=0;i<28;i++) {
                    if (pfree[i] and pyr[i] != null) {
                        if (val(pyr[i]) + tmp2 == 13) {
                            moves = true;
                            break;
                        }
                    }
                }
                if (moves) { break; }
            }
        }
        if (!moves) {
            for (var i=0;i<28;i++) {
                if (pfree[i] and pyr[i] != null) {
                    for (var j=0;j<28;j++) {
                        if ((pfree[j] or selfree(j,i)) and pyr[j] != null) {
                            tmp = val(pyr[i]);
                            tmp2 = val(pyr[j]);
                            if (tmp == 13 or tmp+tmp2 == 13) {
                                moves = true;
                                break;
                            }
                        }
                    }
                }
                if (moves) { break; }
            }
        }
    } else { moves = true; }
    if (!moves) {
        state = 2;
        addstats();
    }

    game = {
        "ver" => 1,
        "state" => state,
        "deck" => deck,
        "pyr" => pyr,
        "play" => play,
        "pfree" => pfree,
        "sel" => sel,
        "tried" => tried
    };
    Storage.setValue("game",game);
}

function draw() {
    if (deck.size() > 0) {
        play.add(deck[0]);
        deck = deck.slice(1,null);
    }
}

function val(c as String) as Number {
    switch (c.substring(0,1)) {
        case "A": return 1;
        case "2": return 2;
        case "3": return 3;
        case "4": return 4;
        case "5": return 5;
        case "6": return 6;
        case "7": return 7;
        case "8": return 8;
        case "9": return 9;
        case "T": return 10;
        case "J": return 11;
        case "Q": return 12;
        case "K": return 13;
    }
    return 0;
}

function checkfree() {
    pfree[0] = (pyr[1] == null and pyr[2] == null);
    pfree[1] = (pyr[3] == null and pyr[4] == null);
    pfree[2] = (pyr[4] == null and pyr[5] == null);
    pfree[3] = (pyr[6] == null and pyr[7] == null);
    pfree[4] = (pyr[7] == null and pyr[8] == null);
    pfree[5] = (pyr[8] == null and pyr[9] == null);
    pfree[6] = (pyr[10] == null and pyr[11] == null);
    pfree[7] = (pyr[11] == null and pyr[12] == null);
    pfree[8] = (pyr[12] == null and pyr[13] == null);
    pfree[9] = (pyr[13] == null and pyr[14] == null);
    pfree[10] = (pyr[15] == null and pyr[16] == null);
    pfree[11] = (pyr[16] == null and pyr[17] == null);
    pfree[12] = (pyr[17] == null and pyr[18] == null);
    pfree[13] = (pyr[18] == null and pyr[19] == null);
    pfree[14] = (pyr[19] == null and pyr[20] == null);
    pfree[15] = (pyr[21] == null and pyr[22] == null);
    pfree[16] = (pyr[22] == null and pyr[23] == null);
    pfree[17] = (pyr[23] == null and pyr[24] == null);
    pfree[18] = (pyr[24] == null and pyr[25] == null);
    pfree[19] = (pyr[25] == null and pyr[26] == null);
    pfree[20] = (pyr[26] == null and pyr[27] == null);
}

function selfree(i,sel) as Boolean {
    switch (i) {
        case 0: return ((pyr[1] == null and sel == 2) or (pyr[2] == null and sel == 1));
        case 1: return ((pyr[3] == null and sel == 4) or (pyr[4] == null and sel == 3));
        case 2: return ((pyr[4] == null and sel == 5) or (pyr[5] == null and sel == 4));
        case 3: return ((pyr[6] == null and sel == 7) or (pyr[7] == null and sel == 6));
        case 4: return ((pyr[7] == null and sel == 8) or (pyr[8] == null and sel == 7));
        case 5: return ((pyr[8] == null and sel == 9) or (pyr[9] == null and sel == 8));
        case 6: return ((pyr[10] == null and sel == 11) or (pyr[11] == null and sel == 10));
        case 7: return ((pyr[11] == null and sel == 12) or (pyr[12] == null and sel == 11));
        case 8: return ((pyr[12] == null and sel == 13) or (pyr[13] == null and sel == 12));
        case 9: return ((pyr[13] == null and sel == 14) or (pyr[14] == null and sel == 13));
        case 10: return ((pyr[15] == null and sel == 16) or (pyr[16] == null and sel == 15));
        case 11: return ((pyr[16] == null and sel == 17) or (pyr[17] == null and sel == 16));
        case 12: return ((pyr[17] == null and sel == 18) or (pyr[18] == null and sel == 17));
        case 13: return ((pyr[18] == null and sel == 19) or (pyr[19] == null and sel == 18));
        case 14: return ((pyr[19] == null and sel == 20) or (pyr[20] == null and sel == 19));
        case 15: return ((pyr[21] == null and sel == 22) or (pyr[22] == null and sel == 21));
        case 16: return ((pyr[22] == null and sel == 23) or (pyr[23] == null and sel == 22));
        case 17: return ((pyr[23] == null and sel == 24) or (pyr[24] == null and sel == 23));
        case 18: return ((pyr[24] == null and sel == 25) or (pyr[25] == null and sel == 24));
        case 19: return ((pyr[25] == null and sel == 26) or (pyr[26] == null and sel == 25));
        case 20: return ((pyr[26] == null and sel == 27) or (pyr[27] == null and sel == 26));
    }
    return false;
}

function addstats() as Void {
    var stats = Storage.getValue("stats");
    if (stats == null) {
        stats = [0,0,0,0,0,0,0,0,0,0,0];
    }
    tmp = 0;
    for (var i=0;i<28;i++) {
        if (pyr[i] != null) {
            tmp++;
        }
    }
    if (tmp > 10) { tmp = 10; }
    stats[tmp]++;
    Storage.setValue("stats",stats);
}

function showstats() {
    var stats = Storage.getValue("stats");
    if (stats == null) { return; }
    var menu = new WatchUi.CustomMenu(45, Graphics.COLOR_BLACK,{
        :title => new $.DrawableMenuTitle(),
        :titleItemHeight => 70
    });
    var labels = ["Wins","1 Card","2 Cards","3 Cards","4 Cards","5 Cards","6 Cards","7 Cards","8 Cards","9 Cards","10+ Cards"];
    var total = 0;
    var max = 0;
    for (var i=0;i<stats.size();i++) {
        if (stats[i] > max) { max = stats[i]; }
        total += stats[i];
    }
    for (var i=0;i<stats.size();i++) {
        menu.addItem(new $.CustomItem(i,labels[i],stats[i],total,max));
    }
    WatchUi.pushView(menu, new $.PyramidStatsDelegate(), WatchUi.SLIDE_UP);
    WatchUi.requestUpdate();
}

class PyramidStatsDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
        return;
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DrawableMenuTitle extends WatchUi.Drawable {
    public function initialize() {
        Drawable.initialize({});
    }
    
    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth()/2,(dc.getHeight()*.7).toNumber(),Graphics.FONT_SMALL,"Statistics",center);
        dc.setPenWidth(3);
        dc.drawLine(0,dc.getHeight(),dc.getWidth(),dc.getHeight());
    }
}

class CustomItem extends WatchUi.CustomMenuItem {
    private var _id as Number;
    private var _label as String;
    private var _count as Number;
    private var _total as Number;
    private var _max as Number;

    public function initialize(id as Number, label as String, count as Number, total as Number, max as Number) {
        CustomMenuItem.initialize(id, {});
        _id = id;
        _label = label;
        _count = count;
        _total = total;
        _max = max;
    }

    public function draw(dc as Dc) as Void {
        // Fill background horizontally based on percentage
        var w = dc.getWidth();
        var h = dc.getHeight();
        var bx = w/8;
        var bw = w*6/8;
        var lx = bx;
        var cx = (w*.65).toNumber();
        var px = bx+bw;
        var pct = (_count*1.0/_total*100).toNumber();
        var mpct = (_max*1.0/_total*100).toNumber();
        mpct = 1-((mpct-pct)*1.0/mpct);
        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
        dc.fillRectangle(bx,0,(bw*mpct).toNumber(),h);
        if (_id == 0) { dc.setColor(Graphics.COLOR_GREEN,-1); }
        else { dc.setColor(Graphics.COLOR_RED,-1); }
        dc.drawText(lx,h/2,Graphics.FONT_TINY,_label,Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_BLUE,-1);
        dc.drawText(cx,h/2,Graphics.FONT_TINY,_count,Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_YELLOW,-1);
        dc.drawText(px,h/2,Graphics.FONT_TINY,pct+"%",Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class PyramidSettings extends WatchUi.Menu2 {
    public function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");

        var themeicon = new $.CustomIcon(theme);
        var retriesicon = new $.CustomIcon(retries);
        var deckposicon = new $.CustomIcon(deckpos);
        var statsicon = new $.CustomIcon(0);

        Menu2.addItem(new WatchUi.IconMenuItem("Theme", themes[theme], "theme", themeicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Deck Reloads", retriess[retries], "retries", retriesicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Deck Position", deckposs[deckpos], "deckpos", deckposicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Stats", "Show statistics", "stats", statsicon, null));
    }
}

class CustomIcon extends WatchUi.Drawable {
    private var _index as Number;

    public function initialize(index as Number) {
        _index = index;
        Drawable.initialize({});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(-1,-1);
        dc.clear();
    }
}