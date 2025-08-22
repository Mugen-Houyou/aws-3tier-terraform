# 최신 버전 적용 지침

## 현재 상황
- **기존 환경**: 커밋 `ac3aefe` (VPC + RDS + EC2 + 수정된 DB 비밀번호 설정)
- **최신 버전**: 커밋 `52067f5` (+ ElastiCache + Amazon Linux 2023 + Redis 8.0)
- **현재 배포된 리소스**: VPC, RDS Master-Slave, EC2 인스턴스들

## 주요 추가 기능
1. **ElastiCache Redis 8.0** (Master-Slave 구성)
2. **Amazon Linux 2023** (기존 EC2 교체)
3. **Cache 서브넷** 추가
4. **Redis 보안 그룹** 추가

## 단계별 적용 방법

### 1단계: 현재 상태 백업 및 확인
```bash
cd /root/q-terraform-2/environments/dev

# 상태 파일 백업
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# 현재 리소스 확인
terraform show | grep "resource\|id ="
terraform output > current_outputs.txt
```

### 2단계: 필수 변수 추가
`terraform.tfvars` 파일에 다음 변수들을 추가:

```hcl
# 기존 변수들 유지하고 다음 추가:

# Cache 서브넷 (ElastiCache용)
cache_subnet_cidrs = ["10.0.31.0/24", "10.0.32.0/24"]

# Redis ElastiCache 설정
redis_version                     = "8.0"
redis_node_type                  = "cache.t3.micro"
redis_num_cache_nodes            = 1
redis_snapshot_retention_limit   = 5
redis_at_rest_encryption_enabled = true
redis_transit_encryption_enabled = true
redis_auth_token_enabled         = true
redis_multi_az_enabled           = true
redis_automatic_failover_enabled = true
```

### 3단계: 데이터베이스 모듈 수정사항 적용
기존에 수정한 비밀번호 설정을 최신 코드에 적용:

```bash
# modules/database/main.tf 파일에서 random_password 리소스 수정
```

다음 내용으로 수정:
```hcl
resource "random_password" "db_password" {
  length  = 16
  special = true
  # RDS에서 허용하지 않는 특수문자 제외
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
```

그리고 시크릿 이름을 기존과 동일하게 유지:
```hcl
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-db-credentials-v2"  # 기존 이름 유지
  description = "Database credentials for ${var.project_name}"
  # ... 나머지 설정
}
```

### 4단계: Terraform 초기화 및 계획
```bash
cd /root/q-terraform-2/environments/dev

# 새 모듈 초기화
terraform init

# 변경사항 확인 (주의깊게 검토)
terraform plan
```

### 5단계: 예상 변경사항 검토

**추가될 리소스:**
- ElastiCache 서브넷 그룹
- ElastiCache Redis 클러스터 (Primary + Read Replica)
- Redis 보안 그룹
- Redis AUTH 토큰 (Secrets Manager)
- Cache 서브넷 2개

**교체될 리소스:**
- EC2 인스턴스들 (Amazon Linux 2023으로)

**유지되는 리소스:**
- VPC 및 기존 서브넷들
- RDS 데이터베이스 (Primary + Read Replica)
- 기존 보안 그룹들
- NAT Gateway, Internet Gateway

### 6단계: 단계적 적용 (권장)

#### 6-1. 네트워크 리소스만 먼저 적용
```bash
# 특정 리소스만 적용
terraform apply -target=module.vpc.aws_subnet.cache
terraform apply -target=module.vpc.aws_elasticache_subnet_group.main
```

#### 6-2. 보안 그룹 적용
```bash
terraform apply -target=module.security_groups.aws_security_group.redis
```

#### 6-3. ElastiCache 적용
```bash
terraform apply -target=module.elasticache
```

#### 6-4. EC2 인스턴스 교체 (다운타임 발생)
```bash
terraform apply -target=module.compute
```

### 7단계: 전체 적용 (또는 한번에 적용하는 경우)
```bash
# 모든 변경사항 적용
terraform apply
```

## 적용 후 검증

### 1. 리소스 상태 확인
```bash
# 새로운 출력값 확인
terraform output

# ElastiCache 클러스터 확인
aws elasticache describe-cache-clusters --region ap-northeast-2

# EC2 인스턴스 확인 (새 AMI)
aws ec2 describe-instances --filters "Name=tag:Project,Values=3tier-webapp" --region ap-northeast-2
```

### 2. 연결 테스트
```bash
# Bastion 접속 (새 Public IP 확인)
BASTION_IP=$(terraform output -raw bastion_public_ip)
ssh -i ~/.ssh/aws-key ec2-user@$BASTION_IP

# Redis 연결 테스트 (Bastion에서)
REDIS_ENDPOINT=$(terraform output -raw redis_primary_endpoint)
redis-cli -h $REDIS_ENDPOINT -a $(aws secretsmanager get-secret-value --secret-id $(terraform output -raw redis_auth_token_secret_name) --query SecretString --output text)
```

### 3. 데이터베이스 연결 확인
```bash
# 기존 RDS 연결 확인
DB_ENDPOINT=$(terraform output -raw primary_db_endpoint)
mysql -h $DB_ENDPOINT -u admin -p webapp
```

## 주의사항

### 다운타임
- **EC2 인스턴스 교체**: 약 5-10분 다운타임
- **ElastiCache 생성**: 약 10-15분 소요
- **RDS는 영향 없음**

### 비용 증가
- ElastiCache 추가로 월 약 $15-20 증가 예상 (t3.micro 기준)

### 롤백 방법
문제 발생 시:
```bash
# 이전 커밋으로 롤백
git checkout ac3aefe2c8031b2d9e70c9ea648ef4e7861ae7fd

# 이전 상태로 복원
terraform apply
```

## 예상 최종 아키텍처

```
Internet Gateway
       |
   Public Subnets (2 AZs)
       |
   [Bastion Host] [NAT Gateways]
       |
   Private Subnets (2 AZs)
       |
   [Web Server 1] [Web Server 2]
       |
   Database Subnets (2 AZs)    Cache Subnets (2 AZs)
       |                              |
   [RDS Primary] [RDS Replica]    [Redis Primary] [Redis Replica]
```

## 완료 후 새로운 기능
1. **Redis 캐싱**: 애플리케이션 성능 향상
2. **Amazon Linux 2023**: 최신 보안 패치 및 성능
3. **Redis 8.0**: 향상된 메모리 관리 및 새 기능
4. **완전한 3-tier 아키텍처**: Web + App + Cache + DB

---
**실행 전 필수 확인사항:**
- [ ] 백업 완료
- [ ] terraform.tfvars 업데이트
- [ ] 다운타임 계획 수립
- [ ] 롤백 계획 준비
