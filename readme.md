## 개요
테라폼 공부를 위한 3-tier arcitecture를 terraform으로 구성

## 아키텍처
<img src="https://github.com/user-attachments/assets/4ed69cf6-3ed0-4d57-a376-4f7b1f7941c1" width="70%" height="70%"/>

## Application Repository
### FE 
https://github.com/wcorn/toy-project-fe 
### BE 
https://github.com/wcorn/toy-project-be

## 디렉터리 구조
```
┣ 📂backend         ## terraform backend
┣ 📂envs            ## 배포 환경
┃ ┣ 📂dev           ##  개발 서버
┃ ┣ 📂prod          ##  배포 서버
┃ ┗ 📂shared        ##  공유 서버
┣ 📂modules         ## 모듈
┃ ┣ 📂backend       ##  백엔드
┃ ┃ ┣ 📂ec2         ##    백엔드 ec2
┃ ┃ ┗ 📂pipeline    ##    백엔드 파이프라인
┃ ┣ 📂database      ##  데이터베이스
┃ ┣ 📂frontend      ##  프론트엔드
┃ ┃ ┣ 📂pipeline    ##    프론트엔드 파이프라인
┃ ┃ ┗ 📂s3          ##    프론트엔드 S3
┃ ┣ 📂openvpn       ##  openvpn
┃ ┣ 📂route53       ##  route53
┃ ┣ 📂shared_vpc    ##  공유서버용 VPC
┃ ┗ 📂vpc           ##  VPC
 ```
## 사용 방법
backend -> dev,prod -> shared 순으로 실행한다.
### terraform backend
```
cd backend
terraform init
terraform plan
terraform apply -auto-approve
```
### dev, prod, shared
```
cd envs/${환경}
terraform init
terraform plan
terraform apply -auto-approve
```
### CI/CD 연결
AWS Console에 로그인하여 CodePipeline 서비스에 접근하여 연결 탭에서 CodeConnections에서 배포할 repository를 연결한다.

## 아키텍처 설계 배경
### 프로젝트 요구사항
- 서비스 중단을 최소화하기 위해 다중 가용 영역(Multi-AZ)을 활용한 고가용성 인프라 구축.
- 사용자 요청 증가 시 자동으로 리소스가 확장 및 축소될 수 있도록 오토 스케일링(Auto Scaling) 구성
- 외부 접근으로부터 보호하기 위한 VPN 터널링 및 Private Subnet과 Public Subnet을 구분하여 보안 강화
- 코드 기반의 인프라 관리(IaC)를 통해 인프라 변경사항을 효율적으로 관리<br/>
  개발 환경(dev)과 운영 환경(prod)을 구분
- 애플리케이션의 성능을 유지하고 DB를 포함한 인프라 자원의 부하를 분산하여 안정적인 서비스를 제공
- 리소스 낭비를 줄이고, 효율적인 비용 관리가 가능한 탄력적인 구조를 구축


### 아키텍처 설계 과정
아키텍처 설계 시 아래의 사항을 중점적으로 고려했습니다.
- 3-tier 구조를 사용하여 역할과 책임을 명확하게 분리했습니다.
- Terraform을 활용하여 반복 가능한 자동화 인프라 환경을 구축했습니다.
- 환경(dev, prod, shared)을 명확하게 구분하여 관리가 용이하도록 설계했습니다.
- Private 서브넷을 분리하여 DB 및 내부 서비스 보안을 강화했고, VPN을 통해 안전한 접근을 보장했습니다.
- 로드 밸런서(ALB)를 통해 트래픽을 효과적으로 관리하며, 오토 스케일링 그룹으로 트래픽 변화에 유연하게 대응할 수 있도록 했습니다.


### 현재 아키텍처 구조와 같이 설계한 이유
- AWS를 사용하여 3-tier 아키텍처를 구축했습니다.
- Frontend, Backend, Database 계층을 구분하여 확장성과 유지보수성을 높였습니다. 
- Public Subnet과 Private Subnet을 나누고 VPN을 통한 접근을 통해 보안성을 높였습니다.
- 개발 환경(dev)과 운영 환경(prod) 이외에 중앙에 공유 환경(shared)을 두어 관리의 용이성을 더했습니다.<br/>
- CI/CD 도구로 Code Piepline을 사용한 이유는 Terraform으로 쉽게 구성할 수 있고 AWS와 높은 호환성을 가지고 있으며 관리 부담의 최소화, 보안 및 접근제어가 용이하여 사용했습니다.

### 아키텍처 설계에 대한 고민
본 아키텍처 설계 시 여러 가지 고민과 결정을 했으며, 다음과 같은 사항을 깊게 고민했습니다.

- 환경 분리(Dev/Prod/Shared)의 중요성<br/>
  환경에 따른 Terraform 구성 관리와 리소스 재사용성을 높이기 위해 환경별로 분리된 Terraform 디렉터리 구조를 선택했습니다. 특히 shared의 경우 dev, prod의 log, 접근 도구 등 각 환경에 따로 배치될 필요가 없는 도구 들을 하나로 모아 shared에 넣는 식으로 구축했습니다.

- 모듈화의 필요성<br/>
  처음 구축 당시 모듈화를 하지 않았습니다. 하지만 점점 가독성이 떨어지고 관리가 어려워져 유지보수성이 떨어지고 중복 코드가 생겼습니다. 따라서 Terraform 모듈로 리소스를 추상화하여 코드 재사용성과 가독성을 높였습니다. 

- VPN(OpenVPN)을 통한 보안적인 접근 제어<br/>
  기존에는 Bastion Host를 많이 사용하여 이번에도 사용하려 했으나 내부 시스템, 서비스에 대한 접근이 잦은 반면 접근이 어려웠습니다. 그래서 네트워크 전체에 대한 접근 권한을 제공하는 OpenVPN을 사용하였습니다.

- CI/CD 도구 선택<br/>
  비용문제에 때문에 terraform 한번 사용하고나면 destroy를 해야 했습니다. 그래서 terraform으로 빠르게 구축할 수 있고 AWS와 호환성이 좋은 Code Pipeline을 사용했습니다. 그 결과 terraform 구축 명령어를 내리고 콘솔에서 연결 버튼만 누르면 완전한 배포가 가능게 구성하였습니다.

## 아키텍처의 장단점 및 예상 비용 분석
### 장점
- 안정적인 고가용성 시스템 구축이 가능합니다.
- 확장과 축소가 용이하여 유연한 트래픽 대응이 가능합니다.
- IaC를 통해 인프라 운영의 효율성을 높이고 유지보수 비용을 절감할 수 있습니다.
- 보안 정책으로 민감한 정보와 리소스를 효과적으로 보호합니다.
### 단점 및 개선 가능성
- 초기 설계 및 구축에 시간과 자원이 더 소요됩니다.
- Database의 경우 이중화가 필요합니다.
- dev와 prod가 같은 스펙을 사용하고 있는데 다르게 가져가야 합니다.
- 로그 처리를 하지 않아 추후 추가해야합니다.
- WAF 설정을 통해 보안을 더욱 강화할 수 있습니다. 
### 예상 비용 분석 (월 예상 비용, 24시간 가동 기준, 프리티어 제외)
|사용량 구분 |예상 비용 (월)|비고|
|------|-------|-----|
|저부하|약 $400|최소 리소스 사용시|
|중간부하|약 $500|평균 사용량 유지시|
|고부하|약 $700 |최대 리소스활용시|
## 결론 및 향후 계획
현재 3-tier 아키텍처 구성을 어느정도 완성했다고 생각합니다. 추가적으로 아래와 같은 개선을 진행할 계획입니다.
- CloudWatch를 활용한 모니터링 및 경고 시스템 구축
- terraoform 코드의 추가적인 리펙터링
- WAF 추가 검토
- RDS 이중화
- dev, prod의 스펙 구분
- codepipeline 실행 시 환경변수의 암호화 (1순위)
- CI/CD 안정성 검토