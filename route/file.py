from flask import request,render_template,redirect,send_file, send_from_directory,url_for,session,make_response
import time
from index import app,url,sql
import json
import os
from PIL import Image
import zipfile
import base64
import chardet
import shutil
import traceback
from lib import extract
from config.config import workPath
from .login import cklogin
url.append( {"title": "文件管理",
    "children": [
        {"title": "文件管理器","href": "/file"},
        {"title": "文件分享","href": "/getFileShare"}
        ]
    })
sep=os.path.sep          #当前系统分隔符
@app.route('/file',methods=['GET','POST'])
@cklogin()
def file():
    return render_template('file.html',nowPath=b64encode_(workPath),sep=b64encode_(sep),workPath=b64encode_(workPath))

#返回文件目录
@app.route('/GetFile',methods=['POST'])
@cklogin()
def GetFile():
    try:
        path = b64decode_(request.form['path']) 
        Files =  sorted(os.listdir(path)) 
        dir_=[]
        file_=[]
        fileQuantity = len(Files)
        for i in Files:
            try:
                i=os.path.join(path, i)
                if not os.path.isdir(i):
                    if os.path.islink(i):
                        fileLinkPath = os.readlink(i)
                        file_.append({
                            'fileName':i,
                            'fileSize':getFileSize(i),
                            'fileOnlyName':os.path.split(i)[1] +'-->'+ fileLinkPath,
                            'fileMODTime':time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(os.stat(i).st_mtime)),
                            'power':oct(os.stat(i).st_mode)[-3:],
                            'fileType':'file'
                            })
                    else:
                        file_.append({
                            'fileName':i,
                            'fileSize':getFileSize(i),
                            'fileOnlyName':os.path.split(i)[1],
                            'fileMODTime':time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(os.stat(i).st_mtime)),
                            'power':oct(os.stat(i).st_mode)[-3:],
                            'fileType':'file'
                            })
                else:
                    dir_.append({
                        'fileName':i,
                        'fileOnlyName':os.path.split(i)[1],
                        'fileSize':getFileSize(i),
                        'fileMODTime':time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(os.stat(i).st_mtime)),
                        'power':oct(os.stat(i).st_mode)[-3:],
                        'fileType':'dir'
                        })
            except Exception as e:
                print(e)
                continue
        returnJson = {
        'path':base64.b64encode(path.encode()).decode(),
        'fileQuantity':fileQuantity,
        'files':dir_ + file_
        }
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(traceback.format_exc())})
    else:
        return json.dumps({'resultCode':0,'result':returnJson})
#下载
@app.route('/DownFile',methods=['GET','POST'])
@cklogin()
def DownFile():
    fileName = request.values.get('filename')
    fileName = b64decode_(fileName)
    if os.path.isdir(fileName):
        result = zip_(fileList=[fileName],zipPath=os.path.split(fileName)[0])
        if result[0] :
            fileName = result[1] 
        else:
            return json.dumps({'resultCode':1,'fileCode':str(e)})
    response = make_response(send_from_directory(os.path.split(fileName)[0],os.path.split(fileName)[1],as_attachment=True))
    response.headers["Content-Disposition"] = "attachment; filename={}".format(os.path.split(fileName)[1].encode().decode('latin-1'))
    return response



#在线编辑
@app.route('/codeEdit',methods=['GET','POST'])
@cklogin()
def codeEdit():
    #前端点击编辑时,传来一个get请求,filename为base64编码的包含路径的文件全名
    fileName = request.values.get('filename',None)
    if fileName:
        return render_template('iframe/codeEdit.html',filename=fileName)
    #返回的网页打开后,自动ajax请求该文件内容
    filename = b64decode_(request.form['path'])
    if os.path.getsize(filename) > 2097152 : return json.dumps({'resultCode':1,'fileCode':'不能在线编辑大于2MB的文件！'});
    with open(filename, 'rb') as f:
        #文件编码,fuck you
        srcBody = f.read()
        char=chardet.detect(srcBody)
        fileCoding = char['encoding']
        if fileCoding == 'GB2312' or not fileCoding or fileCoding == 'TIS-620' or fileCoding == 'ISO-8859-9': fileCoding = 'GBK';
        if fileCoding == 'ascii' or fileCoding == 'ISO-8859-1': fileCoding = 'utf-8';
        if fileCoding == 'Big5': fileCoding = 'BIG5';
        if not fileCoding in ['GBK','utf-8','BIG5']: fileCoding = 'utf-8';
        if not fileCoding:
            fileCoding='utf-8'
        try:
            fileCode = srcBody.decode(fileCoding).encode('utf-8')
        except:
            #这一步说明文件编码不被支持,可以按需修改返回数据
            return json.dumps({'resultCode':0,'fileCode':str(srcBody)})
        else:
            return json.dumps({'resultCode':0,'fileCode':fileCode.decode(),'encoding':fileCoding,'fileName':filename})

#保存编辑后的文件
@app.route('/saveEditCode',methods=['POST'])
@cklogin()
def saveEditCode():
    editValues = b64decode_(request.form['editValues'])
    fileName = b64decode_(request.form['fileName'])
    try:
        with open(fileName,'w',encoding='utf-8') as f:
            f.write(editValues)
    except Exception as e :
        return json.dumps({'resultCode':1,'result':str(e)})
    else:
        return json.dumps({'resultCode':0,'result':'success'})

#删除
@app.route('/Delete',methods=['POST'])
@cklogin()
def Delete():
    fileName = b64decode_(request.values.get('filename'))
    result = delete_(fileName)
    if result[0]:
        return json.dumps({'resultCode':0,'result':'success'})
    else:
        return json.dumps({'resultCode':1,'result':str(result[1])})
        
#修改文件权限
@app.route('/chmod',methods=['POST'])
@cklogin()
def chmod():
    fileName = b64decode_(request.values.get('filename'))
    power = request.values.get('power')
    try:
        os.chmod(fileName,int(power,8))
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})
    else:
        return json.dumps({'resultCode':0,'result':'success'})
        

#重命名
@app.route('/RenameFile',methods=['POST'])
@cklogin()
def RenameFile():
    try:
        newFileName = b64decode_(request.values.get('newFileName'))
        oldFileName = b64decode_(request.values.get('oldFileName')) #原文件名,包含路径
        filePath = os.path.split(oldFileName)[0]     #提取路径
        oldFileName = os.path.split(oldFileName)[1]  #原文件名,不包含路径
        if os.path.exists(os.path.join(filePath,newFileName)):
            return json.dumps({'resultCode':1,'result':'新文件名和已有文件名重复!'})
        else:
            os.rename(os.path.join(filePath,oldFileName),os.path.join(filePath,newFileName))
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})
    else:
        return json.dumps({'resultCode':0,'result':'success'})

#创建目录
@app.route('/CreateDir',methods=['POST'])
@cklogin()
def CreateDir():
    try:
        dirName = b64decode_(request.values.get('dirName'))
        path = b64decode_(request.values.get('path'))
        if os.path.exists(os.path.join(path,dirName)):
            return json.dumps({'resultCode':1,'result':'目录已存在'})
        else:
            os.mkdir(os.path.join(path,dirName))
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})
    else:
        return json.dumps({'resultCode':0,'result':'success'})

#创建文件
@app.route('/CreateFile',methods=['POST'])
@cklogin()
def CreateFile():
    try:
        fileName = b64decode_(request.values.get('fileName'))
        path = b64decode_(request.values.get('path'))
        if os.path.exists(os.path.join(path,fileName)):
            return json.dumps({'resultCode':1,'result':'文件已存在'})
        else:
            open(os.path.join(path,fileName),'w',encoding='utf-8')
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})
    else:
        return json.dumps({'resultCode':0,'result':'success'})

#批量操作
@app.route('/batch',methods=['POST'])
@cklogin()
def batch():
    batchType = request.values.get('type')
    selectedListBase64 = json.loads(request.values.get('selectedList'))
    path = b64decode_(request.values.get('path'))
    selectedList = list(b64decode_(i) for i in selectedListBase64)
    if batchType == 'cut':
        for cutFile in selectedList:
            result = cut_(cutFile,path)
            if not result[0] : 
                return json.dumps({'resultCode':1,'result':str(result[1])})
        return json.dumps({'resultCode':0,'result':'success'})
    elif batchType == 'copy':
        for copyFile in selectedList:
            result = copy_(copyFile,path)
            if not result[0] : 
                return json.dumps({'resultCode':1,'result':str(result[1])})
        return json.dumps({'resultCode':0,'result':'success'})
    elif batchType == 'delete':
        for i in selectedList:
            result = delete_(i)
            if not result[0] : 
                return json.dumps({'resultCode':1,'result':str(result[1])})
        return json.dumps({'resultCode':0,'result':'success'})
    elif batchType == 'zip':
        result = zip_(fileList=selectedList,zipPath=path)
        if not result[0] : 
            return json.dumps({'resultCode':1,'result':str(result[1])})
        return json.dumps({'resultCode':0,'result':'success'})
    return json.dumps({'resultCode':1,'result':'未知请求'})
#图片浏览
@app.route('/picVisit',methods=['POST'])
@cklogin()
def picVisit():
    fileName = request.values.get('filename',None)
    fileName = b64decode_(fileName)
    img = Image.open(fileName)
    #因为图片展示页面的div大小为800*800，所以根据图片高、宽等比例缩小
    h_pic=img.size[0]/800 
    w_pic=img.size[1]/800
    size=((int(img.size[0]/h_pic),int(img.size[1]/h_pic)) if h_pic>=w_pic else (int(img.size[0]/w_pic),int(img.size[1]/w_pic)))
    img = img.resize(size, Image.ANTIALIAS)
    name = os.path.join('temp',os.path.split(fileName)[1])
    img.save(name)
    with open(name,'rb') as f:
        imgBase64 = base64.b64encode(f.read()).decode()
    os.remove(name)
    return imgBase64
#上传文件
@app.route('/UploadFile',methods=['POST'])
@cklogin()
def UploadFile():
    try:
        nowPath =  b64decode_(request.values.get('nowPath'))
        UploadFileContent = request.files['File']
        UploadFileName = UploadFileContent.filename
        UploadFileContent.save(os.path.join(nowPath,UploadFileName))
    except Exception as e :
        return json.dumps({'resultCode':1,'result':str(e)})
    else:
        return json.dumps({'resultCode':0,'result':'success'})

#解压文件
@app.route('/Extract',methods=['POST'])
@cklogin()
def Extract_():
    fileName =  b64decode_(request.values.get('filename'))
    extractResult = extract.main(fileName)
    if extractResult[0]:
        return json.dumps({'resultCode':0,'result':'success'})
    else:
        return json.dumps({'resultCode':1,'result':str(extractResult[1])})
#将前端多选的文件记录到session
@app.route('/secectList',methods=['POST'])
def secectList():
    types = request.values.get('type')
    value = request.values.get('value')
    sejson = json.loads(session['secectList'])
    if (types == 'in') and (value not in sejson):
        sejson += [value]
        session['secectList'] = json.dumps(list(set(sejson)))
    elif (types == 'out') and (value in sejson):
        sejson.remove(value)
        session['secectList'] = json.dumps(sejson)
    elif types == 'del':
        session['secectList'] = '[]'
    elif types == 'get':
        return json.dumps({'resultCode':0,'result':session['secectList']})
    return json.dumps({'resultCode':0,'result':'success'})

#新增文件分享
@app.route('/creatFileShare',methods=['POST'])
@cklogin()
def creatFileShare():
    filepath = b64decode_(request.values.get("filepath"))  
    needvie = request.values.get('needvie','yes')
    
    sql.creatFileShare(filepath,needvie)
    return '0'

#删除文件分享
@app.route('/deleteFileShare',methods=['POST'])
@cklogin()
def deleteFileShare():
    ids = request.values.get('ids')
    sql.deleteFileShare(ids)
    return '0'

@app.route('/getFileShare',methods=['GET','POST'])
@cklogin()
def getFileShare():
    if request.method=='GET':
        return render_template("getFlieShare.html")
    sqlResult = sql.getFileShare() 
    result = []
    for i in sqlResult:
        filesizes = getFileSize(i[1])
        result.append({
            'filename':os.path.split(i[1])[1],
            'filepath':i[1].replace('\\','\\\\'),
            'ids':i[0],
            'vie':i[2],
            'filesize':filesizes
            })
    return json.dumps({'resultCode':0,'result':result})  

#文件展示页面
@app.route('/FileShare',methods=['GET'])
def FileShare():
    ids=request.values.get('ids')
    sqlresult = sql.getShareFileInfo(ids)
    return render_template("downFileShare.html",needvie = ('yes' if sqlresult[2] !='' else 'no'),filename=os.path.split(sqlresult[1])[1],ids=ids,filesize=getFileSize(sqlresult[1]))
#下载
@app.route('/DownFileShare',methods=['GET'])
def DownFileShare():
    ids=request.values.get('ids')
    sqlresult = sql.getShareFileInfo(ids)
    if request.values.get('filevie','') == sqlresult[2]:
        fileName = sqlresult[1]
        response = make_response(send_from_directory(os.path.split(fileName)[0],os.path.split(fileName)[1],as_attachment=True,attachment_filename='123'))
        response.headers["Content-Disposition"] = "attachment; filename={}".format(os.path.split(fileName)[1].encode().decode('latin-1'))
        return response
    else:
        return '提取码错误！'


#--------------API---------------#
def delete_(fileName):
    try:
        if os.path.exists(fileName):
            if os.path.isfile(fileName):
                os.remove(fileName)
            else:
                shutil.rmtree(fileName)
        else:
            return [False,"文件或目录不存在"]
    except Exception as e:
        return [False,e]
    else:
        return [True]

def zip_(fileList,zipPath):
    try:
        if len(fileList)>1:
            zipName=os.path.split(zipPath)[1]
        else:
            zipName=os.path.split(fileList[0])[1]
        zipName=('根目录' if zipName == '' else zipName)
        f = zipfile.ZipFile(os.path.join(zipPath,zipName)+'.zip','w',zipfile.ZIP_DEFLATED)
        for i in fileList:
            if os.path.isdir(i):
                for dirpath, dirnames, filenames in os.walk(i):
                    for filename in filenames:
                      f.write(os.path.join(dirpath,filename))
            else:
                f.write(i)
        f.close()
    except Exception as e :
        return [False,e]
    else:
        return [True,os.path.join(zipPath,zipName)+'.zip']
def copy_(copyFile,path):
    try:
        if os.path.isdir(copyFile):
            #将要复制过来的文件夹名
            newPath = os.path.join(path,os.path.split(copyFile)[1])
            if not os.path.exists(os.path.join(path,os.path.split(copyFile)[1])):
                os.mkdir(newPath)
            else:
                return [False,'要复制的文件夹已存在！']
            for i in os.listdir(copyFile):
                #拼接将要复制的文件全路径
                i = os.path.join(copyFile,i)
                if os.path.isdir(i):
                    #要是能像cut一样简单就好了
                    copy_(i,newPath)
                else:
                    shutil.copy(i,newPath)
        else:
            if not os.path.exists(os.path.join(path,os.path.split(copyFile)[1])):
                shutil.copy(copyFile,path)
            else:
                return [False,'要复制的文件已存在！']
    except Exception as e :
        return [False,e]
    else:
        return [True]
def cut_(cutFile,path):
    try:
        if os.path.exists(os.path.join(path,os.path.split(cutFile)[1])):
            return [False,'要剪切的文件已存在！']
        shutil.move(cutFile,path)
    except Exception as e :
        return [False,e]
    else:
        return [True]
def getFileSize(filePath):
    filesizes = ''
    filesizeK = os.stat(filePath).st_size/1024
    if filesizeK>1024:
        filesizeM = filesizeK/1024
        if filesizeM>1024:
            filesizeG = str(round(filesizeM/1024,2))
            filesizes = filesizeG + 'G'
        else:
            filesizes = str(round(filesizeM,2)) + 'M'
    else:
        filesizes = str(round(filesizeK,2)) + 'K'
    return filesizes
def b64decode_(v):
    try:
        return base64.b64decode(v).decode()
    except:
        #网页传来的base64内容,在被flask捕捉的时候,加号会被解码成空格,导致解码报错
        #这个bug调了我半个小时,我还以为前端js生成的base64有问题,fuck
        return base64.b64decode(v.replace(' ','+')).decode()

def b64encode_(v):
    return base64.b64encode(v.encode()).decode()
