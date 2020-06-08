// kiss-readlink --- a utility replacement for readlink
// See LICENSE for copyright information

// This is basically a 'readlink -f' command.
#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <string.h>

int main(int argc, char *argv[]) {

  char buf[512];
  char bname[512];
  strcpy(bname, "/");
  strcat(bname, (basename(argv[1])));

  if (argc != 2 || strcmp(argv[1], "--help") == 0) {
    printf("usage: %s [file]\n", argv[0]);
    return(1);
  }

  if (!realpath(argv[1], buf)) {

    if (!realpath(dirname(argv[1]), buf)) {
    perror("realpath");
    return(1);
    }
    strcat(buf, bname);
  }

  printf("%s\n", buf);
  return(0);
}
