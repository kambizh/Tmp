Review the following GitHub Copilot comment in PR #223, `.github/pr-review/automation.py`:

"[P2] Neither embedded script handles data-catalog-status-filter or data-alert-filter, so the new summary buttons do not filter results or update aria-pressed. Add scoped handlers and card/alert metadata, or render these totals as noninteractive elements. The same issue affects the alert-severity buttons at lines 5313–5324."

Please:
1. Investigate the relevant code and verify whether the finding is valid.
2. Explain the root cause.
3. Recommend the best solution consistent with the existing architecture.
4. Implement the minimal safe fix if the finding is valid.
5. Add or update relevant tests and run them.
6. Show me the changes and test results.

Do not commit or push anything. Do not modify unrelated code.
