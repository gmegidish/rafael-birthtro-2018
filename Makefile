.PHONY: clean all

.PRECIOUS: *.o

all: birthtro.nes

clean:
	@rm -fv birthtro.o birthtro.nes

%.o: %.s
	ca65 $<

%.nes: %.o
	ld65 -C nes.cfg -o $@ $< -m map.txt
	cat map.txt && rm map.txt

install: birthtro.nes
	open $<

