#!/usr/bin/scons

ldc = '/usr/src/d/ldc/latest/bin/ldc2'

env = Environment(
    DC = ldc,
    DCFLAGS = [ ],
    DCTESTFLAGS = [ '-unittest' ],
    DCOPTFLAGS = [ '-O2', '--static' ],
)

common_sources = Split("""
    inter2html.d
""")

sources = common_sources + Split("""
    main.d
""")

cgi_sources = common_sources + Split("""
    cgi.d
    arsd/core.d
    arsd/cgi.d
""")

extra_deps = Split("""
    sample1.ini
    sample1.txt
""")

# Convenience shorthand for building both the 'real' executable and a
# unittest-only executable.
def DProgram(env, target, sources):
	# Build real executable
	env.Command(target, sources, "$DC $DCFLAGS $DCOPTFLAGS $SOURCES -of$TARGET")

	# Build test executable
	testprog = File(target + '-test').path
	teststamp = '.' + target + '-teststamp'
	#env.Depends(target, teststamp)
	env.Command(teststamp, sources, [
		"$DC $DCFLAGS $DCTESTFLAGS $SOURCES -of%s" % testprog,
		"./%s" % testprog,
		"\\rm -f %s*" % testprog,
		"touch $TARGET"
	])
AddMethod(Environment, DProgram)

# Main program
env.DProgram('inter2html', sources)
env.Depends('inter2html', extra_deps)

# CGI driver
cgienv = env.Clone()
cgienv.Append(DCFLAGS = [ '-J.' ])
cgienv.DProgram('inter2html.cgi', cgi_sources)
cgienv.Depends('inter2html.cgi', extra_deps)

# Cross-compiled Windows build
winenv = env.Clone()
winenv.Append(DCFLAGS = [ '-mtriple=x86_64-windows-msvc' ])
winenv.Command('inter2html.exe', sources, "$DC $DCFLAGS $DCOPTFLAGS -of$TARGET $SOURCES")
winenv.Depends('inter2html.exe', extra_deps)

