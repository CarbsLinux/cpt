/* kiss-stat --- a utility for getting the user name of file owner
 * See LICENSE for copyright information
 *
 * The reason this simple tool exists is because 'stat' is not
 * portable and ls is not exactly stable enough for scripting.
 * This program is for outputting the owner name, and that's it.
 */

#include <pwd.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

struct passwd *pw;
struct stat    sb;

int
main (int argc, char *argv[])
{
	/* Exit if no or multiple arguments are given. */
	if (argc != 2 || strcmp(argv[1], "--help") == 0) {
		fprintf(stderr, "Usage: %s [pathname]\n", argv[0]);
		return 1;
	}

	/* Exit if file stat cannot be obtained. */
	if (lstat(argv[1], &sb) == -1) {
		perror(argv[0]);
		return 1;
	}

	/* Exit if name of the owner cannot be retrieved. */
	if (!getpwuid(sb.st_uid)) {
		return 1;
	}

	/* Print the user name of file owner. */
	pw = getpwuid(sb.st_uid);
	printf("%s\n", pw->pw_name);
	return 0;
}
