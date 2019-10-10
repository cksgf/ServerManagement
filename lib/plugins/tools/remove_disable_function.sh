 #!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

clear
echo "+-------------------------------------------------------------------+"
echo "|     Remove PHP disable functions for LNMP, Written by Licess      |"
echo "+-------------------------------------------------------------------+"
echo "|         A tool to remove PHP disable_functions for LNMP           |"
echo "+-------------------------------------------------------------------+"
echo "|        For more information please visit https://lnmp.org         |"
echo "+-------------------------------------------------------------------+"
echo "|             Usage: ./remove_disable_function.sh                   |"
echo "+-------------------------------------------------------------------+"

cur_dir=$(pwd)
        
    ver=""
    echo "Remove all php disable function please type: 1"
    echo "Only remove scandir function please type: 2"
    echo "Only remove exec function please type: 3"
    read -p "Please input 1 2 or 3:" ver
    if [ "$ver" = "" ]; then
        ver="1"
    fi

    if [ "$ver" = "1" ]; then
        echo "You will remove all php disable functions."
    elif [ "$ver" = "2" ]; then 
        echo "You will remove scandir php disable function."
    elif [ "$ver" = "3" ]; then
        echo "You will remove exec php disable_function."
    fi

    get_char()
    {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+c to cancel"
    char=`get_char`


function remove_all_disable_function()
{
    sed -i 's/disable_functions =.*/disable_functions =/g' /usr/local/php/etc/php.ini
}

function remove_scandir_function() 
{
    sed -i 's/,scandir//g' /usr/local/php/etc/php.ini
}

function remove_exec_function()
{
    sed -i 's/,exec//g' /usr/local/php/etc/php.ini
}

if [ "$ver" = "1" ]; then
    remove_all_disable_function
elif [ "$ver" = "2" ]; then 
    remove_scandir_function
elif [ "$ver" = "3" ]; then
    remove_exec_function
fi

if [ -s /etc/init.d/httpd ] && [ -s /usr/local/apache ]; then
echo "Restarting Apache......"
/etc/init.d/httpd -k restart
else
echo "Restarting php-fpm......"
/etc/init.d/php-fpm restart
fi

echo "+-------------------------------------------------+"
echo "| Remove php disable funtion completed,enjoy it!  |"
echo "+-------------------------------------------------+"