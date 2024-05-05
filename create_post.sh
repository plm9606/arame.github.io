#!/bin/bash

# 현재 날짜를 가져옵니다.
current_date=$(date +"%Y-%m-%d %H:%M:%S")

# 파일 이름을 생성합니다.
filename="${current_date:0:10}.md"

# 파일 경로를 설정합니다.
file_path="_posts/${filename}"

# 파일을 생성합니다.
touch $file_path

# 파일에 내용을 추가합니다.
echo "---" >> $file_path
echo "title: " >> $file_path
echo "date: ${current_date}" >> $file_path
echo "categories: []" >> $file_path
echo "tags: []" >> $file_path
echo "author: aram" >> $file_path
echo "toc: true" >> $file_path
echo "comment: true" >> $file_path
echo "---" >> $file_path

echo "File created: ${file_path}"