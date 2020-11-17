#!/usr/bin/scons

env = Environment(
    DC = '/usr/src/d/bin/dmd',
    DCFLAGS = [ '-i' ],
    DCTESTFLAGS = [ '-unittest' ],
    DCOPTFLAGS = [ '-O' ],
)

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
env.DProgram('inter2html', 'inter2html.d')
