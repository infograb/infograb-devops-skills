# GitLab CI X-Ray 룰 카탈로그

20개 룰 상세. 안티패턴 탐지(AP) 17개 + 스키마 검증(SC) 3개.

> fallback 분석 시 이 카탈로그를 참조해서 패턴 기반 탐지를 수행한다.

## 안티패턴 룰 (AP)

### AP-001: only/except deprecated

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | job에 `only` 또는 `except` 키가 있음 |
| fallback 탐지 | 가능 |

**설명**: `only`/`except`는 deprecated. `rules` 키워드로 전환 필요.

**문서**: https://docs.gitlab.com/ee/ci/yaml/#only--except

---

### AP-002: artifacts expire_in 미설정

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | `artifacts.paths`가 있지만 `expire_in`이 없음 (reports 전용 제외) |
| fallback 탐지 | 가능 |

**설명**: expire_in이 없으면 기본 30일 보관. 스토리지 낭비.

**수정 예시**:
```yaml
# before
artifacts:
  paths:
    - dist/

# after
artifacts:
  paths:
    - dist/
  expire_in: 1 week
```

---

### AP-003: 병렬화 가능한 job

| 항목 | 값 |
|------|-----|
| severity | info |
| 탐지 조건 | 같은 stage에 독립 job이 2개 이상이고 `needs`/`dependencies` 미사용 |
| fallback 탐지 | 가능 |

**설명**: 독립 job들에 `needs`를 추가하면 stage 경계를 넘어 병렬 실행 가능.

---

### AP-004: cache key 미설정

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | `cache.paths`가 있지만 `cache.key`가 없음 |
| fallback 탐지 | 가능 |

**설명**: key 없으면 모든 job이 같은 캐시 공유 → 충돌.

---

### AP-005: script 또는 trigger 누락

| 항목 | 값 |
|------|-----|
| severity | error (기본), info (include 미해석 시) |
| 탐지 조건 | job에 `script`도 `trigger`도 없음 |
| fallback 탐지 | 가능 |

**설명**: script/trigger 없으면 파이프라인 실패. include로 상속받는 경우 오탐 가능.

---

### AP-006: 과도한 artifacts 범위

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | artifacts paths에 넓은 패턴 (`*`, `**`, `./`, `dist/` 등) |
| fallback 탐지 | 가능 |

**설명**: 넓은 artifacts + downstream에 dependencies 미지정 → 불필요한 파일 전달.

---

### AP-007: retry 미설정 (네트워크 의존)

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | script에 네트워크 명령 (curl, wget, npm, pip, docker, apt 등) + retry 미설정 |
| fallback 탐지 | 가능 |

**설명**: 네트워크 명령은 일시적 오류에 취약. retry 설정 권장.

**수정 예시**:
```yaml
# after
retry:
  max: 2
  when: runner_system_failure
```

---

### AP-008: resource_group 미설정

| 항목 | 값 |
|------|-----|
| severity | info |
| 탐지 조건 | `environment`가 있지만 `resource_group`이 없음 |
| fallback 탐지 | 가능 |

**설명**: resource_group 없으면 동시 배포 발생 가능.

---

### AP-009: needs 순환 의존

| 항목 | 값 |
|------|-----|
| severity | error |
| 탐지 조건 | needs 그래프에 순환 (DFS로 탐지) |
| fallback 탐지 | **불가** (그래프 알고리즘 필요) |

**설명**: 순환 의존이 있으면 파이프라인 실행 불가.

---

### AP-010: interruptible 미설정

| 항목 | 값 |
|------|-----|
| severity | info |
| 탐지 조건 | `interruptible` 없음 (manual/deploy job 제외, default 미설정) |
| fallback 탐지 | 가능 |

**설명**: `interruptible: true` 설정 시 새 커밋 push 때 이전 파이프라인 자동 취소.

---

### AP-011: script 중복

| 항목 | 값 |
|------|-----|
| severity | info |
| 탐지 조건 | 두 job의 script 유사도 >= 70% (Jaccard index) |
| fallback 탐지 | **불가** (정밀 유사도 계산 필요) |

**설명**: 유사 script를 `extends`나 `!reference`로 추출하면 유지보수성 향상.

---

### AP-012: rules 빈 배열

| 항목 | 값 |
|------|-----|
| severity | error |
| 탐지 조건 | `rules: []` (빈 배열) |
| fallback 탐지 | 가능 |

**설명**: `rules: []`는 job이 절대 실행되지 않음. 의도적이면 `when: never` 사용.

---

### AP-013: image 미설정

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | job에 `image` 없고 `default.image`도 없음 (trigger job 제외) |
| fallback 탐지 | 가능 |

**설명**: 러너 기본 이미지에 의존. 재현 가능한 빌드를 위해 명시 권장.

---

### AP-014: 정의되지 않은 stage

| 항목 | 값 |
|------|-----|
| severity | error |
| 탐지 조건 | job의 stage가 `stages:` 배열에 없음 |
| fallback 탐지 | 가능 |

**설명**: 미정의 stage 참조 시 파이프라인 실패.

---

### AP-015: allow_failure + rules 혼용

| 항목 | 값 |
|------|-----|
| severity | info |
| 탐지 조건 | job에 `allow_failure`와 `rules[].allow_failure` 동시 존재 |
| fallback 탐지 | 가능 |

**설명**: 둘 다 있으면 어느 값이 적용되는지 모호.

---

### AP-016: 파괴적 명령 + 미검증 변수

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | script에 `rm -f $VAR`, `rsync --delete $VAR` 등 + 변수 검증 없음 |
| fallback 탐지 | 가능 |

**설명**: 변수가 빈 값이면 의도치 않은 경로 삭제 가능. `${VAR:?}` 또는 `[ -n "$VAR" ]` 방어 필요.

---

### AP-017: rules 블록 반복

| 항목 | 값 |
|------|-----|
| severity | info |
| 탐지 조건 | 동일한 rules 블록이 3개 이상 job에서 반복 |
| fallback 탐지 | 가능 |

**설명**: hidden job이나 `!reference`로 추출하면 유지보수성 향상.

---

## 스키마 검증 룰 (SC)

### SC-001: 알 수 없는 job 키

| 항목 | 값 |
|------|-----|
| severity | error (기본), warning (include 있을 때) |
| 탐지 조건 | job에 정의되지 않은 키 (hidden job, extends job 제외) |
| fallback 탐지 | **불가** (Levenshtein 오타 제안 불가) |

**설명**: 오타 가능성. CLI는 Levenshtein 거리로 가장 유사한 키 제안.

---

### SC-002: 값 타입 불일치

| 항목 | 값 |
|------|-----|
| severity | error |
| 탐지 조건 | 키 값의 타입이 GitLab CI 스키마와 불일치 |
| fallback 탐지 | **불가** (정밀 타입 검증 필요) |

**설명**: 예) `needs: "test"` (문자열) vs `needs: ["test"]` (배열).

---

### SC-003: 알 수 없는 top-level 키

| 항목 | 값 |
|------|-----|
| severity | warning |
| 탐지 조건 | 최상위에 정의되지 않은 키 (유효한 job 정의가 아닌 것) |
| fallback 탐지 | 가능 |

**설명**: 최상위 키 오타 또는 미지원 키.

---

## Fallback 탐지 요약

| 탐지 가능 (16개) | 탐지 불가 (4개) |
|------------------|----------------|
| AP-001~008, AP-010, AP-012~017, SC-003 | AP-009 (순환 의존), AP-011 (스크립트 유사도), SC-001 (오타 제안), SC-002 (정밀 타입) |
