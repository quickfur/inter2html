/**
 * CGI interface to inter2html.
 *
 * To test, add something like this to Apache config:
 *      ScriptAlias /inter2html/ /var/www/inter2html_cgi/
 *
 * and install the binary as 'index' in that directory.
 *
 * URL will be /inter2html_cgi/index.
 */
module cgi;

import std;
import arsd.cgi;
import inter2html;

static immutable mainPage = q"ENDHTML
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>inter2html: text to interlinear HTML tool</title></head><body>
<style type="text/css">
body {
    background: #c0ffff;
}
h1 {
    font-size: 1.4em;
    font-variant: small-caps;
    font-family: mono;
    text-align: center;
}
h2 {
    font-size: 1.2em;
    text-align: center;
}
legend {
    font-weight: bold;
}
fieldset {
    margin-top: 1ex;
    margin-bottom: 1ex;
}
main {
    max-width: 40em;
    border: .2ex outset #c0c0c0;
    padding: 1ex 1em 1ex 1em;
    margin-left: auto;
    margin-right: auto;
    color: black;
    background: white;
}
</style>
</head><body>

<main>
<h1>inter2html</h1>
<h2>Text to interlinear HTML tool</h2>

<form method="POST" action="%s" enctype="multipart/form-data">
  <fieldset>
    <legend>Input (required)</legend>
    <p>Upload your input file here. It should be a plain text file in the
    required format.</p>
    <input id="inputfile" type="file" name="inputfile" accept=".txt" required />
  </fieldset>

  <fieldset>
    <legend>Style configuration (optional)</legend>
    <p>Upload a style INI file here to configure the style of the output.</p>
    <input id="inifile" type="file" name="inifile" accept=".ini, .txt" />
  </fieldset>

  <button type="submit">Generate interlinear</button>
</form>
</main>

</body></html>
ENDHTML";

void handlePost(Cgi cgi)
{
    CssConfig cssCfg;

    auto inifile = "inifile" in cgi.files;
    if (inifile !is null)
    {
        if (inifile.contentInMemory)
        {
            auto data = cast(string) inifile.content;
            cssCfg = parseCssConfig(data.lineSplitter);
        }
        else
            cssCfg = parseCssConfig(File(inifile.contentFilename, "r")
                                    .byLine);
    }

    auto inputfile = "inputfile" in cgi.files;
    if (inputfile !is null)
    {
        if (inputfile.contentInMemory)
        {
            auto data = cast(string) inputfile.content;
            cgi.setResponseContentType("text/html; charset=utf-8");
            data.lineSplitter
                .parseInput
                .genHtml((const(char)[] s) { cgi.write(s); }, cssCfg);
            return;
        }
        else
        {
            auto data = File(inputfile.contentFilename, "r");

            cgi.setResponseContentType("text/html; charset=utf-8");
            data.byLine
                .parseInput
                .genHtml((const(char)[] s) { cgi.write(s); }, cssCfg);
            return;
        }
    }

    // If we got here, it means user forgot to specify input. Which means
    // either his browser is broken, or he didn't get here via the form. So
    // send him back there.
    cgi.setResponseLocation("/inter2html/index");
}

void cgiMain(Cgi cgi)
{
    switch (cgi.requestMethod)
    {
        case Cgi.RequestMethod.GET:
            cgi.setResponseContentType("text/html; charset=utf-8");
            cgi.write(mainPage.format(cgi.scriptName));
            return;

        case Cgi.RequestMethod.POST:
            handlePost(cgi);
            return;

        default:
            cgi.setResponseStatus("405 Method Not Allowed");
            return;
    }
}

mixin GenericMain!cgiMain;

// vim:set sw=4 ts=4 et ai:
