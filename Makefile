DC=dmd

events: lib/*.d
	mkdir -p out/events
	$(DC) -Hdout/events -c -ofout/events.d.o lib/*.d
	ar -r out/events.d.a out/events.d.o

tests: test/*.d events
	$(DC) -Iout/events out/events.d.a test/*.d -ofout/test.app -unittest -main
	chmod +x out/test.app
	out/./test.app

clean:
	rm -rf out/*
