# Database 모듈

이 모듈은 MySQL RDS 인스턴스를 Master-Slave 구성으로 생성합니다.

## 아키텍처

```
┌─────────────────┐    ┌─────────────────┐
│  Primary DB     │───▶│  Read Replica   │
│  (Master)       │    │  (Slave)        │
│                 │    │                 │
│ - 읽기/쓰기     │    │ - 읽기 전용     │
│ - 백업 수행     │    │ - 부하 분산     │
│ - 모니터링      │    │ - 재해 복구     │
└─────────────────┘    └─────────────────┘
```

## 주요 기능

### Primary Database (Master)
- **역할**: 모든 쓰기 작업과 읽기 작업 처리
- **백업**: 자동 백업 (기본 7일 보존)
- **모니터링**: Enhanced Monitoring 활성화
- **보안**: 스토리지 암호화, VPC 내 배치
- **가용성**: Multi-AZ 배포 옵션 지원

### Read Replica (Slave)
- **역할**: 읽기 전용 작업 처리
- **복제**: Primary에서 비동기 복제
- **성능**: 읽기 트래픽 분산으로 성능 향상
- **재해복구**: Primary 장애 시 승격 가능
- **확장성**: 여러 Read Replica 생성 가능

## 사용법

### 기본 사용법

```hcl
module "database" {
  source = "./modules/database"

  project_name                = "my-project"
  db_subnet_group_name       = "my-db-subnet-group"
  database_security_group_id = "sg-xxxxxxxxx"
  
  # Read Replica 활성화
  enable_read_replica = true
  
  # 기본 설정
  db_name     = "webapp"
  db_username = "admin"
  
  common_tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### 고급 설정

```hcl
module "database" {
  source = "./modules/database"

  project_name                = "my-project"
  db_subnet_group_name       = "my-db-subnet-group"
  database_security_group_id = "sg-xxxxxxxxx"
  
  # 데이터베이스 설정
  db_name                = "webapp"
  db_username           = "admin"
  db_engine_version     = "8.0"
  db_instance_class     = "db.t3.small"
  db_allocated_storage  = 50
  
  # Read Replica 설정
  enable_read_replica        = true
  db_replica_instance_class = "db.t3.micro"
  
  # 백업 및 유지보수
  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # 고가용성
  multi_az = true
  
  # 보안
  deletion_protection = true
  
  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## 입력 변수

| 변수명 | 타입 | 기본값 | 설명 |
|--------|------|--------|------|
| `project_name` | string | - | 프로젝트 이름 |
| `db_subnet_group_name` | string | - | DB 서브넷 그룹 이름 |
| `database_security_group_id` | string | - | 데이터베이스 보안 그룹 ID |
| `db_name` | string | "webapp" | 데이터베이스 이름 |
| `db_username` | string | "admin" | 데이터베이스 사용자명 |
| `db_engine_version` | string | "8.0" | MySQL 엔진 버전 |
| `db_instance_class` | string | "db.t3.micro" | Primary 인스턴스 클래스 |
| `db_replica_instance_class` | string | "db.t3.micro" | Replica 인스턴스 클래스 |
| `db_allocated_storage` | number | 20 | 초기 할당 스토리지 (GB) |
| `db_max_allocated_storage` | number | 100 | 최대 할당 스토리지 (GB) |
| `backup_retention_period` | number | 7 | 백업 보존 기간 (일) |
| `backup_window` | string | "03:00-04:00" | 백업 시간 |
| `maintenance_window` | string | "sun:04:00-sun:05:00" | 유지보수 시간 |
| `multi_az` | bool | false | Multi-AZ 배포 활성화 |
| `enable_read_replica` | bool | true | Read Replica 생성 여부 |
| `deletion_protection` | bool | false | 삭제 보호 활성화 |
| `common_tags` | map(string) | {} | 공통 태그 |

## 출력값

| 출력명 | 설명 |
|--------|------|
| `primary_db_instance_id` | Primary 데이터베이스 인스턴스 ID |
| `primary_db_endpoint` | Primary 데이터베이스 엔드포인트 |
| `replica_db_instance_id` | Read Replica 인스턴스 ID |
| `replica_db_endpoint` | Read Replica 엔드포인트 |
| `db_port` | 데이터베이스 포트 |
| `db_name` | 데이터베이스 이름 |
| `secret_arn` | 데이터베이스 자격증명 시크릿 ARN |
| `secret_name` | 데이터베이스 자격증명 시크릿 이름 |

## 연결 방법

### Primary Database (읽기/쓰기)
```bash
# 직접 연결
mysql -h <primary_endpoint> -P 3306 -u admin -p webapp

# Bastion을 통한 연결
ssh -i ~/.ssh/aws-key -L 3306:<primary_endpoint>:3306 ec2-user@<bastion_ip>
mysql -h localhost -P 3306 -u admin -p webapp
```

### Read Replica (읽기 전용)
```bash
# 직접 연결
mysql -h <replica_endpoint> -P 3306 -u admin -p webapp

# Bastion을 통한 연결
ssh -i ~/.ssh/aws-key -L 3307:<replica_endpoint>:3306 ec2-user@<bastion_ip>
mysql -h localhost -P 3307 -u admin -p webapp
```

## 애플리케이션 연동

### 읽기/쓰기 분리 예제 (PHP)

```php
<?php
// 데이터베이스 설정
$primary_host = 'webapp-database-primary.xxxxx.ap-northeast-2.rds.amazonaws.com';
$replica_host = 'webapp-database-replica.xxxxx.ap-northeast-2.rds.amazonaws.com';
$username = 'admin';
$password = 'your_password';
$database = 'webapp';

// Primary 연결 (쓰기용)
$primary_pdo = new PDO("mysql:host=$primary_host;dbname=$database", $username, $password);

// Replica 연결 (읽기용)
$replica_pdo = new PDO("mysql:host=$replica_host;dbname=$database", $username, $password);

// 쓰기 작업
function insertUser($name, $email) {
    global $primary_pdo;
    $stmt = $primary_pdo->prepare("INSERT INTO users (name, email) VALUES (?, ?)");
    return $stmt->execute([$name, $email]);
}

// 읽기 작업
function getUsers() {
    global $replica_pdo;
    $stmt = $replica_pdo->query("SELECT * FROM users");
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}
?>
```

## 모니터링

### CloudWatch 메트릭
- **Primary Database**:
  - `DatabaseConnections`: 연결 수
  - `CPUUtilization`: CPU 사용률
  - `ReadLatency`, `WriteLatency`: 지연시간
  - `ReplicaLag`: 복제 지연 (Replica가 있는 경우)

- **Read Replica**:
  - `DatabaseConnections`: 연결 수
  - `CPUUtilization`: CPU 사용률
  - `ReadLatency`: 읽기 지연시간
  - `ReplicaLag`: Primary와의 복제 지연

### 로그 모니터링
활성화된 로그:
- `error`: 에러 로그
- `general`: 일반 쿼리 로그
- `slowquery`: 느린 쿼리 로그

## 보안 고려사항

1. **네트워크 보안**
   - Private 서브넷에 배치
   - 보안 그룹으로 접근 제어
   - VPC 내부에서만 접근 가능

2. **데이터 암호화**
   - 저장 시 암호화 (KMS)
   - 전송 중 암호화 (SSL/TLS)

3. **접근 제어**
   - IAM 데이터베이스 인증 지원
   - 최소 권한 원칙 적용

4. **자격증명 관리**
   - AWS Secrets Manager 사용
   - 자동 비밀번호 로테이션 지원

## 재해 복구

### Read Replica 승격
Primary 장애 시 Read Replica를 새로운 Primary로 승격:

```bash
aws rds promote-read-replica \
    --db-instance-identifier webapp-database-replica \
    --region ap-northeast-2
```

### 백업에서 복원
특정 시점으로 복원:

```bash
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier webapp-database-primary \
    --target-db-instance-identifier webapp-database-restored \
    --restore-time 2024-01-01T12:00:00Z \
    --region ap-northeast-2
```

## 성능 최적화

1. **읽기 성능 향상**
   - Read Replica 활용
   - 연결 풀링 사용
   - 쿼리 최적화

2. **쓰기 성능 향상**
   - 인덱스 최적화
   - 배치 처리 활용
   - 트랜잭션 최적화

3. **모니터링 및 튜닝**
   - Performance Insights 활용
   - 느린 쿼리 로그 분석
   - 리소스 사용률 모니터링

## 비용 최적화

1. **인스턴스 크기 조정**
   - 사용량에 따른 적절한 인스턴스 타입 선택
   - Reserved Instance 활용

2. **스토리지 최적화**
   - 자동 스토리지 확장 활용
   - 불필요한 백업 정리

3. **Read Replica 관리**
   - 필요에 따른 Replica 수 조정
   - 사용하지 않는 Replica 제거
