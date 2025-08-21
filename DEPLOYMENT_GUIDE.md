# 3-Tier Web Application 배포 가이드

이 문서는 AWS에서 3-tier 웹 애플리케이션 인프라를 배포하는 방법을 단계별로 설명합니다.

## 사전 요구사항

### 1. 필수 도구 설치
- **Terraform**: >= 1.0
- **AWS CLI**: >= 2.0
- **Git**: 최신 버전

### 2. AWS 계정 설정
- AWS 계정 및 적절한 권한을 가진 IAM 사용자
- AWS CLI 프로필 구성 완료

### 3. 권한 요구사항
다음 AWS 서비스에 대한 권한이 필요합니다:
- EC2 (VPC, Subnet, Security Group, NAT Gateway, Internet Gateway)
- RDS (DB Subnet Group)
- IAM (역할 및 정책 관리)

## 배포 단계

### 1단계: 저장소 클론 및 설정

```bash
# 저장소 클론 (실제 환경에서는 Git 저장소 URL 사용)
cd /path/to/your/workspace
git clone <repository-url>
cd q-terraform-2
```

### 2단계: AWS 자격 증명 확인

```bash
# AWS 계정 정보 확인
aws sts get-caller-identity

# 서울 리전 설정 확인
aws configure get region
# 또는 환경 변수로 설정
export AWS_DEFAULT_REGION=ap-northeast-2
```

### 3단계: 환경별 배포

#### 개발 환경 배포

```bash
# 개발 환경 디렉토리로 이동
cd environments/dev

# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 변경사항 검토 후 배포 실행
terraform apply
```

#### 스테이징 환경 배포 (향후)

```bash
cd environments/staging
terraform init
terraform plan
terraform apply
```

#### 프로덕션 환경 배포 (향후)

```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

## 환경별 설정 커스터마이징

### terraform.tfvars 파일 수정

각 환경의 `terraform.tfvars` 파일을 수정하여 환경에 맞는 설정을 적용할 수 있습니다:

```hcl
# environments/dev/terraform.tfvars
aws_region   = "ap-northeast-2"
project_name = "3tier-webapp"
environment  = "dev"

# VPC 설정
vpc_cidr = "10.0.0.0/16"

# 서브넷 설정
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]

# NAT Gateway 설정
enable_nat_gateway = true

# 보안 설정
allowed_ssh_cidrs = ["YOUR_IP/32"]  # 실제 IP로 변경 필요
```

### 환경별 차이점

| 설정 항목 | 개발환경 | 스테이징 | 프로덕션 |
|-----------|----------|----------|----------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| NAT Gateway | 1개 (비용 절약) | 2개 | 2개 (고가용성) |
| SSH 접근 | 개발팀 IP만 | 개발팀 IP만 | 매우 제한적 |

## 배포 후 확인사항

### 1. 리소스 생성 확인

```bash
# VPC 생성 확인
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=3tier-webapp"

# 서브넷 생성 확인
aws ec2 describe-subnets --filters "Name=tag:Project,Values=3tier-webapp"

# 보안 그룹 생성 확인
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=3tier-webapp"

# EC2 인스턴스 확인
aws ec2 describe-instances --filters "Name=tag:Project,Values=3tier-webapp"

# RDS 인스턴스 확인
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `webapp-database`)]'
```

### 2. Terraform 출력값 확인

```bash
# 모든 출력값 확인
terraform output

# 특정 출력값 확인
terraform output vpc_id
terraform output public_subnet_ids
terraform output primary_db_endpoint
terraform output replica_db_endpoint
terraform output connection_info
```

### 3. 네트워크 연결성 테스트

```bash
# NAT Gateway 상태 확인
aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=3tier-webapp"

# 라우팅 테이블 확인
aws ec2 describe-route-tables --filters "Name=tag:Project,Values=3tier-webapp"
```

### 4. 데이터베이스 연결 테스트

```bash
# Bastion 호스트를 통한 데이터베이스 연결 테스트
# 1. Bastion 호스트에 SSH 연결
ssh -i ~/.ssh/aws-key ec2-user@<bastion_public_ip>

# 2. Bastion에서 Primary DB 연결 테스트
mysql -h <primary_db_endpoint> -P 3306 -u admin -p webapp

# 3. Bastion에서 Read Replica 연결 테스트
mysql -h <replica_db_endpoint> -P 3306 -u admin -p webapp
```

### 5. 데이터베이스 복제 상태 확인

```bash
# Read Replica 상태 확인
aws rds describe-db-instances \
    --db-instance-identifier webapp-database-replica \
    --query 'DBInstances[0].StatusInfos'

# 복제 지연 시간 확인 (CloudWatch 메트릭)
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ReplicaLag \
    --dimensions Name=DBInstanceIdentifier,Value=webapp-database-replica \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average
```

## 문제 해결

### 일반적인 오류 및 해결방법

#### 1. 권한 부족 오류
```
Error: UnauthorizedOperation
```
**해결방법**: IAM 사용자에게 필요한 권한 추가

#### 2. 리전 설정 오류
```
Error: InvalidRegion
```
**해결방법**: AWS CLI 리전 설정 확인 및 수정

#### 3. CIDR 블록 충돌
```
Error: InvalidVpc.Range
```
**해결방법**: terraform.tfvars에서 CIDR 블록 수정

#### 4. 리소스 한도 초과
```
Error: VpcLimitExceeded
```
**해결방법**: AWS 서비스 한도 확인 및 증가 요청

#### 5. 데이터베이스 관련 오류

##### Read Replica 생성 실패
```
Error: InvalidDBInstanceState: DB Instance is not in a state that allows read replica creation
```
**해결방법**: Primary 데이터베이스가 `available` 상태인지 확인

##### 백업 설정 오류
```
Error: InvalidParameterValue: Backup retention period must be at least 1 to add a read replica
```
**해결방법**: Primary 데이터베이스의 백업 보존 기간을 1일 이상으로 설정

##### 인스턴스 클래스 지원 오류
```
Error: InvalidParameterValue: The specified DB instance class is not supported for this engine version
```
**해결방법**: 해당 리전에서 지원하는 인스턴스 클래스로 변경

##### 서브넷 그룹 오류
```
Error: InvalidDBSubnetGroupName: DB subnet group name must be lowercase
```
**해결방법**: DB 서브넷 그룹 이름을 소문자로 변경

### 디버깅 명령어

```bash
# Terraform 디버그 모드 실행
TF_LOG=DEBUG terraform plan

# 상태 파일 확인
terraform show

# 특정 리소스 상태 확인
terraform state show module.vpc.aws_vpc.main
```

## 정리 및 삭제

### 리소스 삭제

```bash
# 개발 환경 리소스 삭제
cd environments/dev
terraform destroy

# 삭제 전 확인
terraform plan -destroy
```

### 주의사항
- 프로덕션 환경 삭제 시 특별한 주의 필요
- **데이터베이스 삭제 전 필수 확인사항**:
  - 최종 스냅샷 생성 여부 확인
  - 중요 데이터 백업 완료 확인
  - Read Replica는 Primary보다 먼저 삭제됨
- 삭제 후 AWS 콘솔에서 리소스 완전 삭제 확인
- **데이터베이스 자격증명**: AWS Secrets Manager에서 별도 삭제 필요

### 데이터베이스 수동 백업 (삭제 전 권장)

```bash
# 수동 스냅샷 생성
aws rds create-db-snapshot \
    --db-instance-identifier webapp-database-primary \
    --db-snapshot-identifier webapp-database-final-snapshot-$(date +%Y%m%d%H%M%S)

# 스냅샷 생성 상태 확인
aws rds describe-db-snapshots \
    --db-snapshot-identifier webapp-database-final-snapshot-*
```

## 모니터링 및 유지보수

### 1. 비용 모니터링
- AWS Cost Explorer를 통한 비용 추적
- 태그 기반 비용 분석 활용

### 2. 보안 검토
- 보안 그룹 규칙 정기 검토
- SSH 접근 IP 주기적 업데이트

### 3. 백업 및 복구
- Terraform 상태 파일 백업
- 설정 파일 버전 관리

## 다음 단계

현재 배포된 기본 인프라 위에 다음 구성 요소들을 추가할 예정입니다:

1. **Load Balancer 모듈**: Application Load Balancer ⏳
2. **Auto Scaling 모듈**: Auto Scaling Groups ⏳
3. **Cache 모듈**: ElastiCache ⏳
4. **Monitoring 모듈**: CloudWatch, SNS ⏳
5. **CI/CD 모듈**: CodePipeline, CodeBuild ⏳

### 현재 완료된 구성 요소 ✅
- **VPC 모듈**: 네트워킹 인프라 완료
- **Security Groups 모듈**: 보안 그룹 완료
- **Compute 모듈**: EC2 인스턴스 (Bastion, Web Servers) 완료
- **Database 모듈**: Master-Slave RDS 구성 완료

각 모듈 추가 시 별도의 배포 가이드가 제공될 예정입니다.

## 지원 및 문의

- 기술적 문제: [이슈 트래커 링크]
- 문서 개선 제안: [문서 저장소 링크]
- 긴급 지원: [연락처 정보]
