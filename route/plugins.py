from flask import request,render_template,redirect,url_for,session,Response
from index import app,url
import base64,platform,os,time,json,subprocess
from .login import cklogin
SYSTEMDEB = None
if 'LINUX' in platform.platform().upper():
    SYSTEMDEB = True
if SYSTEMDEB:
    url.append( {"title": "软件管理",
        "children": [
            {"title": "nginx","href": "/plugins/nginx"},
            {"title": "mysql","href": "/plugins/mysql"}
            ]
        })
#---------------------------nginx------------------------------------------------#
NGINXSTATUS = None
@app.route('/plugins/nginx',methods=['GET','POST'])
@cklogin()
def pluginsNginx():
    global NGINXSTATUS
    if request.method == 'GET':
        if not NGINXSTATUS :
            status = subprocess.Popen(
                    'whereis nginx',
                    shell=True,
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.STDOUT)
            status = status.stdout.read().decode()
            if '/usr/' not in status:
                return render_template('plugins/pluginsInstall.html',name = 'nginx')
            else: 
                NGINXSTATUS = True
        return render_template('plugins/nginxMange.html')
    else:
        d = {'0':'start', '1':'stop','2':'reload','3':'restart','4':'status','5':'configtest'}
        nginxType = d.get(request.values.get('types'))
        if nginxType:
            shellResult = subprocess.Popen(
                    'service nginx %s'%nginxType,
                    shell=True,
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.STDOUT)
            return json.dumps({'resultCode':0,'result':shellResult.stdout.read().decode()})
        else:
            return json.dumps({'resultCode':1})
        
@app.route('/plugins/install/nginx',methods=['GET'])
@cklogin()
def pluginsinstallNginx():
    global NGINXSTATUS
    if NGINXSTATUS:
        return render_template('plugins/nginxMange.html')
    installScript = 'cd %s && /bin/bash %s' %(os.path.join(os.getcwd(),'lib/plugins'),'install.sh nginx')
    process = subprocess.Popen(
            installScript,
            shell=True,
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT)
    NGINXSTATUS = True
    def getNginxInfo(process):
        yield bytes("<h2>正在安装nginx...请稍等,安装完后会自动跳转...</h2>",'utf-8')
        while process.poll() == None:
            time.sleep(0.1)
            yield process.stdout.readline().replace(b'\n',b'<br>')
        yield bytes("<script>location.href = '/plugins/nginx'</script>",'utf-8')
    return Response(getNginxInfo(process))
#---------------------------nginx------------------------------------------------#
#---------------------------mysql------------------------------------------------#
MYSQLSTATUS = None
@app.route('/plugins/mysql',methods=['GET','POST'])
@cklogin()
def pluginsMysql():
    global MYSQLSTATUS
    if request.method == 'GET':
        if not MYSQLSTATUS :
            status = subprocess.Popen(
                    'service mysql',
                    shell=True,
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.STDOUT)
            status = status.stdout.read().decode()
            if ('|' not in status) and ('{' not in status):
                return render_template('plugins/pluginsInstall.html',name = 'mysql')
            else: 
                MYSQLSTATUS = True
        return render_template('plugins/mysqlMange.html')
    else:
        d = {'0':'start', '1':'stop','2':'reload','3':'restart','4':'status'}
        nginxType = d.get(request.values.get('types'))
        if nginxType:
            shellResult = subprocess.Popen(
                    'service mysql %s'%nginxType,
                    shell=True,
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.STDOUT)
            return json.dumps({'resultCode':0,'result':shellResult.stdout.read().decode()})
        else:
            return json.dumps({'resultCode':1})
        
@app.route('/plugins/install/mysql',methods=['GET'])
@cklogin()
def pluginsinstallMysql():
    global MYSQLSTATUS
    status = subprocess.Popen(
            'service mysql',
            shell=True,
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT)
    status = status.stdout.read().decode()
    if ('|' in status) and ('{' in status):
        MYSQLSTATUS = True
    if MYSQLSTATUS:
        return render_template('plugins/mysqlMange.html')
    version = request.values.get('version')
    if version not in ['10','1','2','3','4','5','6','7','8','9']:
        return '<script>location.href = "/plugins/mysql"</script>'
    pwd = request.values.get('pwd')
    if not pwd:
        pwd = 'cm9vdDEyMzQ1Ng=='
    try:
        rootpwd = base64.b64decode(pwd).decode()
    except:
        rootpwd = base64.b64decode(pwd.replace(' ','+')).decode()
    print(rootpwd)
    if not os.path.exists('/home/lnmpconfig/DBSelect'):
        try:
            os.makedirs('/home/lnmpconfig/')
        except:
            pass
    with open('/home/lnmpconfig/DBSelect','w') as f:
        f.write(version)
    with open('/home/lnmpconfig/DBPWD','w') as f:
        f.write(rootpwd)
    installScript = 'cd %s && /bin/bash %s' %(os.path.join(os.getcwd(),'lib/plugins'),'install.sh db')
    mysqlProcess = subprocess.Popen(
            installScript,
            shell=True,
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT)
    MYSQLSTATUS = True
    name = ['MySQL 5.1.73','MySQL 5.5.62','MySQL 5.6.42','MySQL 5.7.24','MySQL 8.0.13','MariaDB 5.5.62','MariaDB 10.0.37','MariaDB 10.1.37','MariaDB 10.2.19','MariaDB 10.3.11'][int(version)-1]
    def getMysqlInfo(mysqlProcess):
        yield bytes("<h2>正在安装%s...密码设为%s 请稍等,安装完后会自动跳转...</h2>" %(name,rootpwd),'utf-8')
        while mysqlProcess.poll() == None:
            time.sleep(0.1)
            yield mysqlProcess.stdout.readline().replace(b'\n',b'<br>')
        yield bytes("<script>location.href = '/plugins/mysql'</script>",'utf-8')
    return Response(getMysqlInfo(mysqlProcess))
#---------------------------mysql------------------------------------------------#