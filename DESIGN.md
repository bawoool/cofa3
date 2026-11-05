# 디자인 메모 (frontend-design)
처음부터 적용한다. setup.sh가 `scratch/frontend-design/`에 받아 두고, "계획" 때 Codex가 읽어 PLAN.md에 디자인 방향을 정한다.
화면은 PLAN.md의 디자인 방향 + AGENTS.md 3-1 화면 원칙(명확함)을 함께 따른다.

## setup에서 받기를 실패했을 때 (수동)
```bash
git clone -q --depth 1 --filter=blob:none --sparse https://github.com/anthropics/skills.git /tmp/anskills && git -C /tmp/anskills sparse-checkout set skills/frontend-design && mkdir -p scratch && cp -r /tmp/anskills/skills/frontend-design scratch/
```
그다음 "계획"을 다시 요청하거나, PLAN.md에 디자인 방향만 추가하라고 지시.

## 중간에 겉모양만 다시 다듬고 싶을 때
1. Codex에 "커밋해줘" (되돌릴 지점)
2. 붙여넣기
```
PLAN.md 디자인 방향과 scratch/frontend-design/SKILL.md 기준으로 화면 겉모양만 다듬어줘.
기능·구조·JS 로직·테스트는 건드리지 마. 끝나면 테스트 실행하고 WORKLOG에 보고.
```
3. 미리보기로 직접 확인 → "브라우저 점검" → 깨진 게 있으면 "방금 디자인 커밋 revert해줘"
