/**
 * Simple HTML interlinear generator from tab-separated input.
 */
module inter2html;
import std;

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
table.interlinear {
	display:inline;
}
h6 {
	margin-bottom:0;
}
</style>
</head>
<body>
ENDHTML";

static immutable htmlSecHeading = q"ENDHTML
<h6>%s</h6>
ENDHTML";

static immutable htmlMorph = q"ENDHTML
<table class="interlinear">%-(<tr><td>%s</td></tr>%|%)</table>
ENDHTML";

static immutable htmlEpilogue = q"ENDHTML
</body></html>
ENDHTML";

void genHtml(R,S)(R interlinear, S sink)
    if (isInputRange!R && is(ElementType!R : Section))
{
    put(sink, htmlPrologue);
    foreach (sec; interlinear)
    {
        formattedWrite(sink, htmlSecHeading, sec.heading);
        foreach (morph; sec.morphemes)
        {
            formattedWrite(sink, htmlMorph, morph);
        }
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

    // FIXME
    auto f = File("/tmp/test.html", "w");
    sample.parseInput
          .genHtml(f.lockingTextWriter);
    f.close;
}

int main(string[] args)
{
    if (args.length < 2)
    {
        stderr.writefln("Usage: %s <input file>", args[0]);
        return 1;
    }

    auto f = File(args[1], "r");
    f.byLine.parseInput.genHtml(stdout.lockingTextWriter);

    return 0;
}

// vim:set sw=4 ts=4 et ai:
