DC=dmd

events: lib/*.d
	mkdir -p out/events
	$(DC) -Hdout/events -c -ofout/events.d.o lib/*.d
	ar -r out/events.d.a out/events.d.o

tests: test/*.d events
	$(DC) -Iout/events out/events.d.a test/*.d -ofout/test.app -unittest -main
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
