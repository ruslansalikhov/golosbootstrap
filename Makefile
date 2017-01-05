CONTRIB_DIR = contrib

# the build target executable:
TARGET = golosbootstrap.sh

all: $(TARGET)

$(TARGET): golosbootstrap.sh.template contrib.tar.gz
	perl -pe 's/rmdir \$BASEDIR/`base64 -b 64 contrib.tar.gz`/ge' golosnodebootstrap.sh.template > $(TARGET)

contrib.tar.gz.b64: contrib.tar.gz
	base64 -w 72 contrib.tar.gz > contrib.tar.gz.b64

contrib.tar.gz: contrib
	tar -czf contrib.tar.gz contrib

clean:
	$(RM) $(TARGET) contrib.* 
