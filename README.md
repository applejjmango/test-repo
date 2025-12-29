좋아 👍
**Senior Architect 톤 README + 테스트 방식(여러 방식 포함) + 전체 Markdown 완성본** 으로 다시 정리했다.
단순 ping만이 아니라, **엔터프라이즈 환경에서 실제로 검증할 때 사용하는 방식도 포함**했어.

---

# 🌏 Terraform Multi-Region VPC Peering & Zero-SSH Architecture

## 🚧 Context & Motivation

멀티 리전 환경에서 **안정적으로 통신 가능한 Private 네트워크를 구축**하면서도
SSH 키 관리, Bastion Host 운영, Security Group Inbound 오픈과 같은
전통적인 운영 부담을 최소화할 방법이 필요했다.

이 프로젝트는 AWS 상에서 **Zero-SSH Architecture** 를 기반으로,
**Virginia (us-east-1)** 와 **Seoul (ap-northeast-2)** 간 Private VPC Peering 네트워크를
**Terraform으로 재현 가능하게 설계·구성한 레퍼런스 구현**이다.

---

## 🎯 Objectives

- 🔐 SSH & Bastion 없이 Private EC2 접근
- 🌏 Region 간 안정적인 Private Routing 제공
- 🧱 AWS Native Networking 기반 설계
- 🧪 Terraform 기반 재현 가능 아키텍처

---

## 🏗️ Architecture Overview

| 항목     | Virginia (Primary)    | Seoul (Secondary)     |
| -------- | --------------------- | --------------------- |
| Region   | us-east-1             | ap-northeast-2        |
| VPC CIDR | 10.0.0.0/16           | 10.1.0.0/16           |
| Subnets  | Public(2), Private(2) | Public(2), Private(2) |
| Gateway  | IGW + NAT (AZ별)      | IGW + NAT (AZ별)      |
| Compute  | Amazon Linux 2023     | Amazon Linux 2023     |
| Access   | SSM Session Manager   | SSM Session Manager   |

---

## 🧠 Design Decisions

- ❌ Bastion Host 미사용 → 키 관리 제거 + 공격 표면 감소
- ❌ SSH(22) 인바운드 **완전 제거**
- ✅ NAT Gateway 경로 통해 SSM 안정적 통신
- ✅ Routing Dependencies 명확화 (`depends_on`)

---

## 🛡️ Security Considerations

- “**기본이 안전한(Default Secure)**” 구조
- 최소 권한 IAM (`AmazonSSMManagedInstanceCore`)
- 인바운드 Rule Zero
- 필요 시

  - SSM Session Logging
  - CloudTrail 연계
  - Session Audit 가능

---

## ⚙️ Provisioning

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

# 🧪 Verification Strategy (테스트 방법)

VPC Peering + Private Networking이 정상 동작하는지 아래 방식으로 검증했다.

---

## ✅ 1️⃣ SSM 기반 Private Shell 접속

Virginia / Seoul 각각 접속

```bash
aws ssm start-session --target <INSTANCE_ID> --region us-east-1
aws ssm start-session --target <INSTANCE_ID> --region ap-northeast-2
```

---

## ✅ 2️⃣ Cross-Region Private Ping 테스트 (기본)

Virginia → Seoul

```bash
ping 10.1.x.x
```

Seoul → Virginia

```bash
ping 10.0.x.x
```

**정상 결과 예**

```text
64 bytes from 10.1.10.123: icmp_seq=1 ttl=253 time=182 ms
64 bytes from 10.1.10.123: icmp_seq=2 ttl=253 time=181 ms
```

---

## ✅ 3️⃣ Traceroute (라우팅 경로 확인)

Virginia EC2 내부에서 실행:

```bash
sudo yum install traceroute -y
traceroute 10.1.x.x
```

👉 NAT / Peering Path 확인 가능
👉 Blackhole 발생 여부 확인 가능

---

## ✅ 4️⃣ TCP Connectivity Test (ICMP 차단 환경 대비)

**엔터프라이즈 환경에서는 Ping이 차단된 경우가 많음**
그래서 아래 테스트를 추가:

### Option A — curl (TCP Layer 확인)

```bash
curl -v telnet://10.1.x.x:22
```

(22번 안 열려있지만 SYN 실패 응답 여부로 reachability 확인 가능)

---

### Option B — nc (netcat)

```bash
nc -zv 10.1.x.x 80
```

---

### Option C — socat / custom listener

한쪽에 listener

```bash
socat TCP-LISTEN:8080,fork stdout
```

다른쪽에서 테스트

```bash
nc 10.1.x.x 8080
```

**엔터프라이즈 검증 방식에 매우 유용**

---

## ✅ 5️⃣ AWS Layer 검증

### Route Table Blackhole 확인

```bash
aws ec2 describe-route-tables
```

확인 포인트:

- Status = active
- blackhole = false

---

## ⚠️ Failure Cases & Lessons Learned

- Peering Active 前 Route 적용 시 → 일시 블랙홀
  → `depends_on = [aws_vpc_peering_connection_accepter.peer]` 로 해결

- NAT 미연결 시 SSM 통신 실패
  → Outbound 경로는 SSM 생명선

---

## 💰 Cost & Operational Notes

- NAT Gateway 비용 발생
- Cross-region 트래픽 비용 발생
- Bastion 제거로 운영비 / 보안 리스크 감소
- SSH 키 관리 정책 불필요

---

## 📂 Project Structure

```text
.
├── main.tf
├── ec2.tf
├── sg.tf
├── iam.tf
├── data.tf
├── variables.tf
├── providers.tf
└── README.md
```

---

## 🧾 Conclusion

이 프로젝트는 단순 실습이 아니라,
**운영 가능한 Multi-Region Private Networking Architecture** 를
Terraform 기반으로 재현 가능하게 설계하고 검증한 레퍼런스다.

SSH 없이도 안정적인 운영이 가능하다는 것을 증명하며,
보안, 실용성, 운영성을 균형 있게 고려한 구조다.

---

원하면
👉 README를 GitHub에 바로 붙여넣어도 되게 스타일 다듬어줄 수도 있고
👉 영어 버전 / 기업 블로그 버전 / 발표자료 버전도 만들어 줄 수 있음
