/*
  This file is not licenced under the GPL like the rest of the code.
  Its is under the MIT license, to encourage reuse by cut-and-paste.

  Copyright (c) 2007 Red Hat, inc

  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation files
  (the "Software"), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge,
  publish, distribute, sublicense, and/or sell copies of the Software,
  and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions: 

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software. 

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * xdg_user_dir_lookup_with_fallback:
 * @type: a string specifying the type of directory
 * @fallback: value to use if the directory isn't specified by the user
 * @returns: a newly allocated absolute pathname
 *
 * Looks up a XDG user directory of the specified type.
 * Example of types are "DESKTOP" and "DOWNLOAD".
 *
 * In case the user hasn't specified any directory for the specified
 * type the value returned is @fallback.
 *
 * The return value is newly allocated and must be freed with
 * free(). The return value is never NULL if @fallback != NULL, unless
 * out of memory.
 **/
static char *
xdg_user_dir_lookup_with_fallback (const char *type, const char *fallback)
{
  FILE *file;
  char *home_dir, *config_home, *config_file;
  char buffer[512];
  char *user_dir;
  char *p, *d;
  int len;
  int relative;
  
  home_dir = getenv ("HOME");

  if (home_dir == NULL)
    goto error;

  config_home = getenv ("XDG_CONFIG_HOME");
  if (config_home == NULL || config_home[0] == 0)
    {
      config_file = (char*) malloc (strlen (home_dir) + strlen ("/.config/user-dirs.dirs") + 1);
      if (config_file == NULL)
        goto error;

      strcpy (config_file, home_dir);
      strcat (config_file, "/.config/user-dirs.dirs");
    }
  else
    {
      config_file = (char*) malloc (strlen (config_home) + strlen ("/user-dirs.dirs") + 1);
      if (config_file == NULL)
        goto error;

      strcpy (config_file, config_home);
      strcat (config_file, "/user-dirs.dirs");
    }

  file = fopen (config_file, "r");
  free (config_file);
  if (file == NULL)
    goto error;

  user_dir = NULL;
  while (fgets (buffer, sizeof (buffer), file))
    {
      /* Remove newline at end */
      len = strlen (buffer);
      if (len > 0 && buffer[len-1] == '\n')
	buffer[len-1] = 0;
      
      p = buffer;
      while (*p == ' ' || *p == '\t')
	p++;
      
      if (strncmp (p, "XDG_", 4) != 0)
	continue;
      p += 4;
      if (strncmp (p, type, strlen (type)) != 0)
	continue;
      p += strlen (type);
      if (strncmp (p, "_DIR", 4) != 0)
	continue;
      p += 4;

      while (*p == ' ' || *p == '\t')
	p++;

      if (*p != '=')
	continue;
      p++;
      
      while (*p == ' ' || *p == '\t')
	p++;

      if (*p != '"')
	continue;
      p++;
      
      relative = 0;
      if (strncmp (p, "$HOME/", 6) == 0)
	{
	  p += 6;
	  relative = 1;
	}
      else if (*p != '/')
	continue;
      
      if (relative)
	{
	  user_dir = (char*) malloc (strlen (home_dir) + 1 + strlen (p) + 1);
          if (user_dir == NULL)
            goto error2;

	  strcpy (user_dir, home_dir);
	  strcat (user_dir, "/");
	}
      else
	{
	  user_dir = (char*) malloc (strlen (p) + 1);
          if (user_dir == NULL)
            goto error2;

	  *user_dir = 0;
	}
      
      d = user_dir + strlen (user_dir);
      while (*p && *p != '"')
	{
	  if ((*p == '\\') && (*(p+1) != 0))
	    p++;
	  *d++ = *p++;
	}
      *d = 0;
    }
error2:
  fclose (file);

  if (user_dir)
    return user_dir;

 error:
  if (fallback)
    return strdup (fallback);
  return NULL;
}

/**
 * xdg_user_dir_lookup:
 * @type: a string specifying the type of directory
 * @returns: a newly allocated absolute pathname
 *
 * Looks up a XDG user directory of the specified type.
 * Example of types are "DESKTOP" and "DOWNLOAD".
 *
 * The return value is always != NULL (unless out of memory),
 * and if a directory
 * for the type is not specified by the user the default
 * is the home directory. Except for DESKTOP which defaults
 * to ~/Desktop.
 *
 * The return value is newly allocated and must be freed with
 * free().
 **/
char *
xdg_user_dir_lookup (const char *type)
{
  char *dir, *home_dir, *user_dir;
	  
  dir = xdg_user_dir_lookup_with_fallback (type, NULL);
  if (dir != NULL)
    return dir;
  
  home_dir = getenv ("HOME");
  
  if (home_dir == NULL)
    return strdup ("/tmp");
  
  /* Special case desktop for historical compatibility */
  if (strcmp (type, "DESKTOP") == 0)
    {
      user_dir = (char*) malloc (strlen (home_dir) + strlen ("/Desktop") + 1);
      if (user_dir == NULL)
        return NULL;

      strcpy (user_dir, home_dir);
      strcat (user_dir, "/Desktop");
      return user_dir;
    }
  
  return strdup (home_dir);
}

#ifdef STANDALONE_XDG_USER_DIR_LOOKUP
int
main (int argc, char *argv[])
{
  if (argc != 2)
    {
      fprintf (stderr, "Usage %s <dir-type>\n", argv[0]);
      exit (1);
    }
  
  printf ("%s\n", xdg_user_dir_lookup (argv[1]));
  return 0;
}
#endif
