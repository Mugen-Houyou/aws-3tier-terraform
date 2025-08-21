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
```

### 2. Terraform 출력값 확인

```bash
# 모든 출력값 확인
terraform output

# 특정 출력값 확인
terraform output vpc_id
terraform output public_subnet_ids
```

### 3. 네트워크 연결성 테스트

```bash
# NAT Gateway 상태 확인
aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=3tier-webapp"

# 라우팅 테이블 확인
aws ec2 describe-route-tables --filters "Name=tag:Project,Values=3tier-webapp"
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
- 데이터베이스가 있는 경우 백업 확인 후 삭제
- 삭제 후 AWS 콘솔에서 리소스 완전 삭제 확인

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

1. **Compute 모듈**: EC2 인스턴스, Auto Scaling Groups
2. **Load Balancer 모듈**: Application Load Balancer
3. **Database 모듈**: RDS, ElastiCache
4. **Monitoring 모듈**: CloudWatch, SNS

각 모듈 추가 시 별도의 배포 가이드가 제공될 예정입니다.

## 지원 및 문의

- 기술적 문제: [이슈 트래커 링크]
- 문서 개선 제안: [문서 저장소 링크]
- 긴급 지원: [연락처 정보]
