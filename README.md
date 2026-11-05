# cofa3

AI 해커톤 2차 예선 재응시(Cofa-Probe)용 개인 작업 하네스. 직접 작성한 지침과 점검 스크립트만 들어 있고, 과제 내용·답안·결과물 코드는 없다.

운영팀 안내에 따라 이 저장소는 **2차 예선 결과 통지 전까지 공개 상태로 유지**한다. 키·토큰 등 비밀값은 넣지 않는다.

## 구성
| 파일 | 용도 |
|---|---|
| `AGENTS.md` | Codex 작업 규칙 (기능 단위 진행, WORKLOG 보고, 토큰 절약, 검증, 커밋, 짧은 명령) |
| `templates/NOTES.md` | 지금 상태 / 결정한 것 / AI가 틀렸던 것 / 한계 |
| `templates/WORKLOG.md` | 기능마다 쌓이는 쉬운 말 보고 (한 일 / 확인하는 법 / 이유 / 안 된 것) |
| `setup.sh` | 작업 폴더 준비: .gitignore, git 작성자, AGENTS·NOTES·WORKLOG 배치, 첫 커밋 |
| `check.sh` | 점검: 커밋, 테스트 실제 실행, 비밀값, 서버 바인딩, 과제 원본 변경, 제출물 구성 |

## 사용 (과제 README가 있는 폴더에서, 시작 직후)
```bash
git clone https://github.com/bawoool/cofa3.git ~/.harness && bash ~/.harness/setup.sh
```
- 플랫폼 설정(`~/.codex` 등)은 건드리지 않는다. 과제가 준 AGENTS.md가 있으면 덮어쓰지 않고 뒤에 덧붙인다.
- Codex 명령: 분석 / 계획 / 상태 / 리뷰 / 보안 리뷰 / 체크 / 인계 / 이어서 / 제출 준비
