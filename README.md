inter2html: a simple HTML interlinear generator
===============================================

A simple utility for creating interlinear texts in HTML format. It takes a text
input file, with an optional style configuration .ini file, and produces its
output as a HTML file or webpage.

There are two front ends:

- A standalone command-line utility that can be run locally on local files;

- A CGI interface that can be hooked to a web server for browser access.

License
-------

[Boost License version 1.0](http://www.boost.org/LICENSE_1_0.txt)


Building
--------

Build requirements:

- A Posix OS, or equivalent environment (tested on Linux)
- [Git](https://git-scm.com/) (for cloning Adam Ruppe's D library, arsd)
- [SCons](https://scons.org/)
- D compiler, preferably [LDC](https://github.com/ldc-developers/ldc/releases/)

Build steps:

- Edit `SConstruct`. Change the `ldc` setting at the top of the file to the
  path to your local installation of LDC.

- Run SCons to build:

    scons

If all goes well, it will produce 3 binaries:

- `inter2html`: the command-line version.
- `inter2html.exe`: the Windows command-line version, if you have LDC
  cross-compilation setup.
- `inter2html.cgi`: a CGI executable that you can hook up to your web server.


Invocation
----------

For the command-line versions, simply running the program with `-h` will
display a list of options.

For the CGI version, the default page is a form that provides upload buttons
and links for downloading sample input files.


Input format
------------

The input is a text file consisting of blocks separated by blank lines. Each
block represents a line of interlinear text.

The first line is considered a sub-heading for that line of text. Its style is
configured by the [heading] section in the style .ini file.

Subsequent lines consists of tab-separated fields. Each line corresponds with a
word group in the interlinear, and each field corresponds to a line in the
output.

At the end of each block, there's an optional line for a free translation line
(rendered separately and not column-aligned with the interlinear). This line
must come last in the block, and must not contain any tab characters or any
embedded newlines.

Example:

    John 1:1
    В	PREP	In
    начале	N:PREP	beginning
    было	V:P:NEUT	was
    Слово,	N:NOM	Word,
    и	CONJ	and
    Слово	N:NOM	Word
    было	V:P:NEUT	was
    у	PREP	with
    Бога,	N:GEN	God,
    и	CONJ	and
    Слово	N:NOM	Word
    было	V:P:NEUT	was
    Бог.	N:NOM	God.
    In the beginning was the Word, and the Word was with God, and the Word was God.

The first line indicates the heading of the this block.  The subsequent lines
consist of 3 fields each:

- The first field is a morpheme unit from the source language;
- The second field is the grammatical tag of that morpheme unit;
- The third field is the English gloss of that morpheme unit.

The last line, which contains no tabs, is a free translation line. It is
optional, and may be omitted, in which case it will be skipped in the output.


Style configuration
-------------------

The style of the output is controlled by an optional .ini file that can be
specified by the `-s` option in the command-line utility, or by uploading the
.ini file to the web form in the CGI interface.

The .ini file follows the standard .ini syntax commonly used by Windows
programs.  The sample file `sample1.ini` in this repository contains an
annotated example of the available style parameters that can be configured.

