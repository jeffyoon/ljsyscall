-- define system calls for ffi, OSX specific calls

local cdef = require "ffi".cdef

require "syscall.osx.ffitypes"

cdef[[
int lchmod(const char *path, mode_t mode);
int fchroot(int fd);
int stat64(const char *path, struct stat *sb);
int lstat64(const char *path, struct stat *sb);
int fstat64(int fd, struct stat *sb);
]]

--[[ -- need more types defined
pid_t wait4(pid_t wpid, int *status, int options, struct rusage *rusage);
]]

-- in BSD these are in man(3) but that is ok as we require standard libc; however not in rump kernel of course
-- some however could implement ourself, using sysctl etc

--[[ -- need more types defined
int uname(struct utsname *buf);
time_t time(time_t *t);
]]

cdef[[
int gethostname(char *name, size_t namelen);
int sethostname(const char *name, size_t len);
int getdomainname(char *name, size_t namelen);
int setdomainname(const char *name, size_t len);
void exit(int status);
char *getcwd(char *buf, size_t size);
]]

-- setreuid, setregid are deprecated, implement by other means

-- setpgrp see man pages, may need these for BSD

