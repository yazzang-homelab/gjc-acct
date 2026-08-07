# Notices

`gjc-acct` 는 **비공식 서드파티 런처**입니다. 아래 프로젝트들과 제휴·후원·승인 관계가 없습니다.

- [Gajae-Code (`gjc`)](https://github.com/Yeachan-Heo/gajae-code) — © 2025-2026 Yeachan-Heo and Gajae Code
  Contributors, MIT. 이 도구는 Gajae-Code 를 **실행만** 하며 코드를 포함하지 않습니다. 다만 다음
  공개 인터페이스에 의존합니다:
  - `GJC_CODING_AGENT_DIR` — 에이전트 저장소 디렉터리 오버라이드(문서화된 환경변수).
  - `--session-dir` — 명시적 세션 저장 위치 오버라이드(`docs/session.md` 에 오퍼레이터 오버라이드로 명시됨).
  - `CLAUDE_CONFIG_DIR` / `CODEX_HOME` + `gjc setup credentials --yes` — 외부 자격증명 임포트의 공식 경로.
  - `agent.db` 의 `auth_credentials` 테이블 — **내부 구현 세부사항**이며 공개 API 가 아닙니다.
    업스트림이 언제든 바꿀 수 있고, 그때 이 도구가 깨지는 것은 이 저장소의 책임입니다.
  - 세션 디렉터리 이름 규칙 — 내부 세부사항을 재현한 것이며 상위 버전과 어긋날 수 있습니다.
- [`claude-acct`](https://github.com/yazzang-homelab/claude-acct) — Claude 계정 슬롯(`~/.claude-accounts`)
  관리를 그대로 재사용합니다.
- [`codex-acct`](https://github.com/yazzang-homelab/codex-acct) — Codex 계정 슬롯(`~/.codex-accounts`)
  관리를 그대로 재사용합니다.
- Claude, Claude Code 는 Anthropic 의, ChatGPT, Codex 는 OpenAI 의 상표입니다. 이 도구는 두 회사와 무관하며,
  [Anthropic 사용정책](https://www.anthropic.com/legal/aup) 준수는 사용자 책임입니다.

버그·문의는 이 저장소로 보내십시오. 위 업스트림 프로젝트들의 이슈 트래커로 보내지 마십시오.
