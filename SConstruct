#!/usr/bin/scons

env = Environment(
    DC = '/usr/src/d/bin/dmd',
    DCFLAGS = [ '-i' ],
    DCTESTFLAGS = [ '-unittest' ],
    DCOPTFLAGS = [ '-O' ],
)

sources = Split("""
    inter2html.d
    main.d
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

# Cross-compiled Windows build
winenv = env.Clone(
    DC = '/usr/src/d/ldc/latest/bin/ldc2',
    DCOPTFLAGS = [ '-O2' ],
)
winenv.Append(DCFLAGS = [ '-mtriple=x86_64-windows-msvc' ])
winenv.Command('inter2html.exe', sources, "$DC $DCFLAGS $DCOPTFLAGS -of$TARGET $SOURCES")

