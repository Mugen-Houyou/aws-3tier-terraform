# 빠른 시작 가이드

## 5분 만에 배포하기

### 1. 사전 준비 (1분)
```bash
# AWS 자격 증명 확인
aws sts get-caller-identity

# 서울 리전 설정
export AWS_DEFAULT_REGION=ap-northeast-2
```

### 2. 배포 실행 (3분)
```bash
# 개발 환경으로 이동
cd environments/dev

# 초기화 및 배포
terraform init
terraform apply -auto-approve
```

### 3. 결과 확인 (1분)
```bash
# 생성된 리소스 확인
terraform output

# VPC ID 확인
terraform output vpc_id
```

## 기본 설정값

- **리전**: ap-northeast-2 (서울)
- **VPC CIDR**: 10.0.0.0/16
- **가용 영역**: 2개 (ap-northeast-2a, ap-northeast-2c)
- **서브넷**: 각 AZ당 3개 (Public, Private, Database)
- **NAT Gateway**: 2개 (각 AZ별)

## 커스터마이징

설정을 변경하려면 `environments/dev/terraform.tfvars` 파일을 수정하세요:

```hcl
# 프로젝트 이름 변경
project_name = "my-webapp"

# SSH 접근 IP 제한 (보안 강화)
allowed_ssh_cidrs = ["YOUR_IP/32"]

# 비용 절약을 위해 NAT Gateway 1개만 사용
enable_nat_gateway = false  # 또는 별도 설정으로 1개만 생성
```

## 정리

```bash
# 모든 리소스 삭제
terraform destroy -auto-approve
```

## 다음 단계

기본 네트워크 인프라가 준비되었습니다. 이제 다음을 추가할 수 있습니다:

1. **웹 서버**: EC2 인스턴스 또는 ECS
2. **로드 밸런서**: Application Load Balancer
3. **데이터베이스**: RDS MySQL/PostgreSQL
4. **캐시**: ElastiCache Redis

자세한 내용은 [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)를 참조하세요.
