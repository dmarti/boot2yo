CFLAGS = -std=gnu99 -fPIC -levent -lpthread
LDFLAGS = -shared 

all : boot2yo.so

%.so : %.c
	$(CC) -o $@ -std=gnu99 -fPIC -shared -lcurl $^

hooks : .git/hooks/pre-commit

.git/hooks/% : Makefile
	echo "#!/bin/sh" > $@
	echo "make `basename $@`" >> $@
	chmod 755 $@

pre-commit :
	git diff-index --check HEAD

# Remove anything listed in the .gitignore file.
clean :
	find . -path ./.git -prune -o -print0 | \
	git check-ignore -z --stdin | xargs -0 rm -f

.PHONY : all clean hooks
