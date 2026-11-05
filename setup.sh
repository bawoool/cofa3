#!/usr/bin/env bash
# 작업 폴더 초기 준비. 플랫폼 설정(~/.codex 등)은 건드리지 않는다.
# 사용: bash ~/.harness/setup.sh        (과제 README가 있는 폴더에서)
set -u
H="$(cd "$(dirname "$0")" && pwd)"
W="${1:-$PWD}"
NAME="${GIT_NAME:-bawool}"
EMAIL="${GIT_EMAIL:-bawool@example.com}"

cd "$W" || { echo "[ERR] 폴더 없음: $W"; exit 1; }
echo "작업 폴더: $(pwd)"
[ -f README.md ] || echo "[주의] 여기에 README.md가 없음. 과제 폴더가 맞는지 확인"

# 1) .gitignore: 숨김 파일(.bashrc, .codex, .npm, .literacy, .harness 등)이 커밋에 섞이지 않게
#    단, 과제 산출물이 될 수 있는 숨김 파일(.env.example, .dockerignore, .gitkeep)은 예외
touch .gitignore
for line in '.*' '!.gitignore' '!.env.example' '!.dockerignore' '!.gitkeep' 'node_modules/' '__pycache__/' '*.pyc' '.venv/' '*.log'; do
  grep -qxF -- "$line" .gitignore || echo "$line" >> .gitignore
done
echo "[ok] .gitignore"

# 2) git 저장소와 작성자
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { git init -q; echo "[ok] git init"; }
[ -n "$(git config user.name)" ]  || git config user.name  "$NAME"
[ -n "$(git config user.email)" ] || git config user.email "$EMAIL"
echo "[ok] git 작성자: $(git config user.name) <$(git config user.email)>"

# 3) AGENTS.md: 없으면 복사, 과제가 준 게 있으면 끝에 덧붙임(덮어쓰지 않음)
if [ ! -f AGENTS.md ]; then
  cp "$H/AGENTS.md" AGENTS.md; echo "[copy] AGENTS.md"
elif grep -q 'harness:bawool' AGENTS.md; then
  echo "[skip] AGENTS.md (이미 적용됨)"
else
  printf '\n\n' >> AGENTS.md; cat "$H/AGENTS.md" >> AGENTS.md; echo "[append] AGENTS.md (과제 원본 뒤에 덧붙임)"
fi

# 4) NOTES.md, WORKLOG.md: 없을 때만
for f in NOTES.md WORKLOG.md; do
  if [ -f "$f" ]; then echo "[skip] $f (이미 있음)"; else cp "$H/templates/$f" "$f"; echo "[copy] $f"; fi
done

# 5) 디자인 지침(Anthropic 공개 스킬 frontend-design)을 scratch/에 받기. 실패해도 계속 진행
if [ -f scratch/frontend-design/SKILL.md ]; then
  echo "[skip] scratch/frontend-design (이미 있음)"
else
  tmp=$(mktemp -d)
  if timeout 60 git clone -q --depth 1 --filter=blob:none --sparse https://github.com/anthropics/skills.git "$tmp/s" 2>/dev/null \
     && git -C "$tmp/s" sparse-checkout set skills/frontend-design 2>/dev/null \
     && [ -f "$tmp/s/skills/frontend-design/SKILL.md" ]; then
    mkdir -p scratch && cp -r "$tmp/s/skills/frontend-design" scratch/ && echo "[ok] scratch/frontend-design (디자인 지침)"
  else
    echo "[주의] frontend-design 받기 실패. 디자인 지침 없이 진행하거나 DESIGN.md의 수동 명령 사용"
  fi
  rm -rf "$tmp"
fi

# 6) 첫 커밋: 커밋이 하나도 없을 때만 (과제 원본 + 준비 파일)
if ! git rev-parse HEAD >/dev/null 2>&1; then
  git add -A
  git commit -q -m "[준비] 과제 원본과 작업 규칙·기록 틀 추가" && echo "[ok] 첫 커밋" && git show --stat --format='' HEAD | tail -n 15
else
  echo "[skip] 첫 커밋 (이미 커밋 있음). 필요하면: git add -A && git commit -m \"[준비] 작업 규칙 추가\""
fi

cat <<'EOF'

다음 할 일
  1. 실행 중인 Codex가 있으면 /quit 후 다시 codex 실행 (AGENTS.md 반영)
  2. 업데이트 창이 뜨면 "Skip until next version"
  3. /status 의 Agents.md 줄에 두 파일이 보이는지 확인
  4. Codex에 "분석" → TASK_BRIEF.md 읽기, INTERVIEW.md 질문을 담당자에게 하나씩 보내고 답변 칸에 붙여넣기
  5. Codex에 "계획" → PLAN.md 보고 스택·순서 결정 → 첫 기능부터
  6. 에디터에 WORKLOG.md 열어 두기 (기능마다 보고가 쌓임)
EOF
