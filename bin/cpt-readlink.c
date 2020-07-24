/* cpt-readlink --- a utility replacement for readlink
 * See LICENSE for copyright information.
 *
 * This is basically a 'readlink -f' command.
 */
#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <string.h>
#include <limits.h>

#define DIR_MAX PATH_MAX - NAME_MAX - 1


char *realpath(const char *path, char *resolved_path);

int
main(int argc, char *argv[])
{

	char buf[PATH_MAX];

	/* We are going to use these if the file doesn't exist, but we can still
	 * use directories above the file. We are using dname and bname so that
	 * they don't clash with the functions with the same name.
	 */
	char dname[DIR_MAX]; /* directory name */
	char bname[NAME_MAX]; /* base name      */
	sprintf(bname, "%s", (basename(argv[1])));

	if (argc != 2 || strcmp(argv[1], "--help") == 0) {
		fprintf(stderr, "usage: %s [file]\n", argv[0]);
		return 1;
	}

	if (!realpath(argv[1], buf)) {

		if (!realpath(dirname(argv[1]), dname)) {
			perror(argv[0]);
			return 1;
		}
		sprintf(buf, "%s/%s", dname, bname);
	}

	printf("%s\n", buf);
	return 0;
}
