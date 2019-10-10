#!/usr/bin/env python
# coding=utf-8
from __future__ import print_function, unicode_literals, division, absolute_import
import sys
import time
import binascii
import struct
import collections
import socket
import select
import threading
import traceback
import functools

try:
    from typing import Union, Callable
except:
    pass
RECV_BUFFER_SIZE = 2 ** 14
SECRET_KEY = "0"
SPARE_SLAVER_TTL = 300
INTERNAL_VERSION = 0x000D
__version__ = (2, 2, 8, INTERNAL_VERSION)


def version_info():
    return "{}.{}.{}-r{}".format(*__version__)


def configure_logging(level):
    pass


def fmt_addr(socket):
    return "{}:{}".format(*socket)


def split_host(x):
    try:
        host, port = x.split(":")
        port = int(port)
    except:
        raise ValueError(
            "wrong syntax, format host:port is "
            "required, not {}".format(x))
    else:
        return host, port


def try_close(closable):
    try:
        closable.close()
    except:
        pass


def select_recv(conn, buff_size, timeout=None):
    rlist, _, _ = select.select([conn], [], [], timeout)
    if not rlist:
        # timeout
        raise RuntimeError("recv timeout")

    buff = conn.recv(buff_size)
    if not buff:
        raise RuntimeError("received zero bytes, socket was closed")

    return buff


class SocketBridge:
    def __init__(self):
        self.conn_rd = set()
        self.map = {}
        self.callbacks = {}

    def add_conn_pair(self, conn1, conn2, callback=None):
        self.conn_rd.add(conn1)
        self.conn_rd.add(conn2)
        self.map[conn1] = conn2
        self.map[conn2] = conn1
        if callback is not None:
            self.callbacks[conn1] = callback

    def start_as_daemon(self):
        t = threading.Thread(target=self.start)
        t.daemon = True
        t.start()
        return t

    def start(self):
        while True:
            try:
                self._start()
            except:
                pass

    def _start(self):
        buff = memoryview(bytearray(RECV_BUFFER_SIZE))
        while True:
            if not self.conn_rd:
                time.sleep(0.06)
                continue
            r, w, e = select.select(self.conn_rd, [], [], 0.5)

            for s in r:
                try:
                    rec_len = s.recv_into(buff, RECV_BUFFER_SIZE)
                except:
                    self._rd_shutdown(s)
                    continue

                if not rec_len:
                    self._rd_shutdown(s)
                    continue

                try:
                    self.map[s].send(buff[:rec_len])
                except:
                    self._rd_shutdown(s)
                    continue

    def _rd_shutdown(self, conn, once=False):
        if conn in self.conn_rd:
            self.conn_rd.remove(conn)

        try:
            conn.shutdown(socket.SHUT_RD)
        except:
            pass

        if not once and conn in self.map:
            self._wr_shutdown(self.map[conn], True)

        if self.map.get(conn) not in self.conn_rd:
            self._terminate(conn)

    def _wr_shutdown(self, conn, once=False):
        try:
            conn.shutdown(socket.SHUT_WR)
        except:
            pass

        if not once and conn in self.map:
            self._rd_shutdown(self.map[conn], True)

    def _terminate(self, conn):
        try_close(conn)
        if conn in self.map:
            _mapped_conn = self.map[conn]
            try_close(_mapped_conn)
            if _mapped_conn in self.map:
                del self.map[_mapped_conn]

            del self.map[conn]
        else:
            _mapped_conn = None 
        if conn in self.callbacks:
            try:
                self.callbacks[conn]()
            except :
                pass
            del self.callbacks[conn]
        elif _mapped_conn and _mapped_conn in self.callbacks:
            try:
                self.callbacks[_mapped_conn]()
            except :
                pass
            del self.callbacks[_mapped_conn]


class CtrlPkg:
    PACKAGE_SIZE = 2 ** 6
    CTRL_PKG_TIMEOUT = 5
    SECRET_KEY_CRC32 = binascii.crc32(SECRET_KEY.encode('utf-8')) & 0xffffffff
    SECRET_KEY_REVERSED_CRC32 = binascii.crc32(SECRET_KEY[::-1].encode('utf-8')) & 0xffffffff
    PTYPE_HS_S2M = -1
    PTYPE_HEART_BEAT = 0
    PTYPE_HS_M2S = +1

    TYPE_NAME_MAP = {
        PTYPE_HS_S2M: "PTYPE_HS_S2M",
        PTYPE_HEART_BEAT: "PTYPE_HEART_BEAT",
        PTYPE_HS_M2S: "PTYPE_HS_M2S",
    }
    FORMAT_PKG = "!b b H 20x 40s"
    FORMATS_DATA = {
        PTYPE_HS_S2M: "!I 36x",
        PTYPE_HEART_BEAT: "!40x",
        PTYPE_HS_M2S: "!I 36x",
    }

    _cache_prebuilt_pkg = {}

    def __init__(self, pkg_ver=0x01, pkg_type=0,
                 prgm_ver=INTERNAL_VERSION, data=(),
                 raw=None,
                 ):
        self.pkg_ver = pkg_ver
        self.pkg_type = pkg_type
        self.prgm_ver = prgm_ver
        self.data = data
        if raw:
            self.raw = raw
        else:
            self._build_bytes()

    @property
    def type_name(self):
        return self.TYPE_NAME_MAP.get(self.pkg_type, "TypeUnknown")

    def __str__(self):
        return """pkg_ver: {} pkg_type:{} prgm_ver:{} data:{}""".format(
            self.pkg_ver,
            self.type_name,
            self.prgm_ver,
            self.data,
        )

    def __repr__(self):
        return self.__str__()

    def _build_bytes(self):
        self.raw = struct.pack(
            self.FORMAT_PKG,
            self.pkg_ver,
            self.pkg_type,
            self.prgm_ver,
            self.data_encode(self.pkg_type, self.data),
        )

    @classmethod
    def _prebuilt_pkg(cls, pkg_type, fallback):
        if pkg_type not in cls._cache_prebuilt_pkg:
            pkg = fallback(force_rebuilt=True)
            cls._cache_prebuilt_pkg[pkg_type] = pkg

        return cls._cache_prebuilt_pkg[pkg_type]

    @classmethod
    def recalc_crc32(cls):
        cls.SECRET_KEY_CRC32 = binascii.crc32(SECRET_KEY.encode('utf-8')) & 0xffffffff
        cls.SECRET_KEY_REVERSED_CRC32 = binascii.crc32(SECRET_KEY[::-1].encode('utf-8')) & 0xffffffff

    @classmethod
    def data_decode(cls, ptype, data_raw):
        return struct.unpack(cls.FORMATS_DATA[ptype], data_raw)

    @classmethod
    def data_encode(cls, ptype, data):
        return struct.pack(cls.FORMATS_DATA[ptype], *data)

    def verify(self, pkg_type=None):
        try:
            if pkg_type is not None and self.pkg_type != pkg_type:
                return False
            elif self.pkg_type == self.PTYPE_HS_S2M:
                return self.data[0] == self.SECRET_KEY_REVERSED_CRC32
            elif self.pkg_type == self.PTYPE_HEART_BEAT:
                return True
            elif self.pkg_type == self.PTYPE_HS_M2S:
                return self.data[0] == self.SECRET_KEY_CRC32
            else:
                return True
        except:
            return False

    @classmethod
    def decode_only(cls, raw):
        if not raw or len(raw) != cls.PACKAGE_SIZE:
            raise ValueError("content size should be {}, but {}".format(
                cls.PACKAGE_SIZE, len(raw)
            ))
        pkg_ver, pkg_type, prgm_ver, data_raw = struct.unpack(cls.FORMAT_PKG, raw)
        data = cls.data_decode(pkg_type, data_raw)

        return cls(
            pkg_ver=pkg_ver, pkg_type=pkg_type,
            prgm_ver=prgm_ver,
            data=data,
            raw=raw,
        )

    @classmethod
    def decode_verify(cls, raw, pkg_type=None):
        try:
            pkg = cls.decode_only(raw)
        except:
            return None, False
        else:
            return pkg, pkg.verify(pkg_type=pkg_type)

    @classmethod
    def pbuild_hs_m2s(cls, force_rebuilt=False):
        if force_rebuilt:
            return cls(
                pkg_type=cls.PTYPE_HS_M2S,
                data=(cls.SECRET_KEY_CRC32,),
            )
        else:
            return cls._prebuilt_pkg(cls.PTYPE_HS_M2S, cls.pbuild_hs_m2s)

    @classmethod
    def pbuild_hs_s2m(cls, force_rebuilt=False):
        if force_rebuilt:
            return cls(
                pkg_type=cls.PTYPE_HS_S2M,
                data=(cls.SECRET_KEY_REVERSED_CRC32,),
            )
        else:
            return cls._prebuilt_pkg(cls.PTYPE_HS_S2M, cls.pbuild_hs_s2m)

    @classmethod
    def pbuild_heart_beat(cls, force_rebuilt=False):
        if force_rebuilt:
            return cls(
                pkg_type=cls.PTYPE_HEART_BEAT,
            )
        else:
            return cls._prebuilt_pkg(cls.PTYPE_HEART_BEAT, cls.pbuild_heart_beat)

    @classmethod
    def recv(cls, sock, timeout=CTRL_PKG_TIMEOUT, expect_ptype=None):
        buff = select_recv(sock, cls.PACKAGE_SIZE, timeout)
        pkg, verify = CtrlPkg.decode_verify(buff, pkg_type=expect_ptype)  # type: CtrlPkg,bool
        return pkg, verify
