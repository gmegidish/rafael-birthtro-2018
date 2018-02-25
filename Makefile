.PHONY: clean all

.PRECIOUS: *.o

all: birthtro.nes

clean:
	@rm -fv birthtro.s birthtro.o birthtro.nes

%.o: %.s
	ca65 $<

%.nes: %.o
	ld65 -C nes.cfg -o $@ $<

