# 3-Tier Web Application AWS Infrastructure

이 Terraform 프로젝트는 AWS에서 3-tier 웹 애플리케이션을 위한 모듈화된 인프라를 구성합니다.

## 프로젝트 구조

```
.
├── modules/                    # 재사용 가능한 Terraform 모듈들
│   ├── vpc/                   # VPC 및 네트워킹 모듈
│   ├── security-groups/       # 보안 그룹 모듈
│   ├── compute/              # EC2, Auto Scaling 모듈 (예정)
│   ├── database/             # RDS, ElastiCache 모듈 (예정)
│   └── load-balancer/        # ALB 모듈 (예정)
├── environments/              # 환경별 설정
│   ├── dev/                  # 개발 환경
│   ├── staging/              # 스테이징 환경 (예정)
│   └── prod/                 # 프로덕션 환경 (예정)
└── README.md
```

## 아키텍처 개요

### 네트워크 구성
- **VPC**: 10.0.0.0/16
- **가용 영역**: ap-northeast-2a, ap-northeast-2c (서울 리전)

### 서브넷 구성
각 가용 영역마다 다음 서브넷들이 생성됩니다:

#### Public Subnets (Web Tier)
- AZ-1: 10.0.1.0/24
- AZ-2: 10.0.2.0/24
- 용도: Load Balancer, Bastion Host, NAT Gateway

#### Private Subnets (Application Tier)
- AZ-1: 10.0.11.0/24
- AZ-2: 10.0.12.0/24
- 용도: Web Server, Application Server

#### Database Subnets (Database Tier)
- AZ-1: 10.0.21.0/24
- AZ-2: 10.0.22.0/24
- 용도: RDS, ElastiCache

### 보안 그룹
- **ALB Security Group**: HTTP/HTTPS 트래픽 허용
- **Web Security Group**: ALB에서의 트래픽과 Bastion에서의 SSH 허용
- **Database Security Group**: Web 서버에서의 데이터베이스 연결 허용
- **Bastion Security Group**: 특정 IP에서의 SSH 허용

## 사용 방법

### 빠른 시작
처음 사용하시는 경우 [빠른 시작 가이드](./QUICK_START.md)를 참조하세요.

### 상세 배포 가이드
전체 배포 과정은 [배포 가이드](./DEPLOYMENT_GUIDE.md)를 참조하세요.

### 기본 사용법

#### 1. 개발 환경 배포
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

#### 2. 다른 환경 배포
```bash
cd environments/staging  # 또는 prod
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일 수정 후
terraform init
terraform plan
terraform apply
```

#### 3. 정리
```bash
terraform destroy
```

## 모듈 설명

### VPC 모듈 (`modules/vpc/`)
- VPC, 서브넷, 라우팅 테이블 생성
- Internet Gateway, NAT Gateway 구성
- DB Subnet Group 생성

### Security Groups 모듈 (`modules/security-groups/`)
- 각 티어별 보안 그룹 생성
- 최소 권한 원칙에 따른 규칙 설정

## 환경별 설정

각 환경(`dev`, `staging`, `prod`)은 독립적인 설정을 가집니다:

- `main.tf`: 모듈 호출 및 리소스 정의
- `variables.tf`: 변수 정의
- `outputs.tf`: 출력값 정의
- `terraform.tfvars`: 환경별 변수 값

## 확장 계획

다음 모듈들을 추가할 예정입니다:

1. **Compute 모듈**: EC2 인스턴스, Auto Scaling Groups
2. **Load Balancer 모듈**: Application Load Balancer
3. **Database 모듈**: RDS, ElastiCache
4. **Monitoring 모듈**: CloudWatch, SNS
5. **CI/CD 모듈**: CodePipeline, CodeBuild

## 모범 사례

- 모듈화를 통한 코드 재사용성 향상
- 환경별 분리를 통한 격리된 배포
- 태그를 통한 리소스 관리
- 보안 그룹을 통한 네트워크 보안 강화
