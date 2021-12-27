#!/bin/bash
set -e

source ./exam.sh

# issue: 默认值设置无效
default_tests_limit=$(ls $tests_folder | wc -l | tr -d ' ') # 每次最大测试题数量

score=0
name="exam-in-shell"
version="v1.0.0"

reports_folder="$(pwd -P)/reports"
if [ ! -d "$reports_folder" ]; then
  mkdir -p "$reports_folder"
fi

tests=()
answers=()
results=()

is_review='false'

# 打印程序的版本信息
# `print_title 'true'` 可以打印分数
function print_title() {
  print_score=$1
  clear
  echo "=========================================================="
  echo -e "Welcome to $name $version"
  echo -e "基于 Shell 的驾照理论考试练习软件的设计与实现"
  [ "$print_score" = 'true' ] && echo -e "\n\n当前分数: $score" || true
  echo "=========================================================="
  echo -e "\n\n"
}

# 考试练习 or 复习错题集
function list_tests() {
  choice=$1
  limit=$2
  case $choice in
  1)
    random_tests $limit
    ;;
  2)
    is_review='true'
    random_failed $limit
    ;;
  *)
    err "无效的选项"
    exit 1
    ;;
  esac
}

function print_test_result() {
  start_time=$1
  used_time=$2
  score=$3

  for i in ${!tests[@]}; do
    test=${tests[$i]}

    content_file="$tests_folder/$test/content.txt"
    content=$(cat $content_file)

    answer_idx=${answers[$i]}
    options_file="$tests_folder/$test/options.txt"
    answer=$(get_option $options_file $answer_idx)

    right_answer=$(cat "$tests_folder/$test/answer.txt")

    [ "${results[$i]}" = 'true' ] && result='回答正确' || result='回答错误'

    echo -e "$((i + 1)). ${test} [$result]"
    echo -e "> 题目内容: \n$content"
    echo -e "> 你的答案: ${answer}"
    echo -e "> 正确答案: ${right_answer}"
    echo -e "\n"
  done

  echo -e "> 用时: $used_time"
  echo -e "> 分数: $score"
  echo -e "> 考试时间: $start_time"
}

function start_exam() {
  print_title

  echo "1. 考试练习"
  echo "2. 复习错题集"
  read -p "请选择测试类型：" choice
  # issue: list_tests 设置 is_review 没有生效
  [ $choice -eq 2 ] && is_review='true' || true

  read -p "请输入测试题目数量 (默认: $default_tests_limit):" tests_limit
  tests_limit=${tests_limit:-$default_tests_limit}
  set +e
  [ $tests_limit -gt 0 ] 2>/dev/null
  if [ $? -ne 0 ]; then
    err "输入的题目数量不合法"
    exit 1
  fi
  set -e
  #    read -p "请输入测试题目数量: " tests_limit

  start_time=$(date +%s)
  for test in $(list_tests $choice $tests_limit); do
    if [ ! -d "$tests_folder/$test" ]; then
      err "试题不存在: $tests_folder/$test"
      exit 1
    fi

    # https://www.masteringunixshell.net/qa36/bash-how-to-add-to-array.html
    tests+=("$test")

    print_title 'true'

    options_file="$tests_folder/$test/options.txt"
    content_file="$tests_folder/$test/content.txt"

    echo -e "** 题目内容 **:\n$(cat $content_file)\n"
    echo -e "** 题目选项 **:\n$(read_options $options_file)\n"
    # todo: 检查用户输入的选项是否合法
    read -p "** 请输入正确的选项序号**: " option
    result=$(check_answer $test $option $is_review)
    if [ "$result" = "true" ]; then
      score=$(($score + 1))
    fi
    results+=("$result")
    answers+=("$option")
  done
  end_time=$(date +%s)
  used_time="$((($end_time - $start_time) / 60)) 分 $((($end_time - $start_time) % 60)) 秒"

  print_title

  # 保存每次测试的分数和用时
  report_file="$reports_folder/$(date +%Y%m%d%H%M%S).txt"
  os=$(uname -s)
  if [ "$os" = 'Darwin' ]; then
    start_time=$(date -r $start_time +"%Y-%m-%d %H:%M:%S")
  elif [ "$os" = 'Linux' ]; then
    # https://www.theunixschool.com/2013/01/gawk-date-and-time-calculation-functions.html
    start_time=$(echo $start_time | gawk '{print strftime("%Y-%m-%d %H:%M:%S", $1)}')
  fi
  print_test_result "$start_time" "$used_time" "$score" >$report_file
  cat $report_file

  read -p "是否保存测试结果？(y/n): " save_result
  if [ "$save_result" == "y" ]; then
    read -p "请输入保存文件名: " save_file
    save_file="$reports_folder/$save_file.txt"
    mv $report_file $save_file
  else
    rm -f $report_file
  fi
}

function view_reports() {
  clear
  echo "=========================================================="
  echo -e "查看测试结果"
  echo "=========================================================="
  echo -e "\n\n"
  ls -1 $reports_folder | awk -F, '{print $1}'
  echo -e "\n\n"
  read -p "请输入要查看的测试结果文件名: " report_file
  report_file="$reports_folder/$report_file"
  if [ ! -f "$report_file" ]; then
    err "文件不存在: $report_file"
  else
    cat $report_file
  fi

  read -p "回车退出" back
}

function menu() {
  print_title
  echo -e "1. 考试练习"
  echo -e "2. 查看以往的测试记录"
  echo -e "3. 退出"
  read -p "请选择操作：" choice
  case $choice in
  1)
    tests=()
    answers=()
    results=()
    start_exam
    ;;
  2)
    view_reports
    ;;
  3)
    exit 0
    ;;
  *)
    err "输入的选项不合法"
    exit 1
    ;;
  esac
}

function main() {
  while true; do
    menu
  done
}

main "$@"
