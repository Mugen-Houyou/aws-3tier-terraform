# 최신 버전 업그레이드 지침

## 개요
이 문서는 기존 커밋 `ac3aefe2c8031b2d9e70c9ea648ef4e7861ae7fd`에서 최신 커밋 `52067f5`로 업그레이드하는 방법을 설명합니다.

## 주요 변경사항

### 1. Amazon Linux 2023 마이그레이션
- **변경**: Amazon Linux 2 → Amazon Linux 2023
- **영향**: EC2 인스턴스 AMI 변경, 패키지 관리자 `yum` → `dnf`
- **이유**: Amazon Linux 2 EOL 대비 (2025년 6월 30일)

### 2. Redis 8.0 업그레이드
- **변경**: Redis 7.0 → Redis 8.0
- **영향**: ElastiCache 파라미터 그룹 변경
- **이유**: 향상된 성능 및 보안 기능

### 3. ElastiCache 모듈 추가
- **신규**: Redis ElastiCache Master-Slave 구성
- **기능**: 
  - Primary + Read Replica 구성
  - 저장 시/전송 중 암호화
  - AUTH 토큰 인증
  - AWS Secrets Manager 통합

### 4. ALB 모듈 준비
- **신규**: Application Load Balancer 모듈 디렉토리 추가
- **상태**: 구현 예정

## 업그레이드 절차

### 사전 준비사항

1. **백업 생성**
   ```bash
   # 현재 상태 백업
   cd /root/q-terraform-2/environments/dev
   terraform state pull > terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
   ```

2. **현재 리소스 확인**
   ```bash
   terraform show
   terraform output
   ```

### 단계별 업그레이드

#### 1단계: 코드 업데이트
```bash
cd /root/q-terraform-2
git checkout main
git pull origin main
```

#### 2단계: 데이터베이스 모듈 수정사항 적용
기존에 수정한 비밀번호 설정을 유지하기 위해 다음 변경사항을 적용:

```bash
# modules/database/main.tf 파일에서 비밀번호 설정 수정
# override_special 파라미터 추가 (RDS 호환 특수문자만 사용)
```

#### 3단계: ElastiCache 모듈 활성화
```bash
cd environments/dev
```

`main.tf` 파일에 ElastiCache 모듈 추가:
```hcl
module "elasticache" {
  source = "../../modules/elasticache"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  cache_subnet_ids = module.vpc.cache_subnet_ids
  redis_security_group_id = module.security_groups.redis_security_group_id
  
  # Redis 설정
  node_type = "cache.t3.micro"
  
  common_tags = local.common_tags
}
```

#### 4단계: 보안 그룹 업데이트
Redis용 보안 그룹이 추가되었는지 확인:
```bash
# security-groups 모듈에 Redis 보안 그룹이 포함되어 있는지 확인
```

#### 5단계: VPC 모듈 업데이트
Cache 서브넷이 추가되었는지 확인:
```bash
# vpc 모듈에 cache 서브넷 그룹이 포함되어 있는지 확인
```

#### 6단계: Terraform 계획 및 적용
```bash
cd environments/dev

# 초기화 (새 모듈 다운로드)
terraform init

# 계획 확인
terraform plan

# 적용 (주의: 기존 리소스 영향 확인 후 실행)
terraform apply
```

## 예상 변경사항

### 리소스 교체 (Replacement)
- **EC2 인스턴스**: Amazon Linux 2023으로 교체
- **ElastiCache**: Redis 8.0으로 업그레이드

### 신규 리소스
- **ElastiCache 클러스터**: Redis Primary + Read Replica
- **Cache 서브넷 그룹**
- **Redis 보안 그룹**
- **ElastiCache 관련 Secrets Manager**

### 유지되는 리소스
- **VPC 및 네트워크 구성**
- **RDS 데이터베이스** (변경 없음)
- **보안 그룹** (기존 + Redis 추가)

## 주의사항

### 1. 다운타임 발생
- EC2 인스턴스 교체로 인한 일시적 서비스 중단
- 새 AMI로 인스턴스 재생성 필요

### 2. 데이터 보존
- RDS 데이터베이스는 영향 없음
- EC2 인스턴스 내 데이터는 User Data로 재설정

### 3. 비용 증가
- ElastiCache 추가로 인한 비용 발생
- Redis Primary + Read Replica 구성

### 4. 보안 설정
- Redis AUTH 토큰 자동 생성
- 새로운 Secrets Manager 시크릿 생성

## 롤백 계획

문제 발생 시 이전 커밋으로 롤백:
```bash
cd /root/q-terraform-2
git checkout ac3aefe2c8031b2d9e70c9ea648ef4e7861ae7fd

cd environments/dev
terraform init
terraform plan
terraform apply
```

## 검증 방법

### 1. 인프라 상태 확인
```bash
terraform output
aws ec2 describe-instances --filters "Name=tag:Project,Values=3tier-webapp"
aws rds describe-db-instances --db-instance-identifier webapp-database-primary
aws elasticache describe-cache-clusters --cache-cluster-id webapp-redis-primary
```

### 2. 연결 테스트
```bash
# Bastion 접속 테스트
ssh -i ~/.ssh/aws-key ec2-user@<BASTION_PUBLIC_IP>

# 데이터베이스 연결 테스트
mysql -h <DB_ENDPOINT> -u admin -p

# Redis 연결 테스트 (Bastion에서)
redis-cli -h <REDIS_ENDPOINT> -a <AUTH_TOKEN>
```

## 문의사항
업그레이드 과정에서 문제가 발생하면 다음을 확인:
1. Terraform 상태 파일 백업 존재 여부
2. AWS 리소스 상태
3. 로그 파일 및 에러 메시지

---
**작성일**: 2025-08-22  
**대상 환경**: dev  
**Terraform 버전**: 1.5+  
**AWS Provider 버전**: 5.100+
