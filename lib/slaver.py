#!/usr/bin/env python
# coding=utf-8
from __future__ import print_function, unicode_literals, division, absolute_import
from .common_func import *
class Slaver:
    def __init__(self, communicate_addr, target_addr, max_spare_count=5):
        self.communicate_addr = communicate_addr
        self.target_addr = target_addr
        self.max_spare_count = max_spare_count
        self.spare_slaver_pool = {}
        self.working_pool = {}
        self.socket_bridge = SocketBridge()
    def _connect_master(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(self.communicate_addr)
        self.spare_slaver_pool[sock.getsockname()] = {
            "conn_slaver": sock,
        }
        return sock
    def _connect_target(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(self.target_addr)
        return sock
    def _response_heartbeat(self, conn_slaver, hb_from_master):
        if hb_from_master.prgm_ver < 0x000B:
            conn_slaver.send(CtrlPkg.pbuild_heart_beat().raw)
            return True
        else:
            conn_slaver.send(CtrlPkg.pbuild_heart_beat().raw)
            pkg, verify = CtrlPkg.recv(
                conn_slaver,
                expect_ptype=CtrlPkg.PTYPE_HEART_BEAT)
            if verify:
                return True
            else:
                return False

    def _stage_ctrlpkg(self, conn_slaver):
        while True:
            pkg, verify = CtrlPkg.recv(conn_slaver, SPARE_SLAVER_TTL)
            if not verify:
                return False
            if pkg.pkg_type == CtrlPkg.PTYPE_HEART_BEAT:
                if not self._response_heartbeat(conn_slaver, pkg):
                    return False
            elif pkg.pkg_type == CtrlPkg.PTYPE_HS_M2S:
                break
        conn_slaver.send(CtrlPkg.pbuild_hs_s2m().raw)

        return True

    def _transfer_complete(self, addr_slaver):
        del self.working_pool[addr_slaver]

    def _slaver_working(self, conn_slaver):
        addr_slaver = conn_slaver.getsockname()
        addr_master = conn_slaver.getpeername()
        try:
            hs = self._stage_ctrlpkg(conn_slaver)
        except Exception as e:
            hs = False
        else:
            if not hs:
                pass

        if not hs:
            del self.spare_slaver_pool[addr_slaver]
            try_close(conn_slaver)
            return
        self.working_pool[addr_slaver] = self.spare_slaver_pool.pop(addr_slaver)
        try:
            conn_target = self._connect_target()
        except:
            del self.working_pool[addr_slaver]
            return
        self.working_pool[addr_slaver]["conn_target"] = conn_target
        self.socket_bridge.add_conn_pair(
            conn_slaver, conn_target,
            functools.partial(
                self._transfer_complete, addr_slaver
            )
        )
        return

    def serve_forever(self):
        self.socket_bridge.start_as_daemon()
        err_delay = 0
        max_err_delay = 15
        spare_delay = 0.08
        default_spare_delay = 0.08
        while True:
            if len(self.spare_slaver_pool) >= self.max_spare_count:
                time.sleep(spare_delay)
                spare_delay = (spare_delay + default_spare_delay) / 2.0
                continue
            else:
                spare_delay = 0.0
            try:
                conn_slaver = self._connect_master()
            except Exception as e:
                time.sleep(err_delay)
                if err_delay < max_err_delay:
                    err_delay += 1
                continue
            try:
                t = threading.Thread(target=self._slaver_working,args=(conn_slaver,))
                t.daemon = True
                t.start()
            except Exception as e:
                time.sleep(err_delay)
                if err_delay < max_err_delay:
                    err_delay += 1
                continue
            err_delay = 0


def run_slaver(communicate_addr, target_addr, max_spare_count=5):
    Slaver(communicate_addr, target_addr, max_spare_count=max_spare_count).serve_forever()


def argparse_slaver(m,t,k):
    import argparse
    parser = argparse.ArgumentParser(
        description="""shootback {ver}-slaver
A fast and reliable reverse TCP tunnel (this is slaver)
Help access local-network service from Internet.
https://github.com/aploium/shootback""".format(ver=version_info()),
        epilog="""
Example1:
tunnel local ssh to public internet, assume master's ip is 1.2.3.4
  Master(another public server):  master.py -m 0.0.0.0:10000 -c 0.0.0.0:10022
  Slaver(this pc):                slaver.py -m 1.2.3.4:10000 -t 127.0.0.1:22
  Customer(any internet user):    ssh 1.2.3.4 -p 10022
  the actual traffic is:  customer <--> master(1.2.3.4) <--> slaver(this pc) <--> ssh(this pc)

Example2:
Tunneling for www.example.com
  Master(this pc):                master.py -m 127.0.0.1:10000 -c 127.0.0.1:10080
  Slaver(this pc):                slaver.py -m 127.0.0.1:10000 -t example.com:80
  Customer(this pc):              curl -v -H "host: example.com" 127.0.0.1:10080

Tips: ANY service using TCP is shootback-able.  HTTP/FTP/Proxy/SSH/VNC/...
""",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("-m", "--master", 
                        metavar="host:port",default=m,
                        help="master address, usually an Public-IP. eg: 2.3.3.3:5500")
    parser.add_argument("-t", "--target", 
                        metavar="host:port",default=t,
                        help="where the traffic from master should be tunneled to, usually not public. eg: 10.1.2.3:80")
    parser.add_argument("-k", "--secretkey", default=k,
                        help="secretkey to identity master and slaver, should be set to the same value in both side")
    parser.add_argument("-v", "--verbose", action="count", default=0,
                        help="verbose output")
    parser.add_argument("-q", "--quiet", action="count", default=0,
                        help="quiet output, only display warning and errors, use two to disable output")
    parser.add_argument("-V", "--version", action="version", version="shootback {}-slaver".format(version_info()))
    parser.add_argument("--ttl", default=300, type=int, dest="SPARE_SLAVER_TTL",
                        help="standing-by slaver's TTL, default is 300. "
                             "this value is optimized for most cases")
    parser.add_argument("--max-standby", default=5, type=int, dest="max_spare_count",
                        help="max standby slaver TCP connections count, default is 5. "
                             "which is enough for more than 800 concurrency. "
                             "while working connections are always unlimited")
    return parser.parse_args()
def main_slaver(m,t,k):
    global SPARE_SLAVER_TTL
    global SECRET_KEY
    global SECRET_KEY_CRC32
    global SECRET_KEY_REVERSED_CRC32
    args = argparse_slaver(m=m,t=t,k=k)
    if args.verbose and args.quiet:
        exit(1)
    communicate_addr = split_host(args.master)
    target_addr = split_host(args.target)
    SECRET_KEY = args.secretkey
    CtrlPkg.recalc_crc32()
    CtrlPkg.SECRET_KEY_CRC32 = binascii.crc32(SECRET_KEY.encode('utf-8')) & 0xffffffff
    CtrlPkg.SECRET_KEY_REVERSED_CRC32 = binascii.crc32(SECRET_KEY[::-1].encode('utf-8')) & 0xffffffff
    SPARE_SLAVER_TTL = args.SPARE_SLAVER_TTL
    max_spare_count = args.max_spare_count
    run_slaver(communicate_addr, target_addr, max_spare_count=max_spare_count)

    #main_slaver()