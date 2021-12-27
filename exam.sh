#!/bin/bash

source ./utils.sh

# 测试题目文件夹，每个测试题作为一个目录
# 每个测试题作为一个目录，目录下面必须有 content.txt、options.txt 和 answer.txt 三个文件
# content.txt 文件内容为题目内容
# options.txt 文件内容为题目选项，每个选项占一行
# answer.txt 文件内容为正确答案
export tests_folder='./tests'

export failed_list_file='failed.txt' # 错题集文件

# 随机测试题
function random_tests() {
  limit=$1
  tests_count=$(ls -1 $tests_folder | wc -l)
  if [ $tests_count -lt $limit ]; then
    ls -1 tests/
    return
  fi

  tests=()
  for test in $(ls -1 $tests_folder); do
    if [ $count -ge $limit ]; then
      break
    fi
    tests+=("$test")
    count=$(($count + 1))
  done
  for test in ${tests[@]}; do
    echo $test
  done
}

# 从错题集中随机选取题目
function random_failed() {
  limit=$1
  tests_count=$(read_line $failed_list_file | wc -l)
  if [ $tests_count -lt $limit ]; then
    read_line $failed_list_file
    return
  fi

  tests=()
  for test in $(ls -1 $tests_folder); do
    if [ $count -ge $limit ]; then
      break
    fi
    tests+=("$test")
    count=$(($count + 1))
  done
  for test in ${tests[@]}; do
    echo $test
  done
}

# 从文件中按行读取内容，同时移除每行后面的空格
# https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
# https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
function read_line() {
  file=$1
  if [ ! -f "$file" ]; then
    err "文件不存在: $file"
    exit 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | sed -e 's/[[:space:]]*$//') # remove trailing spaces
    if [ -n "$line" ]; then
      echo "$line"
    fi
  done <$file
}

# 添加错题到错题集
function add_failed() {
  failed_test=$1
  grep -q "$failed_test" $failed_list_file || echo "$failed_test" >>$failed_list_file
}

function read_options() {
  options_file=$1
  if [ ! -f $options_file ]; then
    err "文件不存在: $options_file"
    exit 1
  fi
  idx=1
  # read_line $options_file | while read -r line; do
  #     echo "$idx. $line"
  #     idx=$(($idx + 1))
  # done
  for option in $(read_line $options_file); do
    echo "$idx. $option"
    idx=$(($idx + 1))
  done
}

# todo: options 考虑使用 map: https://www.cnblogs.com/yy3b2007com/p/11267237.html
function get_option() {
  options_file=$1
  option_idx=${2:-0} # 使用缺省值 0
  if [ ! -f $options_file ]; then
    err "文件不存在: $options_file"
    exit 1
  fi
  idx=1
  for option in $(read_line $options_file); do
    if [ $idx -eq $option_idx ]; then
      echo "$option"
      return
    fi
    idx=$(($idx + 1))
  done
}

# 检验答案是否正确，如果不正确，则添加到错题集中
function check_answer() {
  test=$1
  answer=${2-0}
  is_review=${3}

  answer_file="tests/$test/answer.txt"
  if [ ! -f "$answer_file" ]; then
    err "文件不存在: $answer_file"
    exit 1
  fi
  right_answer=$(cat $answer_file)

  options_file="tests/$test/options.txt"
  if [ ! -f "$options_file" ]; then
    err "文件不存在: $options_file"
    exit 1
  fi
  option=$(get_option "$options_file" $answer)
  if [ "$right_answer" = "$option" ]; then
    echo "true"
    if [ "$is_review" = 'true' ]; then
      os=$(uname -s)
      if [ "$os" = 'Darwin' ]; then
        sed -i '' "/$test/d" failed.txt
      elif [ "$os" = 'Linux' ]; then
        sed -i "/$test/d" failed.txt
      fi
    fi
  else
    echo "false"
    [ "$is_review" = 'false' ] && add_failed "$test" || true
  fi
}
