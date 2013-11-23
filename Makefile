UNAME := $(shell uname)

LDFLAGS += -L.

ifeq ($(UNAME), Linux)
LDFLAGS += -pthread
else
LDFLAGS +=
endif

ifeq ($(UNAME), Darwin)
SHAREDFLAGS = -dynamiclib
SHAREDEXT = dylib
else
SHAREDFLAGS = -shared
SHAREDEXT = so
endif

ifeq ($(LIBDIR), "")
LIBDIR=/usr/local/lib
endif

ifeq ($(INCDIR), "")
INCDIR=/usr/local/include
endif

#CC = gcc
TARGETS = $(patsubst %.c, %.o, $(wildcard src/*.c))
TESTS = $(patsubst %.c, %, $(wildcard test/*.c))

TEST_EXEC_ORDER = linklist_test hashtable_test rbuf_test queue_test

all: objects static shared

static: objects
	ar -r libhl.a src/*.o

shared: objects
	$(CC) $(LDFLAGS) $(SHAREDFLAGS) src/*.o -o libhl.$(SHAREDEXT)

objects: CFLAGS += -fPIC -Isrc -Wall -Werror -Wno-parentheses -Wno-pointer-sign -DTHREAD_SAFE -O3
objects: $(TARGETS)

clean:
	rm -f src/*.o
	rm -f test/*_test
	rm -f libhl.a
	rm -f libhl.$(SHAREDEXT)
	rm -f support/testing.o

support/testing.o:
	$(CC) $(CFLAGS) -Isrc -c support/testing.c -o support/testing.o

tests: CFLAGS += -Isrc -Isupport -Wall -Werror -Wno-parentheses -Wno-pointer-sign -DTHREAD_SAFE -O3

tests: support/testing.o static
	@for i in $(TESTS); do\
	  echo "$(CC) $(CFLAGS) $$i.c -o $$i libhl.a $(LDFLAGS) -lm";\
	  $(CC) $(CFLAGS) $$i.c -o $$i libhl.a support/testing.o $(LDFLAGS) -lm;\
	done;\
	for i in $(TEST_EXEC_ORDER); do echo; test/$$i; echo; done

install:
	 @echo "Installing libraries in $(LIBDIR)"; \
	 cp -v libhl.a $(LIBDIR)/;\
	 cp -v libhl.$(SHAREDEXT) $(LIBDIR)/;\
	 echo "Installing headers in $(INCDIR)"; \
	 cp -v src/*.h $(INCDIR)/;
