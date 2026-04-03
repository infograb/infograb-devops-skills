# GitLab CI X-Ray

`.gitlab-ci.yml`을 분석하여 안티패턴 탐지, 스키마 검증, 최적화를 제안하는 스킬.

## 기능

- **20개 룰 기반 분석**: deprecated 키워드, 보안 위험, 성능 이슈, 구조 문제 탐지
- **스키마 검증**: GitLab CI JSON Schema 기반 오타/타입 오류 탐지
- **컨텍스트 확장**: git history, glab 파이프라인 이력, include 파일 추적
- **자동 수정**: 동의 시 before/after 코드를 직접 적용

## 작동 방식

```
사용자 요청 → CI 파일 탐지 → npx 분석 (또는 fallback) → 컨텍스트 확장 → 리포트 → 자동 수정
```

**npx 경로** (권장): `npx gitlab-ci-xray@latest`로 20개 룰 정밀 탐지. JSON 결과를 Claude가 해석하고 레포 컨텍스트로 확장.

**fallback 경로**: npx 없으면 Claude가 SKILL.md의 룰 카탈로그를 참조해서 직접 분석. 16/20개 룰 탐지 가능.

## 사용 예시

에이전트에 자연어로 요청:

```
CI 파이프라인 분석해줘
```

```
.gitlab-ci.yml에 문제 있어?
```

```
파이프라인이 느린데 최적화 방법 알려줘
```

## 필요한 것

| 항목 | 필수 여부 | 용도 |
|------|----------|------|
| `.gitlab-ci.yml` | 필수 | 분석 대상 |
| Node.js 18+ | 권장 | `npx gitlab-ci-xray` 정밀 분석 |
| glab CLI + 인증 | 선택 | 파이프라인 실행 이력 기반 분석 |

Node.js가 없어도 Claude 단독 분석으로 동작합니다.

## npx 설치

```bash
# 별도 설치 불필요. npx가 자동으로 최신 버전 실행.
npx gitlab-ci-xray@latest .gitlab-ci.yml --json
```

## 룰 목록

### 안티패턴 (AP-001 ~ AP-017)

| ID | 설명 | 심각도 |
|----|------|--------|
| AP-001 | only/except deprecated | warning |
| AP-002 | artifacts expire_in 미설정 | warning |
| AP-003 | 병렬화 가능한 job | info |
| AP-004 | cache key 미설정 | warning |
| AP-005 | script 또는 trigger 누락 | error |
| AP-006 | 과도한 artifacts 범위 | warning |
| AP-007 | retry 미설정 (네트워크 의존) | warning |
| AP-008 | resource_group 미설정 | info |
| AP-009 | needs 순환 의존 | error |
| AP-010 | interruptible 미설정 | info |
| AP-011 | script 중복 | info |
| AP-012 | rules 빈 배열 | error |
| AP-013 | image 미설정 | warning |
| AP-014 | 정의되지 않은 stage | error |
| AP-015 | allow_failure + rules 혼용 | info |
| AP-016 | 파괴적 명령 + 미검증 변수 | warning |
| AP-017 | rules 블록 반복 | info |

### 스키마 검증 (SC-001 ~ SC-003)

| ID | 설명 | 심각도 |
|----|------|--------|
| SC-001 | 알 수 없는 job 키 (오타 제안) | error |
| SC-002 | 값 타입 불일치 | error |
| SC-003 | 알 수 없는 top-level 키 | warning |

## 제한사항

- GitLab CI 전용. GitHub Actions, Jenkins 등은 지원하지 않음.
- `include: remote:` 파일은 직접 읽을 수 없음 (목록만 안내)
- fallback 모드에서는 순환 의존(AP-009), 스크립트 유사도(AP-011), 오타 제안(SC-001), 정밀 타입 검증(SC-002) 탐지 불가

---

이 스킬은 InfoGrab의 GitLab CI X-Ray로 구동됩니다.
더 자세한 도움이 필요하시면 → https://insight.infograb.net
