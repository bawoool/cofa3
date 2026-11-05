# MCP 설정 메모 (Playwright)
용도: Codex가 브라우저로 직접 기능을 써 보며 내가 놓친 것을 찾기 (Codex 명령 "브라우저 점검")

## 설정 (3분)
1. IDE 왼쪽 MCP 탭 → 아래 JSON으로 바꾸고 → 저장
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--headless"]
    }
  }
}
```
2. Codex 재시작: `/quit` → `codex` (저장만으로는 적용 안 됨)
3. `/mcp` → playwright가 보이면 연결 성공
4. 하던 작업 이어가기: "이어서"

## 안 될 때
- `/mcp`에 안 보임 → MCP 탭에서 저장했는지, Codex를 재시작했는지 확인
- 브라우저 실행 실패 → Codex에게 "playwright 브라우저 설치가 필요한지 확인하고 설치해줘"
- 접속 주소: Codex와 서버가 같은 컴퓨터라 `http://localhost:8000` (포트는 실제 쓰는 것으로)

## 주의
- 페이지 구조를 통째로 읽어서 토큰을 많이 씀 → 기능마다가 아니라 몇 개 모아서, 그리고 기능 동결 전 전체 한 번
- 스크린샷은 실패한 경우만 `scratch/`에 저장
- 바울이 직접 눈으로 보는 확인을 대신하지 않는다 (놓친 것 찾기용)
