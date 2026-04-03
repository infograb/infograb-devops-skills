# GitLab CI 모범 사례

컨텍스트 확장 분석 시 참조하는 모범 사례 모음. 경고/제안을 설명할 때 근거로 활용한다.

## Stage 구성

**권장 구조**:
```yaml
stages:
  - lint
  - test
  - build
  - deploy
```

- stage 수는 4~6개가 적정. 10개 넘으면 파이프라인이 직렬화되어 느려짐.
- `lint`과 `test`를 분리하면 빠른 피드백 가능 (lint 실패 시 test 미실행).
- `deploy`는 환경별로 분리하지 말고 `environment:` 키워드로 구분.

**안티패턴**: stage를 환경별로 나누기
```yaml
# 피하기
stages:
  - build
  - deploy-dev
  - deploy-staging
  - deploy-prod
```

## needs와 DAG

- `needs:`로 명시적 의존을 선언하면 stage 경계를 넘어 병렬 실행 가능.
- `needs: []`는 파이프라인 시작과 동시에 실행 (이전 stage 대기 없음).
- DAG가 복잡해지면 `needs:`의 `optional: true`로 유연하게 구성.

```yaml
test:unit:
  stage: test
  needs: ["lint"]  # lint만 기다리고 바로 시작

test:e2e:
  stage: test
  needs: ["build"]  # build 완료 후 시작
```

## Cache 전략

**키 설계**:
```yaml
cache:
  key:
    files:
      - package-lock.json  # 락파일 변경 시에만 캐시 무효화
  paths:
    - node_modules/
  policy: pull-push        # 기본 브랜치에서만 push, MR에서는 pull
```

**언어별 권장**:

| 언어/도구 | cache key files | cache paths |
|-----------|----------------|-------------|
| Node.js (npm) | `package-lock.json` | `node_modules/` |
| Node.js (pnpm) | `pnpm-lock.yaml` | `.pnpm-store/` |
| Python (pip) | `requirements.txt` | `.pip-cache/` |
| Python (uv) | `uv.lock` | `.uv-cache/` |
| Go | `go.sum` | `.go-cache/` |
| Rust | `Cargo.lock` | `target/` |

**안티패턴**: `cache.key` 없이 사용 → 모든 job이 같은 캐시를 덮어씀.

## Artifacts

- `expire_in`을 항상 설정. 기본 30일은 대부분 과도함.
- 테스트 리포트: `expire_in: 1 week`
- 빌드 산출물: `expire_in: 3 days` (배포 후 불필요)
- `dependencies:`로 필요한 job의 artifacts만 받기. 전부 받으면 느림.

```yaml
deploy:
  dependencies:
    - build        # build의 artifacts만 받음
```

**안티패턴**: artifacts paths에 `**/*` 같은 넓은 패턴 사용.

## 보안

**민감 작업은 수동 승인**:
```yaml
deploy:prod:
  when: manual
  environment:
    name: production
  resource_group: production  # 동시 배포 방지
```

**변수 보호**:
- CI/CD Variables에서 `Protected` + `Masked` 설정
- script에서 변수 참조 시 `${VAR:?}` (빈 값이면 중단)
- `rm -rf $PATH` 같은 파괴적 명령에 변수 사용 금지

**보안 스캔 통합**:
```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
```

## Retry와 안정성

**네트워크 의존 job에 retry 설정**:
```yaml
install:
  script:
    - npm ci
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

**interruptible로 리소스 절약**:
```yaml
default:
  interruptible: true  # 새 커밋 push 시 이전 파이프라인 자동 취소

deploy:prod:
  interruptible: false  # 배포는 취소하지 않음
```

## DRY (Don't Repeat Yourself)

**extends로 공통 설정 추출**:
```yaml
.base-test:
  stage: test
  retry: 2
  artifacts:
    reports:
      junit: report.xml
    expire_in: 1 week

test:unit:
  extends: .base-test
  script: npm run test:unit

test:integration:
  extends: .base-test
  script: npm run test:integration
```

**!reference로 부분 재사용**:
```yaml
.common-rules:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

test:
  rules: !reference [.common-rules, rules]
```

**3개 이상 job에서 같은 rules 블록 반복 시 → 추출 필요.**
