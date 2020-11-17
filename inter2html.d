/**
 * Simple HTML interlinear generator from tab-separated input.
 */
module inter2html;
import std;

struct CssConfig
{
    static struct LineConfig
    {
        string fontStyle, fontVariant, fontWeight, fontSize, fontFamily;
        string color, bgColor;
    }

    string maxWidth;
    string wordSpacing;
    string lineSpacing;
    LineConfig[] lines;
}

struct Section
{
    string heading;
    string[][] morphemes;
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

auto parseInput(R)(R lines)
    if (isInputRange!R && is(ElementType!R : const(char)[]))
{
    static immutable const(char)[] blankLine = "";
    return lines.map!(l => l.idup)
                .array
                .split(blankLine)
                .map!(ll => Section(ll.takeOne.front.idup,
                                    ll.dropOne.parseMorphemes.array));
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

static immutable htmlPrologue = q"ENDHTML
<html><head>
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

static immutable cssLineStart = q"ENDCSS
.interlinear .line%d {
ENDCSS";

static immutable cssLineEnd = q"ENDCSS
}
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

static immutable htmlSecEnd = q"ENDHTML
</div>
ENDHTML";

static immutable htmlEpilogue = q"ENDHTML
</body></html>
ENDHTML";

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

    foreach (i, lcfg; cfg.lines)
    {
        app.formattedWrite(cssLineStart, i);
        if (lcfg.fontStyle.length > 0)
            app.formattedWrite("    font-style: %s;\n", lcfg.fontStyle);
        if (lcfg.fontVariant.length > 0)
            app.formattedWrite("    font-variant: %s;\n", lcfg.fontVariant);
        if (lcfg.fontWeight.length > 0)
            app.formattedWrite("    font-weight: %s;\n", lcfg.fontWeight);
        if (lcfg.fontSize.length > 0)
            app.formattedWrite("    font-size: %s;\n", lcfg.fontSize);
        if (lcfg.fontFamily.length > 0)
            app.formattedWrite("    font-family: %s;\n", lcfg.fontFamily);
        if (lcfg.color.length > 0)
            app.formattedWrite("    color: %s;\n", lcfg.color);
        if (lcfg.bgColor.length > 0)
            app.formattedWrite("    background: %s;\n", lcfg.bgColor);
        app.formattedWrite(cssLineEnd);
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
    uint idx;

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

            if (!section.startsWith("line"))
                throw new Exception("Unknown section name: " ~
                                    section.to!string);

            auto n = section[4 .. $].to!uint;
            if (n < 1)
                throw new Exception("Invalid line number: " ~ n.to!string);

            idx = n - 1;
            if (cfg.lines.length <= idx)
                cfg.lines.length = idx + 1;

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
                default:
                    throw new Exception("Unknown key: " ~ key.to!string);
            }
            continue;
        }

        // Line config
        switch (key)
        {
            case "fontstyle":   cfg.lines[idx].fontStyle = value;   break;
            case "fontvariant": cfg.lines[idx].fontVariant = value; break;
            case "fontweight":  cfg.lines[idx].fontWeight = value;  break;
            case "fontsize":    cfg.lines[idx].fontSize = value;    break;
            case "fontfamily":  cfg.lines[idx].fontFamily = value;  break;
            case "color":       cfg.lines[idx].color = value;       break;
            case "background":  cfg.lines[idx].bgColor = value;     break;
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
        "",
        "[line1]",
        "color=red",
        "background=yellow",
        "",
        "[line2]",
        "fontsize=1.5em",
    ];

    auto cfg = parseCssConfig(input);

    assert(cfg.maxWidth == "60em");
    assert(cfg.wordSpacing == "2em");
    assert(cfg.lineSpacing == "2ex");

    assert(cfg.lines.length == 2);
    assert(cfg.lines[0].color == "red");
    assert(cfg.lines[0].bgColor == "yellow");
    assert(cfg.lines[1].fontSize == "1.5em");
}

int main(string[] args)
{
    try
    {
        CssConfig cssCfg;

        auto info = getopt(args,
            "style|s", "Specify style configuration file",
                (string key, string value) {
                    cssCfg = parseCssConfig(File(value, "r").byLine);
                },
        );

        if (info.helpWanted || args.length < 2)
        {
            writefln("Usage: %s <input file>", args[0]);
            defaultGetoptPrinter("Available options:", info.options);
            return 1;
        }

        auto f = File(args[1], "r");
        f.byLine.parseInput.genHtml(stdout.lockingTextWriter, cssCfg);

        return 0;
    }
    catch (Exception e)
    {
        stderr.writefln("Error: %s", e.msg);
        return 2;
    }
}

// vim:set sw=4 ts=4 et ai:
