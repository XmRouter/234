echo 'ulimit -f 10000' >> /root/.bashrc  ; source /root/.bashrc
#!/bin/bash
cd /data/workspace/myshixun

# 待执行的评测文件
sourceClassNames=(".testfile/test_1.sh" ".testfile/test_2.sh")

# 执行命令
executeCommand="bash"

# 获取测试用例的输入(请勿改动此行语句)
input=$2;OLD_IFS="$IFS"; IFS=,; ins=($input);IFS="$OLD_IFS"

compileResult=$(echo -n "compile successfully" | base64)

# 执行函数
execute(){
    # 当前关卡的执行目标文件
    sourceClassName=${sourceClassNames[$1 - 1]}
    # 当前关卡号
    challengeStage=$1
	
	# 循环获取各测试用例下的实际输出
    res_usage="{\"testSetUsages\":["
    output=''
    i=0
    while [[ i -lt ${#ins[*]} ]]; do
        echo 0 > /sys/fs/cgroup/memory/memory.max_usage_in_bytes
        startCpuUsage=$(cat /sys/fs/cgroup/cpuacct/cpuacct.usage)
        result=$(echo "${ins[$i]}" | base64 -d | $executeCommand $sourceClassName 2>&1 | base64)
        # 拼接输出结果
        endCpuUsage=$(cat /sys/fs/cgroup/cpuacct/cpuacct.usage)
        let testSetCpuUsage=$endCpuUsage-$startCpuUsage
        maxMemUsage=$(cat /sys/fs/cgroup/memory/memory.max_usage_in_bytes)
        res_usage="$res_usage{\"testSetTime\":\"$testSetCpuUsage\",\"testSetMem\":\"$maxMemUsage\"},"
        output=$output\"$result\",
        let i++
    done
    output="[${output%?}]"
}

execute $1
res_usage="${res_usage::-1}"
res_usage="$res_usage]}"
res_usage=$(echo -ne "$res_usage"|base64)
            
# 返回评测结果
returnResult(){
        result="{\"compileResult\":\"$compileResult\",\"out\":$output,\"resUsage\":\"$res_usage\"}"
        echo $result
}
returnResult