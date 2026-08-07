# gjc-acct

[English](README.md) | [한국어](README.ko.md)

여러 개의 구독 계정/좌석을 **[Gajae-Code](https://github.com/Yeachan-Heo/gajae-code) (`gjc`)** 에서
이름으로 골라 실행하는 작은 런처입니다.

로그인은 직접 하지 않습니다. 자매 도구들이 만들어 둔 **로그인 슬롯**을 gjc 쪽으로 이어 붙이는
역할만 합니다.

| 소스 | 자매 도구 | 슬롯 루트 | gjc 가 읽는 입력 | gjc provider |
| --- | --- | --- | --- | --- |
| `claude` | [`claude-acct`](https://github.com/yazzang-homelab/claude-acct) | `~/.claude-accounts/<slot>` | `CLAUDE_CONFIG_DIR` | `anthropic` |
| `codex` | [`codex-acct`](https://github.com/yazzang-homelab/codex-acct) | `~/.codex-accounts/<slot>` | `CODEX_HOME` | `openai-codex` |

한 계정에 여러 소스를 묶을 수 있습니다. 새 소스는 `GJC_ACCT_EXTRA_SOURCES` 로 추가합니다.

> **비공식 서드파티 도구입니다.** Gajae-Code 프로젝트 및 원작자([@Yeachan-Heo](https://github.com/Yeachan-Heo))와
> 제휴·후원·승인 관계가 없습니다. 이 런처를 쓰다 생긴 문제는 여기(이 저장소)로 신고하십시오.
> [gajae-code](https://github.com/Yeachan-Heo/gajae-code) 이슈 트래커에 올리지 마십시오.

```bash
gjc-acct sources                            # 등록된 소스와 탐지된 슬롯
gjc-acct bind work claude=team-a codex=2    # 한 계정에 Claude 좌석 + Codex 계정을 함께
gjc-acct work                               # "work" 로 gjc 실행
gjc-acct                                    # 기본 계정(없으면 대화형 선택)
```

---

## 설계 원칙: gjc 를 고쳐 쓰지 않는다

이 런처는 의도적으로 얇습니다. 코드가 300줄대인 건 게을러서가 아니라, 필요한 걸 gjc 가 이미
전부 공개 인터페이스로 내주고 있기 때문입니다. 만들면서 실제로 확인한 것들입니다.

- **`GJC_CODING_AGENT_DIR`** — 에이전트 저장소를 통째로 갈아끼울 수 있게 문서화돼 있습니다.
  계정 격리에 필요한 건 이거 하나였습니다.
- **`CLAUDE_CONFIG_DIR` + `gjc setup credentials`** — Claude Code 자격증명 임포트가 이미
  1급 기능입니다(`src/setup/credential-import.ts`). 게다가 임포트할 때 *"Refreshing in gjc may
  log out the Claude/Codex CLI because OAuth refresh tokens can rotate"* 라고 **먼저 경고**합니다.
  자기 편의를 위해 남의 CLI 세션을 조용히 깨뜨리지 않겠다는 태도가 코드에 박혀 있습니다.
  Claude 와 Codex 를 **같은 임포터 한 곳**에서 대칭적으로 다루기 때문에, 이 런처가 소스를
  늘리는 데 드는 코드가 테이블 한 줄입니다.
- **관리형 세션 스코프** (`managed-session-scope.ts`) — sessions 루트나 스코프 디렉터리가
  심링크/junction(reparse point)이면 거부하고, `O_NOFOLLOW` 무추종 순회와 소유자·`0700` 모드·ACL
  검증을 통과해야만 씁니다. 세션 디렉터리 하나에 이 정도 방어를 넣어 둔 코딩 에이전트는 흔치 않습니다.
- **`--session-dir`** — 그러면서도 오퍼레이터가 저장 위치를 직접 고를 길을 막지 않았습니다.
  `docs/session.md` 가 이걸 *"an explicit storage/lookup override … remains an
  operator-selected override"* 로 명시합니다. 관리형 경로는 단단하게 잠그고, 명시적 경로는
  사용자 책임으로 열어 둔 이 분리가 이 런처가 존재할 수 있는 이유입니다.

그래서 이 저장소에는 gjc 를 패치하거나, 몽키패치하거나, 내부 동작을 우회하는 코드가 없습니다.
남은 내부 의존 딱 하나는 아래에 그대로 적어 뒀고, 그건 우리 부채입니다.

---

## 무엇을 위한 도구인가 / 아닌가

**한 사람이 여러 Claude 구독(개인/업무 등)을 한 머신에서 깔끔히 전환**하기 위한 것입니다.

- ✅ 계정마다 **자기 구독으로** 로그인 (슬롯은 각 자매 도구가 관리).
- ✅ 바인딩된 소스의 자격증명만 계정별로 **격리** — 같은 이메일이 서로 다른 좌석이어도 덮어쓰지 않음.
- ✅ 바인딩하지 않은 provider(회사 Copilot 등)는 base 것을 **그대로 상속**.
- ✅ 설정·스킬·커맨드는 base(`~/.gjc/agent`)와 **공유** — "누구로 로그인했나"만 계정별로 갈림.

사용 한도를 우회하려고 계정을 **풀링/로테이션**하거나 하나의 구독을 **여러 사람이 공유**하는 용도가 **아닙니다.**
그런 사용은 [Anthropic 사용정책](https://www.anthropic.com/legal/aup)에 어긋나며, 이 도구는 그것을 하지 않습니다.
한도는 **좌석 단위로 각각** 집계되고, 새 토큰은 항상 현재 로그인한 계정에 청구됩니다.

---

## 동작 방식 (격리형)

계정마다 독립된 gjc 저장소 디렉터리를 씁니다: `~/.gjc-accounts/<name>/agent` (`GJC_CODING_AGENT_DIR`).

- `agent.db`(자격증명)만 계정별로 분리합니다.
- `config.yml`/`models.yml`/`mcp.json`/`skills`/`commands` 등은 base(`~/.gjc/agent`)와 **심링크로 공유**합니다.
- 토큰은 슬롯을 단일 원본으로 삼고, 주입은 **업스트림 공식 임포터**로만 합니다. 바인딩된 모든
  소스를 한 번의 호출로 함께 임포트합니다:

  ```bash
  GJC_CODING_AGENT_DIR=<계정 저장소> \
  CLAUDE_CONFIG_DIR=<claude 슬롯> CODEX_HOME=<codex 슬롯> \
    gjc setup credentials --yes
  ```

  자매 도구의 슬롯 레이아웃이 각 CLI 의 설정 디렉터리와 동일해서 그대로 가리키면 됩니다.
  `agent.db` 에 직접 INSERT 하지 않습니다. 바인딩하지 **않은** 소스의 env 변수는 빈 디렉터리로
  눌러 다른 계정 자격증명이 섞여 들어오지 않게 합니다. 슬롯 마커 파일의 mtime/size 가 바뀌었을
  때만 재임포트하므로 평소 실행 오버헤드는 없습니다.

> ℹ️ **`codex-acct` 과의 관계.** 공개판 `codex-acct`는 `CODEX_HOME` 슬롯만 관리하며
> OAuth 토큰을 추출하거나 gjc의 `.env`·`models.yml`을 수정하지 않습니다. `gjc-acct`가 그 슬롯을
> 공식 임포터로 가져와 계정별 `agent.db`에 저장하는 유일한 연동 경로입니다.

### 계정과 슬롯 바인딩

계정 이름과 같은 이름의 슬롯이 있으면 **자동으로** 묶입니다(`lee` → `claude=lee`).
이름이 다르거나 여러 소스를 묶으려면 명시합니다:

```bash
gjc-acct bind work claude=team-a codex=2   # ~/.gjc-accounts/work/sources 에 저장
gjc-acct unbind work codex
gjc-acct list                              # 계정별 바인딩·격리 상태
```

> ⚠️ **토큰 로테이션.** 업스트림 경고 그대로입니다 — 같은 슬롯을 Claude Code 와 gjc 가 동시에 쓰면
> 한쪽의 갱신이 다른 쪽을 로그아웃시킬 수 있습니다. 그때는 해당 슬롯에서 다시 `/login` 하십시오.

> ℹ️ **남아 있는 내부 의존 1건.** 공식 임포터는 insert-if-absent 라, 토큰을 갈아끼우려면 기존 행을
> 먼저 지워야 합니다. 대응하는 공식 명령 `gjc auth-broker logout <provider>` 이 gjc 0.12.12 에서는
> 커맨드 레지스트리(`src/cli.ts`)에 등록돼 있지 않아 argv 가 채팅 프롬프트로 흘러갑니다. 업스트림에
> 보고했습니다 — [Yeachan-Heo/gajae-code#3975](https://github.com/Yeachan-Heo/gajae-code/issues/3975).
> 그때까지는 공식 명령을 **한 번만** 시도해 보고, 안 되면 판정을 캐시한 뒤 해당 행에 직접 `DELETE` 로
> 폴백합니다. 등록되는 순간 공식 경로가 자동으로 우선하고 이 폴백은 죽는 코드가 됩니다.
> 이 한 줄은 gjc 의 내부 스키마에 기대는 부분이고, 스키마가 바뀌어 깨지면 **이 저장소의 책임**입니다.

### 세션(대화 기록) 공유 — `--session-dir` 주입 방식

계정을 바꿔도 `gjc --continue` / `--resume` 로 같은 세션 히스토리를 이어가고 싶을 때가 있습니다.
계정 저장소의 `sessions` 를 base 로 심링크하는 방식은 쓰지 않습니다 — 관리형 세션 스코프가
reparse point 를 정당하게 거부하기 때문입니다(위 설계 원칙 참고). Windows/Git Bash 에선 `ln -s`
자체가 복사본을 만들어 애초에 공유가 성립하지 않습니다.

대신 **세션을 여는 실행에 한해 `--session-dir <공유경로>` 를 주입**합니다. 업스트림이 오퍼레이터
오버라이드로 열어 둔 바로 그 경로이며, Linux / macOS / Windows 에서 동일하게 동작합니다.

- 공유 경로: `<sessions 루트>/<cwd 슬러그>` (기본; `GJC_ACCT_SESSIONS_ROOT` 로 변경 가능).
- cwd 별로 분리되고, 같은 cwd 에서는 **어느 계정이든 동일 경로** → 계정 간 세션 공유.
- 관리 서브커맨드(`stats`, `session`, `ralplan`, …)나 이미 `--session-dir`/`--no-session` 이 있으면 주입하지 않습니다.
- Windows(Git Bash)에선 `gjc.exe` 로 넘기는 경로를 `cygpath -m` 로 네이티브 형식으로 변환합니다.

> ⚠️ **알려진 한계 (gjc 0.12+).** 이 경로는 **계정끼리만** 공유되고, 계정을 지정하지 않은 맨 `gjc`
> 와는 공유되지 않습니다. 0.12 의 기본 세션 디렉터리는 `sessions/v2-<digest>` 형식인데
> (`managed-session-scope.ts`), 이 스크립트가 만드는 이름은 그것과 다릅니다. 또한 명시적 경로를 쓰면
> 그 실행은 관리형 스코프의 ACL·no-follow 검증 **밖**에 놓입니다 — 보안을 한 단계 내리는 선택이니
> 알고 쓰십시오. 관리형 스코프를 그대로 쓰려면 `GJC_ACCT_NO_SESSION_SHARE=1` 로 주입을 끄면 됩니다
> (계정별로 세션이 분리됩니다).

---

## 설치

> `gjc` CLI 가 PATH 에 있어야 합니다 ([Gajae-Code 설치](https://github.com/Yeachan-Heo/gajae-code): `bun install -g gajae-code`).
> 계정 슬롯 로그인은 자매 도구 [`claude-acct`](https://github.com/yazzang-homelab/claude-acct) 로 합니다.

### 클론 후 설치

```bash
git clone https://github.com/yazzang-homelab/gjc-acct.git
cd gjc-acct
./install.sh
```

### 원라이너

```bash
curl -fsSL https://raw.githubusercontent.com/yazzang-homelab/gjc-acct/main/install.sh \
  | GJC_ACCT_RAW_BASE=https://raw.githubusercontent.com/yazzang-homelab/gjc-acct/main bash
```

- Linux/macOS: `/usr/local/bin/gjc-acct` (+ `gca` 단축) 설치.
- Windows(Git Bash): `~/.local/libexec/gjc-acct` + `gjc-acct.cmd` 래퍼 설치.

---

## 사용법

```
gjc-acct                      기본 계정으로 gjc 실행(없으면 대화형 선택)
gjc-acct <name> [args…]       지정 계정으로 gjc 실행 (나머지 인자는 gjc 로 전달)
gjc-acct list|ls              계정 목록 + 소스별 인증/격리저장소 상태
gjc-acct status               계정별 소스·슬롯·구독/한도tier 개요
gjc-acct sources              등록된 슬롯 소스와 탐지된 슬롯 목록
gjc-acct bind <name> <src>=<slot> [...]   슬롯 수동 바인딩
gjc-acct unbind <name> <src>  바인딩 해제
gjc-acct sync <name>          슬롯 토큰을 해당 계정 저장소로 동기화만(실행 안 함)
gjc-acct reseed <name>        계정 저장소를 base 기준으로 재시드
gjc-acct default [name]       무인자 실행 시 쓸 기본 계정 조회/설정
gjc-acct dir <name>           계정 저장소 경로 출력
gjc-acct completion bash|zsh  셸 자동완성 스크립트 출력
```

### 환경 변수

| 변수 | 기본값 | 설명 |
| --- | --- | --- |
| `GJC_ACCOUNTS_DIR` | `~/.gjc-accounts` | 계정별 격리 저장소 루트 |
| `GJC_BASE_AGENT_DIR` | `~/.gjc/agent` | 공유 base 저장소 |
| `CLAUDE_ACCOUNTS_DIR` | `~/.claude-accounts` | `claude-acct` 슬롯 위치 |
| `CODEX_ACCOUNTS_DIR` | `~/.codex-accounts` | `codex-acct` 슬롯 위치 |
| `GJC_ACCT_EXTRA_SOURCES` | (미설정) | 추가 소스 `key\|루트\|env\|마커\|provider\|도구` (`;` 구분) |
| `GJC_ACCT_SESSIONS_ROOT` | `<base>/sessions` | 공유 세션 루트 |
| `GJC_ACCT_BIN` | `gjc` | 실행할 gjc 바이너리 |
| `GJC_ACCT_NO_SESSION_SHARE` | (미설정) | `1` 이면 `--session-dir` 주입을 끄고 gjc 기본 관리형 스코프 사용 |

---

## 라이선스 / 귀속

MIT — [`LICENSE`](./LICENSE) 참고. 업스트림 귀속과, 이 도구가 기대는 인터페이스 중 무엇이 공개
API 이고 무엇이 내부 구현인지는 [`NOTICE.md`](./NOTICE.md) 에 정리해 뒀습니다.
