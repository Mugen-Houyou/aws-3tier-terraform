# 데이터베이스 운영 가이드

이 문서는 Master-Slave RDS 구성의 운영 및 관리 방법을 설명합니다.

## 목차
- [데이터베이스 아키텍처](#데이터베이스-아키텍처)
- [일상 운영](#일상-운영)
- [모니터링](#모니터링)
- [백업 및 복원](#백업-및-복원)
- [성능 최적화](#성능-최적화)
- [재해 복구](#재해-복구)
- [보안 관리](#보안-관리)
- [문제 해결](#문제-해결)

## 데이터베이스 아키텍처

### 현재 구성
```
┌─────────────────────┐    ┌─────────────────────┐
│   Primary DB        │───▶│   Read Replica      │
│   (Master)          │    │   (Slave)           │
│                     │    │                     │
│ - 읽기/쓰기 처리    │    │ - 읽기 전용         │
│ - 백업 수행         │    │ - 부하 분산         │
│ - 자동 장애조치     │    │ - 재해 복구 대비    │
└─────────────────────┘    └─────────────────────┘
```

### 연결 정보
- **Primary**: `webapp-database-primary.xxxxx.ap-northeast-2.rds.amazonaws.com:3306`
- **Read Replica**: `webapp-database-replica.xxxxx.ap-northeast-2.rds.amazonaws.com:3306`

## 일상 운영

### 1. 데이터베이스 상태 확인

```bash
# 모든 RDS 인스턴스 상태 확인
aws rds describe-db-instances \
    --query 'DBInstances[?contains(DBInstanceIdentifier, `webapp-database`)].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass}'

# 특정 인스턴스 상세 정보
aws rds describe-db-instances \
    --db-instance-identifier webapp-database-primary
```

### 2. 연결 테스트

```bash
# Primary 데이터베이스 연결 테스트
mysql -h webapp-database-primary.xxxxx.ap-northeast-2.rds.amazonaws.com \
      -P 3306 -u admin -p webapp \
      -e "SELECT 'Primary DB Connected' as status;"

# Read Replica 연결 테스트
mysql -h webapp-database-replica.xxxxx.ap-northeast-2.rds.amazonaws.com \
      -P 3306 -u admin -p webapp \
      -e "SELECT 'Replica DB Connected' as status;"
```

### 3. 복제 상태 확인

```bash
# Read Replica 복제 지연 확인
aws rds describe-db-instances \
    --db-instance-identifier webapp-database-replica \
    --query 'DBInstances[0].StatusInfos'

# CloudWatch에서 복제 지연 메트릭 확인
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ReplicaLag \
    --dimensions Name=DBInstanceIdentifier,Value=webapp-database-replica \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average,Maximum
```

## 모니터링

### 1. 주요 메트릭

#### Primary Database 메트릭
- `DatabaseConnections`: 현재 연결 수
- `CPUUtilization`: CPU 사용률
- `FreeableMemory`: 사용 가능한 메모리
- `ReadLatency` / `WriteLatency`: 읽기/쓰기 지연시간
- `ReadIOPS` / `WriteIOPS`: 초당 I/O 작업 수

#### Read Replica 메트릭
- `ReplicaLag`: 복제 지연시간 (중요!)
- `DatabaseConnections`: 연결 수
- `CPUUtilization`: CPU 사용률
- `ReadLatency`: 읽기 지연시간

### 2. CloudWatch 대시보드 생성

```bash
# 대시보드 생성 (JSON 파일 필요)
aws cloudwatch put-dashboard \
    --dashboard-name "RDS-Master-Slave-Dashboard" \
    --dashboard-body file://dashboard-config.json
```

### 3. 알람 설정

```bash
# 복제 지연 알람 설정
aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-Replica-Lag-High" \
    --alarm-description "Read replica lag is too high" \
    --metric-name ReplicaLag \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 300 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=webapp-database-replica \
    --evaluation-periods 2

# CPU 사용률 알람 설정
aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-Primary-CPU-High" \
    --alarm-description "Primary DB CPU usage is high" \
    --metric-name CPUUtilization \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=webapp-database-primary \
    --evaluation-periods 2
```

## 백업 및 복원

### 1. 자동 백업 설정 확인

```bash
# 백업 설정 확인
aws rds describe-db-instances \
    --db-instance-identifier webapp-database-primary \
    --query 'DBInstances[0].{BackupRetentionPeriod:BackupRetentionPeriod,BackupWindow:PreferredBackupWindow,MaintenanceWindow:PreferredMaintenanceWindow}'
```

### 2. 수동 스냅샷 생성

```bash
# 수동 스냅샷 생성
aws rds create-db-snapshot \
    --db-instance-identifier webapp-database-primary \
    --db-snapshot-identifier webapp-manual-snapshot-$(date +%Y%m%d%H%M%S)

# 스냅샷 생성 진행 상황 확인
aws rds describe-db-snapshots \
    --db-snapshot-identifier webapp-manual-snapshot-* \
    --query 'DBSnapshots[0].{Status:Status,Progress:PercentProgress}'
```

### 3. 특정 시점 복원 (PITR)

```bash
# 특정 시점으로 새 인스턴스 생성
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier webapp-database-primary \
    --target-db-instance-identifier webapp-database-restored \
    --restore-time 2024-01-01T12:00:00Z \
    --db-subnet-group-name webapp-db-subnet-group \
    --vpc-security-group-ids sg-xxxxxxxxx
```

### 4. 스냅샷에서 복원

```bash
# 스냅샷에서 새 인스턴스 생성
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier webapp-database-from-snapshot \
    --db-snapshot-identifier webapp-manual-snapshot-20240101120000 \
    --db-instance-class db.t3.micro \
    --db-subnet-group-name webapp-db-subnet-group \
    --vpc-security-group-ids sg-xxxxxxxxx
```

## 성능 최적화

### 1. 읽기/쓰기 분리 구현

#### PHP 예제
```php
<?php
class DatabaseManager {
    private $primaryPdo;
    private $replicaPdo;
    
    public function __construct() {
        $this->primaryPdo = new PDO(
            "mysql:host=webapp-database-primary.xxxxx.ap-northeast-2.rds.amazonaws.com;dbname=webapp",
            "admin", "password"
        );
        
        $this->replicaPdo = new PDO(
            "mysql:host=webapp-database-replica.xxxxx.ap-northeast-2.rds.amazonaws.com;dbname=webapp",
            "admin", "password"
        );
    }
    
    // 쓰기 작업은 Primary로
    public function write($query, $params = []) {
        $stmt = $this->primaryPdo->prepare($query);
        return $stmt->execute($params);
    }
    
    // 읽기 작업은 Replica로
    public function read($query, $params = []) {
        $stmt = $this->replicaPdo->prepare($query);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
```

### 2. 연결 풀링 설정

#### Python 예제 (SQLAlchemy)
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Primary 연결 (쓰기용)
primary_engine = create_engine(
    'mysql+pymysql://admin:password@webapp-database-primary.xxxxx.ap-northeast-2.rds.amazonaws.com/webapp',
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True
)

# Replica 연결 (읽기용)
replica_engine = create_engine(
    'mysql+pymysql://admin:password@webapp-database-replica.xxxxx.ap-northeast-2.rds.amazonaws.com/webapp',
    poolclass=QueuePool,
    pool_size=15,
    max_overflow=25,
    pool_pre_ping=True
)
```

### 3. 쿼리 최적화

```sql
-- 인덱스 사용 현황 확인
SHOW INDEX FROM your_table;

-- 느린 쿼리 확인
SELECT * FROM mysql.slow_log 
WHERE start_time > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY query_time DESC;

-- 실행 계획 확인
EXPLAIN SELECT * FROM your_table WHERE condition;
```

## 재해 복구

### 1. Read Replica 승격 (Failover)

```bash
# Read Replica를 독립적인 Primary로 승격
aws rds promote-read-replica \
    --db-instance-identifier webapp-database-replica

# 승격 진행 상황 확인
aws rds describe-db-instances \
    --db-instance-identifier webapp-database-replica \
    --query 'DBInstances[0].DBInstanceStatus'
```

### 2. 새로운 Read Replica 생성

```bash
# 승격된 인스턴스에 새 Read Replica 생성
aws rds create-db-instance-read-replica \
    --db-instance-identifier webapp-database-replica-new \
    --source-db-instance-identifier webapp-database-replica \
    --db-instance-class db.t3.micro \
    --publicly-accessible false
```

### 3. 애플리케이션 연결 문자열 업데이트

승격 후 애플리케이션의 데이터베이스 연결 설정을 업데이트해야 합니다:

```bash
# 새로운 엔드포인트 확인
aws rds describe-db-instances \
    --db-instance-identifier webapp-database-replica \
    --query 'DBInstances[0].Endpoint.Address'
```

## 보안 관리

### 1. 자격증명 로테이션

```bash
# Secrets Manager에서 자동 로테이션 설정
aws secretsmanager update-secret \
    --secret-id 3tier-webapp-db-credentials \
    --description "Database credentials with auto-rotation" \
    --rotation-lambda-arn arn:aws:lambda:ap-northeast-2:account:function:rotation-function \
    --rotation-rules AutomaticallyAfterDays=30
```

### 2. 보안 그룹 검토

```bash
# 데이터베이스 보안 그룹 규칙 확인
aws ec2 describe-security-groups \
    --group-ids sg-xxxxxxxxx \
    --query 'SecurityGroups[0].IpPermissions'
```

### 3. SSL/TLS 연결 강제

```sql
-- SSL 연결 상태 확인
SHOW STATUS LIKE 'Ssl_cipher';

-- 사용자별 SSL 요구 설정
ALTER USER 'admin'@'%' REQUIRE SSL;
```

## 문제 해결

### 1. 복제 지연 문제

#### 원인 분석
```bash
# 복제 지연 메트릭 확인
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ReplicaLag \
    --dimensions Name=DBInstanceIdentifier,Value=webapp-database-replica \
    --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Average,Maximum
```

#### 해결 방법
1. **Read Replica 인스턴스 크기 증가**
2. **네트워크 대역폭 확인**
3. **Primary의 쓰기 부하 분산**

### 2. 연결 문제

#### 연결 수 확인
```sql
-- 현재 연결 수 확인
SHOW STATUS LIKE 'Threads_connected';

-- 최대 연결 수 확인
SHOW VARIABLES LIKE 'max_connections';

-- 연결 중인 프로세스 확인
SHOW PROCESSLIST;
```

#### 해결 방법
1. **연결 풀링 구현**
2. **불필요한 연결 정리**
3. **max_connections 파라미터 조정**

### 3. 성능 문제

#### 느린 쿼리 분석
```sql
-- 느린 쿼리 로그 활성화 확인
SHOW VARIABLES LIKE 'slow_query_log';

-- 느린 쿼리 임계값 확인
SHOW VARIABLES LIKE 'long_query_time';

-- 최근 느린 쿼리 확인
SELECT * FROM mysql.slow_log 
WHERE start_time > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY query_time DESC
LIMIT 10;
```

### 4. 디스크 공간 부족

```bash
# 스토리지 사용량 확인
aws rds describe-db-instances \
    --db-instance-identifier webapp-database-primary \
    --query 'DBInstances[0].{AllocatedStorage:AllocatedStorage,StorageType:StorageType,MaxAllocatedStorage:MaxAllocatedStorage}'

# 자동 스토리지 확장 활성화
aws rds modify-db-instance \
    --db-instance-identifier webapp-database-primary \
    --max-allocated-storage 1000 \
    --apply-immediately
```

## 정기 점검 체크리스트

### 일일 점검
- [ ] 데이터베이스 상태 확인
- [ ] 복제 지연 시간 확인
- [ ] 연결 수 모니터링
- [ ] 에러 로그 검토

### 주간 점검
- [ ] 성능 메트릭 리뷰
- [ ] 백업 상태 확인
- [ ] 보안 그룹 규칙 검토
- [ ] 느린 쿼리 분석

### 월간 점검
- [ ] 용량 계획 검토
- [ ] 보안 패치 적용
- [ ] 재해 복구 테스트
- [ ] 비용 최적화 검토

## 연락처 및 지원

- **긴급 상황**: [24/7 지원 연락처]
- **기술 문의**: [기술팀 이메일]
- **문서 업데이트**: [문서 관리자]

---

이 가이드는 지속적으로 업데이트됩니다. 최신 버전은 GitHub 저장소에서 확인하세요.
