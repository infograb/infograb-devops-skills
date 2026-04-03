# JSON 결과 해석 가이드

`npx gitlab-ci-xray <file> --json` 출력을 해석하는 가이드.

## 최상위 구조

```json
{
  "version": 1,
  "dag": [...],
  "warnings": [...],
  "suggestions": [...],
  "summary": { "jobs": N, "stages": [...], "warnings": N, "suggestions": N }
}
```

- `version`: JSON 스키마 버전. 현재 1.
- `dag`: 파이프라인 DAG (Directed Acyclic Graph). job 간 의존 관계.
- `warnings`: 안티패턴 경고 + 스키마 검증 결과.
- `suggestions`: 최적화 제안.
- `summary`: 통계 요약.

## DAG 노드

```json
{
  "job": "build",
  "stage": "build",
  "needs": ["lint"],
  "stageNeeds": []
}
```

- `needs`: 명시적 의존 (`needs:` 키워드로 선언)
- `stageNeeds`: 암묵적 의존 (앞 stage의 모든 job). `needs`가 없으면 자동 설정.

**해석 포인트**: `stageNeeds`가 많은 job은 `needs:`를 명시해서 불필요한 대기를 줄일 수 있음.

## Warning 객체

```json
{
  "ruleId": "AP-002",
  "severity": "warning",
  "message": "'build'의 artifacts에 expire_in이 설정되지 않았습니다.",
  "description": "artifacts에 expire_in이 없으면 기본 30일간 보관되어 스토리지를 낭비합니다.",
  "job": "build",
  "key": "artifacts",
  "line": 15,
  "docUrl": "https://docs.gitlab.com/ee/ci/yaml/#artifactsexpire_in",
  "fix": {
    "id": "fix-ap-002",
    "title": "expire_in 추가",
    "before": "artifacts:\n  paths:\n    - dist/",
    "after": "artifacts:\n  paths:\n    - dist/\n  expire_in: 1 week"
  }
}
```

### Severity 해석

| severity | 의미 | 리포트 표시 |
|----------|------|-----------|
| `error` | 파이프라인 실패 또는 심각한 문제 | 즉시 수정 필요 |
| `warning` | 모범 사례 위반, 잠재적 문제 | 권장 수정 |
| `info` | 개선 가능 사항 | 참고 |

### ruleId 접두사

| 접두사 | 의미 | 룰 수 |
|--------|------|-------|
| `AP-` | Anti-Pattern — 코드 패턴 기반 탐지 | 17개 (AP-001~017) |
| `SC-` | Schema — JSON 스키마 기반 검증 | 3개 (SC-001~003) |

### fix 활용

`fix`가 `null`이 아니면 자동 수정 가능:
- `before`: 현재 코드 (YAML 스니펫)
- `after`: 수정 후 코드
- 사용자에게 before/after를 보여주고 동의 시 Edit 도구로 적용

`fix`가 `null`이면 수동 수정 필요. `description`을 바탕으로 수정 방법 설명.

### line 활용

`line`이 숫자면 해당 줄 번호를 리포트에 포함: `(line 15)`.
`line`이 `null`이면 줄 번호 생략.

### docUrl 활용

`null`이 아니면 "GitLab 문서: {url}" 링크 포함.

## Suggestion 객체

```json
{
  "id": "opt-security-manual-deploy",
  "type": "security",
  "title": "'deploy' 프로덕션 배포에 when: manual 추가",
  "description": "프로덕션 배포는 수동 승인을 거치는 것이 안전합니다.",
  "impact": "high",
  "jobs": ["deploy"],
  "before": "deploy:\n  stage: deploy\n  environment: production",
  "after": "deploy:\n  stage: deploy\n  environment: production\n  when: manual"
}
```

### type 해석

| type | 의미 |
|------|------|
| `parallelization` | `needs:`로 병렬 실행 가능 |
| `cache` | 캐시 키 전략 개선 |
| `artifacts` | 아티팩트 최적화 (불필요 전달 제거) |
| `structure` | 파이프라인 구조 개선 |
| `security` | 보안 강화 (수동 승인 등) |

### impact 해석

| impact | 의미 | 리포트 순서 |
|--------|------|-----------|
| `high` | 파이프라인 시간/보안에 큰 영향 | 먼저 표시 |
| `medium` | 중간 수준 개선 | 다음 |
| `low` | 사소한 개선 | 마지막 |

### before/after 활용

모든 suggestion에 before/after YAML 스니펫이 포함됨.
리포트에 코드 블록으로 표시하고, 자동 수정 시 참조.
