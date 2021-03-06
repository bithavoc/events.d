DC=dmd
DFLAGS=
ifeq (${DEBUG}, 1)
	DFLAGS=-debug -gc -gs -g
else
	DFLAGS=-O -release -inline -noboundscheck
endif

events: lib/*.d
	mkdir -p out/events
	$(DC) -Hdout/events -c -ofout/events.d.o lib/*.d $(DFLAGS)
	ar -r out/events.d.a out/events.d.o

tests: test/*.d events
	$(DC) lib/*.d test/*.d -ofout/test.app -unittest -main $(DFLAGS)
	chmod +x out/test.app
	out/./test.app

examples: examples/*.d events
	$(DC) -Iout/events out/events.d.a examples/simpleExample.d -ofout/simpleExample
	$(DC) -Iout/events out/events.d.a examples/paramsExample.d -ofout/paramsExample
	$(DC) -Iout/events out/events.d.a examples/returnExample.d -ofout/returnExample
	$(DC) -Iout/events out/events.d.a examples/changedExample.d -ofout/changedExample
	$(DC) -Iout/events out/events.d.a examples/fiberedExample.d -ofout/fiberedExample

clean:
	rm -rf out/*
