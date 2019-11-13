import paramiko
import threading
import time,random,json
from flask import request,redirect,render_template
from index import app,sql,url
from .login import cklogin
url.append( {"title": "SHELL",
    "children": [
        {"title": "web shell","href": "/ssh"},
        {"title": "批量主机","href": "/BatchExec"}
        ]
    })
sshListDict={}
sshTimeout={}
def checkSSH():
    t=[]
    for k,v in sshTimeout.items():
        if time.time() > (v+180):
            t.append(k)
    for i in t:

        sshListDict[i].close()
        del sshListDict[i]
        del sshTimeout[i]


#此方法用于处理ssh登陆,并返回id号码
@app.route('/ssh',methods=['GET','POST'])
def ssh():
    if request.method == 'GET':
        return render_template('webssh.html')
    else:
        checkSSH()
        #获取前端输入的服务器地址信息等
        host=request.values.get('host')
        port=request.values.get('port')
        username=request.values.get('username')
        pwd=request.values.get('pwd')
        #创建ssh链接
        sshclient = paramiko.SSHClient()
        sshclient.load_system_host_keys()
        sshclient.set_missing_host_key_policy(paramiko.AutoAddPolicy()) #不限制白名单以外的连接
        try:
            sshclient.connect(host, port, username, pwd)
            chan = sshclient.invoke_shell(term='xterm') #创建交互终端
            chan.settimeout(0)
            ids = str(int(time.time()+random.randint(1,999999999)))
            sshListDict[ids] = chan
        except paramiko.BadAuthenticationType:
            return json.dumps({'resultCode':1,'result':'登录失败,错误的连接类型'})
        except paramiko.AuthenticationException:
            return json.dumps({'resultCode':1,'result':'登录失败'})
        except paramiko.BadHostKeyException:
            return json.dumps({'resultCode':1,'result':'登录失败,请检查IP'})
        except:
            return json.dumps({'resultCode':1,'result':'登录失败'})
        else:
            sshTimeout[ids]=time.time()
            return json.dumps({'resultCode':0,'ids':ids})

#此方法用于获取前端监听的键盘动作,输入到远程ssh
@app.route('/SSHInput',methods=['POST'])
def SSHInput():
    WebInput = request.values.get('input')
    ids = request.values.get('ids')
    chan = sshListDict.get(ids)
    sshTimeout[ids]=time.time()
    if not chan : 
        return json.dumps({'resultCode':1})
    chan.send(WebInput)
    return json.dumps({'resultCode':0})

#根据id号,获取远程ssh结果,方法比较low,用的轮询而没有用socket
@app.route('/GetSsh',methods=['POST'])
def GetSsh():
    ids = request.values.get('ids')
    chan = sshListDict.get(ids)
    if not chan : 
        return json.dumps({'resultCode':1})
    if not chan.exit_status_ready():
        try:
            data=chan.recv(1024).decode()
        except :
            data = ''
        return json.dumps({'resultCode':0,'data':data})
    else:
        chan.close()
        del sshListDict[ids]
        return json.dumps({'resultCode':1})

#批量远程主机执行shell
@app.route('/BatchExec',methods=['GET','POST'])
@cklogin()
def BatchExec():
    if request.method == 'GET':
        return render_template('batchExec.html')
#添加主机
@app.route('/CreateBatchExec',methods=['POST'])
@cklogin()
def CreateBatchExec():
    IP = request.values.get('IP')
    PORT = request.values.get('PORT')
    PWD = request.values.get('PWD')
    GROUPS = request.values.get('GROUPS')
    NOTE = request.values.get('NOTE')
    USERNAME = request.values.get('USERNAME')
    ROOTPWD = request.values.get('ROOTPWD')
    if not (IP and PWD and USERNAME) :
        return json.dumps({'resultCode':1,'result':'请输入正确的IP和账号密码'})
    sqlResult = sql.insertRemoteHost(IP=IP,PORT=PORT,CTYPE='PWD',USERNAME=USERNAME,GROUPS=GROUPS,NOTE=NOTE,PWD=PWD,PKPATH=None,ROOTPWD=ROOTPWD)
    if sqlResult[0]:
        return json.dumps({'resultCode':0})
    else:
        return json.dumps({'resultCode':1,'result':str(sqlResult[1])})
#查询主机
@app.route('/SelectBatchExec',methods=['POST'])
@cklogin()
def SelectBatchExec():
    sqlResult = sql.selectRemoteHost()
    if sqlResult[0]:
        return json.dumps({'resultCode':0,'result':list(sqlResult[1])})
    else:
        return json.dumps({'resultCode':1,'result':str(sqlResult[1])})
#删除主机
@app.route('/DeletetBatchExec',methods=['POST'])
@cklogin()
def DeletetBatchExec():
    ipList = json.loads(request.values.get('ipList'))
    for i in ipList:
        sqlResult = sql.deleteRemoteHost(i)
        if not sqlResult[0]:
            return json.dumps({'resultCode':1,'result':str(sqlResult[1])})
    return json.dumps({'resultCode':0})
#执行远程SHELL
@app.route('/BatchExecShell',methods=['POST'])
@cklogin()
def BatchExecShell():
    ipList = json.loads(request.values.get('ipList'))
    shell = request.values.get('shell')
    userRoot = (True if shell[-5:] == '#root' else False)
    if userRoot:
        shell = shell[:-5]
    for i in ipList:
        sqlResult = sql.selectRemoteHostForIP(i)
        if not sqlResult[0]:
            return json.dumps({'resultCode':1,'result':str(sqlResult[1])})
        else:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ip = sqlResult[1][0]
            port = sqlResult[1][1]
            username = sqlResult[1][2]
            pwd = sqlResult[1][3]
            rootpwd = sqlResult[1][4]
            ssh.connect(ip,int(port),username,pwd)
            if userRoot :
                #如果以root身份运行shell,先su并回车,输入密码,再执行shell
                std_in,std_out,std_err = ssh.exec_command('su'+'\n',get_pty=True)
                std_in.write(rootpwd+'\n')
                std_in.write(shell+'\n')
            else:
                ssh.exec_command(shell+'\n',get_pty=True)
            ssh.close()
    return json.dumps({'resultCode':0})