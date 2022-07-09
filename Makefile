CURRENT=301
TARGETDIR=~/tmp
TARGET=tmp.com
SRC=$(CURRENT).nasm
LST=$(CURRENT).lst

.PHONY: clean disass $(TARGET)

$(TARGET): $(SRC)
	nasm -f bin -l $(TARGETDIR)/$(LST) -o $(TARGETDIR)/$@ $^

disass: $(TARGET)
	ndisasm -b16 $(TARGETDIR)/$<

diag: $(TARGET)
	ls -la $(TARGETDIR)/$(TARGET)

clean:
	rm -rf $(TARGETDIR)/$(TARGET) *.com $(TARGETDIR)/$(LST)
