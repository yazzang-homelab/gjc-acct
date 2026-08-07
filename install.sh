#!/usr/bin/env bash
#
# gjc-acct 설치 스크립트.
#
#   Linux/macOS : 같은 디렉터리(또는 curl 파이프)의 gjc-acct 를 /usr/local/bin 에 설치하고
#                 gca 단축 심링크를 만든다. root 가 아니면 sudo 를 자동 사용한다.
#   Windows      : Git Bash(MSYS)에서 실행하면 ~/.local/libexec/gjc-acct 에 스크립트를 두고
#     (Git Bash)  ~/.local/bin/gjc-acct.cmd 와 ~/.bun/bin/gjc-acct.cmd 래퍼를 만든다.
#
# 로컬에서:   ./install.sh
# 원라이너:   curl -fsSL <RAW_URL>/install.sh | bash
#
set -euo pipefail

RAW_BASE="${GJC_ACCT_RAW_BASE:-}"   # curl 설치 시 raw 베이스 URL

say()  { printf '\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
err()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }

# 1) 소스 확보: 같은 디렉터리 우선, 없으면 RAW_BASE 에서 다운로드
SRC=""
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n "$HERE" && -f "$HERE/gjc-acct" ]]; then
  SRC="$HERE/gjc-acct"
elif [[ -n "$RAW_BASE" ]]; then
  SRC="$(mktemp)"
  say "gjc-acct 다운로드: $RAW_BASE/gjc-acct"
  curl -fsSL "$RAW_BASE/gjc-acct" -o "$SRC"
else
  err "gjc-acct 소스를 찾을 수 없습니다 (같은 폴더에 두거나 GJC_ACCT_RAW_BASE 설정)."
  exit 1
fi

case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*)
    # ── Windows (Git Bash) ────────────────────────────────────────────────
    # gjc.exe 는 네이티브 바이너리라 bash 스크립트를 .cmd 래퍼로 감싸 호출한다.
    LIBEXEC="$HOME/.local/libexec"; BINDIR="$HOME/.local/bin"
    GITBASH="C:\\Program Files\\Git\\bin\\bash.exe"
    mkdir -p "$LIBEXEC" "$BINDIR"
    install -m 755 "$SRC" "$LIBEXEC/gjc-acct"
    make_cmd() {
      cat > "$1" <<CMD
@echo off
set "MSYS=winsymlinks:nativestrict"
set "PATH=%USERPROFILE%\\.bun\\bin;%PATH%"
"$GITBASH" "%USERPROFILE%\\.local\\libexec\\gjc-acct" %*
CMD
    }
    make_cmd "$BINDIR/gjc-acct.cmd"
    [[ -d "$HOME/.bun/bin" ]] && make_cmd "$HOME/.bun/bin/gjc-acct.cmd"
    ok "설치 완료(Windows): $LIBEXEC/gjc-acct + gjc-acct.cmd 래퍼"
    say "PATH 에 %USERPROFILE%\\.local\\bin 또는 %USERPROFILE%\\.bun\\bin 이 있는지 확인하세요."
    ;;
  *)
    # ── Linux / macOS ─────────────────────────────────────────────────────
    PREFIX="${PREFIX:-/usr/local/bin}"
    BIN="$PREFIX/gjc-acct"; ALIAS="$PREFIX/gca"
    SUDO=""; [[ "$(id -u)" -ne 0 ]] && SUDO="sudo"
    say "설치: $SRC → $BIN"
    $SUDO install -m 755 "$SRC" "$BIN"
    $SUDO ln -sf "$BIN" "$ALIAS"
    ok "설치 완료: gjc-acct, gca (단축)"
    ;;
esac

command -v gjc >/dev/null 2>&1 || err "주의: 'gjc' CLI 가 PATH 에 없습니다 — Gajae-Code 를 먼저 설치하세요 (bun install -g gajae-code)."
command -v claude-acct >/dev/null 2>&1 || say "참고: Claude 슬롯 로그인은 claude-acct(자매 도구)로 관리합니다."
command -v codex-acct  >/dev/null 2>&1 || say "참고: Codex 슬롯 로그인은 codex-acct(자매 도구)로 관리합니다."

cat <<'NEXT'

다음 단계:
  claude-acct add work        # Claude 슬롯 생성 + 로그인
  codex-acct  add work        # (선택) Codex 슬롯 생성 + 로그인
  gjc-acct sources            # 탐지된 슬롯 확인
  gjc-acct work               # 그 계정으로 gjc 실행
  gjc-acct list               # 계정/인증/격리저장소 상태
  gjc-acct default work       # 무인자 실행 기본 계정 설정

프로젝트가 도움이 됐다면 GitHub에서 Star로 응원해 주세요(선택):
  https://github.com/yazzang-homelab/gjc-acct
NEXT
