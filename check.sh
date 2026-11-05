#!/usr/bin/env bash
# 제출 전 점검. 원칙: 확인하지 못한 항목은 통과가 아니다.
# 사용: bash ~/.harness/check.sh
# 종료 코드: 0 전부 통과 / 1 실패 있음 / 3 실패는 없지만 확인 필요 항목 있음
cd "${1:-$PWD}" || exit 1
fail=0; warn=0
ok(){ printf "[ OK ] %s\n" "$1"; }
ng(){ printf "[FAIL] %s\n" "$1"; fail=$((fail+1)); }
ck(){ printf "[확인] %s\n" "$1"; warn=$((warn+1)); }

echo "── 제출 전 점검: $(pwd) ──"

# 1) git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ng "git 저장소가 아님"
else
  n=$(git rev-list --count HEAD 2>/dev/null || echo 0)
  if [ "$n" -gt 1 ]; then ok "커밋 ${n}개"; else ng "커밋 ${n}개 (작업 과정이 기록으로 남지 않음)"; fi
  c=$(git status --porcelain | wc -l)
  if [ "$c" -eq 0 ]; then ok "커밋 안 된 변경 없음"; else ng "커밋 안 된 변경 ${c}개 → git status --short"; fi
fi

# 2) 테스트: 실제로 돌았는지까지 확인
py_tests=$(git ls-files 2>/dev/null | grep -E '(^|/)(test_[^/]*|[^/]*_test)\.py$' | head -1)
if [ -n "$py_tests" ]; then
  # .venv가 실행되면 그 Python을 쓴다 (Codex는 명령마다 새 셸이라 activate가 이어지지 않음)
  py=python3
  if [ -e .venv ]; then
    if .venv/bin/python -c 'import sys' >/dev/null 2>&1; then py=.venv/bin/python
    else ck "깨진 .venv — rm -rf .venv 후 3차 설치"; fi
  fi
  printf "[정보] python: %s\n" "$py"
  out=$(timeout 120 "$py" -m pytest -q 2>&1 | tail -n 5)
  printf '%s\n' "$out" | sed 's/^/       /'
  passed=$(printf '%s' "$out" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' | head -1)
  if printf '%s' "$out" | grep -qE '[0-9]+ (failed|errors?)'; then ng "pytest 실패 있음"
  elif [ "${passed:-0}" -gt 0 ]; then ok "pytest ${passed}개 통과"
  else ng "pytest 실행된 테스트 0개 (통과가 아님)"; fi
elif [ -f package.json ] && grep -q '"test"' package.json; then
  if timeout 120 npm test --silent >/tmp/check_npm_test.log 2>&1; then
    ok "npm test 통과"; tail -n 5 /tmp/check_npm_test.log | sed 's/^/       /'
    ck "npm test 실행 개수를 위 로그에서 직접 확인"
  else ng "npm test 실패 → /tmp/check_npm_test.log"; fi
else
  ng "커밋된 테스트 없음 (test_*.py 또는 package.json의 test)"
fi

# 3) 비밀값 (커밋된 파일만)
pat='sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(api[_-]?key|secret|passwd|password|token)["'"'"' ]*[:=] *["'"'"']?[A-Za-z0-9_/+-]{12,}'
hits=$(git grep -nIiE "$pat" 2>/dev/null | head -n 5)
if [ -z "$hits" ]; then ok "비밀값 의심 패턴 없음 (커밋 파일 $(git ls-files 2>/dev/null | wc -l)개 검사)"
else ng "비밀값 의심 (오탐일 수 있음, 직접 확인):"; printf '%s\n' "$hits" | sed 's/^/       /'; fi

# 4) 웹 서버 (웹 과제일 때만 의미 있음)
listening(){
  if command -v ss >/dev/null 2>&1; then
    ss -ltn | grep -qE '(0\.0\.0\.0|\*|\[::\]):(3000|8000)\b'; return
  fi
  # ss가 없으면 /proc에서 직접 확인 (0A=LISTEN, 0BB8=3000, 1F40=8000, 주소 0=모든 인터페이스)
  local files=""; for f in /proc/net/tcp /proc/net/tcp6; do [ -r "$f" ] && files="$files $f"; done
  [ -n "$files" ] || return 1
  awk 'FNR>1 && $4=="0A" {split($2,a,":"); if ((a[2]=="0BB8"||a[2]=="1F40") && a[1] ~ /^0+$/) f=1} END{exit !f}' $files
}
if listening; then
  ok "3000/8000 포트가 외부(0.0.0.0)로 열려 있음"
else
  ck "3000/8000이 0.0.0.0에 LISTEN 아님 (서버 없음 또는 127.0.0.1 바인딩 → 웹 과제면 미리보기 불가)"
fi

# 5) 과제 원본 변경 여부 (첫 커밋에 있던 파일 중 바뀐 것. 하네스가 만든 파일은 제외)
first=$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -n 1)
if [ -n "$first" ]; then
  changed=$(git diff --name-only --diff-filter=MD "$first" -- . ':!AGENTS.md' ':!NOTES.md' ':!WORKLOG.md' ':!.gitignore' 2>/dev/null)
  if [ -z "$changed" ]; then ok "과제 원본 파일 변경 없음"
  else ck "과제 원본 중 바뀐 파일 (과제가 수정 금지했다면 되돌릴 것):"; printf '%s\n' "$changed" | head -n 10 | sed 's/^/       /'; fi
fi

# 6) 제출물 구성 (정보만, 아무것도 지우지 않음)
echo "── 제출물 구성 (숨김 폴더 제외) ──"
total=0
rootn=$(find . -maxdepth 1 -type f ! -name '.*' | wc -l); total=$((total+rootn))
printf "       %-16s %5d개\n" "(루트 파일)" "$rootn"
while IFS= read -r d; do
  n=$(find "$d" -type f | wc -l); total=$((total+n))
  printf "       %-16s %5d개\n" "${d#./}/" "$n"
done < <(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' | sort)
printf "       %-16s %5d개\n" "합계" "$total"
by=""
for p in __pycache__ .pytest_cache node_modules .venv; do
  c=$(find . -path ./.git -prune -o -type d -name "$p" -print 2>/dev/null | wc -l)
  [ "$c" -gt 0 ] && by="$by $p(${c}곳)"
done
[ -n "$by" ] && printf "[정보] 부산물:%s → 다시 생성 가능, 지워도 됨 (지우는 건 사용자 판단)\n" "$by"
big=$(find . -path ./.git -prune -o -path ./.venv -prune -o -path ./node_modules -prune -o -type f -size +5M -print 2>/dev/null | head -n 5)
[ -n "$big" ] && { echo "[정보] 5MB 넘는 파일:"; printf '%s\n' "$big" | sed 's/^/       /'; }
if [ -d .venv ] || [ -n "$(git ls-files '*.py' 2>/dev/null | head -1)" ]; then
  if [ ! -f requirements.txt ] && [ ! -f pyproject.toml ]; then ck "Python 프로젝트인데 requirements.txt 없음 (설치한 패키지 기록 필요)"; fi
fi

echo "──"
echo "실패 ${fail} · 확인 필요 ${warn}"
[ "$fail" -gt 0 ] && exit 1
[ "$warn" -gt 0 ] && exit 3
echo "전부 통과. 단, 요구사항이 맞는지는 실무자 합의와 테스트가 답한다."
exit 0
