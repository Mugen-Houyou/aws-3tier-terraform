# 3-Tier Web Application AWS Infrastructure

이 Terraform 프로젝트는 AWS에서 3-tier 웹 애플리케이션을 위한 모듈화된 인프라를 구성합니다.

## 프로젝트 구조

```
.
├── modules/                    # 재사용 가능한 Terraform 모듈들
│   ├── vpc/                   # VPC 및 네트워킹 모듈
│   ├── security-groups/       # 보안 그룹 모듈
│   ├── compute/              # EC2 인스턴스 모듈 (Bastion, Web Servers)
│   ├── database/             # RDS MySQL 모듈 (Master-Slave)
│   ├── elasticache/          # Redis ElastiCache 모듈 (Master-Slave)
│   └── load-balancer/        # ALB 모듈 (예정)
├── environments/              # 환경별 설정
│   ├── dev/                  # 개발 환경 (구현 완료)
│   ├── staging/              # 스테이징 환경 (예정)
│   └── prod/                 # 프로덕션 환경 (예정)
├── docs/                     # 문서 (예정)
│   ├── QUICK_START.md        # 빠른 시작 가이드
│   └── DEPLOYMENT_GUIDE.md   # 상세 배포 가이드
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

#### Cache Subnets (Cache Tier)
- AZ-1: 10.0.31.0/24
- AZ-2: 10.0.32.0/24
- 용도: Redis ElastiCache

### 보안 그룹
- **ALB Security Group**: HTTP/HTTPS 트래픽 허용
- **Web Security Group**: ALB에서의 트래픽과 Bastion에서의 SSH 허용
- **Database Security Group**: Web 서버에서의 데이터베이스 연결 허용
- **Redis Security Group**: Web 서버와 Bastion에서의 Redis 연결 허용
- **Bastion Security Group**: 특정 IP에서의 SSH 허용

### 데이터베이스 구성 (Master-Slave)
- **Primary Database**: 읽기/쓰기 작업 처리
  - MySQL 8.0 엔진
  - 자동 백업 (7일 보존)
  - Enhanced Monitoring 활성화
  - 스토리지 암호화
- **Read Replica**: 읽기 전용 작업 처리
  - Primary에서 실시간 복제
  - 읽기 성능 향상
  - 부하 분산 지원
  - 재해 복구 옵션

### Redis 구성 (Master-Slave)
- **Primary Redis**: 읽기/쓰기 작업 처리
  - Redis 8.0 엔진
  - 자동 백업 (5일 보존)
  - 저장 시 암호화 및 전송 중 암호화
  - AUTH 토큰 인증
- **Read Replica**: 읽기 전용 작업 처리
  - Primary에서 실시간 복제
  - Multi-AZ 배포
  - 자동 장애 조치
  - 캐시 성능 향상

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
- DB Subnet Group 및 Cache Subnet Group 생성
- 4개 계층별 서브넷 구성 (Public, Private, Database, Cache)

### Security Groups 모듈 (`modules/security-groups/`)
- 각 티어별 보안 그룹 생성
- 최소 권한 원칙에 따른 규칙 설정
- ALB, Web, Database, Redis, Bastion 보안 그룹 포함

### Compute 모듈 (`modules/compute/`)
- **Amazon Linux 2023** 기반 EC2 인스턴스
- Bastion Host (Public Subnet)
- Web Servers (Private Subnet)
- SSH 키 페어 관리
- User Data 스크립트를 통한 자동 설정

### Database 모듈 (`modules/database/`)
- **MySQL 8.0** RDS 인스턴스
- Master-Slave 구성 (Primary + Read Replica)
- 자동 백업 및 스냅샷
- Enhanced Monitoring
- 저장 시 암호화
- Multi-AZ 지원

### ElastiCache 모듈 (`modules/elasticache/`)
- **Redis 8.0** ElastiCache 클러스터
- Master-Slave 구성 (Primary + Read Replica)
- 저장 시 및 전송 중 암호화
- AUTH 토큰 인증
- AWS Secrets Manager 통합
- Multi-AZ 자동 장애 조치

## 환경별 설정

각 환경(`dev`, `staging`, `prod`)은 독립적인 설정을 가집니다:

- `main.tf`: 모듈 호출 및 리소스 정의
- `variables.tf`: 변수 정의
- `outputs.tf`: 출력값 정의
- `terraform.tfvars`: 환경별 변수 값

## 현재 구현된 기능

### ✅ 완료된 모듈들
1. **VPC 모듈**: 네트워킹 인프라 (VPC, 서브넷, 라우팅)
2. **Security Groups 모듈**: 계층별 보안 그룹
3. **Compute 모듈**: EC2 인스턴스 (Bastion, Web Servers)
4. **Database 모듈**: Master-Slave RDS 구성 (Primary + Read Replica)
5. **ElastiCache 모듈**: Master-Slave Redis 구성 (Primary + Read Replica)

### 🔄 확장 계획

다음 모듈들을 추가할 예정입니다:

1. **Load Balancer 모듈**: Application Load Balancer
2. **Auto Scaling 모듈**: Auto Scaling Groups
3. **Monitoring 모듈**: CloudWatch, SNS
4. **CI/CD 모듈**: CodePipeline, CodeBuild

## 최근 업데이트 (2025년 8월)

### ✅ **Amazon Linux 2023 마이그레이션**
- Amazon Linux 2 EOL 대비 (2025년 6월 30일)
- 모든 EC2 인스턴스를 Amazon Linux 2023으로 업그레이드
- 패키지 관리자 `yum` → `dnf` 변경
- 향상된 보안 및 성능

### ✅ **Redis 8.0 업그레이드**
- Redis 7.0 → 8.0 업그레이드
- 향상된 메모리 관리 및 성능
- 새로운 보안 기능 및 데이터 타입 지원
- ElastiCache Parameter Group `redis8.x` 사용

### ✅ **보안 강화**
- 모든 데이터베이스 저장 시 암호화
- Redis AUTH 토큰 인증
- AWS Secrets Manager 통합
- 네트워크 계층별 보안 그룹 분리

## 기술 스택

### **운영 체제**
- Amazon Linux 2023 (최신)

### **데이터베이스**
- MySQL 8.0 (RDS)
- Redis 8.0 (ElastiCache)

### **컴퓨팅**
- EC2 인스턴스 (t3.micro)
- Bastion Host + Web Servers

### **네트워킹**
- VPC (10.0.0.0/16)
- Multi-AZ 배포 (ap-northeast-2a, 2c)
- NAT Gateway (고가용성)

### **보안**
- 계층별 보안 그룹
- 저장 시/전송 중 암호화
- SSH 키 기반 인증
