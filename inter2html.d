/**
 * Simple HTML interlinear generator from tab-separated input.
 *
 * Copyright: H. S. Teoh, 2020
 * License:  [http://www.boost.org/LICENSE_1_0.txt|Boost License 1.0].
 */
module inter2html;

import std;

struct FontConfig
{
    string fontStyle, fontVariant, fontWeight, fontSize, fontFamily;
    string color, bgColor;
}

struct CssConfig
{
    string maxWidth;
    string wordSpacing;
    string lineSpacing;
    string innerLineSpacing;
    string freeTransSpacing;

    FontConfig heading;
    FontConfig freeTrans;
    FontConfig[] lines;
}

struct Section
{
    string heading;
    string[][] morphemes;
    string freeTrans;
}

auto parseMorphemes(R)(R lines)
    if (isInputRange!R && is(ElementType!R : const(char)[]))
{
    return lines.map!((const(char)[] l) => l.idup.split('\t'));
}

unittest
{
    auto sample = [
        "В\tPREP\tIn",
        "начале\tN:PREP\tbeginning",
        "было\tV:P:NEUT\twas",
        "Слово\tN:NOM\tWord",
    ];
    assert(sample.parseMorphemes.equal([
        [ "В", "PREP", "In" ],
        [ "начале", "N:PREP", "beginning" ],
        [ "было", "V:P:NEUT", "was" ],
        [ "Слово", "N:NOM", "Word" ],
    ]));
}

Section parseSection(R)(R lines)
    if (isInputRange!R && is(ElementType!R : const(char)[]))
{
    Section s;
    s.heading = lines.takeOne.front.idup;
    s.morphemes = lines.dropOne.parseMorphemes.array;

    if (s.morphemes.length > 0 && s.morphemes[$-1].length == 1)
    {
        s.freeTrans = s.morphemes[$-1][0];
        s.morphemes = s.morphemes[0 .. $-1];
    }

    return s;
}

auto parseInput(R)(R lines)
    if (isInputRange!R && is(ElementType!R : const(char)[]))
{
    static immutable const(char)[] blankLine = "";
    return lines.map!(l => l.idup)
                .array
                .split(blankLine)
                .map!(ll => parseSection(ll));
}

unittest
{
    auto sample = [
        "John 1:1",
        "В\tPREP\tIn",
        "начале\tN:PREP\tbeginning",
        "было\tV:P:NEUT\twas",
        "Слово\tN:NOM\tWord",
        "",
        "John 1:2",
        "Оно\tPRON:NEUT:SG:NOM\tHe",
        "было\tV:P:NEUT\twas",
        "в\tPREP\tin",
        "начале\tN:PREP\tbeginning",
        "у\tPREP\twith",
        "Бога\tN:GEN\tGod",
    ];
    assert(sample.parseInput.equal([
        Section("John 1:1", [
            [ "В", "PREP", "In" ],
            [ "начале", "N:PREP", "beginning" ],
            [ "было", "V:P:NEUT", "was" ],
            [ "Слово", "N:NOM", "Word" ],
        ]),
        Section("John 1:2", [
            [ "Оно", "PRON:NEUT:SG:NOM", "He" ],
            [ "было", "V:P:NEUT", "was" ],
            [ "в", "PREP", "in" ],
            [ "начале", "N:PREP", "beginning" ],
            [ "у", "PREP", "with" ],
            [ "Бога", "N:GEN", "God" ],
        ])
    ]));
}

unittest
{
    auto sample = [
        "John 1:1",
        "В\tPREP\tIn",
        "начале\tN:PREP\tbeginning",
        "было\tV:P:NEUT\twas",
        "Слово\tN:NOM\tWord",
        "In the beginning was the Word",
        "",
        "John 1:2",
        "Оно\tPRON:NEUT:SG:NOM\tHe",
        "было\tV:P:NEUT\twas",
        "в\tPREP\tin",
        "начале\tN:PREP\tbeginning",
        "у\tPREP\twith",
        "Бога\tN:GEN\tGod",
        "He was in the beginning with God",
    ];

    assert(sample.parseInput.equal([
        Section("John 1:1", [
                [ "В", "PREP", "In" ],
                [ "начале", "N:PREP", "beginning" ],
                [ "было", "V:P:NEUT", "was" ],
                [ "Слово", "N:NOM", "Word" ],
            ], "In the beginning was the Word"),

        Section("John 1:2", [
                [ "Оно", "PRON:NEUT:SG:NOM", "He" ],
                [ "было", "V:P:NEUT", "was" ],
                [ "в", "PREP", "in" ],
                [ "начале", "N:PREP", "beginning" ],
                [ "у", "PREP", "with" ],
                [ "Бога", "N:GEN", "God" ],
            ], "He was in the beginning with God"),
    ]));
}

static immutable htmlPrologue = q"ENDHTML
<!DOCTYPE html>
<html><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<style type="text/css">
%s
</style>
</head>
<body>
ENDHTML";

static immutable cssBody = q"ENDCSS
    display: table;
    margin-left: auto;
    margin-right: auto;
ENDCSS";

static immutable htmlSecHeading = q"ENDHTML
<h6>%s</h6>
ENDHTML";

static immutable htmlSecStart = q"ENDHTML
<div class="interlinear">
ENDHTML";

static immutable htmlMorphStart = q"ENDHTML
<table class="interlinear">
ENDHTML";

static immutable htmlMorphLine = q"ENDHTML
<tr class="line%d"><td>%s</td></tr>
ENDHTML";

static immutable htmlMorphEnd = q"ENDHTML
</table>
ENDHTML";

static immutable htmlSecFreeTrans = q"ENDHTML
<p>%s</p>
ENDHTML";

static immutable htmlSecEnd = q"ENDHTML
</div>
ENDHTML";

static immutable htmlEpilogue = q"ENDHTML
</body></html>
ENDHTML";

string[] genCssFont(FontConfig lcfg)
{
    string[] result;
    if (lcfg.fontStyle.length > 0)
        result ~= "font-style: %s;".format(lcfg.fontStyle);
    if (lcfg.fontVariant.length > 0)
        result ~= "font-variant: %s;".format(lcfg.fontVariant);
    if (lcfg.fontWeight.length > 0)
        result ~= "font-weight: %s;".format(lcfg.fontWeight);
    if (lcfg.fontSize.length > 0)
        result ~= "font-size: %s;".format(lcfg.fontSize);
    if (lcfg.fontFamily.length > 0)
        result ~= "font-family: %s;".format(lcfg.fontFamily);
    if (lcfg.color.length > 0)
        result ~= "color: %s;".format(lcfg.color);
    if (lcfg.bgColor.length > 0)
        result ~= "background: %s;".format(lcfg.bgColor);

    return result;
}

string genCss(CssConfig cfg)
{
    string[][string] css = [
        "body": [
            "display: table;",
            "margin-left: auto;",
            "margin-right: auto;",
        ],

        "table.interlinear": [
            "display: inline;",
        ],

        "div.interlinear": [],
        "div.interlinear p": [],
        "div.interlinear td": [],
        "table.interlinear tr:last-child td": [],

        "h6": [
            "margin-top: 1ex;",
            "margin-bottom: 0;",
        ],
    ];

    if (cfg.maxWidth.length > 0)
        css["body"] ~= "max-width: %s;".format(cfg.maxWidth);

    if (cfg.wordSpacing.length > 0)
    {
        css["div.interlinear"] ~= "word-spacing: %s;".format(cfg.wordSpacing);
        css["div.interlinear td"] ~= "word-spacing: initial;";
    }

    if (cfg.lineSpacing.length > 0)
    {
        css["table.interlinear tr:last-child td"] ~=
            "padding-bottom: %s;".format(cfg.lineSpacing);
        //css["h6:not(:first-child)"] ~=
        //    "margin-top: -%s;".format(cfg.lineSpacing);
    }

    if (cfg.innerLineSpacing.length > 0)
    {
        css["table.interlinear"] ~= "border-collapse: separate;";
        css["table.interlinear"] ~= "border-spacing: 0 %s;"
                                    .format(cfg.innerLineSpacing);
    }

    css["h6"] ~= genCssFont(cfg.heading);
    css["div.interlinear p"] ~= genCssFont(cfg.freeTrans);
    css["div.interlinear p"] ~= [
        format("margin-top: %s;", cfg.freeTransSpacing ?
                                  cfg.freeTransSpacing : "0")
    ];

    foreach (i, lcfg; cfg.lines)
    {
        auto sel = format(".interlinear .line%d", i);
        css[sel] = genCssFont(lcfg);
    }

    auto app = appender!string;
    foreach (selector; css.keys.sort)
    {
        auto props = css[selector];
        if (props.length == 0)
            continue;

        app.formattedWrite("%s {\n", selector);
        foreach (prop; props)
        {
            app.formattedWrite("    %s\n", prop);
        }
        app.put("}\n");
    }

    return app.data.stripRight;
}

void genHtml(R,S)(R interlinear, S sink, CssConfig cssCfg)
    if (isInputRange!R && is(ElementType!R : Section))
{
    formattedWrite(sink, htmlPrologue, genCss(cssCfg));
    foreach (sec; interlinear)
    {
        formattedWrite(sink, htmlSecHeading, sec.heading);
        put(sink, htmlSecStart);
        foreach (morph; sec.morphemes)
        {
            put(sink, htmlMorphStart);
            foreach (i, line; morph)
            {
                formattedWrite(sink, htmlMorphLine, i, line);
            }
            put(sink, htmlMorphEnd);
        }

        if (sec.freeTrans.length > 0)
            formattedWrite(sink, htmlSecFreeTrans, sec.freeTrans);

        put(sink, htmlSecEnd);
    }
    put(sink, htmlEpilogue);
}

unittest
{
    auto sample = [
        "John 1:1",
        "В\tPREP\tIn",
        "начале\tN:PREP\tbeginning",
        "было\tV:P:NEUT\twas",
        "Слово,\tN:NOM\tWord,",
        "и\tCONJ\tand",
        "Слово\tN:NOM\tWord",
        "было\tV:P:NEUT\twas",
        "у\tPREP\twith",
        "Бога,\tN:GEN\tGod,",
        "и\tCONJ\tand",
        "Слово\tN:NOM\tWord",
        "было\tV:P:NEUT\twas",
        "Бог.\tN:NOM\tGod.",
        "",
        "John 1:2",
        "Оно\tPRON:NEUT:SG:NOM\tHe",
        "было\tV:P:NEUT\twas",
        "в\tPREP\tin",
        "начале\tN:PREP\tbeginning",
        "у\tPREP\twith",
        "Бога.\tN:GEN\tGod.",
    ];

    version(none)
    {
        auto f = File("/tmp/test.html", "w");
        sample.parseInput
              .genHtml(f.lockingTextWriter);
        f.close;
    }
}

CssConfig parseCssConfig(R)(R lines)
    if (isInputRange!R && is(ElementType!R : const(char)[]))
{
    CssConfig cfg;
    string section;
    FontConfig* font;

    foreach (line; lines)
    {
        line = line.strip;
        if (line.length == 0 || line.startsWith(';'))
            continue;

        if (line.startsWith('['))
        {
            if (!line.endsWith(']'))
                throw new Exception("Invalid section: " ~ line.to!string);

            assert(line.length >= 2);
            section = line[1 .. $-1].to!string;

            if (section == "heading")
            {
                font = &cfg.heading;
                continue;
            }
            else if (section == "freetrans")
            {
                font = &cfg.freeTrans;
                continue;
            }

            if (!section.startsWith("line"))
                throw new Exception("Unknown section name: " ~
                                    section.to!string);

            auto n = section[4 .. $].to!uint;
            if (n < 1)
                throw new Exception("Invalid line number: " ~ n.to!string);
            n--;

            if (cfg.lines.length <= n)
                cfg.lines.length = n + 1;
            font = &cfg.lines[n];
            continue;
        }

        auto parts = line.split("=");
        if (parts.length != 2 || parts[0].length == 0)
            throw new Exception("Invalid line: " ~ line.to!string);

        auto key = parts[0];
        auto value = parts[1].to!string;

        if (section == "")  // global
        {
            switch (key)
            {
                case "maxwidth":    cfg.maxWidth = value;   break;
                case "wordspacing": cfg.wordSpacing = value;   break;
                case "linespacing": cfg.lineSpacing = value;   break;
                case "innerlinespacing":
                    cfg.innerLineSpacing = value;
                    break;
                case "freetransspacing":
                    cfg.freeTransSpacing = value;
                    break;
                default:
                    throw new Exception("Unknown key: " ~ key.to!string);
            }
            continue;
        }

        // Line config
        switch (key)
        {
            case "fontstyle":   font.fontStyle = value;     break;
            case "fontvariant": font.fontVariant = value;   break;
            case "fontweight":  font.fontWeight = value;    break;
            case "fontsize":    font.fontSize = value;      break;
            case "fontfamily":  font.fontFamily = value;    break;
            case "color":       font.color = value;         break;
            case "background":  font.bgColor = value;       break;
            default:
                throw new Exception("Unknown key: " ~ key.to!string);
        }
    }
    return cfg;
}

unittest
{
    auto input = [
        "; Sample",
        "maxwidth=60em",
        "wordspacing=2em",
        "linespacing=2ex",
        "innerlinespacing=1.5ex",
        "freetransspacing=0.7ex",
        "",
        "[line1]",
        "color=red",
        "background=yellow",
        "",
        "[line2]",
        "fontsize=1.5em",
        "",
        "[heading]",
        "fontfamily=sans-serif",
    ];

    auto cfg = parseCssConfig(input);

    assert(cfg.maxWidth == "60em");
    assert(cfg.wordSpacing == "2em");
    assert(cfg.lineSpacing == "2ex");
    assert(cfg.innerLineSpacing == "1.5ex");
    assert(cfg.freeTransSpacing == "0.7ex");

    assert(cfg.heading.fontFamily == "sans-serif");

    assert(cfg.lines.length == 2);
    assert(cfg.lines[0].color == "red");
    assert(cfg.lines[0].bgColor == "yellow");
    assert(cfg.lines[1].fontSize == "1.5em");
}

// vim:set sw=4 ts=4 et ai:
