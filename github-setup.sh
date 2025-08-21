#!/bin/bash

# GitHub 레포지토리 설정 스크립트
# 사용법: ./github-setup.sh <your-github-username> <repository-name>

if [ $# -ne 2 ]; then
    echo "사용법: $0 <github-username> <repository-name>"
    echo "예시: $0 myusername aws-3tier-terraform"
    exit 1
fi

GITHUB_USERNAME=$1
REPO_NAME=$2
REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo "GitHub 레포지토리 설정 중..."
echo "레포지토리 URL: ${REPO_URL}"

# 원격 저장소 추가
git remote add origin ${REPO_URL}

# 메인 브랜치로 푸시
git push -u origin main

echo "완료! 레포지토리가 성공적으로 업로드되었습니다."
echo "GitHub에서 확인하세요: ${REPO_URL}"
