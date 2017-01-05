CONTRIB_DIR = contrib

# the build target executable:
TARGET = golosbootstrap.sh

all: $(TARGET)

$(TARGET): golosbootstrap.sh.template contrib.tar.gz
	perl -pe 's/##CONTRIBBASE64##/`base64 -b 64 contrib.tar.gz`/ge' golosbootstrap.sh.template > $(TARGET)

contrib.tar.gz: contrib
	tar -czf contrib.tar.gz contrib

clean:
	$(RM) $(TARGET) contrib.* 
