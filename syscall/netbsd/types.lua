-- BSD types

local require, print, error, assert, tonumber, tostring,
setmetatable, pairs, ipairs, unpack, rawget, rawset,
pcall, type, table, string, math, bit = 
require, print, error, assert, tonumber, tostring,
setmetatable, pairs, ipairs, unpack, rawget, rawset,
pcall, type, table, string, math, bit

local function init(types, hh, abi, c)

local t, pt, s, ctypes = types.t, types.pt, types.s, types.ctypes

local ptt, addtype, lenfn, lenmt, newfn, istype = hh.ptt, hh.addtype, hh.lenfn, hh.lenmt, hh.newfn, hh.istype

local ffi = require "ffi"
local bit = require "bit"

local h = require "syscall.helpers"

local ntohl, ntohl, ntohs, htons = h.ntohl, h.ntohl, h.ntohs, h.htons

local mt = {} -- metatables
local meth = {}

local addtypes = {
  clockid = "clockid_t",
}

local addstructs = {
  ufs_args = "struct ufs_args",
  tmpfs_args = "struct tmpfs_args",
}

for k, v in pairs(addtypes) do addtype(k, v) end
for k, v in pairs(addstructs) do addtype(k, v, lenmt) end

-- 64 bit dev_t
mt.device = {
  __index = {
    major = function(dev)
      local h, l = t.i6432(dev.dev):to32()
      return bit.bor(bit.band(bit.rshift(l, 8), 0xfff), bit.band(h, bit.bnot(0xfff)))
    end,
    minor = function(dev)
      local h, l = t.i6432(dev.dev):to32()
      return bit.bor(bit.band(l, 0xff), bit.band(bit.rshift(l, 12), bit.bnot(0xff)))
    end,
    device = function(dev) return tonumber(dev.dev) end,
  },
}

t.device = function(major, minor)
  local dev = major
  if minor then dev = bit.bor(bit.band(minor, 0xff), bit.lshift(bit.band(major, 0xfff), 8), bit.lshift(bit.band(minor, bit.bnot(0xff)), 12)) + 0x100000000 * bit.band(major, bit.bnot(0xfff)) end
  return setmetatable({dev = t.dev(dev)}, mt.device)
end

-- TODO test properly, different from Linux as metatype
addtype("sockaddr_un", "struct sockaddr_un", {
  index = {
    family = function(sa) return sa.sun_family end,
    path = function(sa) return ffi.string(sa.sun_path) end,
  },
  newindex = {
    family = function(sa, v) sa.sun_family = v end,
    path = function(sa, v) ffi.copy(sa.sun_path, v) end,
  },
  __new = function(tp, path) return newfn(tp, {family = c.AF.UNIX, path = path}) end,
  __len = function(sa)
    if sa.sun_len == 0 then -- length not set explicitly
      return 2 + #sa.path -- does not include terminating 0
    else
      return sa.sun_len
    end
  end,
})

function t.sa(addr, addrlen) return addr end -- non Linux is trivial, Linux has odd unix handling

addtype("stat", "struct stat", {
  index = {
    dev = function(st) return t.device(st.st_dev) end,
    mode = function(st) return st.st_mode end,
    ino = function(st) return tonumber(st.st_ino) end,
    nlink = function(st) return st.st_nlink end,
    uid = function(st) return st.st_uid end,
    gid = function(st) return st.st_gid end,
    rdev = function(st) return t.device(st.st_rdev) end,
    atime = function(st) return st.st_atimespec.time end,
    ctime = function(st) return st.st_ctimespec.time end,
    mtime = function(st) return st.st_mtimespec.time end,
    birthtime = function(st) return st.st_birthtimespec.time end,
    size = function(st) return tonumber(st.st_size) end,
    blocks = function(st) return tonumber(st.st_blocks) end,
    blksize = function(st) return tonumber(st.st_blksize) end,
    flags = function(st) return st.st_flags end,
    gen = function(st) return st.st_gen end,

    type = function(st) return bit.band(st.st_mode, c.S_I.FMT) end,
    todt = function(st) return bit.rshift(st.type, 12) end,
    isreg = function(st) return st.type == c.S_I.FREG end,
    isdir = function(st) return st.type == c.S_I.FDIR end,
    ischr = function(st) return st.type == c.S_I.FCHR end,
    isblk = function(st) return st.type == c.S_I.FBLK end,
    isfifo = function(st) return st.type == c.S_I.FIFO end,
    islnk = function(st) return st.type == c.S_I.FLNK end,
    issock = function(st) return st.type == c.S_I.FSOCK end,
  },
  __len = lenfn,
})

addtype("siginfo", "siginfo_t", {
  index = {
    signo   = function(s) return s._info._signo end,
    code    = function(s) return s._info._code end,
    errno   = function(s) return s._info._errno end,
    value   = function(s) return s._info._reason._rt._value end,
    pid     = function(s) return s._info._reason._child._pid end,
    uid     = function(s) return s._info._reason._child._uid end,
    status  = function(s) return s._info._reason._child._status end,
    utime   = function(s) return s._info._reason._child._utime end,
    stime   = function(s) return s._info._reason._child._stime end,
    addr    = function(s) return s._info._reason._fault._addr end,
    band    = function(s) return s._info._reason._poll._band end,
    fd      = function(s) return s._info._reason._poll._fd end,
  },
  newindex = {
    signo   = function(s, v) s._info._signo = v end,
    code    = function(s, v) s._info._code = v end,
    errno   = function(s, v) s._info._errno = v end,
    value   = function(s, v) s._info._reason._rt._value = v end,
    pid     = function(s, v) s._info._reason._child._pid = v end,
    uid     = function(s, v) s._info._reason._child._uid = v end,
    status  = function(s, v) s._info._reason._child._status = v end,
    utime   = function(s, v) s._info._reason._child._utime = v end,
    stime   = function(s, v) s._info._reason._child._stime = v end,
    addr    = function(s, v) s._info._reason._fault._addr = v end,
    band    = function(s, v) s._info._reason._poll._band = v end,
    fd      = function(s, v) s._info._reason._poll._fd = v end,
  },
  __len = lenfn,
})

-- note t.dirents iterator is defined in common types
meth.dirent = {
  index = {
    fileno = function(self) return tonumber(self.d_fileno) end,
    reclen = function(self) return self.d_reclen end,
    namlen = function(self) return self.d_namlen end,
    type = function(self) return self.d_type end,
    name = function(self) return ffi.string(self.d_name, self.d_namlen) end,
    toif = function(self) return bit.lshift(self.d_type, 12) end, -- convert to stat types
  },
}

meth.dirent.index.ino = meth.dirent.index.fileno -- alternate name

mt.dirent = {
  __index = function(self, k)
    if meth.dirent.index[k] then return meth.dirent.index[k](self) end
    if c.DT[k] then return self.type == c.DT[k] end
  end,
  __len = function(self) return self.d_reclen end,
}

addtype("dirent", "struct dirent", mt.dirent)

meth.ifreq = {
  index = {
    name = function(ifr) return ffi.string(ifr.ifr_name) end,
    addr = function(ifr) return ifr.ifr_ifru.ifru_addr end,
    dstaddr = function(ifr) return ifr.ifr_ifru.ifru_dstaddr end,
    broadaddr = function(ifr) return ifr.ifr_ifru.ifru_broadaddr end,
    space = function(ifr) return ifr.ifr_ifru.ifru_space end,
    flags = function(ifr) return ifr.ifr_ifru.ifru_flags end,
    metric = function(ifr) return ifr.ifr_ifru.ifru_metric end,
    mtu = function(ifr) return ifr.ifr_ifru.ifru_mtu end,
    dlt = function(ifr) return ifr.ifr_ifru.ifru_dlt end,
    value = function(ifr) return ifr.ifr_ifru.ifru_value end,
    media = function(ifr) return ifr.ifr_ifru.ifru_media end,
    -- TODO rest of fields (buf, buflen)
  },
  newindex = {
    name = function(ifr, v)
      assert(#v < c.IFNAMSIZ, "name too long")
      ifr.ifr_name = v
    end,
    flags = function(ifr, v)
      ifr.ifr_ifru.ifru_flags = c.IFREQ[v]
    end,
    -- TODO rest of fields
  },
}

mt.ifreq = {
  __index = function(ifr, k) if meth.ifreq.index[k] then return meth.ifreq.index[k](ifr) end end,
  __newindex = function(ifr, k, v) if meth.ifreq.newindex[k] then meth.ifreq.newindex[k](ifr, v) end end,
  __new = newfn,
}

addtype("ifreq", "struct ifreq", mt.ifreq)

meth.ifaliasreq = {
  index = {
    name = function(ifra) return ffi.string(ifra.ifra_name) end,
    addr = function(ifra) return ifra.ifra_addr end,
    dstaddr = function(ifra) return ifra.ifra_dstaddr end,
    mask = function(ifra) return ifra.ifra_mask end,
  },
  newindex = {
    name = function(ifra, v)
      assert(#v < c.IFNAMSIZ, "name too long")
      ifra.ifra_name = v
    end,
    addr = function(ifra, v) ifra.ifra_addr = v end, -- TODO type constructor?
    dstaddr = function(ifra, v) ifra.ifra_dstaddr = v end,
    mask = function(ifra, v) ifra.ifra_mask = v end,
  },
}

meth.ifaliasreq.index.broadaddr = meth.ifaliasreq.index.dstaddr
meth.ifaliasreq.newindex.broadaddr = meth.ifaliasreq.newindex.dstaddr

mt.ifaliasreq = {
  __index = function(ifr, k) if meth.ifaliasreq.index[k] then return meth.ifaliasreq.index[k](ifr) end end,
  __newindex = function(ifr, k, v) if meth.ifaliasreq.newindex[k] then meth.ifaliasreq.newindex[k](ifr, v) end end,
  __new = newfn,
}

addtype("ifaliasreq", "struct ifaliasreq", mt.ifaliasreq)

return types

end

return {init = init}

