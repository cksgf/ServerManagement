import sqlite3
import os
import time,json
import datetime
import random
class sqlClass(object):
    def __new__(cls):
        if not hasattr(cls,'instance'):
            cls.instance = super(sqlClass,cls).__new__(cls)
        return cls.instance
    def __init__(self):
        self.createSystemInfo()
    def createSystemInfo(self):
        logDB = 'mange.db'
        sqlpath=(os.path.dirname(os.path.realpath(__file__)))
        if logDB in os.listdir(sqlpath):
            self.con = sqlite3.connect(os.path.join(sqlpath,logDB),check_same_thread = False)
        else:
            self.con = sqlite3.connect(os.path.join(sqlpath,logDB),check_same_thread = False)
            self.con.execute('''CREATE TABLE SYSTEMINFO 
                (INFO    TEXT,
                TIM      NUMBER
                );''')
            self.con.execute('''CREATE TABLE RemoteHost 
                (IP           TEXT,
                PORT          TEXT,
                CTYPE         TEXT,
                USERNAME      TEXT,
                PWD           TEXT,
                PKPATH        TEXT,
                GROUPS        TEXT,
                NOTE          TEXT,
                CARETETIME    TEXT,
                ROOTPWD       TEXT
                );''')
            self.con.execute('''CREATE TABLE TaskList 
                (INFO    TEXT,
                TASKID    TEXT
                );''')
            self.con.execute('''CREATE TABLE LinkButton
                (BTID           TEXT,
                BUTTONNAME      TEXT,
                TYPE            TEXT,
                TIM             TEXT,
                NOTE            TEXT,
                SHELL           TEXT,
                CATEGORY        TEXT
                );''')
            self.con.execute('''CREATE TABLE FILES
                                (ids     TEXT,  /*随机ID*/
                                filePath      TEXT,  /*文件全路径*/
                                getVie      TEXT  /*提取码*/
                                );''') 
    def getTime(self):
        return time.strftime('%Y-%m-%d %H:%M:%S',time.localtime())
    def getIds(self):
        return 'a'+str((random.randint(1,int(time.time()))+time.time()+random.random())*100000).replace('.','')
    def getVie(self):
        vieset = list(range(65,91))+list(range(97,123))
        v = ''
        for i in range(6):
            v += chr(random.choice(vieset))
        return v
    #----------------------系统资源统计--------------------
    #写入系统信息
    def insertInfo(self,info):
        info = json.dumps(info)
        self.con.execute("INSERT INTO SYSTEMINFO (INFO,TIM) VALUES (?,?)",(info,self.getTime()))
        self.con.commit()
    #查询记录的信息
    def selectInfo(self,day):
        try:
            date = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()-(int(day) * 86400)))
            resultData = self.con.execute('SELECT * FROM SYSTEMINFO WHERE TIM > (?)',(date,)).fetchall()
            result = [True,resultData]
        except Exception as e:
            result = [False,str(e)]
        return result
    #删除过期数据
    def deleteInfo(self,day):
        date = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()-(int(day) * 86400)))
        self.con.execute('DELETE FROM SYSTEMINFO WHERE TIM < (?)',(date,))
        self.con.commit()

    #----------------------远程主机--------------------
    #新建主机
    def insertRemoteHost(self,IP,PORT,CTYPE,USERNAME,GROUPS,NOTE,ROOTPWD,PWD=None,PKPATH=None):
        try:
            self.con.execute("INSERT INTO RemoteHost (IP,PORT,CTYPE,USERNAME,PWD,PKPATH,GROUPS,NOTE,CARETETIME,ROOTPWD) VALUES (?,?,?,?,?,?,?,?,?,?)",(IP,PORT,CTYPE,USERNAME,PWD,PKPATH,GROUPS,NOTE,self.getTime(),ROOTPWD))
            self.con.commit()
        except Exception as e:
            return [False,str(e)]
        else:
            return [True]
    #查询全部主机
    def selectRemoteHost(self):
        try:
            resultData = self.con.execute('SELECT IP,PORT,USERNAME,GROUPS,NOTE,CARETETIME FROM RemoteHost').fetchall()
            result = [True,resultData]
        except Exception as e:
            result = [False,str(e)]
        return result
    #删除主机记录
    def deleteRemoteHost(self,IP):
        try:
            self.con.execute('DELETE FROM RemoteHost WHERE IP = (?)',(IP,))
            self.con.commit()
        except Exception as e:
            result = [False,str(e)]
        else:
            result = [True]
        return result
    #按照IP查询主机
    def selectRemoteHostForIP(self,IP):
        try:
            resultData = self.con.execute('SELECT IP,PORT,USERNAME,PWD,ROOTPWD FROM RemoteHost WHERE IP = (?)',(IP,)).fetchall()[0]
            result = [True,resultData]
        except Exception as e:
            result = [False,str(e)]
        return result
    #----------------------定时任务--------------------
    #写入任务
    def insertTask(self,info):
        self.con.execute("INSERT INTO TaskList (INFO,TASKID) VALUES (?,?)",(json.dumps(info),info['taskID']))
        self.con.commit()
    #查询任务
    def selectTask(self):
        try:
            resultData = self.con.execute('SELECT * FROM TaskList').fetchall()
            result = [True,resultData]
        except Exception as e:
            result = [False,str(e)]
        return result
    #删除任务
    def deleteTask(self,taskID):
        self.con.execute('DELETE FROM TaskList WHERE TASKID = (?)',(taskID,))
        self.con.commit()
        #----------------------快捷方式--------------------
    #创建一个快捷按钮
    def createLinkButton(self,LinkButtonDict):
        try:
            BTID = str(random.random()+time.time())
            BUTTONNAME =LinkButtonDict['BUTTONNAME']
            TYPE = LinkButtonDict['TYPE']
            TIM = self.getTime()
            NOTE = LinkButtonDict['NOTE']
            SHELL = LinkButtonDict['SHELL']
            CATEGORY = LinkButtonDict['CATEGORY']
            self.con.execute('INSERT INTO LinkButton (BTID,BUTTONNAME,TYPE,TIM,NOTE,SHELL,CATEGORY) VALUES (?,?,?,?,?,?,?)',(BTID,BUTTONNAME,TYPE,TIM,NOTE,SHELL,CATEGORY))
            self.con.commit()
            return [True]
        except Exception as e:
            return [False,e]
    #查询按钮数据
    def selectLinkButton(self,CATEGORY):
        return self.con.execute('SELECT * FROM LinkButton WHERE CATEGORY=?',(CATEGORY,)).fetchall()
    #按照BTID号查询shell
    def selectShellForLinkButton(self,BTID):
        return self.con.execute('SELECT SHELL FROM LinkButton WHERE BTID=?',(BTID,)).fetchall()
    #更新shell
    def updateLinkButton(self,BTID,SHELL):
        try:
            self.con.execute('UPDATE LinkButton set SHELL=? WHERE BTID=?',(SHELL,BTID))
            self.con.commit()
            return [True]
        except Exception as e:
            return [False,e]
    #删除按钮
    def deleteLinkButton(self,BTID):
        self.con.execute('DELETE FROM LinkButton WHERE BTID=?',(BTID,))
        self.con.commit()
    #---------------------文件分享---------------------------------#
    def creatFileShare(self,filepath,needvie):
        vies = (self.getVie() if needvie == 'yes' else '')
        sqlQue = "INSERT INTO FILES (ids,filePath,getVie) VALUES (?,?,?)"
        self.con.execute(sqlQue,(self.getIds(),filepath,vies))
        self.con.commit()
    def deleteFileShare(self,ids):
        sqlQue = "DELETE FROM FILES WHERE ids='%s'"
        self.con.execute(sqlQue%ids)
        self.con.commit()
    def getFileShare(self):
        sqlQue = "SELECT * from FILES"
        return self.con.execute(sqlQue).fetchall()
    def getShareFileInfo(self,ids):
        sqlQue = "SELECT * from FILES WHERE ids = '%s'" %ids
        return self.con.execute(sqlQue).fetchall()[0]