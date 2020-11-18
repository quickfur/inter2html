/**
 * CLI driver for inter2html.
 */
module main;

import inter2html;
import std;

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

        if (info.helpWanted || args.length < 3)
        {
            writefln("Usage: %s <input file> <output file>", args[0]);
            defaultGetoptPrinter("Available options:", info.options);
            return 1;
        }

        auto infile = args[1];
        auto outfile = args[2];

        auto input = (infile == "-") ? stdin : File(infile, "r");
        auto output = (outfile == "-") ? stdout : File(outfile, "w");

        input.byLine
             .parseInput
             .genHtml(output.lockingTextWriter, cssCfg);

        return 0;
    }
    catch (Exception e)
    {
        stderr.writefln("Error: %s", e.msg);
        return 2;
    }
}

// vim:set sw=4 ts=4 et ai:
