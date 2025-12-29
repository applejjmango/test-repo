# 🌏 Terraform Multi-Region VPC Peering & SSM Lab

이 프로젝트는 **Terraform**을 사용하여 AWS의 **Virginia(us-east-1)** 리전과 **Seoul(ap-northeast-2)** 리전에 각각 격리된 네트워크(VPC)를 구축하고, **VPC Peering**을 통해 두 리전 간의 사설 통신(Private Communication)을 구현한 IaC(Infrastructure as Code) 프로젝트입니다.

보안 모범 사례(Best Practice)를 준수하여 **SSH 포트(22)를 개방하거나 Bastion Host를 두지 않고**, **AWS Systems Manager (SSM) Session Manager**를 통해 안전하게 Private EC2에 접속하도록 설계되었습니다.

## 🏗️ 아키텍처 (Architecture)

| 구분            | Primary Region (Virginia)          | Secondary Region (Seoul)           |
| --------------- | ---------------------------------- | ---------------------------------- |
| **Region Code** | `us-east-1`                        | `ap-northeast-2`                   |
| **VPC CIDR**    | `10.0.0.0/16`                      | `10.1.0.0/16`                      |
| **Subnets**     | Public(2), Private(2)              | Public(2), Private(2)              |
| **Gateway**     | IGW, NAT Gateway (AZ별)            | IGW, NAT Gateway (AZ별)            |
| **Compute**     | Amazon Linux 2023 (Private Subnet) | Amazon Linux 2023 (Private Subnet) |
| **Access**      | SSM Session Manager (No SSH)       | SSM Session Manager (No SSH)       |

- **VPC Peering:** 두 VPC 간의 트래픽 라우팅 구성 완료.
- **IAM Role:** EC2가 SSM 서비스와 통신할 수 있도록 `AmazonSSMManagedInstanceCore` 권한 부여.

---

## 🛠️ 사전 요구 사항 (Prerequisites)

이 프로젝트를 실행하기 위해 로컬 환경에 다음 도구들이 설치되어 있어야 합니다.

1. **Terraform:** (v1.6 이상 권장함)
2. **AWS CLI:** 인증 정보(`~/.aws/credentials`)가 설정되어 있어야 합니다.
3. **Session Manager Plugin:** (★ 필수) 로컬 터미널에서 EC2로 접속하기 위해 필요합니다.

- _Mac:_ `brew install --cask session-manager-plugin`
- _Windows/Linux:_ [AWS 공식 설치 가이드 참고](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

---

## 🚀 배포 방법 (Deployment)

1. **프로젝트 클론 및 초기화**
```bash
git clone <YOUR_REPO_URL>
cd <PROJECT_DIR>
terraform init
```

2. **계획 확인 (Plan)**
   생성될 리소스(VPC, Subnet, EC2, Peering 등)를 미리 확인합니다.
```bash
terraform plan
```

3. **인프라 적용 (Apply)**
   실제 AWS 리소스를 생성합니다.
```bash
terraform apply -auto-approve
```

---

## 💻 접속 및 테스트 방법 (Verification)

SSH 키 파일(.pem) 없이 **AWS SSM**을 통해 로컬 터미널에서 Private EC2에 직접 접속합니다.

### 1. EC2 인스턴스 ID 확인

AWS 콘솔 또는 아래 명령어로 생성된 인스턴스 ID를 확인합니다.
```bash
# Virginia 인스턴스 ID 확인
aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=Primary-Test-EC2" --query "Reservations[].Instances[].InstanceId" --output text

# Seoul 인스턴스 ID 확인
aws ec2 describe-instances --region ap-northeast-2 --filters "Name=tag:Name,Values=Seoul-Test-EC2" --query "Reservations[].Instances[].InstanceId" --output text
```

### 2. 로컬에서 접속 (SSM)

위에서 확인한 인스턴스 ID(`i-xxxxxx`)를 사용하여 접속합니다.
```bash
# Virginia EC2 접속
aws ssm start-session --target <VIRGINIA_INSTANCE_ID> --region us-east-1

# Seoul EC2 접속
aws ssm start-session --target <SEOUL_INSTANCE_ID> --region ap-northeast-2
```

### 3. Cross-Region Ping 테스트

접속한 터미널(예: Virginia EC2)에서 상대방 리전(Seoul)의 **Private IP**로 Ping을 전송하여 Peering 연결을 확인합니다.

> **주의:** DNS 호스트네임이 아닌 **IP 주소**를 사용해야 합니다.
```bash
# Virginia EC2 내부에서 실행:
sh-5.2$ ping 10.1.x.x  # 서울 EC2의 Private IP 입력
```

**결과 예시:**
```text
PING 10.1.10.123 (10.1.10.123) 56(84) bytes of data.
64 bytes from 10.1.10.123: icmp_seq=1 ttl=253 time=182 ms
64 bytes from 10.1.10.123: icmp_seq=2 ttl=253 time=182 ms
...
```

_응답이 오면 VPC Peering과 라우팅 테이블이 정상적으로 설정된 것입니다._

---

## 📂 프로젝트 구조 (File Structure)
```text
.
├── main.tf        # VPC, Subnet, NAT Gateway, Route Table, Peering 리소스 정의
├── ec2.tf         # EC2 인스턴스 생성 (Private Subnet 배치)
├── sg.tf          # Security Group 정의 (ICMP 허용, SSM용 Outbound 허용)
├── iam.tf         # SSM 접속을 위한 IAM Role 및 Instance Profile 정의
├── data.tf        # 최신 Amazon Linux 2023 AMI 및 AZ 조회
├── variables.tf   # 리전별 CIDR, AZ 등 환경 변수 정의
├── providers.tf   # AWS Provider 설정 (Alias 사용: Virginia/Seoul)
└── README.md      # 프로젝트 문서
```

---

## 🧹 리소스 삭제 (Clean Up)

과금을 방지하기 위해 테스트가 끝나면 리소스를 삭제해 주세요.
```bash
terraform destroy -auto-approve
```

---

### 📝 주요 트러블슈팅 내역 (Lessons Learned)

- **Race Condition:** VPC Peering이 `Active` 상태가 되기 전에 라우팅 테이블이 생성되어 패킷이 유실되는(Blackhole) 현상 발생. -> `aws_route` 리소스에 `depends_on = [aws_vpc_peering_connection_accepter.peer]`를 추가하여 해결.
- **TargetNotConnected:** SSM Agent 통신 불가 문제. -> Private Subnet의 NAT Gateway 라우팅 설정 및 IAM Role(`AmazonSSMManagedInstanceCore`) 연결 확인으로 해결.
