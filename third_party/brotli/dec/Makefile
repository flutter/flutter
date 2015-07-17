#brotli/dec

include ../shared.mk

CFLAGS += -Wall

OBJS = bit_reader.o decode.o huffman.o safe_malloc.o state.o streams.o

all : $(OBJS)

clean :
	rm -f $(OBJS)
