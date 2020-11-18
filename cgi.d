/**
 * CGI interface to inter2html.
 */
module cgi;

import std;
import arsd.cgi;

static immutable mainPage = q"ENDHTML
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>inter2html: text to interlinear HTML tool</title></head><body>
</head><body>

<h1>inter2html: text to interlinear HTML tool</h1>

<form method="POST" action="">
<label for="inifile">INI file.</label>
<input id="inifile" type="file" name="inifile"/>

<label for="inputfile">Text input file.</label>
<input id="inputfile" type="file" name="inputfile"/>

<button>Generate HTML</button>
</form>

</body></html>
ENDHTML";

void cgiMain(Cgi cgi)
{
    cgi.setResponseContentType("text/html");
    cgi.write(mainPage);
}

mixin GenericMain!cgiMain;

// vim:set sw=4 ts=4 et ai:
