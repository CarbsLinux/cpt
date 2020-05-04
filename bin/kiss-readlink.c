// kiss-readlink --- a utility replacement for readlink
// See LICENSE for copyright information

// This is basically a 'readlink -f' command.
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {

  char buf[512];

  if (argc != 2) {
    printf("usage: %s FILE\n", argv[0]);
    return(1);
  }

  if (!realpath(argv[1], buf)) {
    perror("realpath");
    return(1);
  }

  // fputs(buf,stdout);
  printf("%s\n", buf);
  return(0);
}
