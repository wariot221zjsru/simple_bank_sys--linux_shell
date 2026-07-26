#!/bin/bash
#Register
#Login
#Fund
# 判断文件是否存在，不存在则创建
#if [ ! -f "bank_accounts.txt" ]; then
    #touch "bank_accounts.txt"
#    echo "已成功创建存储文本文件！"
#fi


# 循环的次数
#count=3
while true;#[[ ${count}>0 ]]
do
  echo "*******************************
        银行系统  Bank Sisterm
*******************************"
  echo "1. 登录"
  echo "2. 注册"
  echo "3. 彻底退出 （或输入q）"
  #echo "4. 继续其它操作："

  # 键盘录入
  read -p "请输入指定的序号：" num
  case $num in
    1) 
      if [ ! -f "bank_accounts.txt" ]; then
        echo "没有注册用户，请先注册！"
        continue
      fi
      
      #写在这，方便输入 退出的情况，在这个for循环退出后不显示具体账户里的操作，直接返回主菜单#2026.07.26#
      #ifsuccess只有在成功才被赋值为1。因此不用担心循环过程中某一次变为了1后面再执行时再变为0。如果成功就直接跳出这个登录的for循环。
      ifsuccess=0
      for ((i=0;i<3;i++));
      do
      
        read -p "请输入用户名称（按q可退出登录步骤）:" username
        #dpsk:建议将退出检查提前，放在读取用户名之后、循环验证之前，
        #2026.07.26#登录循环(for,这里是循环3次)也要有退出机制
        #给 $username 加上双引号：这样当 username 为空时，实际执行的是 [ "" == "q" ]，不会报错，
        #条件不成立，继续执行后面的用户名存在性检查（ifnotexist 等），然后会输出“用户名不存在！”。
        if [ "$username" == "q" ] || [ "$username" == "Q" ];then
            break
        fi

        read -p "请输入密码：" -s password

        # 判断用户名和密码是否正确
        ifnotexist=1

        found_line=
        #行号
        lineno=0

        #这是逐行读取，一次读不到不代表是错的。故判断用户名的语句放在外边，循环中用标记变量测是否一致没匹配到
        while IFS=' ' read -r value1 value2 value3; do
          lineno=$((lineno+1))
            #echo "Value 1: $value1, Value 2: $value2"
            if [ "$username" == "$value1" ] && [ "$password" == "$value2" ]; then
                echo "登陆成功！"
                ifnotexist=0
                ifsuccess=1
                found_line=$lineno
                
                #取出余额
                remaining=$value3
                #如上所述，成功就跳出循环！
                break
            elif [ "$username" == "$value1" ] && [ "$password" != "$value2" ]; then
            echo "密码错误！"
            #密码错误但账号存在
            ifnotexist=0
            break
            fi
        done < bank_accounts.txt
        if [ $ifnotexist -eq 1 ]; then
            echo "用户名不存在！"
        fi
        
        if [ $ifsuccess -eq 1 ]; then
            printf "欢迎用户: %s    余额: %.2f\n" "$username" "$remaining"
            break
        fi
      done
        #上面的done动起来会使代码看起来太麻烦，结构太复杂。所以上面有问题 没成功登录 的还是在这里 进行“继续” #2026.07.26
        #返回主菜单！
        if (( ifsuccess == 0 ));then
            continue
        fi

        while true; 
        do
        ##github copilot#2026.7.22#
            # 操作菜单（假定已登录并且 found_line 已含匹配行号）
            PS3="请选择序号 (输入数字，或输入 q 退出): "
            options=("存款" "取款" "查询余额" "退出")

            select choice in "${options[@]}"; 
            do
                # 验证用户输入是否为合法序号
                if [[ $REPLY =~ ^[0-9]+$ ]] && (( REPLY>=1 && REPLY<= ${#options[@]} )); then
                opt=$REPLY
                break
                elif [[ $REPLY =~ ^[qQ]$ ]]; then
                opt=4   # treat q as 4 (退出)
                break
                else
                echo "输入无效，请输入 1-${#options[@]} 的数字，或 q 退出。"
                fi
            done

            case "$opt" in

                            #此处不能有break!
            1) echo "你选了：1 - $choice"; 
                read -p "请输入存款金额(最多两位小数)：" deposit_amount
                if [[ ! $deposit_amount =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
                # -?
                    echo "输入无效，请输入一个数字。且至多到两位小数。"
                else
                    #line=$(sed -n "${found_line}p" bank_accounts.txt)
                    #read -r value1 value2 value3 <<< "$line"
                #remaining+充值的值 #在前面登陆成功时就取余额
                    new_balance=$(echo "$remaining + $deposit_amount" | bc)
                    #在用户的循环中，一并修改余额 #更清楚 #直接在程序里做，不涉及文件，减少读取文件次数
                    remaining=$new_balance
                #
                


        #用 sed 直接替换整行（要注意对替换内容中可能的特殊字符做转义）#copilot#
                        # 构造新的整行文本
                    new_line="$username $password $new_balance"

                    # 对 new_line 中的 '/' 和 '&' 做转义以安全传给 sed
                    safe_line=$(printf '%s' "$new_line" | sed 's/[\/&]/\\&/g')

                    # 原地替换第 found_line 行
                    sed -i "${found_line}s/.*/${safe_line}/" bank_accounts.txt
        #copilot#
                #${变量}
                echo "存款成功！新余额为：${new_balance}"
                fi
                ;;
                
                2) echo "你选了：2 - $choice";
                read -p "请输入取款金额(最多两位小数)：" withdraw_amount
                if [[ ! $withdraw_amount =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
                    echo "输入无效，请输入一个数字。且至多到两位小数。"

                    #浮点数比较
                elif [ $(echo "$withdraw_amount > $remaining" | bc) -eq 1 ];then
                    echo "取款金额超出余额！请重新选择。"
                
                else
                    new_balance=$(echo "$remaining - $withdraw_amount" | bc)
                    new_line="$username $password $new_balance"

                # 对 new_line 中的 '/' 和 '&' 做转义以安全传给 sed
                    safe_line=$(printf '%s' "$new_line" | sed 's/[\/&]/\\&/g')

                # 原地替换第 found_line 行
                    sed -i "${found_line}s/.*/${safe_line}/" bank_accounts.txt
        #copilot#
                #${变量}
                    echo "取款成功！新余额为：${new_balance}"

                    #一并修改余额
                    remaining=$new_balance

                fi
                ;;
                
                3) echo "你选了：3 - $choice";
                echo "现有余额：${remaining}"
                ;;

                4|q|Q) echo "退出"; break ;;
                *) echo "无效输入，请输入列表中的数字。" ;;
                    esac
        done
  

    ;;
        
        2) 
        echo "请输入用户名称："
        read username

        #函数内使用 continue 不合法
        #continue 只能在循环（for、while、until）内部使用，不能在函数体中单独出现。
        #if改成while循环，避免continue跳出注册过程#2026.07.26
        checknull()
        {
            #-z 是 "zero length" 的缩写。
                        #如果 $username 的值为空字符串（即未设置或设置为空），则测试结果为 真（返回 0）。
                        #如果 $username 有内容（非空），则测试结果为 假（返回非 0）。
                        #在shell中，“退出状态码”为0表示成功，非0表示失败。和python相反。
            while [ -z "$username" ]; do
                echo "用户名不能为空，请重新输入："
                read username
            done
        }

        checknull $username
        #第一次输入判空也加入退出机制#2026.07.26#   不需要向上面一样加引号。因为checknull()已经判空了，空值根本到不了这里来。而登录部分不需要专门做判空，直接“登录失败”就得了。
        if [ $username == "q" ] || [ $username == "Q" ];then
            continue
        fi

        quitRegister=0
        #2026.07.26#
        ifrepeat=0

        #先判断文件是否存在，不存在的话不需要检查
        if [ -f "bank_accounts.txt" ];then
            #不断输入的循环
            while true;
            do
                while IFS=' ' read -r value1 value2 value3;
                do
                    if [ "$username" == "$value1" ]; then
                        #有输出提示，还要有标记，以便退出 用户名重复 的外层循环#2026.07.26#
                        ifrepeat=1
                        echo "用户名已存在，请重新输入："
                        read username
                        
                        #调用函数，检查非空；若不行就反复输入
                        checknull $username
                        
                        if [ $username == "q" ] || [ $username == "Q" ];then
                            quitRegister=1
                            break 2
                            #退出文件里的循环和不断输入的循环
                        #
                        fi
                    fi
                done < bank_accounts.txt
                #2026.07.26#若匹配完文件的每一行发现没有重复，则推出 用户重名 的外层不断循环
                if(( $ifrepeat == 0 ));then
                    break
                fi
            done
        fi

        if [ $quitRegister -eq 1 ]; then
            echo "退出注册"
            #退回到菜单
            continue
        fi

        echo "请输入密码："
        read -s password
        echo "请再次输入密码："
        read -s password2
        if [ $password == $password2 ]
        then
          echo "注册成功！"

        remaining=0
        #echo $username && echo " " && echo $password > accounts.txt
        #若无文件，自动创建将文件
        printf "%s %s %f\n" $username $password $remaining>> bank_accounts.txt

      
        else
          echo "两次输入的密码不一致，注册失败！"
        fi
        echo "注册成功！" 
        ;;
      3|q|Q) 
        echo "退出成功！"
        exit 0 ;;
      #4)
      #  echo "继续其它操作"
      #  ;;
      *) 
        echo "你的输入有误!请输入一个1~3的数字" ;;
  esac
done