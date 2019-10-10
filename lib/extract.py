import gzip
import tarfile
import zipfile
import os
#主函数,传入带路径的压缩文件名
def main(file):
    fileType = os.path.splitext(file)[1]
    if fileType.upper() == '.ZIP':
        return zip(file)
    elif fileType.upper() == '.GZ':
        return gz(file)
    elif fileType.upper() == '.TAR':
        return tar(file)
    else:
        return [False,'文件类型暂时不受支持']
def gz(file):
    try:
        fileName = file.replace(".gz", "")
        g_file = gzip.GzipFile(file)
        with open(fileName, "wb+") as f:
            f.write(g_file.read())
        g_file.close()
    except Exception as e:
        return [False,e]
    else:
        return [True]
def tar(file):
    try:
        tar = tarfile.open(file)
        names = tar.getnames()
        os.mkdir(file + "_files")
        for name in names:
            tar.extract(name, file + "_files/")
        tar.close()
    except Exception as e:
        return [False,e]
    else:
        return [True]
def zip(file):
    try:
        zip_file = zipfile.ZipFile(file)
        os.mkdir(file + "_files")
        nameDict={}
        for names in zip_file.namelist():
            oldname=names
            try:
                names = names.encode('cp437').decode('gbk')
            except:
                names = names.encode('utf-8').decode('utf-8')
            nameDict[oldname]=names
            zip_file.extract(oldname,file + "_files/")
        zip_file.close()
        #zipfile解压中文文件名会乱码,所以解压完后要重命名回正常的文件名
        for k,v in nameDict.items():
            os.rename(file + "_files/"+k,file + "_files/"+v)
    except Exception as e:
        return [False,e]
    else:
        return [True]